import { describe, expect, it } from "vitest";

import {
  syncMutationSchema,
  syncPullQuerySchema,
  syncPushSchema,
} from "@/modules/sync/sync-schema";

const uuid = "8c879b85-91f8-4fdb-b5fc-08aeed6635cb";

describe("sync schemas", () => {
  it("accepts an inventory create mutation", () => {
    expect(() =>
      syncMutationSchema.parse({
        mutationId: uuid,
        entityType: "inventory",
        operation: "create",
        payload: {},
      }),
    ).not.toThrow();
  });

  it("requires entity IDs for non-create operations", () => {
    expect(() =>
      syncMutationSchema.parse({
        mutationId: uuid,
        entityType: "booking",
        operation: "cancel",
        payload: {},
      }),
    ).toThrow();
  });

  it("rejects operations belonging to another entity", () => {
    expect(() =>
      syncMutationSchema.parse({
        mutationId: uuid,
        entityType: "booking",
        operation: "adjust",
        entityId: uuid,
        payload: {},
      }),
    ).toThrow();
  });

  it("limits push batches", () => {
    const mutation = {
      mutationId: uuid,
      entityType: "inventory",
      operation: "create",
      payload: {},
    };
    expect(() =>
      syncPushSchema.parse({ mutations: Array(51).fill(mutation) }),
    ).toThrow();
  });

  it("coerces pull cursors and limits", () => {
    expect(syncPullQuerySchema.parse({ cursor: "10", limit: "25" })).toEqual({
      cursor: "10",
      limit: 25,
    });
  });

  it("preserves cursors larger than JavaScript safe integers", () => {
    expect(
      syncPullQuerySchema.parse({ cursor: "9223372036854775807" }).cursor,
    ).toBe("9223372036854775807");
  });
});
