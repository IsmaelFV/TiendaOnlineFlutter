// ══════════════════════════════════════════════════════════════
//  ENDPOINT PARA TU BACKEND ASTRO
//  Ruta: src/pages/api/checkout/create-payment-intent.ts
//
//  Este endpoint crea un PaymentIntent de Stripe (NO una Session)
//  y devuelve el clientSecret necesario para Payment Sheet nativo.
// ══════════════════════════════════════════════════════════════
import type { APIRoute } from 'astro';
import Stripe from 'stripe';
import { createClient } from '@supabase/supabase-js';

const stripe = new Stripe(import.meta.env.STRIPE_SECRET_KEY);

export const POST: APIRoute = async ({ request }) => {
  const headers = { 'Content-Type': 'application/json' };

  try {
    // ─── 1. Autenticación ───
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
    const { items, shipping, discountCode } = await request.json();

    if (!items || !Array.isArray(items) || items.length === 0) {
      return new Response(
        JSON.stringify({ message: 'Carrito vacío' }),
        { status: 400, headers },
      );
    }

    // ─── 3. Validar stock y precios desde la BD ───
    let total = 0;
    const validatedItems: any[] = [];

    for (const item of items) {
      const { data: product, error } = await supabase
        .from('products')
        .select('id, name, slug, price, stock, stock_by_size, images')
        .eq('id', item.id)
        .single();

      if (error || !product) {
        return new Response(
          JSON.stringify({ message: `Producto no encontrado: ${item.id}` }),
          { status: 400, headers },
        );
      }

      // Validar stock por talla
      const sizeStock = product.stock_by_size?.[item.size] ?? 0;
      if (sizeStock < item.quantity) {
        return new Response(
          JSON.stringify({
            message: `Sin stock de "${product.name}" en talla ${item.size}`,
          }),
          { status: 400, headers },
        );
      }

      const subtotal = product.price * item.quantity;
      total += subtotal;

      validatedItems.push({
        product_id: product.id,
        product_name: product.name,
        product_slug: product.slug,
        product_image: product.images?.[0] ?? '',
        size: item.size,
        quantity: item.quantity,
        price: product.price,
        subtotal,
      });
    }

    // ─── 4. Crear PaymentIntent en Stripe ───
    const paymentIntent = await stripe.paymentIntents.create({
      amount: total, // Ya en céntimos desde la BD
      currency: 'eur',
      automatic_payment_methods: { enabled: true },
      metadata: {
        user_id: user.id,
        customer_email: shipping?.email ?? user.email ?? '',
        customer_name: shipping?.fullName ?? '',
        items_json: JSON.stringify(validatedItems),
        shipping_json: JSON.stringify(shipping ?? {}),
      },
    });

    // ─── 5. Respuesta ───
    return new Response(
      JSON.stringify({
        clientSecret: paymentIntent.client_secret,
        paymentIntentId: paymentIntent.id,
        total,
      }),
      { status: 200, headers },
    );
  } catch (err: any) {
    console.error('[create-payment-intent]', err);
    return new Response(
      JSON.stringify({ message: err.message ?? 'Error interno del servidor' }),
      { status: 500, headers },
    );
  }
};
