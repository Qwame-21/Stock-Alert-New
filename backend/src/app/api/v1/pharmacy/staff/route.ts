import { z } from "zod";
import { withAuth } from "@/lib/auth/with-auth";
import { getSupabaseAdmin } from "@/lib/db/supabase-admin";
import { apiSuccess } from "@/lib/http/api-response";
import { HttpError } from "@/lib/http/errors";
import { readJsonBody } from "@/lib/http/json-body";

const inviteSchema = z.object({
  fullName: z.string().trim().min(2).max(150),
  email: z.email().max(254).transform((value) => value.toLowerCase()),
  staffRole: z.enum(["pharmacist", "staff"]),
});

async function ownerPharmacy(userId: string) {
  const { data, error } = await getSupabaseAdmin().from("pharmacies").select("id").eq("owner_profile_id", userId).maybeSingle();
  if (error) throw new HttpError(502, "PHARMACY_LOOKUP_FAILED", "The pharmacy could not be loaded.");
  if (!data) throw new HttpError(403, "PHARMACY_OWNER_REQUIRED", "Only the pharmacy owner can manage staff.");
  return data.id as string;
}

export const GET = withAuth(async (_request, { requestId, user }) => {
  const pharmacyId = await ownerPharmacy(user.id);
  const { data, error } = await getSupabaseAdmin().from("pharmacy_staff").select("profile_id,staff_role,profiles(email,full_name)").eq("pharmacy_id", pharmacyId).neq("staff_role", "owner");
  if (error) throw new HttpError(502, "STAFF_LOOKUP_FAILED", "Staff accounts could not be loaded.");
  return apiSuccess({ staff: (data ?? []).map((row) => {
    const profile = row.profiles as unknown as { email?: string; full_name?: string } | null;
    return { profileId: row.profile_id, staffRole: row.staff_role, email: profile?.email, fullName: profile?.full_name };
  }) }, undefined, { requestId });
});

export const POST = withAuth(async (request, { requestId, user }) => {
  const pharmacyId = await ownerPharmacy(user.id);
  const input = inviteSchema.parse(await readJsonBody(request));
  const admin = getSupabaseAdmin();
  const { data: invited, error: inviteError } = await admin.auth.admin.inviteUserByEmail(input.email, { data: { role: "pharmacy", full_name: input.fullName, pharmacy_staff_role: input.staffRole } });
  if (inviteError || !invited.user) throw new HttpError(400, "STAFF_INVITE_FAILED", inviteError?.message ?? "The staff invitation could not be sent.");
  const { error: profileError } = await admin.from("profiles").upsert({ id: invited.user.id, role: "pharmacy", email: input.email, full_name: input.fullName });
  if (profileError) throw new HttpError(502, "STAFF_INVITE_FAILED", "The staff profile could not be created.");
  const { error } = await admin.from("pharmacy_staff").upsert({ pharmacy_id: pharmacyId, profile_id: invited.user.id, staff_role: input.staffRole });
  if (error) throw new HttpError(502, "STAFF_INVITE_FAILED", "Staff access could not be assigned.");
  return apiSuccess({ invited: true }, { status: 201 }, { requestId });
});
