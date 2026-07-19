import { z } from "zod";

import { withAuth } from "@/lib/auth/with-auth";
import { getSupabaseAdmin } from "@/lib/db/supabase-admin";
import { apiSuccess } from "@/lib/http/api-response";
import { HttpError } from "@/lib/http/errors";
import { readJsonBody } from "@/lib/http/json-body";

export const dynamic = "force-dynamic";

const settingsSchema = z.object({
  sharingEnabled: z.boolean().optional(),
  shareFullName: z.boolean().optional(),
  shareDateOfBirth: z.boolean().optional(),
  shareEmergencyContact: z.boolean().optional(),
  rotateToken: z.boolean().optional(),
}).strict();

const selection = "public_id, qr_token, sharing_enabled, share_full_name, share_date_of_birth, share_emergency_contact";

async function ensureCard(userId: string) {
  const db = getSupabaseAdmin();
  const { data: patient } = await db.from("patients").select("profile_id").eq("profile_id", userId).maybeSingle();
  if (!patient) throw new HttpError(403, "PATIENT_REQUIRED", "Only patient accounts have identity cards.");
  const { data, error } = await db.from("patient_identity_cards")
    .upsert({ patient_profile_id: userId }, { onConflict: "patient_profile_id", ignoreDuplicates: true })
    .select(selection).maybeSingle();
  if (error) throw new HttpError(502, "IDENTITY_CARD_FAILED", "The identity card could not be loaded.");
  if (data) return data;
  const retry = await db.from("patient_identity_cards").select(selection).eq("patient_profile_id", userId).single();
  if (retry.error) throw new HttpError(502, "IDENTITY_CARD_FAILED", "The identity card could not be loaded.");
  return retry.data;
}

export const GET = withAuth(async (_request, { requestId, user }) => {
  return apiSuccess(await ensureCard(user.id), undefined, { requestId });
});

export const PATCH = withAuth(async (request, { requestId, user }) => {
  await ensureCard(user.id);
  const input = settingsSchema.parse(await readJsonBody(request));
  const payload = {
    ...(input.sharingEnabled !== undefined && { sharing_enabled: input.sharingEnabled }),
    ...(input.shareFullName !== undefined && { share_full_name: input.shareFullName }),
    ...(input.shareDateOfBirth !== undefined && { share_date_of_birth: input.shareDateOfBirth }),
    ...(input.shareEmergencyContact !== undefined && { share_emergency_contact: input.shareEmergencyContact }),
    ...(input.rotateToken === true && { qr_token: crypto.randomUUID() }),
    updated_at: new Date().toISOString(),
  };
  const { data, error } = await getSupabaseAdmin().from("patient_identity_cards")
    .update(payload).eq("patient_profile_id", user.id).select(selection).single();
  if (error) throw new HttpError(502, "IDENTITY_CARD_UPDATE_FAILED", "Identity privacy settings could not be saved.");
  return apiSuccess(data, undefined, { requestId });
});
