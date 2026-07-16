import { z } from "zod";

export const pharmacyDiscoveryQuerySchema = z.object({
  search: z.string().trim().max(100).default(""),
  limit: z.coerce.number().int().min(1).max(100).default(50),
});

export type PharmacyDiscoveryQuery = z.infer<
  typeof pharmacyDiscoveryQuerySchema
>;
