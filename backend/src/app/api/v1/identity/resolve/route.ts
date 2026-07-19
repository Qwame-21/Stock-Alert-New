import { z } from "zod";

import { withAuth } from "@/lib/auth/with-auth";
import { getSupabaseAdmin } from "@/lib/db/supabase-admin";
import { apiSuccess } from "@/lib/http/api-response";
import { HttpError } from "@/lib/http/errors";
import { readJsonBody } from "@/lib/http/json-body";

export const dynamic = "force-dynamic";
const resolveSchema = z.object({ token: z.string().uuid() }).strict();

export const POST = withAuth(async (request, { requestId, user }) => {
  const db = getSupabaseAdmin();
  const { data: requester } = await db.from("profiles").select("role").eq("id", user.id).single();
  if (!requester || !["pharmacy", "provider"].includes(requester.role)) {
    throw new HttpError(403, "VERIFIER_REQUIRED", "A pharmacy or consultation-provider account is required.");
  }
  const { token } = resolveSchema.parse(await readJsonBody(request));
  const { data: card } = await db.from("patient_identity_cards").select("patient_profile_id, public_id, sharing_enabled, share_full_name, share_date_of_birth, share_emergency_contact").eq("qr_token", token).maybeSingle();
  if (!card) throw new HttpError(404, "IDENTITY_NOT_FOUND", "This identity card is invalid or has been replaced.");
  if (!card.sharing_enabled) throw new HttpError(403, "IDENTITY_PRIVATE", "The patient has disabled identity sharing.");

  const { data: profile } = await db.from("profiles").select("full_name, dob").eq("id", card.patient_profile_id).single();
  const { data: patient } = await db.from("patients").select("emergency_contact_name, emergency_contact_phone").eq("profile_id", card.patient_profile_id).single();
  return apiSuccess({
    patientId: card.public_id,
    ...(card.share_full_name && { fullName: profile?.full_name }),
    ...(card.share_date_of_birth && { dateOfBirth: profile?.dob }),
    ...(card.share_emergency_contact && {
      emergencyContactName: patient?.emergency_contact_name,
      emergencyContactPhone: patient?.emergency_contact_phone,
    }),
  }, undefined, { requestId });
});
