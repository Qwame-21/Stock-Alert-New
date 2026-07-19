import { withAuth } from "@/lib/auth/with-auth";
import { getSupabaseAdmin } from "@/lib/db/supabase-admin";
import { apiSuccess } from "@/lib/http/api-response";
import { HttpError } from "@/lib/http/errors";
import { enforceRateLimit } from "@/lib/security/rate-limit";

export const dynamic = "force-dynamic";

export const DELETE = withAuth(async (request, { requestId, user }) => {
  await enforceRateLimit(request, { scope: "account-delete", identity: user.id, limit: 2, windowSeconds: 3600 });
  const admin = getSupabaseAdmin();
  const { error: cleanupError } = await admin.rpc("prepare_account_deletion", {
    target_profile_id: user.id,
  });
  if (cleanupError) {
    console.error("Account association cleanup failed", {
      userId: user.id,
      error: cleanupError.message,
    });
    throw new HttpError(
      502,
      "ACCOUNT_CLEANUP_FAILED",
      "The account associations could not be removed. Please contact support.",
    );
  }

  const { error } = await admin.auth.admin.deleteUser(user.id);
  if (error) throw new HttpError(502, "ACCOUNT_DELETE_FAILED", "The account could not be deleted. Please contact support.");
  return apiSuccess({ deleted: true }, undefined, { requestId });
});
