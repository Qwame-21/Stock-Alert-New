import { getSupabaseAdmin } from "@/lib/db/supabase-admin";
import { HttpError } from "@/lib/http/errors";

function timeOnDate(date: string, time: string) {
  return new Date(`${date}T${time}:00`);
}

export async function listProviders(date: string, specialty?: string) {
  let query = getSupabaseAdmin()
    .from("consultation_providers")
    .select("profile_id, display_name, specialty, years_experience, bio, consultation_mode, location, consultation_duration, verification_status, provider_availability(weekday,start_time,end_time,is_active)")
    .eq("verification_status", "verified")
    .eq("is_accepting_bookings", true)
    .order("display_name");
  if (specialty) query = query.ilike("specialty", `%${specialty}%`);
  const { data, error } = await query;
  if (error) throw new HttpError(502, "PROVIDERS_UNAVAILABLE", "Consultation providers could not be loaded.");

  const day = new Date(`${date}T12:00:00`).getDay() || 7;
  const providerIds = (data ?? []).map((provider) => provider.profile_id);
  const start = new Date(`${date}T00:00:00`).toISOString();
  const end = new Date(`${date}T23:59:59`).toISOString();
  const { data: bookings, error: bookingError } = providerIds.length
    ? await getSupabaseAdmin()
        .from("appointments")
        .select("provider_profile_id,scheduled_at,duration_minutes")
        .in("provider_profile_id", providerIds)
        .in("status", ["pending", "confirmed"])
        .gte("scheduled_at", start)
        .lte("scheduled_at", end)
        .is("deleted_at", null)
    : { data: [], error: null };
  if (bookingError) throw new HttpError(502, "PROVIDERS_UNAVAILABLE", "Provider schedules could not be loaded.");

  return (data ?? []).map((provider) => {
    const duration = provider.consultation_duration;
    const slots: string[] = [];
    const windows = (provider.provider_availability ?? []).filter(
      (item) => item.is_active && item.weekday === day,
    );
    for (const window of windows) {
      let cursor = timeOnDate(date, window.start_time.slice(0, 5));
      const finish = timeOnDate(date, window.end_time.slice(0, 5));
      while (cursor.getTime() + duration * 60000 <= finish.getTime()) {
        const slotEnd = new Date(cursor.getTime() + duration * 60000);
        const conflict = (bookings ?? []).some((booking) => {
          if (booking.provider_profile_id !== provider.profile_id) return false;
          const bookedStart = new Date(booking.scheduled_at);
          const bookedEnd = new Date(bookedStart.getTime() + booking.duration_minutes * 60000);
          return bookedStart < slotEnd && bookedEnd > cursor;
        });
        if (!conflict && cursor > new Date()) slots.push(cursor.toISOString());
        cursor = slotEnd;
      }
    }
    return {
      id: provider.profile_id,
      name: provider.display_name,
      specialty: provider.specialty,
      yearsExperience: provider.years_experience,
      bio: provider.bio,
      consultationMode: provider.consultation_mode,
      location: provider.location,
      durationMinutes: duration,
      slots,
    };
  });
}

export async function getProviderAccount(userId: string) {
  const { data, error } = await getSupabaseAdmin()
    .from("consultation_providers")
    .select("profile_id,display_name,specialty,professional_license,registration_authority,years_experience,bio,consultation_mode,location,consultation_duration,verification_status,is_accepting_bookings,provider_availability(id,weekday,start_time,end_time,is_active)")
    .eq("profile_id", userId)
    .maybeSingle();
  if (error) throw new HttpError(502, "PROVIDER_PROFILE_UNAVAILABLE", "Provider profile could not be loaded.");
  if (!data) throw new HttpError(404, "PROVIDER_PROFILE_NOT_FOUND", "Consultation provider profile was not found.");
  return data;
}

export async function updateAvailability(
  userId: string,
  input: {
    isAcceptingBookings: boolean;
    consultationDuration: number;
    availability: Array<{ weekday: number; startTime: string; endTime: string }>;
  },
) {
  const admin = getSupabaseAdmin();
  const { error: profileError } = await admin
    .from("consultation_providers")
    .update({
      is_accepting_bookings: input.isAcceptingBookings,
      consultation_duration: input.consultationDuration,
    })
    .eq("profile_id", userId);
  if (profileError) throw new HttpError(502, "AVAILABILITY_UPDATE_FAILED", "Provider settings could not be saved.");
  const { error: deleteError } = await admin
    .from("provider_availability")
    .delete()
    .eq("provider_profile_id", userId);
  if (deleteError) throw new HttpError(502, "AVAILABILITY_UPDATE_FAILED", "Existing availability could not be replaced.");
  if (input.availability.length) {
    const { error } = await admin.from("provider_availability").insert(
      input.availability.map((item) => ({
        provider_profile_id: userId,
        weekday: item.weekday,
        start_time: item.startTime,
        end_time: item.endTime,
      })),
    );
    if (error) throw new HttpError(502, "AVAILABILITY_UPDATE_FAILED", "Availability could not be saved.");
  }
  return getProviderAccount(userId);
}
