/**
 * ============================================================================
 * CONFIRM PAYMENT — Supabase Edge Function
 * ============================================================================
 * Tras pago exitoso en el Payment Sheet, Flutter llama aquí para:
 *   1. Verificar con Stripe que el PaymentIntent fue exitoso
 *   2. Crear order + order_items en la BD
 *   3. Decrementar stock (RPC atómico + fallback)
 *   4. Incrementar uso de código de descuento
 *   5. Enviar email de confirmación (vía send-order-email)
 *
 * POST /functions/v1/confirm-payment
 * Body: { paymentIntentId: string }
 * Auth: Bearer <supabase_jwt>
 * Returns: { status, order: { id, orderNumber } }
 * ============================================================================
 */
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const STRIPE_SECRET_KEY = Deno.env.get('STRIPE_SECRET_KEY') ?? ''

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

/** GET helper for Stripe REST API */
async function stripeGet(endpoint: string): Promise<any> {
  const res = await fetch(`https://api.stripe.com/v1${endpoint}`, {
    headers: { 'Authorization': `Bearer ${STRIPE_SECRET_KEY}` },
  })
  return res.json()
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  const json = (body: unknown, status = 200) =>
    new Response(JSON.stringify(body), {
      status,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })

  try {
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      { auth: { autoRefreshToken: false, persistSession: false } },
    )

    // ════════════════════════════════════════════════════════════
    // 1. AUTENTICACIÓN
    // ════════════════════════════════════════════════════════════
    const token = (req.headers.get('Authorization') ?? '').replace('Bearer ', '')
    let user: any = null
    if (token) {
      const { data } = await supabaseAdmin.auth.getUser(token)
      user = data.user
    }

    // ════════════════════════════════════════════════════════════
    // 2. VALIDAR INPUT
    // ════════════════════════════════════════════════════════════
    const { paymentIntentId } = await req.json()

    if (!paymentIntentId || typeof paymentIntentId !== 'string') {
      return json({ error: 'paymentIntentId requerido' }, 400)
    }
    if (!/^pi_[a-zA-Z0-9]+$/.test(paymentIntentId)) {
      return json({ error: 'paymentIntentId inválido' }, 400)
    }

    console.log(`[CONFIRM] Verificando PaymentIntent: ${paymentIntentId}`)

    // ════════════════════════════════════════════════════════════
    // 3. VERIFICAR CON STRIPE QUE EL PAGO FUE EXITOSO
    // ════════════════════════════════════════════════════════════
    const paymentIntent = await stripeGet(`/payment_intents/${paymentIntentId}`)

    if (paymentIntent.error) {
      console.error('[CONFIRM] PI no encontrado:', paymentIntent.error)
      return json({ error: 'PaymentIntent no encontrado' }, 404)
    }

    if (paymentIntent.status !== 'succeeded') {
      console.log(`[CONFIRM] PI ${paymentIntentId} status: ${paymentIntent.status}`)
      return json({
        status: 'pending',
        message: 'Pago aún no completado',
        paymentStatus: paymentIntent.status,
      })
    }

    // ════════════════════════════════════════════════════════════
    // 4. COMPROBAR DUPLICADOS
    // ════════════════════════════════════════════════════════════
    const { data: existingOrder } = await supabaseAdmin
      .from('orders')
      .select('id, order_number, status')
      .or(`payment_id.eq.${paymentIntentId},admin_notes.ilike.%${paymentIntentId}%`)
      .maybeSingle()

    if (existingOrder) {
      console.log(`[CONFIRM] Pedido ya existe: ${existingOrder.order_number}`)
      return json({
        status: 'exists',
        order: {
          id: existingOrder.id,
          orderNumber: existingOrder.order_number,
        },
      })
    }

    // ════════════════════════════════════════════════════════════
    // 5. EXTRAER METADATA DEL PAYMENT INTENT
    // ════════════════════════════════════════════════════════════
    console.log('[CONFIRM] Pedido NO encontrado, creando...')

    const meta = paymentIntent.metadata || {}
    const userId = meta.user_id && meta.user_id !== 'guest' ? meta.user_id : user?.id || null
    const discountCode = meta.discount_code || ''
    const discountAmountCents = parseInt(meta.discount_amount || '0', 10)
    const totalAmountCents = parseInt(meta.total_amount || '0', 10)

    // Items con tallas
    let orderItemsSizes: Array<{ id: string; size: string; qty: number }> = []
    try {
      if (meta.order_items_sizes) orderItemsSizes = JSON.parse(meta.order_items_sizes)
    } catch (_) {
      console.warn('[CONFIRM] Error parsing order_items_sizes')
    }

    // Shipping
    let shippingData: any = {}
    try {
      if (meta.shipping) {
        const s = JSON.parse(meta.shipping)
        shippingData = {
          fullName: s.fn || '',
          email: s.em || '',
          phone: s.ph || '',
          addressLine1: s.a1 || '',
          addressLine2: s.a2 || '',
          city: s.ci || '',
          state: s.st || '',
          postalCode: s.pc || '',
          country: s.co || 'ES',
          notes: s.no || '',
        }
      }
    } catch (_) {
      console.warn('[CONFIRM] Error parsing shipping metadata')
    }

    // ════════════════════════════════════════════════════════════
    // 6. CREAR PEDIDO EN BASE DE DATOS
    // ════════════════════════════════════════════════════════════
    const totalCents = paymentIntent.amount || 0
    const subtotalCents = totalAmountCents || totalCents

    const yearNow = new Date().getFullYear()
    const rndSuffix = Math.random().toString(36).substring(2, 8).toUpperCase()
    const orderNumber = `ORD-${yearNow}-${Date.now().toString().slice(-6)}-${rndSuffix}`

    const customerEmail = shippingData.email || meta.user_email || user?.email || ''
    const customerName = shippingData.fullName || 'Cliente'

    const { data: order, error: orderError } = await supabaseAdmin
      .from('orders')
      .insert({
        order_number: orderNumber,
        user_id: userId,
        shipping_full_name: customerName,
        shipping_phone: shippingData.phone || '',
        shipping_address_line1: shippingData.addressLine1 || 'Dirección no proporcionada',
        shipping_address_line2: shippingData.addressLine2 || null,
        shipping_city: shippingData.city || 'Ciudad',
        shipping_state: shippingData.state || '',
        shipping_postal_code: shippingData.postalCode || '00000',
        shipping_country: shippingData.country || 'ES',
        customer_email: customerEmail,
        subtotal: subtotalCents / 100,
        shipping_cost: 0,
        tax: 0,
        discount: discountAmountCents / 100,
        total: totalCents / 100,
        payment_method: 'card',
        payment_status: 'paid',
        payment_id: paymentIntentId,
        status: 'confirmed',
        customer_notes: discountCode
          ? `Código aplicado: ${discountCode}`
          : shippingData.notes || null,
        admin_notes: `[FLUTTER] PaymentIntent: ${paymentIntentId} | Email: ${customerEmail}`,
      })
      .select()
      .single()

    if (orderError) {
      console.error('[CONFIRM] Error creando pedido:', orderError)
      return json({ error: 'Error creando pedido' }, 500)
    }

    console.log(`[CONFIRM] Pedido creado: ${order.order_number} (ID: ${order.id})`)

    // ════════════════════════════════════════════════════════════
    // 7. CREAR ORDER_ITEMS Y DECREMENTAR STOCK
    // ════════════════════════════════════════════════════════════
    const productIds = orderItemsSizes.map((oi) => oi.id)
    const emailItems: any[] = []

    if (productIds.length > 0) {
      const { data: products } = await supabaseAdmin
        .from('products')
        .select('id, name, slug, sku, price, sale_price, is_on_sale, images, stock, stock_by_size')
        .in('id', productIds)

      const productMap = new Map((products || []).map((p: any) => [p.id, p]))

      // Intentar decrement atómico vía RPC
      let stockRpcOk = false
      try {
        const rpcItems = orderItemsSizes.map((oi) => ({
          product_id: oi.id,
          quantity: oi.qty,
          size: oi.size || 'Única',
        }))
        const { error: rpcError } = await supabaseAdmin.rpc(
          'validate_and_decrement_stock',
          { p_items: rpcItems },
        )
        if (!rpcError) {
          stockRpcOk = true
          console.log('[CONFIRM] Stock decrementado vía RPC')
        } else {
          console.warn('[CONFIRM] RPC stock falló:', rpcError.message)
        }
      } catch (_) {
        console.warn('[CONFIRM] RPC no disponible')
      }

      for (const oi of orderItemsSizes) {
        const product = productMap.get(oi.id)
        if (!product) continue

        const itemSize = oi.size || 'Única'
        const quantity = oi.qty || 1
        // Usar sale_price cuando el producto está en rebaja
        const pricePerUnit =
          product.is_on_sale && product.sale_price != null
            ? product.sale_price
            : (product.price || 0)
        const productImage = product.images?.[0] || null

        // Crear order_item
        await supabaseAdmin.from('order_items').insert({
          order_id: order.id,
          product_id: product.id,
          product_name: product.name,
          product_slug: product.slug,
          product_image: productImage,
          size: itemSize,
          color: null,
          price: pricePerUnit / 100,
          quantity,
          subtotal: (pricePerUnit * quantity) / 100,
        })

        emailItems.push({
          name: product.name,
          quantity,
          size: itemSize,
          price: pricePerUnit / 100,
          image: productImage,
        })

        // Fallback: decrementar stock directamente si RPC no funcionó
        if (!stockRpcOk) {
          try {
            const { data: freshProd } = await supabaseAdmin
              .from('products')
              .select('stock, stock_by_size')
              .eq('id', product.id)
              .single()

            if (freshProd) {
              const newStock = Math.max(0, (freshProd.stock || 0) - quantity)
              const updateData: any = {
                stock: newStock,
                updated_at: new Date().toISOString(),
              }

              if (freshProd.stock_by_size && typeof freshProd.stock_by_size === 'object') {
                const sizeStock = freshProd.stock_by_size as Record<string, number>
                if (itemSize in sizeStock) {
                  sizeStock[itemSize] = Math.max(0, (sizeStock[itemSize] || 0) - quantity)
                  updateData.stock_by_size = sizeStock
                }
              }

              await supabaseAdmin
                .from('products')
                .update(updateData)
                .eq('id', product.id)
            }
          } catch (e: any) {
            console.error(`[CONFIRM] Error fallback stock ${product.id}:`, e.message)
          }
        }
      }
    }

    // ════════════════════════════════════════════════════════════
    // 8. INCREMENTAR USO DEL CÓDIGO DE DESCUENTO
    // ════════════════════════════════════════════════════════════
    if (discountCode) {
      try {
        await supabaseAdmin.rpc('increment_discount_usage', { p_code: discountCode })
        console.log(`[CONFIRM] Descuento incrementado: ${discountCode}`)
      } catch (_) {
        console.warn('[CONFIRM] Error incrementando descuento')
      }
    }

    // ════════════════════════════════════════════════════════════
    // 9. ENVIAR EMAIL DE CONFIRMACIÓN
    // ════════════════════════════════════════════════════════════
    try {
      if (customerEmail) {
        const emailRes = await fetch(
          `${Deno.env.get('SUPABASE_URL')}/functions/v1/send-order-email`,
          {
            method: 'POST',
            headers: {
              'Authorization': `Bearer ${Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')}`,
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({
              type: 'purchase_confirmation',
              to_email: customerEmail,
              to_name: customerName,
              order_number: order.order_number,
              order_items: emailItems,
              subtotal: subtotalCents / 100,
              shipping_cost: 0,
              discount: discountAmountCents / 100,
              total: totalCents / 100,
            }),
          },
        )

        if (emailRes.ok) {
          console.log(`[CONFIRM] Email de confirmación enviado a ${customerEmail}`)
        } else {
          console.warn('[CONFIRM] Email respondió con status:', emailRes.status)
        }
      }
    } catch (emailErr: any) {
      console.error('[CONFIRM] Error enviando email:', emailErr.message)
      // No fallar la confirmación por el email
    }

    // ════════════════════════════════════════════════════════════
    // 10. RESPUESTA EXITOSA
    // ════════════════════════════════════════════════════════════
    return json({
      status: 'created',
      order: {
        id: order.id,
        orderNumber: order.order_number,
      },
      message: 'Pedido creado correctamente',
    })
  } catch (error: any) {
    console.error('[CONFIRM] Error general:', error)
    return json(
      { error: 'Error confirmando pedido', details: error.message },
      500,
    )
  }
})
