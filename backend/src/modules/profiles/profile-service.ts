import { getSupabaseAdmin } from "@/lib/db/supabase-admin";
import { HttpError } from "@/lib/http/errors";
import {
  hasFieldsForAnotherRole,
  profileSchema,
  type Profile,
  type ProfileUpdateInput,
} from "@/modules/profiles/profile";

export async function getProfileByUserId(userId: string): Promise<Profile | null> {
  const { data, error } = await getSupabaseAdmin()
    .from("profiles")
    .select(
      "role, full_name, email, phone_number, dob, gender, pharmacy_name, license_number, location",
    )
    .eq("id", userId)
    .maybeSingle();

  if (error) {
    throw new HttpError(
      502,
      "PROFILE_LOOKUP_FAILED",
      "The profile could not be loaded.",
    );
  }

  if (!data) {
    return null;
  }

  let pharmacyId: string | null = null;
  if (data.role === "pharmacy") {
    const { data: pharmacy, error: pharmacyError } = await getSupabaseAdmin()
      .from("pharmacies")
      .select("id")
      .eq("owner_profile_id", userId)
      .maybeSingle();
    if (pharmacyError) {
      throw new HttpError(
        502,
        "PROFILE_LOOKUP_FAILED",
        "The pharmacy context could not be loaded.",
      );
    }
    pharmacyId = pharmacy?.id ?? null;
  }

  return profileSchema.parse({ ...data, pharmacy_id: pharmacyId });
}

export async function updateProfile(
  userId: string,
  input: ProfileUpdateInput,
): Promise<Profile> {
  const existing = await getProfileByUserId(userId);
  if (!existing) {
    throw new HttpError(404, "PROFILE_NOT_FOUND", "The profile was not found.");
  }

  if (!existing.role) {
    throw new HttpError(
      409,
      "PROFILE_ROLE_MISSING",
      "The profile does not have a valid account role.",
    );
  }

  if (hasFieldsForAnotherRole(existing.role, input)) {
    throw new HttpError(
      403,
      "PROFILE_FIELD_FORBIDDEN",
      "One or more fields cannot be changed for this account role.",
    );
  }

  const payload = {
    ...(input.fullName !== undefined && { full_name: input.fullName }),
    ...(input.phoneNumber !== undefined && {
      phone_number: input.phoneNumber,
    }),
    ...(input.dateOfBirth !== undefined && { dob: input.dateOfBirth }),
    ...(input.gender !== undefined && { gender: input.gender }),
    ...(input.pharmacyName !== undefined && {
      pharmacy_name: input.pharmacyName,
    }),
    ...(input.licenseNumber !== undefined && {
      license_number: input.licenseNumber,
    }),
    ...(input.location !== undefined && { location: input.location }),
  };

  const { data, error } = await getSupabaseAdmin()
    .from("profiles")
    .update(payload)
    .eq("id", userId)
    .select(
      "role, full_name, email, phone_number, dob, gender, pharmacy_name, license_number, location",
    )
    .maybeSingle();

  if (error) {
    throw new HttpError(
      502,
      "PROFILE_UPDATE_FAILED",
      "The profile could not be updated.",
    );
  }

  if (!data) {
    throw new HttpError(404, "PROFILE_NOT_FOUND", "The profile was not found.");
  }

  return profileSchema.parse({
    ...data,
    pharmacy_id: existing.pharmacy_id,
  });
}
