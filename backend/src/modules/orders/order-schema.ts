import { z } from "zod";

export const supplierInputSchema = z.object({
  pharmacyId: z.uuid(), name: z.string().trim().min(2).max(200),
  contactPerson: z.string().trim().max(150).optional(), phone: z.string().trim().max(40).optional(),
  email: z.email().optional(), address: z.string().trim().max(500).optional(),
  paymentTerms: z.string().trim().max(200).optional(), leadTimeDays: z.number().int().min(0).max(365).default(0),
  notes: z.string().trim().max(1000).optional(),
});
export const supplierQuerySchema = z.object({ pharmacyId: z.uuid() });

export const orderItemSchema = z.object({
  medicineId: z.uuid().optional(), medicineName: z.string().trim().min(2).max(200),
  barcode: z.string().trim().max(100).optional(), quantity: z.number().int().positive().max(100000000),
  unitCost: z.number().finite().min(0).nullable().optional(),
});
export const createOrderSchema = z.object({
  pharmacyId: z.uuid(), supplierId: z.uuid(), expectedDeliveryDate: z.string().date().nullable().optional(),
  notes: z.string().trim().max(2000).optional(), currency: z.string().length(3).toUpperCase().default("GHS"),
  items: z.array(orderItemSchema).min(1).max(200),
});
export const orderQuerySchema = z.object({ pharmacyId: z.uuid(), status: z.string().optional() });
export const updateOrderStatusSchema = z.object({
  status: z.enum(["draft", "submitted", "confirmed", "cancelled"]), note: z.string().trim().max(500).optional(),
});
export const receiveOrderSchema = z.object({ lines: z.array(z.object({
  orderItemId: z.uuid(), quantity: z.number().int().positive(), batchNumber: z.string().trim().min(1).max(100),
  expiryDate: z.string().date().nullable().optional(), mutationId: z.uuid(),
})).min(1).max(200) });
export type SupplierInput = z.infer<typeof supplierInputSchema>;
export type CreateOrderInput = z.infer<typeof createOrderSchema>;
