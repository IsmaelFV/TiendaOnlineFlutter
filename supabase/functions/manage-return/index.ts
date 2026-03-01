/**
 * ============================================================================
 * MANAGE RETURN — Supabase Edge Function
 * ============================================================================
 * Gestiona devoluciones:
 *   - request  (usuario autenticado) → crea solicitud de devolución
 *   - approve  (admin) → aprueba la solicitud
 *   - reject   (admin) → rechaza la solicitud
 *   - complete (admin) → procesa refund Stripe + restaura stock
 *
 * POST /functions/v1/manage-return
 * Body: { action: 'request'|'approve'|'reject'|'complete', ... }
 * Auth: Bearer <supabase_jwt>
 * Returns: { status, message }
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

/** Genera un return_number único */
function generateReturnNumber(): string {
  const now = new Date()
  const y = now.getFullYear()
  const m = String(now.getMonth() + 1).padStart(2, '0')
  const d = String(now.getDate()).padStart(2, '0')
  const rand = Math.floor(1000 + Math.random() * 9000)
  return `RET-${y}${m}${d}-${rand}`
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
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? ''

    const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    })

    // ════════════════════════════════════════════════════════════
    // 1. AUTENTICACIÓN
    // ════════════════════════════════════════════════════════════
    const authHeader = req.headers.get('Authorization') ?? ''
    const token = authHeader.replace('Bearer ', '')

    // Verificar usuario con el anon client para respetar JWT
    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    })
    const { data: { user }, error: authError } = await userClient.auth.getUser()

    if (authError || !user) {
      return json({ error: 'No autorizado' }, 401)
    }

    // ════════════════════════════════════════════════════════════
    // 2. PARSEAR INPUT
    // ════════════════════════════════════════════════════════════
    const body = await req.json()
    const { action } = body

    // ════════════════════════════════════════════════════════════
    // 3. SOLICITUD DE DEVOLUCIÓN (USUARIO)
    // ════════════════════════════════════════════════════════════
    if (action === 'request') {
      const { orderId, reason, description, items, refundAmount } = body

      if (!orderId) return json({ error: 'orderId requerido' }, 400)
      if (!reason) return json({ error: 'Motivo requerido' }, 400)

      // Verificar que el pedido pertenece al usuario
      const { data: order, error: orderErr } = await supabaseAdmin
        .from('orders')
        .select('*, order_items(*)')
        .eq('id', orderId)
        .single()

      if (orderErr || !order) {
        return json({ error: 'Pedido no encontrado' }, 404)
      }

      if (order.user_id !== user.id) {
        return json({ error: 'Este pedido no te pertenece' }, 403)
      }

      // No permitir si ya está cancelado/reembolsado/en devolución
      const blocked = ['cancelled', 'refunded', 'return_requested']
      if (blocked.includes(order.status)) {
        return json({ error: `No se puede solicitar devolución para un pedido con estado "${order.status}"` }, 400)
      }

      // Verificar si ya existe una devolución pendiente
      const { data: existingReturn } = await supabaseAdmin
        .from('returns')
        .select('id')
        .eq('order_id', orderId)
        .in('status', ['pending', 'approved'])
        .maybeSingle()

      if (existingReturn) {
        return json({ error: 'Ya existe una solicitud de devolución pendiente para este pedido' }, 400)
      }

      // Calcular items de la devolución
      const returnItems = items || order.order_items.map((oi: any) => ({
        product_id: oi.product_id,
        product_name: oi.product_name,
        product_image: oi.product_image,
        order_item_id: oi.id,
        size: oi.size || 'Única',
        quantity: oi.quantity || 1,
        refund_amount: oi.subtotal || (oi.price * oi.quantity),
      }))

      const totalRefund = refundAmount ??
        returnItems.reduce((sum: number, i: any) => sum + (i.refund_amount || 0), 0)

      const returnNumber = generateReturnNumber()
      const now = new Date().toISOString()

      // Crear registro de devolución
      const { data: newReturn, error: insertErr } = await supabaseAdmin
        .from('returns')
        .insert({
          order_id: orderId,
          status: 'pending',
          reason: reason,
          description: description || null,
          items: returnItems,
          refund_amount: totalRefund,
          customer_email: order.customer_email || user.email || '',
          type: 'return',
          requested_at: now,
          return_deadline: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
        })
        .select()
        .single()

      if (insertErr) {
        console.error('[RETURN] Error creando devolución:', insertErr.message)
        throw insertErr
      }

      // Actualizar estado del pedido
      await supabaseAdmin
        .from('orders')
        .update({
          status: 'return_requested',
          updated_at: now,
        })
        .eq('id', orderId)

      // Enviar email de confirmación
      await _sendReturnEmail(supabaseAdmin, newReturn, 'refund_requested')

      return json({
        status: 'requested',
        message: 'Solicitud de devolución creada correctamente',
        returnId: newReturn.id,
      })
    }

    // ════════════════════════════════════════════════════════════
    // ACCIONES ADMIN: verificar permisos
    // ════════════════════════════════════════════════════════════
    const { data: adminRow } = await supabaseAdmin
      .from('admin_users')
      .select('id')
      .eq('user_id', user.id)
      .maybeSingle()

    if (!adminRow) {
      return json({ error: 'Se requieren permisos de administrador' }, 403)
    }

    const { returnId, adminNotes } = body

    if (!returnId || typeof returnId !== 'string') {
      return json({ error: 'returnId requerido' }, 400)
    }
    if (!['approve', 'reject', 'complete'].includes(action)) {
      return json({ error: 'action debe ser approve, reject o complete' }, 400)
    }

    // ════════════════════════════════════════════════════════════
    // 3. OBTENER DEVOLUCIÓN
    // ════════════════════════════════════════════════════════════
    const { data: ret, error: retErr } = await supabaseAdmin
      .from('returns')
      .select('*')
      .eq('id', returnId)
      .single()

    if (retErr || !ret) {
      return json({ error: 'Devolución no encontrada' }, 404)
    }

    console.log(`[RETURN] Procesando ${action} para return ${returnId}`)

    // ════════════════════════════════════════════════════════════
    // 4. APROBAR
    // ════════════════════════════════════════════════════════════
    if (action === 'approve') {
      if (ret.status !== 'pending') {
        return json({ error: `No se puede aprobar una devolución con estado "${ret.status}"` }, 400)
      }

      await supabaseAdmin
        .from('returns')
        .update({
          status: 'approved',
        })
        .eq('id', returnId)

      // Enviar email de aprobación
      await _sendReturnEmail(supabaseAdmin, ret, 'refund_approved', adminNotes)

      return json({ status: 'approved', message: 'Devolución aprobada' })
    }

    // ════════════════════════════════════════════════════════════
    // 5. RECHAZAR
    // ════════════════════════════════════════════════════════════
    if (action === 'reject') {
      if (ret.status !== 'pending') {
        return json({ error: `No se puede rechazar una devolución con estado "${ret.status}"` }, 400)
      }

      await supabaseAdmin
        .from('returns')
        .update({
          status: 'rejected',
        })
        .eq('id', returnId)

      // Enviar email de rechazo
      await _sendReturnEmail(supabaseAdmin, ret, 'refund_rejected', adminNotes)

      return json({ status: 'rejected', message: 'Devolución rechazada' })
    }

    // ════════════════════════════════════════════════════════════
    // 6. COMPLETAR (refund Stripe + restaurar stock)
    // ════════════════════════════════════════════════════════════
    if (action === 'complete') {
      if (!['approved', 'pending'].includes(ret.status)) {
        return json({ error: `No se puede completar una devolución con estado "${ret.status}"` }, 400)
      }

      // 6a. Obtener pedido asociado
      const { data: order } = await supabaseAdmin
        .from('orders')
        .select('*')
        .eq('id', ret.order_id)
        .single()

      if (!order) {
        return json({ error: 'Pedido asociado no encontrado' }, 404)
      }

      // 6b. Refund en Stripe
      let refundId: string | null = null
      if (order.payment_id && STRIPE_SECRET_KEY) {
        try {
          // Si el reembolso es parcial, indicar el monto en céntimos
          const refundParams: Record<string, string> = {
            payment_intent: order.payment_id,
          }
          if (ret.refund_amount && ret.refund_amount < order.total) {
            // Reembolso parcial: amount en céntimos
            refundParams.amount = Math.round(ret.refund_amount * 100).toString()
          }

          const refund = await stripePost('/refunds', refundParams)
          if (refund.id) {
            refundId = refund.id
            console.log(`[RETURN] Stripe refund: ${refund.id} (${ret.refund_amount}€)`)
          } else {
            console.warn('[RETURN] Stripe refund error:', refund.error)
          }
        } catch (e: any) {
          console.error('[RETURN] Error Stripe refund:', e.message)
        }
      }

      // 6c. Restaurar stock de los items devueltos
      const items = ret.items || []
      for (const item of items) {
        if (!item.product_id) continue
        const quantity = item.quantity || 1
        const size = item.size || 'Única'

        try {
          const { error: rpcErr } = await supabaseAdmin.rpc('increment_stock', {
            product_id: item.product_id,
            quantity: quantity,
            p_size: size,
          })
          if (rpcErr) {
            console.warn(`[RETURN] RPC increment_stock falló:`, rpcErr.message)
            await _fallbackIncrementStock(supabaseAdmin, item.product_id, quantity, size)
          } else {
            console.log(`[RETURN] Stock restaurado: ${item.product_name} x${quantity} (${size})`)
          }
        } catch (_) {
          await _fallbackIncrementStock(supabaseAdmin, item.product_id, quantity, size)
        }
      }

      // 6d. Actualizar devolución
      await supabaseAdmin
        .from('returns')
        .update({
          status: 'refunded',
        })
        .eq('id', returnId)

      // 6e. Actualizar pedido
      await supabaseAdmin
        .from('orders')
        .update({
          status: 'refunded',
          payment_status: refundId ? 'refunded' : order.payment_status,
          admin_notes: `${order.admin_notes || ''} | Reembolso completado ${new Date().toISOString()}${refundId ? ` | Refund: ${refundId}` : ''}`,
          updated_at: new Date().toISOString(),
        })
        .eq('id', ret.order_id)

      // 6f. Email confirmación reembolso
      await _sendReturnEmail(supabaseAdmin, ret, 'refund_approved', adminNotes)

      return json({
        status: 'completed',
        message: 'Reembolso completado correctamente',
        refundId,
      })
    }

    return json({ error: 'Acción no válida' }, 400)
  } catch (error: any) {
    console.error('[RETURN] Error general:', error)
    return json({ error: 'Error al procesar devolución' }, 500)
  }
})

/** Envía email de notificación de devolución */
async function _sendReturnEmail(
  supabase: any,
  ret: any,
  emailType: string,
  adminNotes?: string,
) {
  try {
    const customerEmail = ret.customer_email
    if (!customerEmail) return

    // Obtener pedido completo con items
    let orderNumber = ''
    let orderItems: any[] = []
    let subtotal = 0
    let shippingCost = 0
    let discount = 0
    let total = 0
    try {
      const { data: order } = await supabase
        .from('orders')
        .select('order_number, subtotal, shipping_cost, discount, total, order_items(*)')
        .eq('id', ret.order_id)
        .single()
      orderNumber = order?.order_number || ''
      subtotal = order?.subtotal || order?.total || 0
      shippingCost = order?.shipping_cost || 0
      discount = order?.discount || 0
      total = order?.total || 0
      orderItems = (order?.order_items || []).map((oi: any) => ({
        product_name: oi.product_name || 'Producto',
        product_image: oi.product_image || '',
        size: oi.size || '-',
        quantity: oi.quantity || 1,
        price: oi.price || 0,
        subtotal: oi.subtotal || (oi.price || 0) * (oi.quantity || 1),
      }))
    } catch (_) {}

    // Items de la devolución (si los tiene)
    const retItems = Array.isArray(ret.items) ? ret.items.map((ri: any) => ({
      product_name: ri.product_name || 'Producto',
      product_image: ri.product_image || '',
      size: ri.size || '-',
      quantity: ri.quantity || 1,
      price: ri.price || 0,
      subtotal: ri.subtotal || (ri.price || 0) * (ri.quantity || 1),
    })) : orderItems

    await fetch(`${Deno.env.get('SUPABASE_URL')}/functions/v1/send-order-email`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        type: emailType,
        to_email: customerEmail,
        to_name: ret.shipping_full_name || 'Cliente',
        order_number: orderNumber,
        order_items: orderItems,
        refund_items: retItems,
        subtotal,
        shipping_cost: shippingCost,
        discount,
        total,
        refund_amount: ret.refund_amount || 0,
        refund_reason: ret.reason || '',
        admin_notes: adminNotes || '',
      }),
    })
    console.log(`[RETURN] Email ${emailType} enviado a ${customerEmail}`)
  } catch (e: any) {
    console.warn(`[RETURN] Error enviando email ${emailType}:`, e.message)
  }
}

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
    console.log(`[RETURN] Stock restaurado (fallback): ${productId} +${quantity}`)
  } catch (e: any) {
    console.error(`[RETURN] Error fallback stock ${productId}:`, e.message)
  }
}
