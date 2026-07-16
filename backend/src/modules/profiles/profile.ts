import { z } from "zod";

export const profileSchema = z.object({
  role: z.enum(["patient", "pharmacy", "provider"]).nullable().default(null),
  full_name: z.string().nullable().default(null),
  email: z.string().nullable().default(null),
  phone_number: z.string().nullable().default(null),
  dob: z.string().nullable().default(null),
  gender: z.string().nullable().default(null),
  pharmacy_name: z.string().nullable().default(null),
  license_number: z.string().nullable().default(null),
  location: z.string().nullable().default(null),
  pharmacy_id: z.string().uuid().nullable().default(null),
});

export type Profile = z.infer<typeof profileSchema>;

export const profileUpdateSchema = z
  .object({
    fullName: z.string().trim().min(2).max(150).optional(),
    phoneNumber: z.string().trim().min(7).max(30).optional(),
    dateOfBirth: z.string().date().optional(),
    gender: z.string().trim().min(1).max(50).optional(),
    pharmacyName: z.string().trim().min(2).max(180).optional(),
    licenseNumber: z.string().trim().min(2).max(100).optional(),
    location: z.string().trim().min(2).max(300).optional(),
  })
  .strict()
  .refine((value) => Object.keys(value).length > 0, {
    message: "At least one profile field is required.",
  });

export type ProfileUpdateInput = z.infer<typeof profileUpdateSchema>;

const patientOnlyFields: ReadonlyArray<keyof ProfileUpdateInput> = [
  "fullName",
  "dateOfBirth",
  "gender",
];

const pharmacyOnlyFields: ReadonlyArray<keyof ProfileUpdateInput> = [
  "pharmacyName",
  "licenseNumber",
  "location",
];

export function hasFieldsForAnotherRole(
  role: "patient" | "pharmacy" | "provider",
  input: ProfileUpdateInput,
): boolean {
  const forbidden =
    role === "patient"
      ? pharmacyOnlyFields
      : role === "pharmacy"
        ? patientOnlyFields
        : pharmacyOnlyFields;
  return forbidden.some((field) => input[field] !== undefined);
}
