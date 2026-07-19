import { createHash } from "node:crypto";
import { readFile } from "node:fs/promises";
import { resolve } from "node:path";
import process from "node:process";

import { createClient } from "@supabase/supabase-js";

const envName = process.env.DEMO_SEED_ENV;
const allowedEnvironments = new Set(["development", "staging"]);
if (!allowedEnvironments.has(envName)) {
  throw new Error(
    "Refusing to seed. Set DEMO_SEED_ENV=development or DEMO_SEED_ENV=staging.",
  );
}
if (process.env.TESTING_MODE !== "true") {
  throw new Error("Refusing to seed a project without TESTING_MODE=true.");
}

const url = process.env.SUPABASE_URL;
const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
if (!url || !serviceKey) throw new Error("Supabase admin configuration is missing.");
const hostname = new URL(url).hostname.toLowerCase();
if (/prod|production|live/.test(hostname)) {
  throw new Error(`Refusing to seed production-like host ${hostname}.`);
}

const db = createClient(url, serviceKey, {
  auth: { autoRefreshToken: false, persistSession: false },
});

const PASSWORD = "StockAlertDemo!2026";
const ACCOUNTS = {
  patient: { email: "demo.patient@stockalert.test", name: "Kwame Asante" },
  provider: { email: "demo.provider@stockalert.test", name: "Dr. Ama Mensah" },
  pharmacy: { email: "demo.pharmacy@stockalert.test", name: "Ridgeway Community Pharmacy" },
};

function stableUuid(value) {
  const hex = createHash("sha256").update(`stockalert-demo:${value}`).digest("hex");
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-4${hex.slice(13, 16)}-a${hex.slice(17, 20)}-${hex.slice(20, 32)}`;
}

function isoDate(offsetDays) {
  const date = new Date();
  date.setUTCDate(date.getUTCDate() + offsetDays);
  return date.toISOString().slice(0, 10);
}

function futureAt(offsetDays, hour, minute = 0) {
  const date = new Date();
  date.setDate(date.getDate() + offsetDays);
  date.setHours(hour, minute, 0, 0);
  return date.toISOString();
}

async function checked(label, promise) {
  const result = await promise;
  if (result.error) throw new Error(`${label}: ${result.error.message}`);
  return result.data;
}

async function authUser(email, name, role) {
  let page = 1;
  let existing;
  while (!existing) {
    const data = await checked(
      `list auth users for ${email}`,
      db.auth.admin.listUsers({ page, perPage: 1000 }),
    );
    existing = data.users.find((user) => user.email?.toLowerCase() === email);
    if (existing || data.users.length < 1000) break;
    page += 1;
  }
  if (existing) {
    const data = await checked(
      `update auth user ${email}`,
      db.auth.admin.updateUserById(existing.id, {
        password: PASSWORD,
        email_confirm: true,
        user_metadata: { full_name: name, role, demo_seed: true },
      }),
    );
    return data.user;
  }
  const data = await checked(
    `create auth user ${email}`,
    db.auth.admin.createUser({
      email,
      password: PASSWORD,
      email_confirm: true,
      user_metadata: { full_name: name, role, demo_seed: true },
    }),
  );
  return data.user;
}

const pharmacies = [
  ["Ridgeway Community Pharmacy", "6 Independence Avenue, Ridge, Accra", 5.5608, -0.1937, "PH-GPC-ACC-21001"],
  ["Osu Oxford Street Pharmacy", "Oxford Street, Osu, Accra", 5.5562, -0.1821, "PH-GPC-ACC-21002"],
  ["Airport Hills Pharmacy", "Marina Mall Road, Airport City, Accra", 5.6054, -0.1775, "PH-GPC-ACC-21003"],
  ["East Legon HealthPlus", "Lagos Avenue, East Legon, Accra", 5.6408, -0.1531, "PH-GPC-ACC-21004"],
  ["Cantonments Care Pharmacy", "Fourth Circular Road, Cantonments, Accra", 5.5786, -0.1729, "PH-GPC-ACC-21005"],
  ["Kaneshie Market Pharmacy", "Market Complex Road, Kaneshie, Accra", 5.5662, -0.2268, "PH-GPC-ACC-21006"],
  ["Labone Family Pharmacy", "Labone Crescent, Labone, Accra", 5.5657, -0.1647, "PH-GPC-ACC-21007"],
  ["MediCare Plus Pharmacy", "Patrice Lumumba Road, Airport Residential Area, Accra", 5.6007, -0.1868, "PH-GPC-ACC-21008"],
];

// canonical name, generic, brand, strength, form, barcode, manufacturer, Rx
const medicines = [
  ["Paracetamol 500 mg Tablets", "Paracetamol", "Panadol", "500 mg", "Tablet", "9501234500014", "GSK Consumer Healthcare", false],
  ["Amoxicillin 500 mg Capsules", "Amoxicillin", "Amoxil", "500 mg", "Capsule", "9501234500021", "GSK", true],
  ["Ibuprofen 400 mg Tablets", "Ibuprofen", "Brufen", "400 mg", "Tablet", "9501234500038", "Abbott", false],
  ["Metformin 500 mg Tablets", "Metformin hydrochloride", "Glucophage", "500 mg", "Tablet", "9501234500045", "Merck", true],
  ["Amlodipine 5 mg Tablets", "Amlodipine besylate", "Norvasc", "5 mg", "Tablet", "9501234500052", "Pfizer", true],
  ["Artemether/Lumefantrine 20/120 mg", "Artemether/Lumefantrine", "Coartem", "20/120 mg", "Tablet", "9501234500069", "Novartis", true],
  ["Omeprazole 20 mg Capsules", "Omeprazole", "Losec", "20 mg", "Capsule", "9501234500076", "AstraZeneca", false],
  ["Cetirizine 10 mg Tablets", "Cetirizine hydrochloride", "Zirtek", "10 mg", "Tablet", "9501234500083", "UCB Pharma", false],
  ["Azithromycin 500 mg Tablets", "Azithromycin", "Zithromax", "500 mg", "Tablet", "9501234500090", "Pfizer", true],
  ["Ciprofloxacin 500 mg Tablets", "Ciprofloxacin", "Cipro", "500 mg", "Tablet", "9501234500106", "Bayer", true],
  ["Losartan 50 mg Tablets", "Losartan potassium", "Cozaar", "50 mg", "Tablet", "9501234500113", "Organon", true],
  ["Lisinopril 10 mg Tablets", "Lisinopril", "Zestril", "10 mg", "Tablet", "9501234500120", "AstraZeneca", true],
  ["Atorvastatin 20 mg Tablets", "Atorvastatin calcium", "Lipitor", "20 mg", "Tablet", "9501234500137", "Pfizer", true],
  ["Salbutamol 100 mcg Inhaler", "Salbutamol", "Ventolin", "100 mcg/dose", "Inhaler", "9501234500144", "GSK", true],
  ["Diclofenac 50 mg Tablets", "Diclofenac sodium", "Voltaren", "50 mg", "Tablet", "9501234500151", "Novartis", true],
  ["ORS Sachets", "Oral rehydration salts", "Dioralyte", "20.5 g", "Powder for solution", "9501234500168", "Sanofi", false],
  ["Zinc Sulfate 20 mg Tablets", "Zinc sulfate", "Zincovit", "20 mg", "Dispersible tablet", "9501234500175", "Ernest Chemists", false],
  ["Vitamin C 1000 mg Tablets", "Ascorbic acid", "Redoxon", "1000 mg", "Effervescent tablet", "9501234500182", "Bayer", false],
  ["Folic Acid 5 mg Tablets", "Folic acid", "Folvite", "5 mg", "Tablet", "9501234500199", "Pfizer", false],
  ["Ferrous Sulfate 200 mg Tablets", "Ferrous sulfate", "Ferrograd", "200 mg", "Tablet", "9501234500205", "Abbott", false],
  ["Hydrochlorothiazide 25 mg Tablets", "Hydrochlorothiazide", "Esidrex", "25 mg", "Tablet", "9501234500212", "Novartis", true],
  ["Gliclazide MR 30 mg Tablets", "Gliclazide", "Diamicron MR", "30 mg", "Modified-release tablet", "9501234500229", "Servier", true],
  ["Insulin Human 30/70", "Biphasic human insulin", "Mixtard 30", "100 IU/mL", "Injection", "9501234500236", "Novo Nordisk", true],
  ["Clotrimazole 1% Cream", "Clotrimazole", "Canesten", "1% w/w", "Cream", "9501234500243", "Bayer", false],
  ["Metronidazole 400 mg Tablets", "Metronidazole", "Flagyl", "400 mg", "Tablet", "9501234500250", "Sanofi", true],
  ["Co-trimoxazole 960 mg Tablets", "Sulfamethoxazole/Trimethoprim", "Septrin", "800/160 mg", "Tablet", "9501234500267", "Aspen", true],
  ["Doxycycline 100 mg Capsules", "Doxycycline hyclate", "Vibramycin", "100 mg", "Capsule", "9501234500274", "Pfizer", true],
  ["Fluconazole 150 mg Capsules", "Fluconazole", "Diflucan", "150 mg", "Capsule", "9501234500281", "Pfizer", true],
  ["Prednisolone 5 mg Tablets", "Prednisolone", "Deltacortril", "5 mg", "Tablet", "9501234500298", "Pfizer", true],
  ["Aspirin 75 mg Tablets", "Acetylsalicylic acid", "Cardiprin", "75 mg", "Tablet", "9501234500304", "Reckitt", true],
  ["Chlorpheniramine 4 mg Tablets", "Chlorpheniramine maleate", "Piriton", "4 mg", "Tablet", "9501234500311", "GSK", false],
  ["Cough Syrup Honey & Lemon", "Guaifenesin", "Benylin", "100 mg/5 mL", "Oral liquid", "9501234500328", "Kenvue", false],
  ["Mupirocin 2% Ointment", "Mupirocin", "Bactroban", "2% w/w", "Ointment", "9501234500335", "GSK", true],
  ["Loperamide 2 mg Capsules", "Loperamide hydrochloride", "Imodium", "2 mg", "Capsule", "9501234500342", "Kenvue", false],
  // Catalogued for the live receiving demo, deliberately omitted from inventory.
  ["Acetaminophen Paediatric Suspension", "Paracetamol", "Calpol", "120 mg/5 mL", "Oral suspension", "9501234500991", "Haleon", false],
];

async function main() {
  console.log(`Seeding ${envName} project ${hostname}...`);
  const patientUser = await authUser(ACCOUNTS.patient.email, ACCOUNTS.patient.name, "patient");
  const providerUser = await authUser(ACCOUNTS.provider.email, ACCOUNTS.provider.name, "provider");

  const ownerUsers = [];
  for (let index = 0; index < pharmacies.length; index += 1) {
    const email = index === 0 ? ACCOUNTS.pharmacy.email : `demo.pharmacy.${index + 1}@stockalert.test`;
    ownerUsers.push(await authUser(email, pharmacies[index][0], "pharmacy"));
  }

  await checked("upsert profiles", db.from("profiles").upsert([
    { id: patientUser.id, role: "patient", email: ACCOUNTS.patient.email, full_name: ACCOUNTS.patient.name, phone_number: "+233 24 555 0142", dob: "1990-04-12", gender: "Male", location: "Adabraka, Accra" },
    { id: providerUser.id, role: "provider", email: ACCOUNTS.provider.email, full_name: ACCOUNTS.provider.name, phone_number: "+233 24 555 0198", location: "Ridge, Accra" },
    ...ownerUsers.map((user, index) => ({ id: user.id, role: "pharmacy", email: index === 0 ? ACCOUNTS.pharmacy.email : `demo.pharmacy.${index + 1}@stockalert.test`, full_name: index === 0 ? "Nana Boateng, PharmD" : `Demo Pharmacist ${index + 1}`, phone_number: `+233 30 255 10${String(index).padStart(2, "0")}`, pharmacy_name: pharmacies[index][0], license_number: pharmacies[index][4], location: pharmacies[index][1] })),
  ], { onConflict: "id" }));

  await checked("upsert patient health profile", db.from("patients").upsert({
    profile_id: patientUser.id,
    blood_group: "O+",
    known_allergies: ["Penicillin"],
    chronic_conditions: ["Hypertension"],
    current_medication: "Amlodipine 5 mg once daily",
    emergency_contact_name: "Akosua Asante",
    emergency_contact_phone: "+233 20 555 0187",
    emergency_contact_email: "akosua.asante@stockalert.test",
  }, { onConflict: "profile_id" }));

  await checked("upsert identity card", db.from("patient_identity_cards").upsert({
    patient_profile_id: patientUser.id,
    public_id: "PAT-DEMO-ACCRA-001",
    qr_token: stableUuid("patient-identity-token"),
    sharing_enabled: true,
    share_full_name: true,
    share_date_of_birth: true,
    share_emergency_contact: true,
  }, { onConflict: "patient_profile_id" }));

  const rewardRows = [
    ["welcome", "Welcome to StockAlert", "Demo account activation bonus", 150, "promotion", "confirmed", -28],
    ["refill", "On-time prescription refill", "Amlodipine refill at Ridgeway Community Pharmacy", 75, "prescription_refill", "confirmed", -14],
    ["consult", "Completed consultation", "Reward for a completed video consultation", 100, "consultation", "confirmed", -7],
    ["return", "Safe medicine return", "Expired medicines returned for safe disposal", 40, "medicine_return", "pending", -2],
    ["redeem", "Reward voucher redeemed", "GHS 10 pharmacy discount", -100, "adjustment", "confirmed", -1],
  ].map(([key, title, description, points, type, status, days]) => ({
    id: stableUuid(`reward-${key}`), patient_profile_id: patientUser.id, title, description,
    points, status, source_type: type, source_reference: `demo-${key}`,
    occurred_at: futureAt(days, 10), confirmed_at: status === "confirmed" ? futureAt(days, 10) : null,
  }));
  await checked("upsert rewards", db.from("reward_transactions").upsert(rewardRows, { onConflict: "id" }));

  await checked("upsert provider", db.from("consultation_providers").upsert({
    profile_id: providerUser.id,
    display_name: ACCOUNTS.provider.name,
    specialty: "Family Medicine",
    professional_license: "MDC-GH-48217",
    registration_authority: "Medical and Dental Council, Ghana",
    years_experience: 12,
    bio: "Family physician with 12 years of experience in adult primary care, hypertension, diabetes management, and preventive health.",
    consultation_mode: "both",
    location: "Ridge Medical District, Accra",
    consultation_duration: 30,
    video_fee: 120,
    in_person_fee: 180,
    currency: "GHS",
    verification_status: "verified",
    is_accepting_bookings: true,
  }, { onConflict: "profile_id" }));
  await checked("clear demo provider availability", db.from("provider_availability").delete().eq("provider_profile_id", providerUser.id));
  await checked("publish provider availability", db.from("provider_availability").insert(
    Array.from({ length: 7 }, (_, index) => ({
      id: stableUuid(`availability-${index + 1}`), provider_profile_id: providerUser.id,
      weekday: index + 1, start_time: index < 5 ? "08:00" : "09:00", end_time: index < 5 ? "18:00" : "14:00", is_active: true,
    })),
  ));

  const portrait = await readFile(resolve(process.cwd(), "../assets/demo/dr-ama-mensah.png"));
  await checked("upload provider portrait", db.storage.from("avatars").upload(
    `${providerUser.id}/profile.png`, portrait, { upsert: true, contentType: "image/png" },
  ));

  const existingPharmacies = await checked(
    "load existing owner pharmacies",
    db.from("pharmacies").select("id,owner_profile_id").in("owner_profile_id", ownerUsers.map((user) => user.id)),
  );
  const existingPharmacyIds = new Map(existingPharmacies.map((row) => [row.owner_profile_id, row.id]));
  const pharmacyRows = pharmacies.map(([name, location, latitude, longitude, license], index) => ({
    id: existingPharmacyIds.get(ownerUsers[index].id) ?? stableUuid(`pharmacy-${index + 1}`), owner_profile_id: ownerUsers[index].id,
    name, license_number: license, registration_authority: "Pharmacy Council of Ghana",
    location, latitude, longitude, operating_hours: index < 5 ? "Mon–Sat 08:00–20:00; Sun 10:00–16:00" : "Mon–Sat 08:30–19:00",
    supplier_preference: "Licensed Ghanaian pharmaceutical wholesalers", verification_status: "verified", is_active: true,
  }));
  await checked("upsert pharmacies", db.from("pharmacies").upsert(pharmacyRows, { onConflict: "owner_profile_id" }));
  await checked("upsert pharmacy owners", db.from("pharmacy_staff").upsert(pharmacyRows.map((pharmacy, index) => ({
    pharmacy_id: pharmacy.id, profile_id: ownerUsers[index].id, staff_role: "owner",
  })), { onConflict: "pharmacy_id,profile_id" }));

  const medicineRows = medicines.map(([canonical_name, generic_name, brand_name, strength, dosage_form, barcode, manufacturer, requires_prescription], index) => ({
    id: stableUuid(`medicine-${index + 1}`), canonical_name, generic_name, brand_name, strength,
    dosage_form, barcode, manufacturer, requires_prescription,
  }));
  await checked("upsert medicines", db.from("medicines").upsert(medicineRows, { onConflict: "id" }));

  const inventoryRows = [];
  // Uneven distribution: core medicines in 4–7 locations; specialist items in 1–2.
  for (let medicineIndex = 0; medicineIndex < medicineRows.length - 1; medicineIndex += 1) {
    const locations = medicineIndex < 5 ? 4 + (medicineIndex % 4) : medicineIndex < 16 ? 2 + (medicineIndex % 3) : 1 + (medicineIndex % 2);
    for (let pharmacyIndex = 0; pharmacyIndex < locations; pharmacyIndex += 1) {
      const shifted = (pharmacyIndex + medicineIndex) % pharmacyRows.length;
      let expiryOffset = 270 + ((medicineIndex * 19 + pharmacyIndex * 11) % 360);
      let quantity = 18 + ((medicineIndex * 13 + pharmacyIndex * 17) % 115);
      if (medicineIndex === 0 && pharmacyIndex === 0) expiryOffset = -18; // urgent expired alert
      if (medicineIndex === 2 && pharmacyIndex === 0) expiryOffset = -4;
      if (medicineIndex === 3 && pharmacyIndex === 0) expiryOffset = 32;
      if (medicineIndex === 4 && pharmacyIndex === 0) expiryOffset = 74;
      if (shifted === 0 && medicineIndex === 2) expiryOffset = 45;
      if (shifted === 0 && medicineIndex === 4) expiryOffset = 74;
      if (medicineIndex === 8 && pharmacyIndex === 0) quantity = 0;
      if (medicineIndex === 10 && pharmacyIndex === 0) quantity = 4;
      inventoryRows.push({
        id: stableUuid(`inventory-${medicineIndex + 1}-${shifted + 1}`),
        pharmacy_id: pharmacyRows[shifted].id, medicine_id: medicineRows[medicineIndex].id,
        batch_number: `GH${String(medicineIndex + 1).padStart(3, "0")}-${String(shifted + 1).padStart(2, "0")}-26`,
        quantity, reorder_level: 10 + ((medicineIndex + shifted) % 8), expiry_date: isoDate(expiryOffset),
        unit_price: (2.5 + medicineIndex * 1.35 + shifted * 0.4).toFixed(2), currency: "GHS", deleted_at: null,
      });
    }
  }
  await checked("upsert inventory batches", db.from("inventory_items").upsert(inventoryRows, { onConflict: "id" }));

  const demoPharmacyId = pharmacyRows[0].id;
  const supplierId = stableUuid("supplier-acme");
  await checked("upsert supplier", db.from("suppliers").upsert({
    id: supplierId, pharmacy_id: demoPharmacyId, name: "Gokals-Laborex Ghana Ltd",
    contact_person: "Esi Nyarko", phone: "+233 30 222 1492", email: "orders.demo@gokals-laborex.test",
    address: "North Industrial Area, Accra", payment_terms: "30 days net", lead_time_days: 2,
    notes: "Licensed wholesale demo supplier; morning deliveries.", is_active: true,
  }, { onConflict: "id" }));
  const orderId = stableUuid("purchase-order-draft");
  await checked("upsert purchase order", db.from("purchase_orders").upsert({
    id: orderId, pharmacy_id: demoPharmacyId, supplier_id: supplierId, order_number: "PO-DEMO-2026-001",
    status: "draft", expected_delivery_date: isoDate(3), notes: "Routine replenishment for fast-moving medicines.",
    currency: "GHS", created_by: ownerUsers[0].id,
  }, { onConflict: "id" }));
  await checked("upsert purchase order lines", db.from("purchase_order_items").upsert([
    { id: stableUuid("po-line-1"), purchase_order_id: orderId, medicine_id: medicineRows[0].id, medicine_name: medicines[0][0], barcode: medicines[0][5], quantity_ordered: 120, quantity_received: 0, unit_cost: 1.85 },
    { id: stableUuid("po-line-2"), purchase_order_id: orderId, medicine_id: medicineRows[3].id, medicine_name: medicines[3][0], barcode: medicines[3][5], quantity_ordered: 60, quantity_received: 0, unit_cost: 4.9 },
  ], { onConflict: "id" }));

  const bookingId = stableUuid("confirmed-booking");
  await checked("upsert existing confirmed booking", db.from("appointments").upsert({
    id: bookingId, patient_profile_id: patientUser.id, provider_profile_id: providerUser.id,
    provider_name: ACCOUNTS.provider.name, specialty: "Family Medicine", scheduled_at: futureAt(2, 16, 30),
    duration_minutes: 30, status: "confirmed", video_link: "https://meet.jit.si/stockalert-demo-followup",
    consultation_mode: "video", clinical_reason: "Blood pressure follow-up",
    patient_condition: "Hypertension controlled with amlodipine",
    requested_support: "Medication review and interpretation of home readings",
    consultation_fee: 120, deposit_amount: 60, payment_status: "paid",
    notes: "Blood pressure follow-up and medication review", reviewed_at: new Date().toISOString(),
    responded_at: new Date().toISOString(), responded_by: providerUser.id, decision_note: "Confirmed for demo continuity.",
    deleted_at: null,
  }, { onConflict: "id" }));

  await checked("upsert notification preferences", db.from("notification_preferences").upsert([
    { profile_id: patientUser.id, booking_reminders: true, medication_reminders: true, low_stock_alerts: true, expiry_alerts: true, push_enabled: true, email_enabled: true },
    { profile_id: ownerUsers[0].id, booking_reminders: true, medication_reminders: true, low_stock_alerts: true, expiry_alerts: true, push_enabled: true, email_enabled: true },
  ], { onConflict: "profile_id" }));

  console.log(JSON.stringify({
    environment: envName,
    project: hostname,
    accounts: { patient: ACCOUNTS.patient.email, provider: ACCOUNTS.provider.email, pharmacy: ACCOUNTS.pharmacy.email },
    sharedPassword: PASSWORD,
    demoPharmacyId,
    searchMedicines: ["Paracetamol", "Amoxicillin", "Ibuprofen", "Metformin", "Amlodipine"],
    receivingDemo: {
      barcode: medicines.at(-1)[5], name: medicines.at(-1)[0], genericName: medicines.at(-1)[1],
      brandName: medicines.at(-1)[2], strength: medicines.at(-1)[3], dosageForm: medicines.at(-1)[4],
      manufacturer: medicines.at(-1)[6], batchNumber: "CAL-DEMO-0726", expiryDate: isoDate(540), quantity: 48,
      reorderLevel: 12, unitCostGhs: "18.50",
    },
    totals: { pharmacies: pharmacyRows.length, medicines: medicineRows.length, inventoryBatches: inventoryRows.length },
  }, null, 2));
}

await main();
