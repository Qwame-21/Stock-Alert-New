import { z } from "zod";

import { withAuth } from "@/lib/auth/with-auth";
import { getBackendEnv } from "@/lib/config/env";
import { getSupabaseAdmin } from "@/lib/db/supabase-admin";
import { apiSuccess } from "@/lib/http/api-response";
import { HttpError } from "@/lib/http/errors";
import { readJsonBody } from "@/lib/http/json-body";

const schema = z.object({
  amountMinor: z.number().int().positive(),
  currency: z.string().length(3).default("GHS"),
}).strict();

export const POST = withAuth(async (request, { requestId, user }) => {
  const env = getBackendEnv();
  if (!env.PAYSTACK_SECRET_KEY) throw new HttpError(503, "PAYMENTS_NOT_CONFIGURED", "Paystack is not configured yet.");
  const input = schema.parse(await readJsonBody(request));
  const db = getSupabaseAdmin();
  const { data: profile } = await db.from("profiles").select("email, phone_number").eq("id", user.id).single();
  if (!profile?.email) throw new HttpError(400, "PAYMENT_EMAIL_REQUIRED", "Add an email address before paying.");
  const reference = `stockalert_${crypto.randomUUID().replaceAll("-", "")}`;
  const response = await fetch("https://api.paystack.co/transaction/initialize", {
    method: "POST",
    headers: { Authorization: `Bearer ${env.PAYSTACK_SECRET_KEY}`, "Content-Type": "application/json" },
    body: JSON.stringify({
      email: profile.email,
      amount: input.amountMinor,
      currency: input.currency.toUpperCase(),
      reference,
      callback_url: env.APP_PUBLIC_URL ? `${env.APP_PUBLIC_URL}/payments/complete` : undefined,
      metadata: { profileId: user.id, phoneNumber: profile.phone_number },
    }),
  });
  const payload = await response.json();
  if (!response.ok || !payload.status) throw new HttpError(502, "PAYSTACK_INITIALIZE_FAILED", payload.message ?? "Payment could not be started.");
  const { error } = await db.from("payment_transactions").insert({
    profile_id: user.id, reference, amount_minor: input.amountMinor,
    currency: input.currency.toUpperCase(), provider_payload: payload.data,
  });
  if (error) throw new HttpError(502, "PAYMENT_RECORD_FAILED", "Payment could not be recorded.");
  return apiSuccess({ reference, authorizationUrl: payload.data.authorization_url, accessCode: payload.data.access_code }, undefined, { requestId });
});
