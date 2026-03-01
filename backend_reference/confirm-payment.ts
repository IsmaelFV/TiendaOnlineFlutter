// ══════════════════════════════════════════════════════════════
//  ENDPOINT PARA TU BACKEND ASTRO
//  Ruta: src/pages/api/checkout/confirm-payment.ts
//
//  Después de que el usuario paga con Payment Sheet,
//  Flutter llama a este endpoint para:
//   - Verificar que el PaymentIntent está pagado
//   - Crear el pedido en Supabase
//   - Descontar stock
//   - Enviar email de confirmación
// ══════════════════════════════════════════════════════════════
import type { APIRoute } from 'astro';
import Stripe from 'stripe';
import { createClient } from '@supabase/supabase-js';

const stripe = new Stripe(import.meta.env.STRIPE_SECRET_KEY);

export const POST: APIRoute = async ({ request }) => {
  const headers = { 'Content-Type': 'application/json' };

  try {
    // ─── 1. Auth ───
    const authHeader = request.headers.get('Authorization');
    const token = authHeader?.replace('Bearer ', '');
    if (!token) {
      return new Response(
        JSON.stringify({ message: 'No autorizado' }),
        { status: 401, headers },
      );
    }

    const supabase = createClient(
      import.meta.env.SUPABASE_URL,
      import.meta.env.SUPABASE_SERVICE_ROLE_KEY,
    );

    const { data: { user }, error: authError } = await supabase.auth.getUser(token);
    if (authError || !user) {
      return new Response(
        JSON.stringify({ message: 'Token inválido' }),
        { status: 401, headers },
      );
    }

    // ─── 2. Parsear body ───
    const { paymentIntentId } = await request.json();
    if (!paymentIntentId) {
      return new Response(
        JSON.stringify({ message: 'paymentIntentId requerido' }),
        { status: 400, headers },
      );
    }

    // ─── 3. Verificar PaymentIntent con Stripe ───
    const pi = await stripe.paymentIntents.retrieve(paymentIntentId);

    if (pi.status !== 'succeeded') {
      return new Response(
        JSON.stringify({ message: `Pago no completado (estado: ${pi.status})` }),
        { status: 400, headers },
      );
    }

    // ─── 4. Evitar duplicados ───
    const { data: existingOrder } = await supabase
      .from('orders')
      .select('id')
      .eq('payment_id', paymentIntentId)
      .maybeSingle();

    if (existingOrder) {
      return new Response(
        JSON.stringify({ order: existingOrder }),
        { status: 200, headers },
      );
    }

    // ─── 5. Extraer datos del metadata ───
    const items = JSON.parse(pi.metadata.items_json || '[]');
    const shipping = JSON.parse(pi.metadata.shipping_json || '{}');

    // ─── 6. Crear pedido ───
    const { data: order, error: orderError } = await supabase
      .from('orders')
      .insert({
        user_id: user.id,
        customer_email: shipping.email || pi.metadata.customer_email || user.email,
        shipping_full_name: shipping.fullName || '',
        shipping_phone: shipping.phone || '',
        shipping_address_line1: shipping.addressLine1 || '',
        shipping_address_line2: shipping.addressLine2 || '',
        shipping_city: shipping.city || '',
        shipping_state: shipping.state || '',
        shipping_postal_code: shipping.postalCode || '',
        shipping_country: shipping.country || 'España',
        subtotal: pi.amount,
        shipping_cost: 0,
        tax: 0,
        discount: 0,
        total: pi.amount,
        status: 'pending',
        payment_method: 'card',
        payment_status: 'paid',
        payment_id: paymentIntentId,
        customer_notes: shipping.notes || '',
      })
      .select()
      .single();

    if (orderError) throw orderError;

    // ─── 7. Crear order_items ───
    const orderItems = items.map((item: any) => ({
      order_id: order.id,
      product_id: item.product_id,
      product_name: item.product_name,
      product_slug: item.product_slug,
      product_image: item.product_image,
      size: item.size,
      quantity: item.quantity,
      price: item.price,
      subtotal: item.subtotal,
    }));

    await supabase.from('order_items').insert(orderItems);

    // ─── 8. Descontar stock ───
    for (const item of items) {
      const { data: product } = await supabase
        .from('products')
        .select('stock, stock_by_size')
        .eq('id', item.product_id)
        .single();

      if (!product) continue;

      const stockBySize = { ...(product.stock_by_size || {}) };
      const currentSize = (stockBySize[item.size] as number) || 0;
      stockBySize[item.size] = Math.max(0, currentSize - item.quantity);

      await supabase
        .from('products')
        .update({
          stock: Math.max(0, (product.stock || 0) - item.quantity),
          stock_by_size: stockBySize,
        })
        .eq('id', item.product_id);
    }

    // ─── 9. Aquí puedes enviar email de confirmación, generar PDF, etc. ───
    // await sendConfirmationEmail(order, items, shipping);

    return new Response(
      JSON.stringify({ order: { id: order.id } }),
      { status: 200, headers },
    );
  } catch (err: any) {
    console.error('[confirm-payment]', err);
    return new Response(
      JSON.stringify({ message: err.message ?? 'Error interno del servidor' }),
      { status: 500, headers },
    );
  }
};
