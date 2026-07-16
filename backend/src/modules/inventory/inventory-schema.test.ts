import { describe, expect, it } from "vitest";

import {
  createInventorySchema,
  inventoryAdjustmentSchema,
  inventoryQuerySchema,
  updateInventorySchema,
} from "@/modules/inventory/inventory-schema";

const uuid = "8c879b85-91f8-4fdb-b5fc-08aeed6635cb";

describe("inventory schemas", () => {
  it("accepts new medicine inventory", () => {
    expect(() =>
      createInventorySchema.parse({
        mutationId: uuid,
        pharmacyId: uuid,
        medicine: { name: "Amoxicillin 500mg" },
        quantity: 20,
      }),
    ).not.toThrow();
  });

  it("requires medicine identity", () => {
    expect(() =>
      createInventorySchema.parse({
        mutationId: uuid,
        pharmacyId: uuid,
        quantity: 20,
      }),
    ).toThrow();
  });

  it("rejects zero stock adjustments", () => {
    expect(() =>
      inventoryAdjustmentSchema.parse({
        mutationId: uuid,
        expectedVersion: 1,
        quantityDelta: 0,
        movementType: "adjust",
      }),
    ).toThrow();
  });

  it("requires an editable field for updates", () => {
    expect(() =>
      updateInventorySchema.parse({
        mutationId: uuid,
        expectedVersion: 1,
      }),
    ).toThrow();
  });

  it("coerces pagination query values", () => {
    expect(
      inventoryQuerySchema.parse({
        pharmacyId: uuid,
        limit: "25",
        offset: "10",
      }),
    ).toMatchObject({ limit: 25, offset: 10, includeOutOfStock: false });
  });
});
