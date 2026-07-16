import { getSupabaseAdmin } from "@/lib/db/supabase-admin";
import { logger } from "@/lib/observability/logger";

export async function recordAuditEvent(input: {
  actorId?: string;
  action: string;
  entityType: string;
  entityId?: string;
  requestId: string;
  metadata?: Record<string, unknown>;
}) {
  const { error } = await getSupabaseAdmin().rpc("record_audit_event", {
    actor_id: input.actorId,
    event_action: input.action,
    event_entity_type: input.entityType,
    event_entity_id: input.entityId,
    event_request_id: input.requestId,
    event_metadata: input.metadata ?? {},
  });

  if (error) {
    logger.error("audit_write_failed", {
      requestId: input.requestId,
      action: input.action,
      entityType: input.entityType,
      errorCode: error.code,
    });
  }
}
