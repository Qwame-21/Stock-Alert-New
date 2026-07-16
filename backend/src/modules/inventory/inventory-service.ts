import { z } from "zod";

import { getSupabaseAdmin } from "@/lib/db/supabase-admin";
import { HttpError } from "@/lib/http/errors";
import type {
  CreateInventoryInput,
  InventoryAdjustmentInput,
  UpdateInventoryInput,
} from "@/modules/inventory/inventory-schema";

const inventoryRecordSchema = z.object({
  id: z.uuid(),
  pharmacy_id: z.uuid(),
  medicine_id: z.uuid(),
  batch_number: z.string(),
  quantity: z.number().int(),
  reorder_level: z.number().int(),
  expiry_date: z.string().nullable(),
  unit_price: z.coerce.number().nullable(),
  currency: z.string(),
  version: z.coerce.number().int(),
  deleted_at: z.string().nullable(),
  medicines: z
    .object({
      canonical_name: z.string(),
      generic_name: z.string().nullable(),
      brand_name: z.string().nullable(),
      strength: z.string().nullable(),
      dosage_form: z.string().nullable(),
      barcode: z.string().nullable(),
      manufacturer: z.string().nullable(),
      requires_prescription: z.boolean(),
    })
    .optional(),
});

function inventoryFailure(error: { code?: string; message: string }): never {
  const message = error.message.toLowerCase();
  if (error.code === "42501" || message.includes("not a pharmacy member")) {
    throw new HttpError(403, "FORBIDDEN", "Pharmacy membership is required.");
  }
  if (error.code === "P0002" || message.includes("not found")) {
    throw new HttpError(404, "INVENTORY_NOT_FOUND", "Inventory item not found.");
  }
  if (error.code === "40001" || message.includes("version conflict")) {
    throw new HttpError(
      409,
      "VERSION_CONFLICT",
      "The inventory item changed on another device.",
    );
  }
  if (error.code === "22003" || message.includes("insufficient stock")) {
    throw new HttpError(
      409,
      "INSUFFICIENT_STOCK",
      "The adjustment would make stock negative.",
    );
  }
  if (error.code === "23505") {
    throw new HttpError(
      409,
      "INVENTORY_ALREADY_EXISTS",
      "This medicine batch already exists in the pharmacy inventory.",
    );
  }

  throw new HttpError(
    502,
    "INVENTORY_OPERATION_FAILED",
    "The inventory operation could not be completed.",
  );
}

export async function listInventory(input: {
  pharmacyId: string;
  search?: string;
  limit: number;
  offset: number;
  includeOutOfStock: boolean;
}) {
  let query = getSupabaseAdmin()
    .from("inventory_items")
    .select(
      "id, pharmacy_id, medicine_id, batch_number, quantity, reorder_level, expiry_date, unit_price, currency, version, deleted_at, medicines(canonical_name, generic_name, brand_name, strength, dosage_form, barcode, manufacturer, requires_prescription)",
      { count: "exact" },
    )
    .eq("pharmacy_id", input.pharmacyId)
    .is("deleted_at", null)
    .range(input.offset, input.offset + input.limit - 1)
    .order("updated_at", { ascending: false });

  if (!input.includeOutOfStock) {
    query = query.gt("quantity", 0);
  }

  if (input.search) {
    query = query.or(
      `canonical_name.ilike.%${input.search}%,generic_name.ilike.%${input.search}%,brand_name.ilike.%${input.search}%`,
      { referencedTable: "medicines" },
    );
  }

  const { data, error, count } = await query;
  if (error) {
    inventoryFailure(error);
  }

  return {
    items: z.array(inventoryRecordSchema).parse(data ?? []),
    total: count ?? 0,
  };
}

export async function getInventoryItem(inventoryId: string) {
  const { data, error } = await getSupabaseAdmin()
    .from("inventory_items")
    .select(
      "id, pharmacy_id, medicine_id, batch_number, quantity, reorder_level, expiry_date, unit_price, currency, version, deleted_at, medicines(canonical_name, generic_name, brand_name, strength, dosage_form, barcode, manufacturer, requires_prescription)",
    )
    .eq("id", inventoryId)
    .is("deleted_at", null)
    .maybeSingle();

  if (error) {
    inventoryFailure(error);
  }
  if (!data) {
    throw new HttpError(404, "INVENTORY_NOT_FOUND", "Inventory item not found.");
  }

  return inventoryRecordSchema.parse(data);
}

export async function createInventoryItem(
  actorId: string,
  input: CreateInventoryInput,
) {
  const { data, error } = await getSupabaseAdmin().rpc(
    "create_inventory_item",
    {
      actor_id: actorId,
      target_pharmacy_id: input.pharmacyId,
      mutation_id: input.mutationId,
      medicine_data: {
        id: input.medicineId,
        canonical_name: input.medicine?.name,
        generic_name: input.medicine?.genericName,
        brand_name: input.medicine?.brandName,
        strength: input.medicine?.strength,
        dosage_form: input.medicine?.dosageForm,
        barcode: input.medicine?.barcode,
        manufacturer: input.medicine?.manufacturer,
        requires_prescription: input.medicine?.requiresPrescription,
      },
      item_data: {
        batch_number: input.batchNumber,
        quantity: input.quantity,
        reorder_level: input.reorderLevel,
        expiry_date: input.expiryDate,
        unit_price: input.unitPrice,
        currency: input.currency,
      },
    },
  );

  if (error) {
    inventoryFailure(error);
  }

  return getInventoryItem(z.uuid().parse(data));
}

export async function updateInventoryItem(
  actorId: string,
  inventoryId: string,
  input: UpdateInventoryInput,
) {
  const { data, error } = await getSupabaseAdmin().rpc(
    "update_inventory_item",
    {
      actor_id: actorId,
      inventory_id: inventoryId,
      mutation_id: input.mutationId,
      expected_version: input.expectedVersion,
      patch_data: {
        batch_number: input.batchNumber,
        reorder_level: input.reorderLevel,
        expiry_date: input.expiryDate,
        unit_price: input.unitPrice,
        currency: input.currency,
      },
    },
  );

  if (error) {
    inventoryFailure(error);
  }

  return inventoryRecordSchema.omit({ medicines: true }).parse(data);
}

export async function adjustInventoryStock(
  actorId: string,
  inventoryId: string,
  input: InventoryAdjustmentInput,
) {
  const { data, error } = await getSupabaseAdmin().rpc(
    "adjust_inventory_stock",
    {
      actor_id: actorId,
      inventory_id: inventoryId,
      mutation_id: input.mutationId,
      quantity_delta: input.quantityDelta,
      movement_kind: input.movementType,
      movement_reason: input.reason,
      expected_version: input.expectedVersion,
    },
  );

  if (error) {
    inventoryFailure(error);
  }

  return inventoryRecordSchema.omit({ medicines: true }).parse(data);
}

export async function deleteInventoryItem(
  actorId: string,
  inventoryId: string,
  input: { mutationId: string; expectedVersion: number },
) {
  const { error } = await getSupabaseAdmin().rpc("update_inventory_item", {
    actor_id: actorId,
    inventory_id: inventoryId,
    mutation_id: input.mutationId,
    expected_version: input.expectedVersion,
    patch_data: { deleted: true },
  });

  if (error) {
    inventoryFailure(error);
  }
}
