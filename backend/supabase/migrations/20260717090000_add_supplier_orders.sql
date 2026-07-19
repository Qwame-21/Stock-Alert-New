begin;

create table if not exists public.suppliers (
  id uuid primary key default gen_random_uuid(),
  pharmacy_id uuid not null references public.pharmacies(id) on delete cascade,
  name text not null,
  contact_person text,
  phone text,
  email text,
  address text,
  payment_terms text,
  lead_time_days integer not null default 0 check (lead_time_days >= 0),
  notes text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  version bigint not null default 1,
  unique (pharmacy_id, name)
);

create table if not exists public.purchase_orders (
  id uuid primary key default gen_random_uuid(),
  pharmacy_id uuid not null references public.pharmacies(id) on delete cascade,
  supplier_id uuid not null references public.suppliers(id) on delete restrict,
  order_number text not null,
  status text not null default 'draft' check (status in
    ('draft', 'submitted', 'confirmed', 'partially_received', 'received', 'cancelled')),
  expected_delivery_date date,
  notes text,
  currency char(3) not null default 'GHS',
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  version bigint not null default 1,
  unique (pharmacy_id, order_number)
);

create table if not exists public.purchase_order_items (
  id uuid primary key default gen_random_uuid(),
  purchase_order_id uuid not null references public.purchase_orders(id) on delete cascade,
  medicine_id uuid references public.medicines(id) on delete restrict,
  medicine_name text not null,
  barcode text,
  quantity_ordered integer not null check (quantity_ordered > 0),
  quantity_received integer not null default 0 check (quantity_received >= 0),
  unit_cost numeric(12,2) check (unit_cost is null or unit_cost >= 0),
  created_at timestamptz not null default now(),
  check (quantity_received <= quantity_ordered)
);

create table if not exists public.purchase_order_receipts (
  id uuid primary key default gen_random_uuid(),
  purchase_order_id uuid not null references public.purchase_orders(id) on delete restrict,
  purchase_order_item_id uuid not null references public.purchase_order_items(id) on delete restrict,
  inventory_item_id uuid not null references public.inventory_items(id) on delete restrict,
  quantity_received integer not null check (quantity_received > 0),
  batch_number text not null,
  expiry_date date,
  received_by uuid references public.profiles(id) on delete set null,
  received_at timestamptz not null default now(),
  mutation_id uuid not null unique
);

create table if not exists public.purchase_order_status_history (
  id bigint generated always as identity primary key,
  purchase_order_id uuid not null references public.purchase_orders(id) on delete cascade,
  status text not null,
  actor_profile_id uuid references public.profiles(id) on delete set null,
  note text,
  created_at timestamptz not null default now()
);

create index if not exists suppliers_pharmacy_idx on public.suppliers(pharmacy_id, is_active);
create index if not exists purchase_orders_pharmacy_idx on public.purchase_orders(pharmacy_id, created_at desc);
create index if not exists purchase_order_items_order_idx on public.purchase_order_items(purchase_order_id);

drop trigger if exists suppliers_set_updated_at on public.suppliers;
create trigger suppliers_set_updated_at before update on public.suppliers
for each row execute function public.set_updated_at_and_version();
drop trigger if exists purchase_orders_set_updated_at on public.purchase_orders;
create trigger purchase_orders_set_updated_at before update on public.purchase_orders
for each row execute function public.set_updated_at_and_version();

alter table public.suppliers enable row level security;
alter table public.purchase_orders enable row level security;
alter table public.purchase_order_items enable row level security;
alter table public.purchase_order_receipts enable row level security;
alter table public.purchase_order_status_history enable row level security;

create policy suppliers_member_all on public.suppliers for all to authenticated
using (public.is_pharmacy_member(pharmacy_id)) with check (public.is_pharmacy_member(pharmacy_id));
create policy purchase_orders_member_all on public.purchase_orders for all to authenticated
using (public.is_pharmacy_member(pharmacy_id)) with check (public.is_pharmacy_member(pharmacy_id));
create policy purchase_order_items_member_all on public.purchase_order_items for all to authenticated
using (exists (select 1 from public.purchase_orders po where po.id = purchase_order_id and public.is_pharmacy_member(po.pharmacy_id)))
with check (exists (select 1 from public.purchase_orders po where po.id = purchase_order_id and public.is_pharmacy_member(po.pharmacy_id)));
create policy purchase_order_receipts_member_read on public.purchase_order_receipts for select to authenticated
using (exists (select 1 from public.purchase_orders po where po.id = purchase_order_id and public.is_pharmacy_member(po.pharmacy_id)));
create policy purchase_order_history_member_read on public.purchase_order_status_history for select to authenticated
using (exists (select 1 from public.purchase_orders po where po.id = purchase_order_id and public.is_pharmacy_member(po.pharmacy_id)));

create or replace function public.receive_purchase_order(actor_id uuid, target_order_id uuid, receipt_lines jsonb)
returns uuid language plpgsql security definer set search_path = '' as $$
declare
  order_record public.purchase_orders;
  line jsonb;
  order_item public.purchase_order_items;
  medicine_record_id uuid;
  inventory_record public.inventory_items;
  receive_quantity integer;
  receive_mutation uuid;
  final_status text;
begin
  select * into order_record from public.purchase_orders where id = target_order_id for update;
  if order_record.id is null then raise exception 'Order not found'; end if;
  if not exists (select 1 from public.pharmacy_staff where pharmacy_id=order_record.pharmacy_id and profile_id=actor_id)
    then raise exception using errcode='42501', message='Not a pharmacy member'; end if;
  if order_record.status not in ('submitted','confirmed','partially_received') then raise exception 'Order cannot be received'; end if;
  for line in select * from jsonb_array_elements(receipt_lines) loop
    select * into order_item from public.purchase_order_items where id=(line->>'orderItemId')::uuid and purchase_order_id=target_order_id for update;
    receive_quantity := (line->>'quantity')::integer;
    receive_mutation := (line->>'mutationId')::uuid;
    if order_item.id is null or receive_quantity <= 0 or order_item.quantity_received + receive_quantity > order_item.quantity_ordered
      then raise exception 'Invalid receipt quantity'; end if;
    medicine_record_id := order_item.medicine_id;
    if medicine_record_id is null then
      select id into medicine_record_id from public.medicines where barcode=order_item.barcode;
      if medicine_record_id is null then
        insert into public.medicines(canonical_name,barcode) values(order_item.medicine_name,nullif(order_item.barcode,'')) returning id into medicine_record_id;
      end if;
      update public.purchase_order_items set medicine_id=medicine_record_id where id=order_item.id;
    end if;
    select * into inventory_record from public.inventory_items where pharmacy_id=order_record.pharmacy_id and medicine_id=medicine_record_id and batch_number=(line->>'batchNumber') for update;
    if inventory_record.id is null then
      insert into public.inventory_items(pharmacy_id,medicine_id,batch_number,quantity,reorder_level,expiry_date,unit_price,currency)
      values(order_record.pharmacy_id,medicine_record_id,line->>'batchNumber',receive_quantity,0,nullif(line->>'expiryDate','')::date,order_item.unit_cost,order_record.currency)
      returning * into inventory_record;
    else
      update public.inventory_items set quantity=quantity+receive_quantity where id=inventory_record.id returning * into inventory_record;
    end if;
    insert into public.inventory_movements(inventory_item_id,pharmacy_id,actor_profile_id,movement_type,quantity_delta,resulting_quantity,reason,mutation_id)
    values(inventory_record.id,order_record.pharmacy_id,actor_id,'receive',receive_quantity,inventory_record.quantity,'Purchase order '||order_record.order_number,receive_mutation);
    update public.purchase_order_items set quantity_received=quantity_received+receive_quantity where id=order_item.id;
    insert into public.purchase_order_receipts(purchase_order_id,purchase_order_item_id,inventory_item_id,quantity_received,batch_number,expiry_date,received_by,mutation_id)
    values(target_order_id,order_item.id,inventory_record.id,receive_quantity,line->>'batchNumber',nullif(line->>'expiryDate','')::date,actor_id,receive_mutation);
  end loop;
  if exists(select 1 from public.purchase_order_items where purchase_order_id=target_order_id and quantity_received<quantity_ordered)
    then final_status := 'partially_received'; else final_status := 'received'; end if;
  update public.purchase_orders set status=final_status where id=target_order_id;
  insert into public.purchase_order_status_history(purchase_order_id,status,actor_profile_id,note)
  values(target_order_id,final_status,actor_id,'Stock receipt recorded');
  return target_order_id;
end; $$;

commit;
