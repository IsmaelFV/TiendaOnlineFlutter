/**
 * ============================================================================
 * POST /api/checkout/create-payment-intent
 * ============================================================================
 * Crea un Stripe PaymentIntent para Payment Sheet nativo en Flutter.
 *
 * Validaciones:
 *  - Auth: Bearer token (Flutter) o cookie (web)
 *  - Estructura de items (UUID, quantity 1-99, size ≤ 10 chars)
 *  - Existencia de productos en BD
 *  - Stock FRESCO por talla con fallback a global
 *  - Precios de BD (nunca del cliente)
 *  - Código de descuento via RPC validate_discount_code
 *
 * Responde: { clientSecret, paymentIntentId }
 *
 * El metadata del PI lleva items_json y shipping_json para que
 * confirm-payment.ts pueda crear el pedido sin segunda lectura pesada.
 * ============================================================================
 */

import type { APIRoute } from 'astro';
import { getSupabaseAdmin, getUserFromRequest } from '../../../lib/supabase';
import { getStripe } from '../../../lib/stripe';
import { json, UUID_RE } from '../../../lib/helpers';

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
    // 2. PARSEAR BODY
    // ══════════════════════════════════════════════════════════════
    const body = await request.json();
    const { items, shipping, discountCode } = body;

    if (!items || !Array.isArray(items) || items.length === 0) {
      return json({ message: 'El carrito está vacío' }, 400);
    }

    // ══════════════════════════════════════════════════════════════
    // 2.5 VALIDAR ESTRUCTURA DE CADA ITEM
    // ══════════════════════════════════════════════════════════════
    for (const item of items) {
      if (!item.id || typeof item.id !== 'string' || !UUID_RE.test(item.id)) {
        return json({ message: 'ID de producto no válido' }, 400);
      }
      if (!Number.isInteger(item.quantity) || item.quantity < 1 || item.quantity > 99) {
        return json({ message: 'Cantidad no válida' }, 400);
      }
      if (item.size !== undefined && item.size !== null && (typeof item.size !== 'string' || item.size.length > 10)) {
        return json({ message: 'Talla no válida' }, 400);
      }
    }

    if (items.length > 50) {
      return json({ message: 'Demasiados artículos en el carrito' }, 400);
    }

    // ══════════════════════════════════════════════════════════════
    // 3. OBTENER PRODUCTOS DE SUPABASE (batch)
    // ══════════════════════════════════════════════════════════════
    const productIds = items.map((i: any) => i.id);
    const { data: products, error: productsError } = await supabase
      .from('products')
      .select('id, name, slug, sku, price, stock, stock_by_size, images')
      .in('id', productIds);

    if (productsError || !products) {
      console.error('[PI] Error al validar productos:', productsError);
      return json({ message: 'Error al validar productos' }, 500);
    }

    const productMap = new Map(products.map((p) => [p.id, p]));

    // ══════════════════════════════════════════════════════════════
    // 4. VALIDAR STOCK (lectura FRESCA por producto)
    // ══════════════════════════════════════════════════════════════
    for (const item of items) {
      const product = productMap.get(item.id);
      if (!product) {
        return json({ message: `Producto no encontrado: ${item.id}` }, 400);
      }

      const itemSize = item.size || 'Única';
      const cartQuantity = item.quantity;

      // Leer stock fresco directamente de BD para evitar stale data
      let availableStock = 0;
      let currentStockBySize: Record<string, number> | null = null;
      let currentStockGlobal = product.stock || 0;

      try {
        const { data: freshProduct, error: freshError } = await supabase
          .from('products')
          .select('stock, stock_by_size')
          .eq('id', item.id)
          .single();

        if (!freshError && freshProduct) {
          currentStockBySize = freshProduct.stock_by_size as Record<string, number> | null;
          currentStockGlobal = freshProduct.stock || 0;
        } else {
          currentStockBySize = product.stock_by_size as Record<string, number> | null;
        }
      } catch {
        currentStockBySize = product.stock_by_size as Record<string, number> | null;
      }

      // Determinar stock disponible para la talla
      if (currentStockBySize && typeof currentStockBySize === 'object' && itemSize in currentStockBySize) {
        availableStock = currentStockBySize[itemSize] || 0;
      } else {
        availableStock = currentStockGlobal;
      }

      const allSizesInfo =
        currentStockBySize && typeof currentStockBySize === 'object'
          ? Object.entries(currentStockBySize).map(([s, qty]) => `${s}:${qty}`).join(', ')
          : 'sin desglose';

      console.log(`[PI] STOCK "${product.name}" talla="${itemSize}" → disp=${availableStock} pedido=${cartQuantity} (${allSizesInfo})`);

      if (availableStock < cartQuantity) {
        return json(
          { message: `No hay suficiente stock de "${product.name}" en talla ${itemSize}` },
          400,
        );
      }
    }

    // ══════════════════════════════════════════════════════════════
    // 5. CALCULAR TOTAL CON PRECIOS DE BD (nunca del cliente)
    // ══════════════════════════════════════════════════════════════
    const validatedItems: any[] = [];
    let totalAmount = 0; // céntimos

    for (const item of items) {
      const product = productMap.get(item.id)!;
      const unitPrice = product.price; // ya en céntimos en BD
      const itemTotal = unitPrice * item.quantity;
      totalAmount += itemTotal;

      const imageUrl =
        product.images && Array.isArray(product.images) && product.images.length > 0
          ? product.images[0]
          : null;

      validatedItems.push({
        product_id: product.id,
        product_name: product.name,
        product_slug: product.slug,
        product_sku: product.sku || null,
        product_image: imageUrl,
        size: item.size || 'Única',
        quantity: item.quantity,
        price: unitPrice,
        subtotal: itemTotal,
      });
    }

    // ══════════════════════════════════════════════════════════════
    // 6. VALIDAR Y APLICAR CÓDIGO DE DESCUENTO
    // ══════════════════════════════════════════════════════════════
    let discountAmount = 0;

    if (discountCode && typeof discountCode === 'string' && discountCode.trim()) {
      try {
        const { data: validationResult, error: discountError } = await supabase.rpc(
          'validate_discount_code',
          {
            p_code: discountCode.trim(),
            p_cart_total: totalAmount / 100, // euros
            p_user_id: user.id,
          },
        );

        if (discountError) {
          console.warn('[PI] Error validando descuento:', discountError.message);
        } else {
          const v = validationResult as {
            valid: boolean;
            message: string;
            discount_amount?: number;
          };

          if (!v.valid) {
            return json({ message: v.message }, 400);
          }

          discountAmount = Math.round((v.discount_amount || 0) * 100);
          console.log(`[PI] Descuento aplicado: ${discountCode} (-${discountAmount / 100}€)`);
        }
      } catch (err: any) {
        console.warn('[PI] RPC validate_discount_code no disponible:', err.message);
      }
    }

    const finalAmount = Math.max(totalAmount - discountAmount, 50); // min 50 cents Stripe

    // ══════════════════════════════════════════════════════════════
    // 7. CREAR PAYMENT INTENT EN STRIPE
    // ══════════════════════════════════════════════════════════════
    // Serializar items y shipping en metadata para confirm-payment
    // Stripe limita cada valor de metadata a 500 chars
    const itemsJson = JSON.stringify(validatedItems);
    const shippingJson = JSON.stringify(shipping || {});

    // Si items_json excede 500 chars, comprimir solo lo esencial
    const itemsMeta =
      itemsJson.length <= 500
        ? itemsJson
        : JSON.stringify(
            validatedItems.map((i) => ({
              pid: i.product_id,
              sz: i.size,
              qty: i.quantity,
              p: i.price,
              st: i.subtotal,
            })),
          );

    const shippingMeta =
      shippingJson.length <= 500
        ? shippingJson
        : JSON.stringify({
            fn: shipping?.fullName || '',
            em: shipping?.email || '',
            ph: shipping?.phone || '',
            a1: shipping?.addressLine1 || '',
            ci: shipping?.city || '',
            pc: shipping?.postalCode || '',
            co: shipping?.country || 'ES',
          });

    const paymentIntent = await stripe.paymentIntents.create({
      amount: finalAmount,
      currency: 'eur',
      automatic_payment_methods: { enabled: true },
      metadata: {
        user_id: user.id,
        customer_email: shipping?.email || user.email || '',
        customer_name: shipping?.fullName || '',
        items_json: itemsMeta,
        shipping_json: shippingMeta,
        discount_code: discountCode || '',
        discount_amount: discountAmount.toString(),
        total_before_discount: totalAmount.toString(),
        source: 'flutter_payment_sheet',
      },
    });

    console.log(`[PI] Creado: ${paymentIntent.id} (${finalAmount / 100}€)`);

    // ══════════════════════════════════════════════════════════════
    // 8. RESPUESTA
    // ══════════════════════════════════════════════════════════════
    return json({
      clientSecret: paymentIntent.client_secret,
      paymentIntentId: paymentIntent.id,
    });
  } catch (error: any) {
    console.error('[PI] Error:', error);
    return json({ message: error.message || 'Error al procesar el pago' }, 500);
  }
};
