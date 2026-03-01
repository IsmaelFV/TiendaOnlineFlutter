/**
 * ============================================================================
 * MANAGE COUPONS — Supabase Edge Function
 * ============================================================================
 * CRUD de cupones de descuento (discount_codes) con service_role.
 * Verifica que el usuario sea administrador antes de ejecutar.
 *
 * POST /functions/v1/manage-coupons
 * Body: { action: 'create'|'update'|'delete'|'toggle', data?: {...}, id?: string }
 * Auth: Bearer <supabase_jwt>
 * Returns: { data?, status }
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
    const { action, data, id } = await req.json()

    // ── 4. Ejecutar acción ──
    switch (action) {
      case 'create': {
        const { data: created, error } = await admin
          .from('discount_codes')
          .insert(data)
          .select()
          .single()
        if (error) throw error
        return jsonResponse({ data: created, status: 'created' })
      }

      case 'update': {
        if (!id) return jsonResponse({ error: 'Falta id del cupón' }, 400)
        const { data: updated, error } = await admin
          .from('discount_codes')
          .update(data)
          .eq('id', id)
          .select()
          .single()
        if (error) throw error
        return jsonResponse({ data: updated, status: 'updated' })
      }

      case 'delete': {
        if (!id) return jsonResponse({ error: 'Falta id del cupón' }, 400)
        const { error } = await admin
          .from('discount_codes')
          .delete()
          .eq('id', id)
        if (error) throw error
        return jsonResponse({ status: 'deleted' })
      }

      case 'toggle': {
        if (!id) return jsonResponse({ error: 'Falta id del cupón' }, 400)
        const { error } = await admin
          .from('discount_codes')
          .update({ is_active: data?.is_active ?? false })
          .eq('id', id)
        if (error) throw error
        return jsonResponse({ status: 'toggled' })
      }

      default:
        return jsonResponse({ error: `Acción no válida: ${action}` }, 400)
    }
  } catch (e: any) {
    const msg = e?.message ?? String(e)
    console.error('[manage-coupons] Error:', msg)
    return jsonResponse({ error: msg }, 500)
  }
})
