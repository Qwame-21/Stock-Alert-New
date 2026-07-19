import { createHmac, timingSafeEqual } from "node:crypto";

import { getBackendEnv } from "@/lib/config/env";
import { getSupabaseAdmin } from "@/lib/db/supabase-admin";
import { apiSuccess } from "@/lib/http/api-response";

export const dynamic = "force-dynamic";

export async function POST(request: Request) {
  console.info(JSON.stringify({ event: "paystack.webhook.received" }));
  const secret = getBackendEnv().PAYSTACK_SECRET_KEY;
  if (!secret) return new Response("Payments not configured", { status: 503 });
  const raw = await request.text();
  const received = request.headers.get("x-paystack-signature") ?? "";
  const expected = createHmac("sha512", secret).update(raw).digest("hex");
  const valid = received.length === expected.length &&
    timingSafeEqual(Buffer.from(received), Buffer.from(expected));
  if (!valid) {
    console.warn(JSON.stringify({ event: "paystack.webhook.signature_invalid" }));
    return new Response("Invalid signature", { status: 401 });
  }
  console.info(JSON.stringify({ event: "paystack.webhook.signature_valid" }));
  const event = JSON.parse(raw) as { event?: string; data?: { reference?: string; status?: string } };
  const reference = event.data?.reference;
  if (reference && event.event === "charge.success") {
    const { error } = await getSupabaseAdmin().from("payment_transactions").update({
      status: "success", provider_payload: event.data, updated_at: new Date().toISOString(),
    }).eq("reference", reference);
    console.info(JSON.stringify({
      event: error ? "paystack.webhook.database_failed" : "paystack.webhook.database_updated",
      reference,
      status: error ? "failed" : "success",
    }));
  }
  return apiSuccess({ received: true });
}
