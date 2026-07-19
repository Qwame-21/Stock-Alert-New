begin;

create or replace function public.prepare_account_deletion(target_profile_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  -- Receipts and movement history use restrictive foreign keys so they must be
  -- removed before an owned pharmacy and its inventory can be deleted.
  delete from public.purchase_order_receipts receipt
  using public.purchase_orders purchase_order
  where receipt.purchase_order_id = purchase_order.id
    and purchase_order.pharmacy_id in (
      select pharmacy.id
      from public.pharmacies pharmacy
      where pharmacy.owner_profile_id = target_profile_id
    );

  delete from public.inventory_movements movement
  where movement.pharmacy_id in (
    select pharmacy.id
    from public.pharmacies pharmacy
    where pharmacy.owner_profile_id = target_profile_id
  );

  delete from public.pharmacies pharmacy
  where pharmacy.owner_profile_id = target_profile_id;

  -- Patient appointments and payment records also deliberately restrict
  -- profile deletion. They contain personal account data and are removed when
  -- the user requests permanent account deletion.
  delete from public.appointments appointment
  where appointment.patient_profile_id = target_profile_id;

  delete from public.payment_transactions payment
  where payment.profile_id = target_profile_id;
end;
$$;

revoke all on function public.prepare_account_deletion(uuid) from public;
revoke all on function public.prepare_account_deletion(uuid) from anon;
revoke all on function public.prepare_account_deletion(uuid) from authenticated;
grant execute on function public.prepare_account_deletion(uuid) to service_role;

commit;
