// Supabase Edge Function: send-order-email
// Envía emails transaccionales de pedidos usando Brevo (Sendinblue)
import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'

const BREVO_API_KEY = Deno.env.get('BREVO_API_KEY') ?? ''
const FROM_EMAIL = Deno.env.get('STORE_EMAIL') ?? 'noreply@fashionstore.com'
const FROM_NAME = Deno.env.get('STORE_NAME') ?? 'Fashion Store'

interface OrderItem {
  product_name: string
  product_image: string
  size: string
  color?: string
  quantity: number
  price: number
  subtotal: number
}

interface EmailPayload {
  type: 'purchase_confirmation' | 'order_cancelled' | 'refund_approved' | 'refund_rejected' | 'refund_requested' | 'order_delivered'
  to_email: string
  to_name: string
  order_number: string
  order_items: OrderItem[]
  subtotal: number
  shipping_cost: number
  discount: number
  total: number
  refund_amount?: number
  refund_items?: OrderItem[]
  refund_reason?: string
  admin_notes?: string
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      },
    })
  }

  try {
    const raw = await req.json()
    // Normalizar campos para evitar undefined
    const payload: EmailPayload = {
      ...raw,
      order_items: raw.order_items || [],
      subtotal: raw.subtotal || raw.total || 0,
      shipping_cost: raw.shipping_cost || 0,
      discount: raw.discount || 0,
      total: raw.total || 0,
    }
    const { type, to_email, to_name } = payload

    let subject = ''
    let htmlContent = ''

    switch (type) {
      case 'purchase_confirmation':
        subject = `✅ Pedido confirmado — ${payload.order_number}`
        htmlContent = buildPurchaseEmail(payload)
        break
      case 'order_cancelled':
        subject = `❌ Pedido cancelado — ${payload.order_number}`
        htmlContent = buildCancellationEmail(payload)
        break
      case 'order_delivered':
        subject = `📦 ¡Pedido entregado! — ${payload.order_number}`
        htmlContent = buildDeliveredEmail(payload)
        break
      case 'refund_requested':
        subject = `📋 Solicitud de reembolso recibida — ${payload.order_number}`
        htmlContent = buildRefundRequestedEmail(payload)
        break
      case 'refund_approved':
        subject = `✅ Reembolso aprobado — ${payload.order_number}`
        htmlContent = buildRefundApprovedEmail(payload)
        break
      case 'refund_rejected':
        subject = `❌ Reembolso rechazado — ${payload.order_number}`
        htmlContent = buildRefundRejectedEmail(payload)
        break
      default:
        return new Response(JSON.stringify({ error: 'Invalid email type' }), { status: 400 })
    }

    // Enviar email via Brevo
    const res = await fetch('https://api.brevo.com/v3/smtp/email', {
      method: 'POST',
      headers: {
        'accept': 'application/json',
        'api-key': BREVO_API_KEY,
        'content-type': 'application/json',
      },
      body: JSON.stringify({
        sender: { name: FROM_NAME, email: FROM_EMAIL },
        to: [{ email: to_email, name: to_name }],
        subject,
        htmlContent,
      }),
    })

    const result = await res.json()

    return new Response(JSON.stringify({ success: true, result }), {
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})

// ═══════════════════════════════════════════
//  TEMPLATES HTML
// ═══════════════════════════════════════════

function baseLayout(title: string, content: string): string {
  return `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${title}</title>
</head>
<body style="margin:0;padding:0;background-color:#0D0D0D;font-family:'Helvetica Neue',Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background-color:#0D0D0D;padding:40px 0;">
    <tr><td align="center">
      <table width="600" cellpadding="0" cellspacing="0" style="background-color:#1A1A1A;border-radius:16px;overflow:hidden;border:1px solid #2A2A2A;">
        <!-- Header -->
        <tr>
          <td style="background:linear-gradient(135deg,#1A1A1A,#2A2010);padding:32px 40px;text-align:center;">
            <h1 style="margin:0;color:#C9A84C;font-size:28px;font-weight:800;letter-spacing:3px;">FASHION STORE</h1>
          </td>
        </tr>
        <!-- Title bar -->
        <tr>
          <td style="background-color:#C9A84C;padding:16px 40px;text-align:center;">
            <h2 style="margin:0;color:#0D0D0D;font-size:18px;font-weight:700;">${title}</h2>
          </td>
        </tr>
        <!-- Content -->
        <tr>
          <td style="padding:32px 40px;color:#E0E0E0;font-size:14px;line-height:1.6;">
            ${content}
          </td>
        </tr>
        <!-- Footer -->
        <tr>
          <td style="background-color:#111;padding:24px 40px;text-align:center;border-top:1px solid #2A2A2A;">
            <p style="margin:0;color:#666;font-size:12px;">© ${new Date().getFullYear()} Fashion Store. Todos los derechos reservados.</p>
            <p style="margin:8px 0 0;color:#555;font-size:11px;">Este email fue enviado automáticamente. Por favor no responda a este mensaje.</p>
          </td>
        </tr>
      </table>
    </td></tr>
  </table>
</body>
</html>`
}

function itemsTable(items: OrderItem[]): string {
  const rows = items.map(item => `
    <tr>
      <td style="padding:12px;border-bottom:1px solid #2A2A2A;">
        <table cellpadding="0" cellspacing="0"><tr>
          <td style="width:60px;vertical-align:top;">
            <img src="${item.product_image}" alt="${item.product_name}" width="56" height="70" style="border-radius:8px;object-fit:cover;display:block;background:#2A2A2A;" />
          </td>
          <td style="padding-left:12px;vertical-align:top;">
            <p style="margin:0;color:#E0E0E0;font-weight:600;font-size:14px;">${item.product_name}</p>
            <p style="margin:4px 0 0;color:#888;font-size:12px;">Talla: ${item.size ?? '-'}${item.color ? ' · Color: ' + item.color : ''} · x${item.quantity}</p>
          </td>
        </tr></table>
      </td>
      <td style="padding:12px;border-bottom:1px solid #2A2A2A;text-align:right;color:#C9A84C;font-weight:600;font-size:14px;vertical-align:top;">
        ${item.subtotal.toFixed(2)} €
      </td>
    </tr>
  `).join('')

  return `
    <table width="100%" cellpadding="0" cellspacing="0" style="background-color:#151515;border-radius:12px;overflow:hidden;margin:16px 0;">
      <tr>
        <td style="padding:12px 12px 8px;color:#888;font-size:11px;text-transform:uppercase;letter-spacing:1px;border-bottom:1px solid #2A2A2A;">Producto</td>
        <td style="padding:12px 12px 8px;color:#888;font-size:11px;text-transform:uppercase;letter-spacing:1px;border-bottom:1px solid #2A2A2A;text-align:right;">Precio</td>
      </tr>
      ${rows}
    </table>`
}

function invoiceSummary(subtotal: number, shipping: number, discount: number, total: number, isCredit = false): string {
  const label = isCredit ? 'NOTA DE ABONO' : 'FACTURA'
  const prefix = isCredit ? '-' : ''
  return `
    <table width="100%" cellpadding="0" cellspacing="0" style="background-color:#151515;border-radius:12px;overflow:hidden;margin:16px 0;">
      <tr><td colspan="2" style="padding:12px;background-color:#1E1E1E;border-bottom:1px solid #2A2A2A;">
        <strong style="color:#C9A84C;font-size:13px;letter-spacing:1px;">${label}</strong>
      </td></tr>
      <tr>
        <td style="padding:8px 12px;color:#AAA;font-size:13px;">Subtotal</td>
        <td style="padding:8px 12px;color:#E0E0E0;font-size:13px;text-align:right;">${prefix}${subtotal.toFixed(2)} €</td>
      </tr>
      ${shipping > 0 ? `<tr>
        <td style="padding:8px 12px;color:#AAA;font-size:13px;">Envío</td>
        <td style="padding:8px 12px;color:#E0E0E0;font-size:13px;text-align:right;">${shipping.toFixed(2)} €</td>
      </tr>` : ''}
      ${discount > 0 ? `<tr>
        <td style="padding:8px 12px;color:#4CAF50;font-size:13px;">Descuento</td>
        <td style="padding:8px 12px;color:#4CAF50;font-size:13px;text-align:right;">-${discount.toFixed(2)} €</td>
      </tr>` : ''}
      <tr>
        <td style="padding:12px;border-top:1px solid #2A2A2A;color:#C9A84C;font-size:16px;font-weight:700;">TOTAL</td>
        <td style="padding:12px;border-top:1px solid #2A2A2A;color:#C9A84C;font-size:16px;font-weight:700;text-align:right;">${prefix}${total.toFixed(2)} €</td>
      </tr>
    </table>`
}

// ─── Email: Confirmación de compra ───
function buildPurchaseEmail(p: EmailPayload): string {
  return baseLayout('Pedido confirmado', `
    <p style="margin:0 0 8px;">Hola <strong>${p.to_name}</strong>,</p>
    <p style="margin:0 0 20px;">¡Gracias por tu compra! Tu pedido <strong style="color:#C9A84C;">${p.order_number}</strong> ha sido recibido y está siendo procesado.</p>
    
    <h3 style="color:#C9A84C;font-size:15px;margin:24px 0 8px;">📦 Productos de tu pedido</h3>
    ${itemsTable(p.order_items)}
    ${invoiceSummary(p.subtotal, p.shipping_cost, p.discount, p.total)}
    
    <div style="background-color:#1E2A1E;border:1px solid #2A4A2A;border-radius:12px;padding:16px;margin:20px 0;">
      <p style="margin:0;color:#4CAF50;font-weight:600;">✅ Te notificaremos cuando tu pedido sea enviado.</p>
    </div>
  `)
}

// ─── Email: Pedido cancelado ───
function buildCancellationEmail(p: EmailPayload): string {
  return baseLayout('Pedido cancelado', `
    <p style="margin:0 0 8px;">Hola <strong>${p.to_name}</strong>,</p>
    <p style="margin:0 0 20px;">Tu pedido <strong style="color:#C9A84C;">${p.order_number}</strong> ha sido cancelado correctamente.</p>
    
    <h3 style="color:#C9A84C;font-size:15px;margin:24px 0 8px;">📦 Productos del pedido cancelado</h3>
    ${itemsTable(p.order_items)}
    ${invoiceSummary(p.subtotal, p.shipping_cost, p.discount, p.total, true)}
    
    <div style="background-color:#2A2010;border:1px solid #4A3820;border-radius:12px;padding:16px;margin:20px 0;">
      <p style="margin:0;color:#C9A84C;font-weight:600;">💰 El importe de ${p.total.toFixed(2)} € será devuelto a tu método de pago original.</p>
    </div>
  `)
}

// ─── Email: Solicitud de reembolso recibida ───
function buildRefundRequestedEmail(p: EmailPayload): string {
  const refundItems = p.refund_items ?? p.order_items
  return baseLayout('Solicitud de reembolso recibida', `
    <p style="margin:0 0 8px;">Hola <strong>${p.to_name}</strong>,</p>
    <p style="margin:0 0 20px;">Hemos recibido tu solicitud de reembolso para el pedido <strong style="color:#C9A84C;">${p.order_number}</strong>.</p>
    
    ${p.refund_reason ? `<div style="background-color:#151515;border-radius:12px;padding:16px;margin:16px 0;">
      <p style="margin:0;color:#888;font-size:12px;text-transform:uppercase;">Motivo</p>
      <p style="margin:6px 0 0;color:#E0E0E0;">${p.refund_reason}</p>
    </div>` : ''}
    
    <h3 style="color:#C9A84C;font-size:15px;margin:24px 0 8px;">📦 Productos a reembolsar</h3>
    ${itemsTable(refundItems)}
    
    <div style="background-color:#151515;border-radius:12px;padding:16px;margin:16px 0;text-align:center;">
      <p style="margin:0;color:#888;font-size:14px;">Importe solicitado</p>
      <p style="margin:8px 0 0;color:#C9A84C;font-size:24px;font-weight:700;">${(p.refund_amount ?? 0).toFixed(2)} €</p>
    </div>
    
    <div style="background-color:#1E1E2A;border:1px solid #2A2A4A;border-radius:12px;padding:16px;margin:20px 0;">
      <p style="margin:0;color:#7B8CDE;font-weight:600;">⏳ Nuestro equipo revisará tu solicitud y te notificaremos la resolución lo antes posible.</p>
    </div>
  `)
}

// ─── Email: Reembolso aprobado ───
function buildRefundApprovedEmail(p: EmailPayload): string {
  const refundItems = p.refund_items ?? p.order_items
  return baseLayout('Reembolso aprobado', `
    <p style="margin:0 0 8px;">Hola <strong>${p.to_name}</strong>,</p>
    <p style="margin:0 0 20px;">¡Buenas noticias! Tu solicitud de reembolso para el pedido <strong style="color:#C9A84C;">${p.order_number}</strong> ha sido <strong style="color:#4CAF50;">aprobada</strong>.</p>
    
    <h3 style="color:#4CAF50;font-size:15px;margin:24px 0 8px;">✅ Productos reembolsados</h3>
    ${itemsTable(refundItems)}
    ${invoiceSummary(p.refund_amount ?? 0, 0, 0, p.refund_amount ?? 0, true)}
    
    ${p.admin_notes ? `<div style="background-color:#151515;border-radius:12px;padding:16px;margin:16px 0;">
      <p style="margin:0;color:#888;font-size:12px;text-transform:uppercase;">Nota del equipo</p>
      <p style="margin:6px 0 0;color:#E0E0E0;">${p.admin_notes}</p>
    </div>` : ''}
    
    <div style="background-color:#1E2A1E;border:1px solid #2A4A2A;border-radius:12px;padding:16px;margin:20px 0;">
      <p style="margin:0;color:#4CAF50;font-weight:600;">💰 El importe de ${(p.refund_amount ?? 0).toFixed(2)} € será devuelto a tu método de pago en un plazo de 5-10 días laborables.</p>
    </div>
  `)
}

// ─── Email: Reembolso rechazado ───
function buildRefundRejectedEmail(p: EmailPayload): string {
  const refundItems = p.refund_items ?? p.order_items
  return baseLayout('Reembolso rechazado', `
    <p style="margin:0 0 8px;">Hola <strong>${p.to_name}</strong>,</p>
    <p style="margin:0 0 20px;">Lamentamos informarte de que tu solicitud de reembolso para el pedido <strong style="color:#C9A84C;">${p.order_number}</strong> ha sido <strong style="color:#EF5350;">rechazada</strong>.</p>
    
    <h3 style="color:#EF5350;font-size:15px;margin:24px 0 8px;">❌ Productos solicitados</h3>
    ${itemsTable(refundItems)}
    
    ${p.admin_notes ? `<div style="background-color:#2A1515;border:1px solid #4A2020;border-radius:12px;padding:16px;margin:16px 0;">
      <p style="margin:0;color:#888;font-size:12px;text-transform:uppercase;">Motivo del rechazo</p>
      <p style="margin:6px 0 0;color:#EF9A9A;">${p.admin_notes}</p>
    </div>` : ''}
    
    <div style="background-color:#151515;border-radius:12px;padding:16px;margin:20px 0;">
      <p style="margin:0;color:#AAA;font-size:13px;">Si tienes alguna duda, puedes contactarnos a través de la sección de contacto en la aplicación.</p>
    </div>
  `)
}

// ─── Email: Pedido entregado ───
function buildDeliveredEmail(p: EmailPayload): string {
  return baseLayout('¡Pedido entregado!', `
    <p style="margin:0 0 8px;">Hola <strong>${p.to_name}</strong>,</p>
    <p style="margin:0 0 20px;">¡Tu pedido <strong style="color:#C9A84C;">${p.order_number}</strong> ha sido <strong style="color:#43A047;">entregado</strong> con éxito!</p>
    
    <h3 style="color:#43A047;font-size:15px;margin:24px 0 8px;">✅ Productos entregados</h3>
    ${itemsTable(p.order_items)}
    ${invoiceSummary(p.subtotal, p.shipping_cost, p.discount, p.total)}
    
    <div style="background-color:#1E2A1E;border:1px solid #2A4A2A;border-radius:12px;padding:16px;margin:20px 0;">
      <p style="margin:0;color:#43A047;font-weight:600;">📦 ¡Esperamos que disfrutes de tus productos!</p>
      <p style="margin:8px 0 0;color:#AAA;font-size:13px;">Si tienes algún problema con tu pedido, puedes solicitar una devolución desde la app en un plazo de 14 días.</p>
    </div>
  `)
}
