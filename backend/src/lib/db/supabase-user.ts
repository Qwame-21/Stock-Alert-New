import { createClient, type SupabaseClient } from "@supabase/supabase-js";

import { getBackendEnv } from "@/lib/config/env";

export function createSupabaseUserClient(accessToken: string): SupabaseClient {
  const env = getBackendEnv();

  return createClient(env.SUPABASE_URL, env.SUPABASE_PUBLISHABLE_KEY, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
    global: {
      headers: {
        Authorization: `Bearer ${accessToken}`,
      },
    },
  });
}
