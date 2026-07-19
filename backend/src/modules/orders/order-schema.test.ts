import { describe, expect, it } from "vitest";
import { createOrderSchema, supplierInputSchema } from "./order-schema";
describe("supplier orders",()=>{
  it("validates supplier details",()=>expect(supplierInputSchema.parse({pharmacyId:"550e8400-e29b-41d4-a716-446655440000",name:"Community Wholesale"}).leadTimeDays).toBe(0));
  it("requires at least one positive order line",()=>expect(()=>createOrderSchema.parse({pharmacyId:"550e8400-e29b-41d4-a716-446655440000",supplierId:"550e8400-e29b-41d4-a716-446655440001",items:[]})).toThrow());
});
