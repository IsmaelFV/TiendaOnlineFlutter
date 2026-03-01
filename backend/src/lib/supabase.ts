/**
 * Supabase Admin Client (service_role)
 * Bypasses RLS — server-side only.
 */
import { createClient, type SupabaseClient } from '@supabase/supabase-js';

let _client: SupabaseClient | null = null;

export function getSupabaseAdmin(): SupabaseClient {
  if (_client) return _client;

  const url = import.meta.env.PUBLIC_SUPABASE_URL;
  const key = import.meta.env.SUPABASE_SERVICE_ROLE_KEY;

  if (!url || !key) {
    throw new Error('Missing PUBLIC_SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY');
  }

  _client = createClient(url, key, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  return _client;
}

/**
 * Obtener usuario a partir de un token JWT de Supabase.
 * Soporta Bearer header (Flutter) y cookie (web).
 */
export async function getUserFromRequest(
  request: Request,
  cookies?: any,
): Promise<{ id: string; email?: string } | null> {
  const token =
    request.headers.get('Authorization')?.replace('Bearer ', '') ||
    cookies?.get?.('sb-access-token')?.value;

  if (!token) return null;

  const supabase = getSupabaseAdmin();
  const {
    data: { user },
    error,
  } = await supabase.auth.getUser(token);

  if (error || !user) return null;
  return { id: user.id, email: user.email };
}
