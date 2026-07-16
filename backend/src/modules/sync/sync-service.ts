import { z } from "zod";

import { HttpError } from "@/lib/http/errors";
import {
  cancelBookingSchema,
  createBookingSchema,
  updateBookingSchema,
} from "@/modules/bookings/booking-schema";
import {
  cancelBooking,
  createBooking,
  updateBooking,
} from "@/modules/bookings/booking-service";
import {
  createInventorySchema,
  deleteInventorySchema,
  inventoryAdjustmentSchema,
  updateInventorySchema,
} from "@/modules/inventory/inventory-schema";
import {
  adjustInventoryStock,
  createInventoryItem,
  deleteInventoryItem,
  updateInventoryItem,
} from "@/modules/inventory/inventory-service";
import type { SyncMutation } from "@/modules/sync/sync-schema";
import { getSupabaseAdmin } from "@/lib/db/supabase-admin";

interface MutationResult {
  mutationId: string;
  status: "synced" | "conflict" | "failed";
  entityId?: string;
  version?: number;
  error?: {
    code: string;
    message: string;
  };
}

const syncEventSchema = z.object({
  cursor: z.union([z.string(), z.number()]).transform(String),
  mutation_id: z.uuid(),
  entity_type: z.string(),
  entity_id: z.uuid(),
  operation: z.enum(["create", "update", "delete"]),
  payload: z.record(z.string(), z.unknown()),
  base_version: z.coerce.number().int().nullable(),
  resulting_version: z.coerce.number().int().nullable(),
  created_at: z.string(),
});

function resultFromRecord(
  mutationId: string,
  record: { id: string; version: number },
): MutationResult {
  return {
    mutationId,
    status: "synced",
    entityId: record.id,
    version: record.version,
  };
}

async function executeMutation(
  actorId: string,
  mutation: SyncMutation,
): Promise<MutationResult> {
  const payload = {
    ...mutation.payload,
    mutationId: mutation.mutationId,
  };

  if (mutation.entityType === "inventory") {
    if (mutation.operation === "create") {
      const record = await createInventoryItem(
        actorId,
        createInventorySchema.parse(payload),
      );
      return resultFromRecord(mutation.mutationId, record);
    }

    const entityId = z.uuid().parse(mutation.entityId);
    if (mutation.operation === "update") {
      const record = await updateInventoryItem(
        actorId,
        entityId,
        updateInventorySchema.parse(payload),
      );
      return resultFromRecord(mutation.mutationId, record);
    }
    if (mutation.operation === "adjust") {
      const record = await adjustInventoryStock(
        actorId,
        entityId,
        inventoryAdjustmentSchema.parse(payload),
      );
      return resultFromRecord(mutation.mutationId, record);
    }
    if (mutation.operation === "delete") {
      await deleteInventoryItem(
        actorId,
        entityId,
        deleteInventorySchema.parse(payload),
      );
      return {
        mutationId: mutation.mutationId,
        status: "synced",
        entityId,
      };
    }
  }

  if (mutation.entityType === "booking") {
    if (mutation.operation === "create") {
      const record = await createBooking(
        actorId,
        createBookingSchema.parse(payload),
      );
      return resultFromRecord(mutation.mutationId, record);
    }

    const entityId = z.uuid().parse(mutation.entityId);
    if (mutation.operation === "update") {
      const record = await updateBooking(
        actorId,
        entityId,
        updateBookingSchema.parse(payload),
      );
      return resultFromRecord(mutation.mutationId, record);
    }
    if (mutation.operation === "cancel") {
      const record = await cancelBooking(
        actorId,
        entityId,
        cancelBookingSchema.parse(payload),
      );
      return resultFromRecord(mutation.mutationId, record);
    }
  }

  throw new HttpError(
    400,
    "UNSUPPORTED_MUTATION",
    "The mutation operation is not supported.",
  );
}

export async function pushMutations(
  actorId: string,
  mutations: SyncMutation[],
): Promise<MutationResult[]> {
  const results: MutationResult[] = [];

  for (const mutation of mutations) {
    try {
      results.push(await executeMutation(actorId, mutation));
    } catch (error) {
      if (error instanceof z.ZodError) {
        results.push({
          mutationId: mutation.mutationId,
          status: "failed",
          entityId: mutation.entityId,
          error: {
            code: "VALIDATION_ERROR",
            message: "The mutation payload is invalid.",
          },
        });
        continue;
      }

      if (error instanceof HttpError) {
        results.push({
          mutationId: mutation.mutationId,
          status:
            error.code === "VERSION_CONFLICT" ||
            error.code === "BOOKING_CONFLICT"
              ? "conflict"
              : "failed",
          entityId: mutation.entityId,
          error: {
            code: error.code,
            message: error.message,
          },
        });
        continue;
      }

      throw error;
    }
  }

  return results;
}

export async function pullEvents(
  actorId: string,
  cursor: string,
  limit: number,
) {
  const { data, error } = await getSupabaseAdmin().rpc("pull_sync_events", {
    actor_id: actorId,
    after_cursor: cursor,
    page_size: limit,
  });

  if (error) {
    throw new HttpError(
      502,
      "SYNC_PULL_FAILED",
      "Synchronization events could not be loaded.",
    );
  }

  const events = z.array(syncEventSchema).parse(data ?? []);
  return {
    events,
    nextCursor:
      events.length > 0 ? events[events.length - 1].cursor : cursor,
    hasMore: events.length === limit,
  };
}
