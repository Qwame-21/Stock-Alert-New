import { getSupabaseAdmin } from "@/lib/db/supabase-admin";
import { HttpError } from "@/lib/http/errors";
import type { CreateOrderInput, SupplierInput } from "./order-schema";

async function requireMembership(actorId: string, pharmacyId: string) {
  const { data } = await getSupabaseAdmin().from("pharmacy_staff").select("pharmacy_id")
    .eq("profile_id", actorId).eq("pharmacy_id", pharmacyId).maybeSingle();
  if (!data) throw new HttpError(403, "FORBIDDEN", "Pharmacy membership is required.");
}
function fail(error: { message: string } | null) {
  if (error) throw new HttpError(502, "ORDER_OPERATION_FAILED", "The supplier order operation failed.");
}
export async function listSuppliers(actorId: string, pharmacyId: string) {
  await requireMembership(actorId, pharmacyId);
  const { data, error } = await getSupabaseAdmin().from("suppliers").select("*").eq("pharmacy_id", pharmacyId).eq("is_active", true).order("name");
  fail(error); return data ?? [];
}
export async function createSupplier(actorId: string, input: SupplierInput) {
  await requireMembership(actorId, input.pharmacyId);
  const { data, error } = await getSupabaseAdmin().from("suppliers").insert({
    pharmacy_id: input.pharmacyId, name: input.name, contact_person: input.contactPerson,
    phone: input.phone, email: input.email, address: input.address, payment_terms: input.paymentTerms,
    lead_time_days: input.leadTimeDays, notes: input.notes,
  }).select().single(); fail(error); return data;
}
export async function listOrders(actorId: string, pharmacyId: string, status?: string) {
  await requireMembership(actorId, pharmacyId);
  let query = getSupabaseAdmin().from("purchase_orders").select("*, suppliers(name), purchase_order_items(*), purchase_order_status_history(status,note,created_at)").eq("pharmacy_id", pharmacyId).order("created_at", { ascending: false });
  if (status) query = query.eq("status", status);
  const { data, error } = await query; fail(error); return data ?? [];
}
export async function createOrder(actorId: string, input: CreateOrderInput) {
  await requireMembership(actorId, input.pharmacyId);
  const admin = getSupabaseAdmin();
  const orderNumber = `PO-${Date.now().toString(36).toUpperCase()}`;
  const { data: order, error } = await admin.from("purchase_orders").insert({
    pharmacy_id: input.pharmacyId, supplier_id: input.supplierId, order_number: orderNumber,
    expected_delivery_date: input.expectedDeliveryDate, notes: input.notes, currency: input.currency, created_by: actorId,
  }).select().single(); fail(error);
  const { error: itemError } = await admin.from("purchase_order_items").insert(input.items.map(item => ({
    purchase_order_id: order.id, medicine_id: item.medicineId, medicine_name: item.medicineName,
    barcode: item.barcode, quantity_ordered: item.quantity, unit_cost: item.unitCost,
  }))); fail(itemError);
  await admin.from("purchase_order_status_history").insert({ purchase_order_id: order.id, status: "draft", actor_profile_id: actorId });
  return (await listOrders(actorId, input.pharmacyId)).find(item => item.id === order.id);
}
export async function updateOrderStatus(actorId: string, id: string, status: string, note?: string) {
  const admin = getSupabaseAdmin();
  const { data: order } = await admin.from("purchase_orders").select("pharmacy_id,status").eq("id", id).maybeSingle();
  if (!order) throw new HttpError(404, "ORDER_NOT_FOUND", "Purchase order not found.");
  await requireMembership(actorId, order.pharmacy_id);
  const allowed: Record<string,string[]> = { draft:["submitted","cancelled"], submitted:["confirmed","cancelled"], confirmed:["cancelled"] };
  if (!(allowed[order.status] ?? []).includes(status)) throw new HttpError(409,"INVALID_ORDER_TRANSITION","That order status change is not allowed.");
  const { data, error } = await admin.from("purchase_orders").update({ status }).eq("id",id).select().single(); fail(error);
  await admin.from("purchase_order_status_history").insert({ purchase_order_id:id,status,actor_profile_id:actorId,note });
  return data;
}
export async function receiveOrder(actorId: string, id: string, lines: unknown[]) {
  const { error } = await getSupabaseAdmin().rpc("receive_purchase_order", {
    actor_id: actorId, target_order_id: id, receipt_lines: lines,
  }); fail(error);
  const { data: order } = await getSupabaseAdmin().from("purchase_orders").select("pharmacy_id").eq("id",id).single();
  return (await listOrders(actorId, order!.pharmacy_id)).find(item => item.id === id);
}
