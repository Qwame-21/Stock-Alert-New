import type { AuthenticatedUser } from "@/lib/auth/authenticated-user";
import { getBearerToken } from "@/lib/auth/bearer-token";
import { getSupabaseAdmin } from "@/lib/db/supabase-admin";
import { HttpError } from "@/lib/http/errors";

export interface VerifiedTokenUser {
  id: string;
  email?: string;
  user_metadata?: Record<string, unknown>;
}

export type TokenVerifier = (
  accessToken: string,
) => Promise<{ user: VerifiedTokenUser | null; error: Error | null }>;

const verifyWithSupabase: TokenVerifier = async (accessToken) => {
  const {
    data: { user },
    error,
  } = await getSupabaseAdmin().auth.getUser(accessToken);

  return { user, error };
};

export async function authenticateRequest(
  request: Request,
  verifyToken: TokenVerifier = verifyWithSupabase,
): Promise<AuthenticatedUser> {
  const accessToken = getBearerToken(request);
  const { user, error } = await verifyToken(accessToken);

  if (error || !user) {
    throw new HttpError(
      401,
      "UNAUTHENTICATED",
      "The access token is invalid or expired.",
    );
  }

  return {
    id: user.id,
    email: user.email ?? null,
    metadata: user.user_metadata ?? {},
  };
}
