import { withAuth } from "@/lib/auth/with-auth";
import { getSupabaseAdmin } from "@/lib/db/supabase-admin";
import { apiSuccess } from "@/lib/http/api-response";
import { HttpError } from "@/lib/http/errors";

export const GET = withAuth(async (request, { requestId, user }) => {
  const reference = new URL(request.url).searchParams.get("reference")?.trim();
  if (!reference) {
    throw new HttpError(400, "PAYMENT_REFERENCE_REQUIRED", "Payment reference is required.");
  }
  const { data, error } = await getSupabaseAdmin()
    .from("payment_transactions")
    .select("reference, status, amount_minor, currency, updated_at")
    .eq("profile_id", user.id)
    .eq("reference", reference)
    .single();
  if (error || !data) {
    throw new HttpError(404, "PAYMENT_NOT_FOUND", "Payment was not found.");
  }
  return apiSuccess({
    reference: data.reference,
    status: data.status,
    amountMinor: data.amount_minor,
    currency: data.currency,
    updatedAt: data.updated_at,
  }, undefined, { requestId });
});
