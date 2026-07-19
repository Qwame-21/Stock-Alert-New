import { NextResponse } from "next/server";

export const dynamic = "force-dynamic";

export async function GET(request: Request) {
  const incoming = new URL(request.url);
  const reference = incoming.searchParams.get("reference") ?? incoming.searchParams.get("trxref") ?? "";
  const appUrl = `stockalert://payments/complete?reference=${encodeURIComponent(reference)}`;
  const html = `<!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1"><meta http-equiv="refresh" content="0;url=${appUrl}"><title>Return to StockAlert</title></head><body style="font-family:system-ui;text-align:center;padding:48px 20px"><h1>Returning to StockAlert…</h1><p>Your payment is being verified securely.</p><p><a href="${appUrl}" style="display:inline-block;padding:14px 20px;background:#0F6E73;color:white;border-radius:10px;text-decoration:none">Open StockAlert</a></p></body></html>`;
  return new NextResponse(html, {
    status: 200,
    headers: { "content-type": "text/html; charset=utf-8", "cache-control": "no-store" },
  });
}
