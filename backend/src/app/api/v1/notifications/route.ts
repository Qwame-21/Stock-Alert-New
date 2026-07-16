import { withAuth } from "@/lib/auth/with-auth";
import { apiSuccess } from "@/lib/http/api-response";
import { readJsonBody } from "@/lib/http/json-body";
import { getSupabaseAdmin } from "@/lib/db/supabase-admin";
import { listNotifications } from "@/modules/notifications/notification-service";
import { z } from "zod";

export const dynamic = "force-dynamic";

export const GET = withAuth(async (_request, { requestId, user }) => {
  return apiSuccess(
    await listNotifications(user.id),
    undefined,
    { requestId },
  );
});

const preferencesSchema = z
  .object({
    pushEnabled: z.boolean().optional(),
    bookingReminders: z.boolean().optional(),
    medicationReminders: z.boolean().optional(),
  })
  .refine((value) => Object.keys(value).length > 0);

export const PATCH = withAuth(async (request, { requestId, user }) => {
  const input = preferencesSchema.parse(await readJsonBody(request));
  const { data, error } = await getSupabaseAdmin()
    .from("notification_preferences")
    .upsert({
      profile_id: user.id,
      ...(input.pushEnabled !== undefined && {
        push_enabled: input.pushEnabled,
      }),
      ...(input.bookingReminders !== undefined && {
        booking_reminders: input.bookingReminders,
      }),
      ...(input.medicationReminders !== undefined && {
        medication_reminders: input.medicationReminders,
      }),
    })
    .select("push_enabled, booking_reminders, medication_reminders")
    .single();
  if (error) throw error;
  return apiSuccess(data, undefined, { requestId });
});
