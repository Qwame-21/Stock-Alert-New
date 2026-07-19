import { z } from "zod";

import { getSupabaseAdmin } from "@/lib/db/supabase-admin";
import { HttpError } from "@/lib/http/errors";
import { logger } from "@/lib/observability/logger";

const rewardTransactionSchema = z.object({
  id: z.uuid(),
  title: z.string(),
  description: z.string().nullable(),
  points: z.number().int(),
  status: z.enum(["pending", "confirmed", "reversed"]),
  source_type: z.enum([
    "medicine_return",
    "prescription_refill",
    "consultation",
    "promotion",
    "adjustment",
  ]),
  source_reference: z.string().nullable(),
  occurred_at: z.string(),
});

export async function getPatientRewards(patientId: string) {
  const [activityResult, balanceResult] = await Promise.all([
    getSupabaseAdmin()
      .from("reward_transactions")
      .select(
        "id,title,description,points,status,source_type,source_reference,occurred_at",
      )
      .eq("patient_profile_id", patientId)
      .order("occurred_at", { ascending: false })
      .limit(100),
    getSupabaseAdmin()
      .from("reward_transactions")
      .select("points")
      .eq("patient_profile_id", patientId)
      .eq("status", "confirmed"),
  ]);

  if (activityResult.error || balanceResult.error) {
    const error = activityResult.error ?? balanceResult.error!;
    logger.error("reward_read_error", {
      databaseCode: error.code,
      databaseMessage: error.message,
    });
    throw new HttpError(
      502,
      "REWARDS_UNAVAILABLE",
      "Rewards could not be loaded right now.",
    );
  }

  const transactions = z
    .array(rewardTransactionSchema)
    .parse(activityResult.data ?? []);
  const balance = (balanceResult.data ?? []).reduce(
    (total, item) => total + z.number().int().parse(item.points),
    0,
  );

  return {
    balance: Math.max(0, balance),
    pending: transactions.filter((item) => item.status === "pending"),
    activity: transactions.filter((item) => item.status !== "pending"),
  };
}
