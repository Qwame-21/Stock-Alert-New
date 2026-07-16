import { z } from "zod";

const moneySchema = z.number().finite().min(0).max(9999999999.99);

export const inventoryQuerySchema = z.object({
  pharmacyId: z.uuid(),
  search: z.string().trim().max(100).optional(),
  limit: z.coerce.number().int().min(1).max(100).default(50),
  offset: z.coerce.number().int().min(0).default(0),
  includeOutOfStock: z
    .enum(["true", "false"])
    .transform((value) => value === "true")
    .default(false),
});

export const createInventorySchema = z
  .object({
    mutationId: z.uuid(),
    pharmacyId: z.uuid(),
    medicineId: z.uuid().optional(),
    medicine: z
      .object({
        name: z.string().trim().min(2).max(200),
        genericName: z.string().trim().max(200).optional(),
        brandName: z.string().trim().max(200).optional(),
        strength: z.string().trim().max(100).optional(),
        dosageForm: z.string().trim().max(100).optional(),
        barcode: z.string().trim().max(100).optional(),
        manufacturer: z.string().trim().max(200).optional(),
        requiresPrescription: z.boolean().default(false),
      })
      .optional(),
    batchNumber: z.string().trim().max(100).default(""),
    quantity: z.number().int().min(0).max(100000000),
    reorderLevel: z.number().int().min(0).max(100000000).default(0),
    expiryDate: z.string().date().nullable().optional(),
    unitPrice: moneySchema.nullable().optional(),
    currency: z.string().trim().length(3).toUpperCase().default("GHS"),
  })
  .refine((value) => value.medicineId || value.medicine, {
    message: "medicineId or medicine is required.",
    path: ["medicine"],
  });

export const updateInventorySchema = z
  .object({
    mutationId: z.uuid(),
    expectedVersion: z.number().int().positive(),
    batchNumber: z.string().trim().max(100).optional(),
    reorderLevel: z.number().int().min(0).max(100000000).optional(),
    expiryDate: z.string().date().nullable().optional(),
    unitPrice: moneySchema.nullable().optional(),
    currency: z.string().trim().length(3).toUpperCase().optional(),
  })
  .refine(
    (value) =>
      Object.keys(value).some(
        (key) => key !== "mutationId" && key !== "expectedVersion",
      ),
    { message: "At least one inventory field is required." },
  );

export const inventoryAdjustmentSchema = z.object({
  mutationId: z.uuid(),
  expectedVersion: z.number().int().positive(),
  quantityDelta: z.number().int().refine((value) => value !== 0),
  movementType: z.enum(["receive", "dispense", "adjust", "expire", "return"]),
  reason: z.string().trim().max(500).optional(),
});

export const deleteInventorySchema = z.object({
  mutationId: z.uuid(),
  expectedVersion: z.number().int().positive(),
});

export type CreateInventoryInput = z.infer<typeof createInventorySchema>;
export type UpdateInventoryInput = z.infer<typeof updateInventorySchema>;
export type InventoryAdjustmentInput = z.infer<
  typeof inventoryAdjustmentSchema
>;
