/**
 * ============================================================================
 * POST /api/checkout/confirm-payment
 * ============================================================================
 * Flutter llama aquí tras un pago exitoso en Payment Sheet.
 *
 * Flujo:
 *  1. Verificar auth (Bearer / cookie)
 *  2. Comprobar con Stripe que el PI está "succeeded"
 *  3. Prevenir pedidos duplicados (same payment_id)
 *  4. Extraer items y shipping del metadata del PI
 *  5. Crear order + order_items en Supabase
 *  6. Decrementar stock (RPC atómico + fallback directo)
 *  7. Incrementar uso del código de descuento
 *
 * Responde: { order: { id } }   ← lo que Flutter espera
 * ============================================================================
 */

import type { APIRoute } from 'astro';
import { getSupabaseAdmin, getUserFromRequest } from '../../../lib/supabase';
import { getStripe } from '../../../lib/stripe';
import { json } from '../../../lib/helpers';

export const POST: APIRoute = async ({ request, cookies }) => {
  try {
    const supabase = getSupabaseAdmin();
    const stripe = getStripe();

    // ══════════════════════════════════════════════════════════════
    // 1. AUTENTICACIÓN
    // ══════════════════════════════════════════════════════════════
    const user = await getUserFromRequest(request, cookies);
    if (!user) {
      return json({ message: 'No autorizado' }, 401);
    }

    // ══════════════════════════════════════════════════════════════
    // 2. VALIDAR INPUT
    // ══════════════════════════════════════════════════════════════
    const { paymentIntentId } = await request.json();

    if (!paymentIntentId || typeof paymentIntentId !== 'string') {
      return json({ message: 'paymentIntentId requerido' }, 400);
    }

    if (!/^pi_[a-zA-Z0-9_]+$/.test(paymentIntentId)) {
      return json({ message: 'paymentIntentId inválido' }, 400);
    }

    console.log(`[CONFIRM] Verificando PI: ${paymentIntentId}`);

    // ══════════════════════════════════════════════════════════════
    // 3. VERIFICAR CON STRIPE
    // ══════════════════════════════════════════════════════════════
    let pi;
    try {
      pi = await stripe.paymentIntents.retrieve(paymentIntentId);
    } catch (err: any) {
      console.error('[CONFIRM] Stripe retrieve error:', err.message);
      return json({ message: 'PaymentIntent no encontrado' }, 404);
    }

    if (pi.status !== 'succeeded') {
      return json(
        { message: `Pago no completado (estado: ${pi.status})` },
        400,
      );
    }

    // ══════════════════════════════════════════════════════════════
    // 4. PREVENIR DUPLICADOS
    // ══════════════════════════════════════════════════════════════
    const { data: existing } = await supabase
      .from('orders')
      .select('id, order_number')
      .eq('payment_id', paymentIntentId)
      .maybeSingle();

    if (existing) {
      console.log(`[CONFIRM] Pedido ya existe: ${existing.order_number}`);
      return json({ order: { id: existing.id } });
    }

    // ══════════════════════════════════════════════════════════════
    // 5. EXTRAER DATA DEL METADATA
    // ══════════════════════════════════════════════════════════════
    const meta = pi.metadata || {};

    // items – puede estar en formato completo o comprimido
    let items: any[] = [];
    try {
      const raw = JSON.parse(meta.items_json || '[]');
      // Normalizar: si viene en formato comprimido (pid/sz/qty)
      items = raw.map((r: any) =>
        r.product_id
          ? r // formato completo
          : {
              product_id: r.pid,
              size: r.sz,
              quantity: r.qty,
              price: r.p,
              subtotal: r.st,
            },
      );
    } catch {
      console.warn('[CONFIRM] Error parsing items_json');
    }

    // shipping
    let shipping: any = {};
    try {
      const raw = JSON.parse(meta.shipping_json || '{}');
      // Normalizar de formato comprimido si hace falta
      shipping = raw.fullName
        ? raw
        : {
            fullName: raw.fn || '',
            email: raw.em || '',
            phone: raw.ph || '',
            addressLine1: raw.a1 || '',
            addressLine2: raw.a2 || '',
            city: raw.ci || '',
            state: raw.st || '',
            postalCode: raw.pc || '',
            country: raw.co || 'ES',
            notes: raw.no || '',
          };
    } catch {
      console.warn('[CONFIRM] Error parsing shipping_json');
    }

    const discountCode = meta.discount_code || '';
    const discountAmountCents = parseInt(meta.discount_amount || '0', 10);
    const totalBeforeDiscount = parseInt(meta.total_before_discount || '0', 10);
    const customerEmail = shipping.email || meta.customer_email || user.email || '';
    const customerName = shipping.fullName || meta.customer_name || 'Cliente';

    // ══════════════════════════════════════════════════════════════
    // 6. CREAR PEDIDO
    // ══════════════════════════════════════════════════════════════
    const year = new Date().getFullYear();
    const rnd = Math.random().toString(36).substring(2, 8).toUpperCase();
    const orderNumber = `ORD-${year}-${Date.now().toString().slice(-6)}-${rnd}`;

    const totalCents = pi.amount || 0;
    const subtotalCents = totalBeforeDiscount || totalCents;

    const { data: order, error: orderError } = await supabase
      .from('orders')
      .insert({
        order_number: orderNumber,
        user_id: user.id,
        customer_email: customerEmail,
        shipping_full_name: customerName,
        shipping_phone: shipping.phone || '',
        shipping_address_line1: shipping.addressLine1 || 'Dirección no proporcionada',
        shipping_address_line2: shipping.addressLine2 || null,
        shipping_city: shipping.city || 'Ciudad',
        shipping_state: shipping.state || '',
        shipping_postal_code: shipping.postalCode || '00000',
        shipping_country: shipping.country || 'ES',
        subtotal: subtotalCents / 100,
        shipping_cost: 0,
        tax: 0,
        discount: discountAmountCents / 100,
        total: totalCents / 100,
        payment_method: 'card',
        payment_status: 'paid',
        payment_id: paymentIntentId,
        status: 'confirmed',
        customer_notes: shipping.notes || (discountCode ? `Código: ${discountCode}` : null),
        admin_notes: `[FLUTTER] PI: ${paymentIntentId} | Email: ${customerEmail}`,
      })
      .select()
      .single();

    if (orderError) {
      console.error('[CONFIRM] Error creando pedido:', orderError);
      return json({ message: 'Error creando pedido' }, 500);
    }

    console.log(`[CONFIRM] Pedido creado: ${order.order_number} (${order.id})`);

    // ══════════════════════════════════════════════════════════════
    // 7. CREAR ORDER_ITEMS + DECREMENTAR STOCK
    // ══════════════════════════════════════════════════════════════
    if (items.length > 0) {
      // 7a. Resolver datos de producto para items que venían comprimidos
      const productIds = [...new Set(items.map((i) => i.product_id))];
      const { data: prods } = await supabase
        .from('products')
        .select('id, name, slug, sku, price, images, stock, stock_by_size')
        .in('id', productIds);

      const prodMap = new Map((prods || []).map((p) => [p.id, p]));

      // 7b. Intentar decremento atómico via RPC
      let stockRpcOk = false;
      try {
        const rpcItems = items.map((i) => ({
          product_id: i.product_id,
          quantity: i.quantity,
          size: i.size || 'Única',
        }));

        const { error: rpcErr } = await supabase.rpc('validate_and_decrement_stock', {
          p_items: rpcItems,
        });

        if (!rpcErr) {
          stockRpcOk = true;
          console.log('[CONFIRM] Stock decrementado via RPC');
        } else {
          console.warn('[CONFIRM] RPC validate_and_decrement_stock falló:', rpcErr.message);
        }
      } catch (e: any) {
        console.warn('[CONFIRM] RPC no disponible:', e.message);
      }

      // 7c. Insertar order_items y fallback de stock
      for (const item of items) {
        const prod = prodMap.get(item.product_id);
        const productName = item.product_name || prod?.name || 'Producto';
        const productSlug = item.product_slug || prod?.slug || '';
        const productImage = item.product_image || prod?.images?.[0] || null;
        const pricePerUnit = item.price || prod?.price || 0;

        // Insertar order_item
        await supabase.from('order_items').insert({
          order_id: order.id,
          product_id: item.product_id,
          product_name: productName,
          product_slug: productSlug,
          product_image: productImage,
          size: item.size || 'Única',
          color: null,
          price: pricePerUnit / 100,
          quantity: item.quantity,
          subtotal: (pricePerUnit * item.quantity) / 100,
        });

        // Fallback: decrementar stock directamente si RPC no funcionó
        if (!stockRpcOk && prod) {
          try {
            const { data: fresh } = await supabase
              .from('products')
              .select('stock, stock_by_size')
              .eq('id', item.product_id)
              .single();

            if (fresh) {
              const newStock = Math.max(0, (fresh.stock || 0) - item.quantity);
              const updateData: any = {
                stock: newStock,
                updated_at: new Date().toISOString(),
              };

              if (fresh.stock_by_size && typeof fresh.stock_by_size === 'object') {
                const sizeStock = { ...(fresh.stock_by_size as Record<string, number>) };
                const sz = item.size || 'Única';
                if (sz in sizeStock) {
                  sizeStock[sz] = Math.max(0, (sizeStock[sz] || 0) - item.quantity);
                  updateData.stock_by_size = sizeStock;
                }
              }

              await supabase.from('products').update(updateData).eq('id', item.product_id);
              console.log(`[CONFIRM] Stock fallback: ${item.product_id} → ${newStock}`);
            }
          } catch (e: any) {
            console.error(`[CONFIRM] Error stock fallback ${item.product_id}:`, e.message);
          }
        }
      }
    }

    // ══════════════════════════════════════════════════════════════
    // 8. INCREMENTAR USO DEL DESCUENTO
    // ══════════════════════════════════════════════════════════════
    if (discountCode) {
      try {
        await supabase.rpc('increment_discount_usage', { p_code: discountCode });
        console.log(`[CONFIRM] Uso descuento incrementado: ${discountCode}`);
      } catch (e: any) {
        console.warn('[CONFIRM] Error increment_discount_usage:', e.message);
      }
    }

    // ══════════════════════════════════════════════════════════════
    // 9. RESPUESTA (Flutter espera { order: { id } })
    // ══════════════════════════════════════════════════════════════
    return json({
      order: { id: order.id, orderNumber: order.order_number },
    });
  } catch (error: any) {
    console.error('[CONFIRM] Error general:', error);
    return json({ message: error.message || 'Error confirmando pedido' }, 500);
  }
};
