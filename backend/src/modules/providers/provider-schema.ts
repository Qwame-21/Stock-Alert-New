import { z } from "zod";

export const providerQuerySchema = z.object({
  date: z.string().date(),
  specialty: z.string().trim().max(180).optional(),
});

export const availabilityUpdateSchema = z.object({
  isAcceptingBookings: z.boolean(),
  consultationDuration: z.number().int().min(10).max(180),
  consultationMode: z.enum(["video", "in_person", "both"]),
  videoFee: z.number().min(0).max(100000),
  inPersonFee: z.number().min(0).max(100000),
  availability: z.array(
    z.object({
      weekday: z.number().int().min(1).max(7),
      startTime: z.string().regex(/^\d{2}:\d{2}$/),
      endTime: z.string().regex(/^\d{2}:\d{2}$/),
    }),
  ).max(28),
});
