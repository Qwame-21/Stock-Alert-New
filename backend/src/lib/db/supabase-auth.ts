import { createClient, type SupabaseClient } from "@supabase/supabase-js";

import { getBackendEnv } from "@/lib/config/env";

let authClient: SupabaseClient | undefined;

export function getSupabaseAuthClient(): SupabaseClient {
  if (authClient) {
    return authClient;
  }

  const env = getBackendEnv();
  authClient = createClient(env.SUPABASE_URL, env.SUPABASE_PUBLISHABLE_KEY, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  });

  return authClient;
}
