import { z } from "zod";

import { getSupabaseAdmin } from "@/lib/db/supabase-admin";
import { HttpError } from "@/lib/http/errors";
import { logger } from "@/lib/observability/logger";
import type {
  CancelBookingInput,
  CreateBookingInput,
  UpdateBookingInput,
} from "@/modules/bookings/booking-schema";

const bookingRecordSchema = z.object({
  id: z.uuid(),
  patient_profile_id: z.uuid(),
  provider_profile_id: z.uuid().nullable(),
  pharmacy_id: z.uuid().nullable(),
  provider_name: z.string(),
  specialty: z.string().nullable(),
  scheduled_at: z.string(),
  duration_minutes: z.number().int(),
  status: z.enum([
    "pending",
    "confirmed",
    "completed",
    "cancelled",
    "no_show",
  ]),
  video_link: z.string().nullable(),
  notes: z.string().nullable(),
  cancellation_reason: z.string().nullable(),
  requested_at: z.string(),
  reviewed_at: z.string().nullable(),
  responded_at: z.string().nullable(),
  responded_by: z.string().uuid().nullable(),
  decision_note: z.string().nullable(),
  version: z.coerce.number().int(),
});

function bookingFailure(error: { code?: string; message: string }): never {
  const message = error.message.toLowerCase();
  logger.error("booking_operation_error", {
    databaseCode: error.code,
    databaseMessage: error.message,
  });
  if (message.includes("patient account required")) {
    throw new HttpError(
      409,
      "PATIENT_PROFILE_REQUIRED",
      "Complete the patient profile before booking a consultation.",
    );
  }
  if (error.code === "42501") {
    throw new HttpError(
      403,
      "FORBIDDEN",
      "You do not have access to this appointment.",
    );
  }
  if (error.code === "P0002" || message.includes("not found")) {
    throw new HttpError(404, "BOOKING_NOT_FOUND", "Appointment not found.");
  }
  if (error.code === "40001" || message.includes("version conflict")) {
    throw new HttpError(
      409,
      "VERSION_CONFLICT",
      "The appointment changed on another device.",
    );
  }
  if (error.code === "23P01" || message.includes("time conflict")) {
    throw new HttpError(
      409,
      "BOOKING_CONFLICT",
      "The patient or provider is unavailable at that time.",
    );
  }
  if (message.includes("appointment must be in the future")) {
    throw new HttpError(
      400,
      "BOOKING_TIME_INVALID",
      "Choose an appointment time that is still in the future.",
    );
  }
  if (message.includes("invalid appointment duration")) {
    throw new HttpError(
      400,
      "BOOKING_DURATION_INVALID",
      "The appointment duration is invalid.",
    );
  }
  if (
    message.includes("status transition") ||
    message.includes("finalized appointment")
  ) {
    throw new HttpError(
      409,
      "INVALID_BOOKING_STATE",
      "The appointment cannot be changed from its current state.",
    );
  }

  throw new HttpError(
    502,
    "BOOKING_OPERATION_FAILED",
    "The appointment operation could not be completed.",
  );
}

async function pharmacyMemberships(actorId: string): Promise<string[]> {
  const { data, error } = await getSupabaseAdmin()
    .from("pharmacy_staff")
    .select("pharmacy_id")
    .eq("profile_id", actorId);

  if (error) {
    bookingFailure(error);
  }

  return (data ?? []).map((row) => z.uuid().parse(row.pharmacy_id));
}

export async function listBookings(
  actorId: string,
  input: {
    status?: string;
    upcoming: boolean;
    limit: number;
    offset: number;
  },
) {
  const pharmacyIds = await pharmacyMemberships(actorId);
  const participantFilter =
    pharmacyIds.length > 0
      ? `patient_profile_id.eq.${actorId},provider_profile_id.eq.${actorId},pharmacy_id.in.(${pharmacyIds.join(",")})`
      : `patient_profile_id.eq.${actorId},provider_profile_id.eq.${actorId}`;

  let query = getSupabaseAdmin()
    .from("appointments")
    .select(
      "id, patient_profile_id, provider_profile_id, pharmacy_id, provider_name, specialty, scheduled_at, duration_minutes, status, video_link, notes, cancellation_reason, requested_at, reviewed_at, responded_at, responded_by, decision_note, version",
      { count: "exact" },
    )
    .or(participantFilter)
    .is("deleted_at", null)
    .range(input.offset, input.offset + input.limit - 1)
    .order("scheduled_at", { ascending: input.upcoming });

  if (input.status) {
    query = query.eq("status", input.status);
  }
  if (input.upcoming) {
    query = query.gte("scheduled_at", new Date().toISOString());
  }

  const { data, error, count } = await query;
  if (error) {
    bookingFailure(error);
  }

  return {
    items: z.array(bookingRecordSchema).parse(data ?? []),
    total: count ?? 0,
  };
}

export async function getBooking(actorId: string, bookingId: string) {
  const { data, error } = await getSupabaseAdmin()
    .from("appointments")
    .select(
      "id, patient_profile_id, provider_profile_id, pharmacy_id, provider_name, specialty, scheduled_at, duration_minutes, status, video_link, notes, cancellation_reason, requested_at, reviewed_at, responded_at, responded_by, decision_note, version",
    )
    .eq("id", bookingId)
    .is("deleted_at", null)
    .maybeSingle();

  if (error) {
    bookingFailure(error);
  }
  if (!data) {
    throw new HttpError(404, "BOOKING_NOT_FOUND", "Appointment not found.");
  }

  const appointment = bookingRecordSchema.parse(data);
  if (
    appointment.patient_profile_id !== actorId &&
    appointment.provider_profile_id !== actorId
  ) {
    const memberships = await pharmacyMemberships(actorId);
    if (
      !appointment.pharmacy_id ||
      !memberships.includes(appointment.pharmacy_id)
    ) {
      throw new HttpError(
        403,
        "FORBIDDEN",
        "You do not have access to this appointment.",
      );
    }
  }

  return appointment;
}

export async function createBooking(
  actorId: string,
  input: CreateBookingInput,
) {
  const { data: provider, error: providerError } = await getSupabaseAdmin()
    .from("consultation_providers")
    .select(
      "profile_id,display_name,specialty,consultation_duration,verification_status,is_accepting_bookings",
    )
    .eq("profile_id", input.providerId)
    .maybeSingle();
  if (providerError || !provider) {
    throw new HttpError(
      404,
      "PROVIDER_NOT_FOUND",
      "The consultation provider was not found.",
    );
  }
  if (
    provider.verification_status !== "verified" ||
    !provider.is_accepting_bookings
  ) {
    throw new HttpError(
      409,
      "PROVIDER_UNAVAILABLE",
      "This provider is not accepting bookings.",
    );
  }
  const scheduled = new Date(input.scheduledAt);
  const weekday = scheduled.getDay() || 7;
  const time =
    scheduled.getHours().toString().padStart(2, "0") +
    ":" +
    scheduled.getMinutes().toString().padStart(2, "0");
  const { data: windows, error: availabilityError } = await getSupabaseAdmin()
    .from("provider_availability")
    .select("start_time,end_time")
    .eq("provider_profile_id", provider.profile_id)
    .eq("weekday", weekday)
    .eq("is_active", true);
  if (
    availabilityError ||
    !(windows ?? []).some(
      (window) =>
        time >= window.start_time.slice(0, 5) &&
        time < window.end_time.slice(0, 5),
    )
  ) {
    throw new HttpError(
      409,
      "PROVIDER_SLOT_UNAVAILABLE",
      "The selected time is outside this provider's published availability.",
    );
  }
  const { data, error } = await getSupabaseAdmin().rpc("create_appointment", {
    actor_id: actorId,
    mutation_id: input.mutationId,
    target_pharmacy_id: input.pharmacyId ?? null,
    provider_name: provider.display_name,
    provider_specialty: provider.specialty,
    appointment_time: input.scheduledAt,
    appointment_duration: provider.consultation_duration,
    appointment_notes: input.notes,
  });

  if (error) {
    bookingFailure(error);
  }

  const appointment = bookingRecordSchema.parse(data);
  await getSupabaseAdmin()
    .from("appointments")
    .update({ provider_profile_id: provider.profile_id })
    .eq("id", appointment.id);
  return appointment;
}

export async function updateBooking(
  actorId: string,
  bookingId: string,
  input: UpdateBookingInput,
) {
  const current = await getBooking(actorId, bookingId);
  const isProvider = current.provider_profile_id === actorId;

  if (isProvider) {
    if (!input.status || !["confirmed", "cancelled", "completed", "no_show"].includes(input.status)) {
      throw new HttpError(403, "FORBIDDEN", "Providers may only respond to or complete appointment requests.");
    }
    const allowed: Record<string, string[]> = {
      pending: ["confirmed", "cancelled"],
      confirmed: ["completed", "cancelled", "no_show"],
    };
    if (!(allowed[current.status] ?? []).includes(input.status)) {
      throw new HttpError(409, "INVALID_BOOKING_STATE", "That appointment decision is not available.");
    }
    const { data, error } = await getSupabaseAdmin()
      .from("appointments")
      .update({
        status: input.status,
        video_link: input.videoLink,
        decision_note: input.decisionNote,
        responded_by: actorId,
      })
      .eq("id", bookingId)
      .eq("version", input.expectedVersion)
      .select("id, patient_profile_id, provider_profile_id, pharmacy_id, provider_name, specialty, scheduled_at, duration_minutes, status, video_link, notes, cancellation_reason, requested_at, reviewed_at, responded_at, responded_by, decision_note, version")
      .maybeSingle();
    if (error) bookingFailure(error);
    if (!data) throw new HttpError(409, "VERSION_CONFLICT", "The appointment changed on another device.");
    return bookingRecordSchema.parse(data);
  }

  const { data, error } = await getSupabaseAdmin().rpc("update_appointment", {
    actor_id: actorId,
    appointment_id: bookingId,
    mutation_id: input.mutationId,
    expected_version: input.expectedVersion,
    patch_data: {
      scheduled_at: input.scheduledAt,
      duration_minutes: input.durationMinutes,
      notes: input.notes,
      video_link: input.videoLink,
      status: input.status,
    },
  });

  if (error) {
    bookingFailure(error);
  }

  return bookingRecordSchema.parse(data);
}

export async function cancelBooking(
  actorId: string,
  bookingId: string,
  input: CancelBookingInput,
) {
  const { data, error } = await getSupabaseAdmin().rpc("cancel_appointment", {
    actor_id: actorId,
    appointment_id: bookingId,
    mutation_id: input.mutationId,
    cancellation_text: input.reason,
    expected_version: input.expectedVersion,
  });

  if (error) {
    bookingFailure(error);
  }

  return bookingRecordSchema.parse(data);
}
