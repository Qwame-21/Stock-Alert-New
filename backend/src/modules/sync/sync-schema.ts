import { z } from "zod";

export const syncMutationSchema = z
  .object({
    mutationId: z.uuid(),
    entityType: z.enum(["inventory", "booking"]),
    operation: z.enum(["create", "update", "adjust", "delete", "cancel"]),
    entityId: z.uuid().optional(),
    payload: z.record(z.string(), z.unknown()),
  })
  .superRefine((value, context) => {
    const valid =
      (value.entityType === "inventory" &&
        ["create", "update", "adjust", "delete"].includes(value.operation)) ||
      (value.entityType === "booking" &&
        ["create", "update", "cancel"].includes(value.operation));

    if (!valid) {
      context.addIssue({
        code: "custom",
        message: "The operation is not valid for this entity type.",
        path: ["operation"],
      });
    }

    if (value.operation !== "create" && !value.entityId) {
      context.addIssue({
        code: "custom",
        message: "entityId is required for this operation.",
        path: ["entityId"],
      });
    }
  });

export const syncPushSchema = z.object({
  mutations: z.array(syncMutationSchema).min(1).max(50),
});

export const syncPullQuerySchema = z.object({
  cursor: z
    .string()
    .regex(/^\d+$/)
    .default("0"),
  limit: z.coerce.number().int().min(1).max(200).default(100),
});

export type SyncMutation = z.infer<typeof syncMutationSchema>;
