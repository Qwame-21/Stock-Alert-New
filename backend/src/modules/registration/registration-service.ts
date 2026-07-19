import type { Session, User } from "@supabase/supabase-js";

import { getSupabaseAdmin } from "@/lib/db/supabase-admin";
import { getSupabaseAuthClient } from "@/lib/db/supabase-auth";
import { getBackendEnv } from "@/lib/config/env";
import { HttpError } from "@/lib/http/errors";
import type { RegistrationInput } from "@/modules/registration/registration-schema";

interface RegistrationResult {
  user: {
    id: string;
    email: string;
  };
  confirmationRequired: boolean;
  session: {
    accessToken: string;
    refreshToken: string;
    expiresAt: number | null;
  } | null;
}

function profilePayload(
  input: RegistrationInput,
  userId: string,
): Record<string, unknown> {
  const common = {
    id: userId,
    role: input.role,
    email: input.email,
    phone_number: input.phoneNumber,
  };

  if (input.role === "patient") {
    return {
      ...common,
      full_name: input.fullName,
      dob: input.dateOfBirth,
      gender: input.gender,
    };
  }
  if (input.role === "provider") {
    return { ...common, full_name: input.fullName };
  }

  return {
    ...common,
    pharmacy_name: input.pharmacyName,
    license_number: input.licenseNumber,
    location: input.location,
  };
}

function detailsPayload(input: RegistrationInput): Record<string, unknown> {
  const document = {
    document_type: input.documentType,
    document_path: input.documentPath,
  };

  if (input.role === "patient") {
    return {
      ...document,
      blood_group: input.bloodGroup,
      known_allergies: input.knownAllergies ?? [],
      chronic_conditions: input.chronicConditions ?? [],
      current_medication: input.currentMedication,
      emergency_contact_name: input.emergencyContactName,
      emergency_contact_phone: input.emergencyContactPhone,
      emergency_contact_email: input.emergencyContactEmail,
    };
  }
  if (input.role === "provider") {
    return { ...document };
  }

  return {
    ...document,
    registration_authority: input.registrationAuthority,
    operating_hours: input.operatingHours,
    supplier_preference: input.supplierPreference,
  };
}

function sessionPayload(session: Session | null) {
  if (!session) {
    return null;
  }

  return {
    accessToken: session.access_token,
    refreshToken: session.refresh_token,
    expiresAt: session.expires_at ?? null,
  };
}

async function findAuthUserByEmail(email: string): Promise<User | null> {
  const admin = getSupabaseAdmin();
  for (let page = 1; page <= 10; page += 1) {
    const { data, error } = await admin.auth.admin.listUsers({
      page,
      perPage: 1000,
    });
    if (error) {
      throw new HttpError(
        502,
        "ACCOUNT_RECOVERY_FAILED",
        "The existing account could not be checked. Please try again.",
      );
    }
    const match = data.users.find(
      (candidate) => candidate.email?.toLowerCase() === email.toLowerCase(),
    );
    if (match) return match;
    if (data.users.length < 1000) break;
  }
  return null;
}

async function createRoleProfile(input: RegistrationInput, userId: string) {
  const admin = getSupabaseAdmin();
  let profileError;
  if (input.role === "provider") {
    const { error: providerProfileError } = await admin.from("profiles").upsert({
      id: userId,
      role: "provider",
      email: input.email,
      full_name: input.fullName,
      phone_number: input.phoneNumber,
      location: input.location,
    });
    profileError = providerProfileError;
    if (!profileError) {
      const { error } = await admin.from("consultation_providers").upsert({
        profile_id: userId,
        display_name: input.fullName,
        specialty: input.specialty,
        professional_license: input.professionalLicense,
        registration_authority: input.registrationAuthority,
        years_experience: input.yearsExperience,
        bio: input.bio,
        consultation_mode: input.consultationMode,
        location: input.location,
        consultation_duration: input.consultationDuration,
        verification_status: getBackendEnv().TESTING_MODE
          ? "verified"
          : "pending",
      });
      profileError = error;
    }
    if (!profileError) {
      const storage = admin.storage;
      const path = `${userId}/profile.${input.profileImageExtension}`;
      const { error } = await storage.from("avatars").upload(
        path,
        Buffer.from(input.profileImageBase64, "base64"),
        {
          upsert: true,
          contentType: `image/${input.profileImageExtension === "jpg" ? "jpeg" : input.profileImageExtension}`,
        },
      );
      profileError = error;
    }
  } else {
    const result = await admin.rpc("create_account_profile", {
      user_id: userId,
      profile_data: profilePayload(input, userId),
      details_data: detailsPayload(input),
    });
    profileError = result.error;
  }
  return profileError;
}

async function recoverExistingAccount(
  input: RegistrationInput,
): Promise<RegistrationResult> {
  const auth = getSupabaseAuthClient();
  const signIn = await auth.auth.signInWithPassword({
    email: input.email,
    password: input.password,
  });
  const emailUnconfirmed = signIn.error?.message
    .toLowerCase()
    .includes("email not confirmed");
  if (signIn.error && !emailUnconfirmed) {
    throw new HttpError(
      409,
      "EMAIL_ALREADY_REGISTERED",
      "An account with this email already exists. Use its password to continue or reset the password.",
    );
  }

  const existingUser = signIn.data.user ?? (await findAuthUserByEmail(input.email));
  if (!existingUser) {
    throw new HttpError(
      409,
      "EMAIL_ALREADY_REGISTERED",
      "An account with this email already exists. Please sign in instead.",
    );
  }

  const admin = getSupabaseAdmin();
  const { data: existingProfile, error: profileLookupError } = await admin
    .from("profiles")
    .select("role")
    .eq("id", existingUser.id)
    .maybeSingle();
  if (profileLookupError) {
    throw new HttpError(502, "ACCOUNT_RECOVERY_FAILED", "The account profile could not be checked.");
  }
  if (existingProfile && existingProfile.role !== input.role) {
    throw new HttpError(
      409,
      "ACCOUNT_ROLE_MISMATCH",
      `This email belongs to a ${existingProfile.role} account. Choose that account type when signing in.`,
    );
  }
  if (!existingProfile) {
    const profileError = await createRoleProfile(input, existingUser.id);
    if (profileError) {
      console.error("Registration recovery profile creation failed", {
        userId: existingUser.id,
        error: profileError.message,
      });
      throw new HttpError(
        502,
        "PROFILE_CREATION_FAILED",
        "Your sign-in was found, but the account profile could not be repaired. Please try again.",
      );
    }
  }

  return {
    user: { id: existingUser.id, email: existingUser.email ?? input.email },
    confirmationRequired: signIn.data.session === null,
    session: sessionPayload(signIn.data.session),
  };
}

export async function registerAccount(
  input: RegistrationInput,
): Promise<RegistrationResult> {
  const userMetadata =
    input.role === "patient"
      ? {
          role: input.role,
          full_name: input.fullName,
          phone_number: input.phoneNumber,
          dob: input.dateOfBirth,
          gender: input.gender,
        }
      : input.role === "pharmacy"
        ? {
          role: input.role,
          pharmacy_name: input.pharmacyName,
          phone_number: input.phoneNumber,
          license_number: input.licenseNumber,
          location: input.location,
        }
        : {
            role: input.role,
            full_name: input.fullName,
            phone_number: input.phoneNumber,
            specialty: input.specialty,
            professional_license: input.professionalLicense,
            registration_authority: input.registrationAuthority,
            years_experience: input.yearsExperience,
            consultation_mode: input.consultationMode,
            consultation_duration: input.consultationDuration,
            location: input.location,
          };

  const {
    data: { user, session },
    error: signUpError,
  } = await getSupabaseAuthClient().auth.signUp({
    email: input.email,
    password: input.password,
    options: { data: userMetadata },
  });

  if (signUpError || !user) {
    const duplicate = signUpError?.message.toLowerCase().includes("registered");
    if (duplicate) return recoverExistingAccount(input);
    throw new HttpError(
      duplicate ? 409 : 400,
      duplicate ? "EMAIL_ALREADY_REGISTERED" : "REGISTRATION_FAILED",
      duplicate
        ? "An account with this email already exists."
        : "The account could not be created.",
    );
  }

  if (user.identities?.length === 0) {
    return recoverExistingAccount(input);
  }

  const profileError = await createRoleProfile(input, user.id);

  if (profileError) {
    const { error: cleanupError } = await getSupabaseAdmin().auth.admin.deleteUser(
      user.id,
    );
    if (cleanupError) {
      console.error("Registration cleanup failed", {
        userId: user.id,
        error: cleanupError.message,
      });
    }

    throw new HttpError(
      502,
      "PROFILE_CREATION_FAILED",
      "The account profile could not be created.",
    );
  }

  return {
    user: {
      id: user.id,
      email: user.email ?? input.email,
    },
    confirmationRequired: session === null,
    session: sessionPayload(session),
  };
}
