import { z } from "zod";

export const bookingStatusSchema = z.enum([
  "pending",
  "confirmed",
  "completed",
  "cancelled",
  "no_show",
]);

export const bookingQuerySchema = z.object({
  status: bookingStatusSchema.optional(),
  upcoming: z
    .enum(["true", "false"])
    .transform((value) => value === "true")
    .default(true),
  limit: z.coerce.number().int().min(1).max(100).default(50),
  offset: z.coerce.number().int().min(0).default(0),
});

export const createBookingSchema = z.object({
  mutationId: z.uuid(),
  providerId: z.uuid(),
  pharmacyId: z.uuid().nullable().optional(),
  providerName: z.string().trim().min(2).max(180),
  specialty: z.string().trim().max(180).optional(),
  scheduledAt: z.iso.datetime({ offset: true }),
  consultationMode: z.enum(["video", "in_person"]),
  clinicalReason: z.string().trim().min(2).max(300),
  patientCondition: z.string().trim().min(2).max(300),
  requestedSupport: z.string().trim().min(2).max(500),
  durationMinutes: z.number().int().min(5).max(480).default(30),
  notes: z.string().trim().max(2000).optional(),
});

export const updateBookingSchema = z
  .object({
    mutationId: z.uuid(),
    expectedVersion: z.number().int().positive(),
    scheduledAt: z.iso.datetime({ offset: true }).optional(),
    durationMinutes: z.number().int().min(5).max(480).optional(),
    notes: z.string().trim().max(2000).nullable().optional(),
    videoLink: z.url().max(1000).nullable().optional(),
    status: bookingStatusSchema.optional(),
    decisionNote: z.string().trim().max(500).nullable().optional(),
  })
  .refine(
    (value) =>
      Object.keys(value).some(
        (key) => key !== "mutationId" && key !== "expectedVersion",
      ),
    { message: "At least one booking field is required." },
  );

export const cancelBookingSchema = z.object({
  mutationId: z.uuid(),
  expectedVersion: z.number().int().positive(),
  reason: z.string().trim().min(2).max(500),
  category: z.enum(["schedule_change", "feeling_better", "cost", "provider_change", "other"]),
});

export type CreateBookingInput = z.infer<typeof createBookingSchema>;
export type UpdateBookingInput = z.infer<typeof updateBookingSchema>;
export type CancelBookingInput = z.infer<typeof cancelBookingSchema>;
