/**
 * ============================================================================
 * CANCEL ORDER — Supabase Edge Function
 * ============================================================================
 * Cancela un pedido reciente (≤2h), restaura stock y hace refund en Stripe.
 *
 * POST /functions/v1/cancel-order
 * Body: { orderId: string }
 * Auth: Bearer <supabase_jwt>
 * Returns: { status, message }
 * ============================================================================
 */
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const STRIPE_SECRET_KEY = Deno.env.get('STRIPE_SECRET_KEY') ?? ''
const CANCEL_TIMEOUT_HOURS = 2

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

/** POST helper for Stripe REST API */
async function stripePost(
  endpoint: string,
  params: Record<string, string>,
): Promise<any> {
  const res = await fetch(`https://api.stripe.com/v1${endpoint}`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${STRIPE_SECRET_KEY}`,
      'Content-Type': 'application/x-www-form-urlencoded',
    },
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
    if (!user) {
      return json({ error: 'No autorizado' }, 401)
    }

    // ════════════════════════════════════════════════════════════
    // 2. VALIDAR INPUT
    // ════════════════════════════════════════════════════════════
    const { orderId } = await req.json()
    if (!orderId || typeof orderId !== 'string') {
      return json({ error: 'orderId requerido' }, 400)
    }

    // ════════════════════════════════════════════════════════════
    // 3. OBTENER PEDIDO
    // ════════════════════════════════════════════════════════════
    const { data: order, error: orderErr } = await supabaseAdmin
      .from('orders')
      .select('*, order_items(*)')
      .eq('id', orderId)
      .single()

    if (orderErr || !order) {
      return json({ error: 'Pedido no encontrado' }, 404)
    }

    // Verificar que el pedido pertenece al usuario
    if (order.user_id !== user.id) {
      return json({ error: 'No tienes permiso para cancelar este pedido' }, 403)
    }

    // Solo se pueden cancelar pedidos confirmados/pendientes
    if (!['confirmed', 'pending', 'processing'].includes(order.status)) {
      return json({ error: `No se puede cancelar un pedido con estado "${order.status}"` }, 400)
    }

    // Verificar ventana de cancelación (2 horas)
    const createdAt = new Date(order.created_at)
    const now = new Date()
    const hoursElapsed = (now.getTime() - createdAt.getTime()) / (1000 * 60 * 60)
    if (hoursElapsed > CANCEL_TIMEOUT_HOURS) {
      return json({
        error: `El plazo de cancelación (${CANCEL_TIMEOUT_HOURS}h) ha expirado. Solicita una devolución.`,
      }, 400)
    }

    console.log(`[CANCEL] Cancelando pedido ${order.order_number} (${orderId})`)

    // ════════════════════════════════════════════════════════════
    // 4. REFUND EN STRIPE (si hay payment_id)
    // ════════════════════════════════════════════════════════════
    let refundId: string | null = null
    if (order.payment_id && STRIPE_SECRET_KEY) {
      try {
        const refund = await stripePost('/refunds', {
          payment_intent: order.payment_id,
        })
        if (refund.id) {
          refundId = refund.id
          console.log(`[CANCEL] Stripe refund creado: ${refund.id}`)
        } else {
          console.warn('[CANCEL] Stripe refund error:', refund.error)
        }
      } catch (e: any) {
        console.error('[CANCEL] Error en Stripe refund:', e.message)
      }
    }

    // ════════════════════════════════════════════════════════════
    // 5. RESTAURAR STOCK
    // ════════════════════════════════════════════════════════════
    const orderItems = order.order_items || []
    for (const item of orderItems) {
      if (!item.product_id) continue

      const quantity = item.quantity || 1
      const size = item.size || 'Única'

      try {
        // Usar RPC increment_stock (parámetros: product_id, quantity, p_size)
        const { error: rpcErr } = await supabaseAdmin.rpc('increment_stock', {
          product_id: item.product_id,
          quantity: quantity,
          p_size: size,
        })

        if (rpcErr) {
          console.warn(`[CANCEL] RPC increment_stock falló para ${item.product_id}:`, rpcErr.message)
          // Fallback manual
          await _fallbackIncrementStock(supabaseAdmin, item.product_id, quantity, size)
        } else {
          console.log(`[CANCEL] Stock restaurado: ${item.product_name} x${quantity} (${size})`)
        }
      } catch (_) {
        await _fallbackIncrementStock(supabaseAdmin, item.product_id, quantity, size)
      }
    }

    // ════════════════════════════════════════════════════════════
    // 6. ACTUALIZAR PEDIDO
    // ════════════════════════════════════════════════════════════
    await supabaseAdmin
      .from('orders')
      .update({
        status: 'cancelled',
        payment_status: refundId ? 'refunded' : 'cancelled',
        admin_notes: `${order.admin_notes || ''} | Cancelado por usuario ${new Date().toISOString()}${refundId ? ` | Refund: ${refundId}` : ''}`,
        updated_at: new Date().toISOString(),
      })
      .eq('id', orderId)

    // ════════════════════════════════════════════════════════════
    // 7. CREAR REGISTRO EN RETURNS (para historial)
    // ════════════════════════════════════════════════════════════
    try {
      await supabaseAdmin.from('returns').insert({
        order_id: orderId,
        type: 'cancellation',
        reason: 'changed_mind',
        description: 'Cancelación solicitada por el cliente',
        status: 'refunded',
        refund_amount: order.total || 0,
        customer_email: order.customer_email || user.email || '',
        requested_at: new Date().toISOString(),
        items: orderItems.map((oi: any) => ({
          product_id: oi.product_id,
          product_name: oi.product_name,
          size: oi.size,
          quantity: oi.quantity,
          price: oi.price,
          subtotal: oi.subtotal,
          product_image: oi.product_image,
        })),
      })
    } catch (e: any) {
      console.warn('[CANCEL] Error creando registro returns:', e.message)
    }

    // ════════════════════════════════════════════════════════════
    // 8. ENVIAR EMAIL DE CANCELACIÓN
    // ════════════════════════════════════════════════════════════
    try {
      const customerEmail = order.customer_email || user.email
      if (customerEmail) {
        await fetch(`${Deno.env.get('SUPABASE_URL')}/functions/v1/send-order-email`, {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            type: 'order_cancelled',
            to_email: customerEmail,
            to_name: order.shipping_full_name || 'Cliente',
            order_number: order.order_number,
            order_items: orderItems.map((oi: any) => ({
              product_name: oi.product_name || 'Producto',
              product_image: oi.product_image || '',
              size: oi.size || '-',
              quantity: oi.quantity || 1,
              price: oi.price || 0,
              subtotal: oi.subtotal || (oi.price || 0) * (oi.quantity || 1),
            })),
            subtotal: order.subtotal || order.total || 0,
            shipping_cost: order.shipping_cost || 0,
            discount: order.discount || 0,
            total: order.total || 0,
          }),
        })
        console.log(`[CANCEL] Email de cancelación enviado a ${customerEmail}`)
      }
    } catch (_) {
      console.warn('[CANCEL] Error enviando email de cancelación')
    }

    // ════════════════════════════════════════════════════════════
    // 9. RESPUESTA
    // ════════════════════════════════════════════════════════════
    return json({
      status: 'cancelled',
      message: 'Pedido cancelado correctamente. El reembolso se procesará en 5-10 días laborables.',
      refundId,
    })
  } catch (error: any) {
    console.error('[CANCEL] Error general:', error)
    return json({ error: 'Error al cancelar pedido' }, 500)
  }
})

/** Fallback: incrementar stock manualmente si la RPC falla */
async function _fallbackIncrementStock(
  supabase: any,
  productId: string,
  quantity: number,
  size: string,
) {
  try {
    const { data: prod } = await supabase
      .from('products')
      .select('stock, stock_by_size')
      .eq('id', productId)
      .single()

    if (!prod) return

    const updateData: any = {
      stock: (prod.stock || 0) + quantity,
      updated_at: new Date().toISOString(),
    }

    if (prod.stock_by_size && typeof prod.stock_by_size === 'object') {
      const sizeStock = prod.stock_by_size as Record<string, number>
      if (size in sizeStock) {
        sizeStock[size] = (sizeStock[size] || 0) + quantity
        updateData.stock_by_size = sizeStock
      }
    }

    await supabase.from('products').update(updateData).eq('id', productId)
    console.log(`[CANCEL] Stock restaurado (fallback): ${productId} +${quantity}`)
  } catch (e: any) {
    console.error(`[CANCEL] Error fallback stock ${productId}:`, e.message)
  }
}
