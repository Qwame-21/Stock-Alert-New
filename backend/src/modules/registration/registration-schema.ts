import { z } from "zod";

const email = z.email().max(254).transform((value) => value.toLowerCase());
const optionalText = z.string().trim().max(200).optional();

const accountSchema = z.object({
  email,
  password: z
    .string()
    .min(8, "Password must be at least 8 characters.")
    .max(72),
  phoneNumber: z.string().trim().min(7).max(30),
  documentType: z.string().trim().min(1).max(80).optional(),
  documentPath: z.string().trim().max(500).optional(),
});

const patientRegistrationSchema = accountSchema.extend({
  role: z.literal("patient"),
  fullName: z.string().trim().min(2).max(150),
  dateOfBirth: z.string().date(),
  gender: z.string().trim().min(1).max(50),
  bloodGroup: optionalText,
  knownAllergies: z.array(z.string().trim().min(1).max(100)).max(50).optional(),
  chronicConditions: z
    .array(z.string().trim().min(1).max(100))
    .max(50)
    .optional(),
  currentMedication: z.string().trim().max(1000).optional(),
  emergencyContactName: optionalText,
  emergencyContactPhone: z.string().trim().max(30).optional(),
  emergencyContactEmail: z.email().max(254).optional(),
});

const pharmacyRegistrationSchema = accountSchema.extend({
  role: z.literal("pharmacy"),
  pharmacyName: z.string().trim().min(2).max(180),
  licenseNumber: z.string().trim().min(2).max(100),
  registrationAuthority: optionalText,
  location: z.string().trim().min(2).max(300),
  operatingHours: optionalText,
  supplierPreference: optionalText,
});

const providerRegistrationSchema = accountSchema.extend({
  role: z.literal("provider"),
  fullName: z.string().trim().min(2).max(150),
  specialty: z.string().trim().min(2).max(180),
  professionalLicense: z.string().trim().min(2).max(120),
  registrationAuthority: z.string().trim().min(2).max(180),
  yearsExperience: z.number().int().min(0).max(80).default(0),
  bio: z.string().trim().max(1500).optional(),
  consultationMode: z.enum(["video", "in_person", "both"]).default("video"),
  location: z.string().trim().max(300).optional(),
  consultationDuration: z.number().int().min(10).max(180).default(30),
  profileImageBase64: z.string().min(1).max(4_000_000),
  profileImageExtension: z.enum(["jpg", "jpeg", "png", "webp"]),
  providerPolicyAccepted: z.literal(true),
});

export const registrationSchema = z.discriminatedUnion("role", [
  patientRegistrationSchema,
  pharmacyRegistrationSchema,
  providerRegistrationSchema,
]);

export type RegistrationInput = z.infer<typeof registrationSchema>;
