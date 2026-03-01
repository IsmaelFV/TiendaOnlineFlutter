/**
 * ============================================================================
 * MANAGE PRODUCTS — Supabase Edge Function
 * ============================================================================
 * Operaciones admin sobre productos con service_role (bypasses RLS).
 * Verifica que el usuario sea administrador antes de ejecutar.
 *
 * POST /functions/v1/manage-products
 * Body: { action: 'delete'|'toggle_active'|'toggle_featured', id: string, data?: {...} }
 * Auth: Bearer <supabase_jwt>
 * Returns: { data?, status, error? }
 * ============================================================================
 */
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
}

function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

Deno.serve(async (req) => {
  // ── CORS preflight ──
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY')!

    // ── 1. Verificar autenticación ──
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return jsonResponse({ error: 'No autorizado' }, 401)
    }

    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    })
    const {
      data: { user },
      error: authError,
    } = await userClient.auth.getUser()

    if (authError || !user) {
      return jsonResponse({ error: 'Token inválido' }, 401)
    }

    // ── 2. Verificar que sea admin ──
    const admin = createClient(supabaseUrl, serviceRoleKey)
    const { data: adminRow } = await admin
      .from('admin_users')
      .select('id')
      .eq('user_id', user.id)
      .maybeSingle()

    if (!adminRow) {
      return jsonResponse({ error: 'No es administrador' }, 403)
    }

    // ── 3. Leer body ──
    const { action, id, data } = await req.json()

    if (!id) {
      return jsonResponse({ error: 'Falta id del producto' }, 400)
    }

    // ── 4. Ejecutar acción ──
    switch (action) {
      case 'delete': {
        // Verificar si el producto tiene ventas (order_items con ese product_id)
        const { data: orderItems, error: checkError } = await admin
          .from('order_items')
          .select('id')
          .eq('product_id', id)
          .limit(1)

        if (checkError) throw checkError

        if (orderItems && orderItems.length > 0) {
          return jsonResponse(
            {
              error:
                'No se puede eliminar un producto que ha sido vendido. Puedes desactivarlo en su lugar.',
            },
            409,
          )
        }

        // Seguro para eliminar — también eliminar imágenes del storage
        const { error } = await admin
          .from('products')
          .delete()
          .eq('id', id)
        if (error) throw error
        return jsonResponse({ status: 'deleted' })
      }

      case 'toggle_active': {
        const isActive = data?.is_active ?? false
        const { error } = await admin
          .from('products')
          .update({ is_active: isActive })
          .eq('id', id)
        if (error) throw error
        return jsonResponse({ status: 'toggled', is_active: isActive })
      }

      case 'toggle_featured': {
        const featured = data?.featured ?? false
        const { error } = await admin
          .from('products')
          .update({ featured: featured })
          .eq('id', id)
        if (error) throw error
        return jsonResponse({ status: 'toggled', featured: featured })
      }

      default:
        return jsonResponse({ error: `Acción no válida: ${action}` }, 400)
    }
  } catch (e: any) {
    const msg = e?.message ?? String(e)
    console.error('[manage-products] Error:', msg)
    return jsonResponse({ error: msg }, 500)
  }
})
