import { randomUUID } from "node:crypto";
import process from "node:process";

import { createClient } from "@supabase/supabase-js";

const url = process.env.SUPABASE_URL;
const publishableKey = process.env.SUPABASE_PUBLISHABLE_KEY;
const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
const apiBaseUrl = (process.env.APP_PUBLIC_URL ?? "http://127.0.0.1:3100").replace(/\/$/, "");
if (!url || !publishableKey || !serviceKey) throw new Error("Supabase client configuration is missing.");
if (process.env.TESTING_MODE !== "true") throw new Error("Demo verification requires TESTING_MODE=true.");

const email = "demo.patient@stockalert.test";
const password = "StockAlertDemo!2026";
const auth = createClient(url, publishableKey, { auth: { persistSession: false } });
const admin = createClient(url, serviceKey, { auth: { persistSession: false } });
const { data: session, error: authError } = await auth.auth.signInWithPassword({ email, password });
if (authError || !session.session) throw new Error(`Patient sign-in failed: ${authError?.message}`);
const headers = { Authorization: `Bearer ${session.session.access_token}` };
const verificationNote = "Automated demo slot verification; removed immediately.";

async function cleanupVerificationBookings() {
  const { error } = await admin.from("appointments").delete().in("notes", [
    "Automated demo slot verification; cancelled immediately.",
    verificationNote,
  ]);
  if (error) throw new Error(`Booking verification cleanup failed: ${error.message}`);
}

await cleanupVerificationBookings();

async function api(path, options = {}) {
  const response = await fetch(`${apiBaseUrl}${path}`, { ...options, headers: { ...headers, ...options.headers } });
  const body = await response.json();
  if (!response.ok) throw new Error(`${path} returned ${response.status}: ${JSON.stringify(body)}`);
  return body.data;
}

const [identity, rewards, pharmacies, providers, bookings] = await Promise.all([
  api("/api/v1/identity/me"),
  api("/api/v1/rewards"),
  api("/api/v1/discovery/pharmacies?search=Paracetamol&limit=100"),
  api(`/api/v1/consultation-providers?date=${new Date(Date.now() + 86400000).toISOString().slice(0, 10)}`),
  api("/api/v1/bookings?upcoming=true"),
]);

const demoProvider = providers.find((provider) => provider.name === "Dr. Ama Mensah");
const errors = [];
if (identity.public_id !== "PAT-DEMO-ACCRA-001") errors.push("seeded identity card was not returned");
if (rewards.balance !== 225 || rewards.activity.length < 4) errors.push("reward balance/activity mismatch");
if (pharmacies.length < 3 || pharmacies.some((pharmacy) => !pharmacy.latitude || !pharmacy.longitude)) errors.push("discovery coordinates/results incomplete");
if (!demoProvider || demoProvider.slots.length === 0) errors.push("provider has no generated slots");
if (!bookings.some((booking) => booking.status === "confirmed")) errors.push("confirmed booking missing");
if (errors.length) throw new Error(errors.join("; "));

const createdBooking = await api("/api/v1/bookings", {
  method: "POST",
  headers: { "content-type": "application/json" },
  body: JSON.stringify({
    mutationId: randomUUID(),
    providerId: demoProvider.id,
    providerName: demoProvider.name,
    specialty: demoProvider.specialty,
    scheduledAt: demoProvider.slots[0],
    consultationMode: "video",
    clinicalReason: "Routine blood pressure review",
    patientCondition: "Hypertension, stable on medication",
    requestedSupport: "Review readings and current treatment",
    notes: verificationNote,
  }),
});
await cleanupVerificationBookings();

console.log(JSON.stringify({
  apiBaseUrl,
  identity: identity.public_id,
  rewardsBalance: rewards.balance,
  rewardActivity: rewards.activity.length,
  paracetamolPharmacies: pharmacies.map((pharmacy) => pharmacy.name),
  providerSlotsTomorrow: demoProvider.slots.length,
  confirmedBookings: bookings.filter((booking) => booking.status === "confirmed").length,
  liveBookingCheck: `created ${createdBooking.id} without conflict and removed`,
}, null, 2));
