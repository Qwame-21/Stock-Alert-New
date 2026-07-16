import { getSupabaseAdmin } from "@/lib/db/supabase-admin";
import { HttpError } from "@/lib/http/errors";

export async function listNotifications(userId: string) {
  const { data: preferences, error: preferenceError } = await getSupabaseAdmin()
    .from("notification_preferences")
    .select("booking_reminders, medication_reminders, push_enabled, email_enabled")
    .eq("profile_id", userId)
    .maybeSingle();

  if (preferenceError) {
    throw new HttpError(
      502,
      "NOTIFICATIONS_UNAVAILABLE",
      "Notification preferences could not be loaded.",
    );
  }

  const notifications: Array<Record<string, unknown>> = [];
  if (preferences?.booking_reminders !== false) {
    const { data: appointments, error } = await getSupabaseAdmin()
      .from("appointments")
      .select("id, provider_name, specialty, scheduled_at, status, notes")
      .eq("patient_profile_id", userId)
      .in("status", ["pending", "confirmed"])
      .gte("scheduled_at", new Date().toISOString())
      .is("deleted_at", null)
      .order("scheduled_at", { ascending: true })
      .limit(20);

    if (error) {
      throw new HttpError(
        502,
        "NOTIFICATIONS_UNAVAILABLE",
        "Appointment reminders could not be loaded.",
      );
    }

    for (const appointment of appointments ?? []) {
      notifications.push({
        id: `appointment:${appointment.id}`,
        type: "Appointments",
        title:
          appointment.status === "confirmed"
            ? "Consultation confirmed"
            : "Consultation awaiting confirmation",
        description: `${appointment.provider_name}${appointment.specialty ? ` · ${appointment.specialty}` : ""}`,
        scheduledAt: appointment.scheduled_at,
        createdAt: appointment.scheduled_at,
        actionPath: "/patient/bookings",
      });
    }
  }

  return {
    notifications,
    preferences: preferences ?? {
      booking_reminders: true,
      medication_reminders: true,
      push_enabled: true,
      email_enabled: true,
    },
  };
}
