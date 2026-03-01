/**
 * ============================================================================
 * CREATE PAYMENT INTENT — Supabase Edge Function
 * ============================================================================
 * Valida stock, precios y descuentos contra la BD, luego crea un
 * Stripe Customer + Ephemeral Key + PaymentIntent para el Payment Sheet
 * nativo de Flutter.
 *
 * POST /functions/v1/create-payment-intent
 * Body: { items: [{id, quantity, size}], shipping: {...}, discountCode? }
 * Auth: Bearer <supabase_jwt>
 * Returns: { clientSecret, ephemeralKey, customerId, paymentIntentId }
 * ============================================================================
 */
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const STRIPE_SECRET_KEY = Deno.env.get('STRIPE_SECRET_KEY') ?? ''

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

/** POST helper for Stripe REST API */
async function stripePost(
  endpoint: string,
  params: Record<string, string>,
  apiVersion?: string,
): Promise<any> {
  const headers: Record<string, string> = {
    'Authorization': `Bearer ${STRIPE_SECRET_KEY}`,
    'Content-Type': 'application/x-www-form-urlencoded',
  }
  if (apiVersion) headers['Stripe-Version'] = apiVersion

  const res = await fetch(`https://api.stripe.com/v1${endpoint}`, {
    method: 'POST',
    headers,
    body: new URLSearchParams(params).toString(),
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
    if (!STRIPE_SECRET_KEY) {
      return json({ error: 'Stripe no configurado en el servidor' }, 500)
    }

    // ════════════════════════════════════════════════════════════
    // 1. AUTENTICACIÓN
    // ════════════════════════════════════════════════════════════
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      { auth: { autoRefreshToken: false, persistSession: false } },
    )

    const token = (req.headers.get('Authorization') ?? '').replace('Bearer ', '')
    let user: any = null
    if (token) {
      const { data } = await supabaseAdmin.auth.getUser(token)
      user = data.user
    }

    // ════════════════════════════════════════════════════════════
    // 2. PARSEAR BODY
    // ════════════════════════════════════════════════════════════
    const body = await req.json()
    const { items, shipping, discountCode } = body

    if (!items || !Array.isArray(items) || items.length === 0) {
      return json({ error: 'El carrito está vacío' }, 400)
    }
    if (items.length > 50) {
      return json({ error: 'Demasiados artículos en el carrito' }, 400)
    }

    // ════════════════════════════════════════════════════════════
    // 2.5 VALIDAR ESTRUCTURA DE CADA ITEM
    // ════════════════════════════════════════════════════════════
    const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i

    for (const item of items) {
      if (!item.id || typeof item.id !== 'string' || !UUID_RE.test(item.id)) {
        return json({ error: 'ID de producto no válido' }, 400)
      }
      if (!Number.isInteger(item.quantity) || item.quantity < 1 || item.quantity > 99) {
        return json({ error: 'Cantidad no válida' }, 400)
      }
      if (item.size !== undefined && (typeof item.size !== 'string' || item.size.length > 10)) {
        return json({ error: 'Talla no válida' }, 400)
      }
    }

    // ════════════════════════════════════════════════════════════
    // 3. VALIDAR PRODUCTOS EN BD
    // ════════════════════════════════════════════════════════════
    const productIds = items.map((i: any) => i.id)
    const { data: products, error: productsError } = await supabaseAdmin
      .from('products')
      .select('id, name, slug, sku, price, sale_price, is_on_sale, stock, stock_by_size, images')
      .in('id', productIds)

    if (productsError || !products) {
      console.error('[PI] Error validando productos:', productsError)
      return json({ error: 'Error al validar productos' }, 500)
    }

    const productMap = new Map(products.map((p: any) => [p.id, p]))

    // ════════════════════════════════════════════════════════════
    // 4. VALIDAR STOCK (lectura fresca por producto)
    // ════════════════════════════════════════════════════════════
    for (const item of items) {
      const product = productMap.get(item.id)
      if (!product) {
        return json({ error: `Producto no encontrado: ${item.id}` }, 400)
      }

      const itemSize = item.size || 'Única'
      const cartQty = item.quantity

      // Stock fresco
      const { data: fresh } = await supabaseAdmin
        .from('products')
        .select('stock, stock_by_size')
        .eq('id', item.id)
        .single()

      const stockBySize = fresh?.stock_by_size ?? product.stock_by_size
      const stockGlobal = fresh?.stock ?? product.stock ?? 0

      let available = 0
      if (stockBySize && typeof stockBySize === 'object' && itemSize in stockBySize) {
        available = stockBySize[itemSize] || 0
      } else {
        available = stockGlobal
      }

      if (available < cartQty) {
        return json(
          { error: `No hay suficiente stock de "${product.name}" en talla ${itemSize}` },
          400,
        )
      }
    }

    // ════════════════════════════════════════════════════════════
    // 5. CALCULAR TOTALES (precios de BD, única fuente de verdad)
    // ════════════════════════════════════════════════════════════
    let totalAmount = 0 // en céntimos
    for (const item of items) {
      const product = productMap.get(item.id)!
      // Usar sale_price cuando el producto está en rebaja
      const effectivePrice =
        product.is_on_sale && product.sale_price != null
          ? product.sale_price
          : product.price
      totalAmount += effectivePrice * item.quantity
    }

    // ════════════════════════════════════════════════════════════
    // 6. CÓDIGO DE DESCUENTO
    // ════════════════════════════════════════════════════════════
    let discountAmount = 0
    if (discountCode && discountCode.trim()) {
      try {
        const { data: validation, error: dErr } = await supabaseAdmin.rpc(
          'validate_discount_code',
          {
            p_code: discountCode.trim(),
            p_cart_total: totalAmount / 100,
            p_user_id: user?.id || null,
          },
        )

        if (!dErr && validation) {
          if (!validation.valid) {
            return json({ error: validation.message }, 400)
          }
          discountAmount = Math.round((validation.discount_amount || 0) * 100)
        }
      } catch (_) {
        /* continuar sin descuento */
      }
    }

    const finalAmount = Math.max(totalAmount - discountAmount, 50) // mín 50 cents

    // ════════════════════════════════════════════════════════════
    // 7. STRIPE: Customer + Ephemeral Key + PaymentIntent
    // ════════════════════════════════════════════════════════════
    const customer = await stripePost('/customers', {
      email: user?.email || shipping?.email || '',
      name: shipping?.fullName || '',
      'metadata[user_id]': user?.id || 'guest',
    })

    if (customer.error) {
      console.error('[PI] Stripe customer error:', customer.error)
      return json({ error: 'Error al crear cliente de pago' }, 500)
    }

    const ephemeralKey = await stripePost(
      '/ephemeral_keys',
      { customer: customer.id },
      '2025-12-15.clover',
    )

    // Metadata compacta (Stripe limita 500 chars por valor)
    const orderItemsSizes = JSON.stringify(
      items.map((i: any) => ({ id: i.id, size: i.size || 'Única', qty: i.quantity })),
    )

    const shippingMeta = shipping
      ? JSON.stringify({
          fn: shipping.fullName || '',
          em: shipping.email || '',
          ph: shipping.phone || '',
          a1: shipping.addressLine1 || '',
          a2: shipping.addressLine2 || '',
          ci: shipping.city || '',
          st: shipping.state || '',
          pc: shipping.postalCode || '',
          co: shipping.country || 'ES',
          no: shipping.notes || '',
        })
      : '{}'

    const paymentIntent = await stripePost('/payment_intents', {
      amount: finalAmount.toString(),
      currency: 'eur',
      customer: customer.id,
      'automatic_payment_methods[enabled]': 'true',
      'metadata[user_id]': user?.id || 'guest',
      'metadata[user_email]': user?.email || shipping?.email || '',
      'metadata[total_amount]': totalAmount.toString(),
      'metadata[discount_code]': discountCode || '',
      'metadata[discount_amount]': discountAmount.toString(),
      'metadata[order_items_sizes]': orderItemsSizes,
      'metadata[shipping]': shippingMeta,
      'metadata[source]': 'flutter_payment_sheet',
    })

    if (paymentIntent.error) {
      console.error('[PI] Stripe PI error:', paymentIntent.error)
      return json({ error: 'Error al crear el pago' }, 500)
    }

    console.log(`[PI] PaymentIntent creado: ${paymentIntent.id} (${finalAmount / 100}€)`)

    // ════════════════════════════════════════════════════════════
    // 8. RESPUESTA
    // ════════════════════════════════════════════════════════════
    return json({
      clientSecret: paymentIntent.client_secret,
      ephemeralKey: ephemeralKey.secret,
      customerId: customer.id,
      paymentIntentId: paymentIntent.id,
    })
  } catch (error: any) {
    console.error('[PI] Error general:', error)
    return json({ error: 'Error al procesar el pago' }, 500)
  }
})
