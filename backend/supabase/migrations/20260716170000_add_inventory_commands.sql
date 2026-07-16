begin;

create or replace function public.create_inventory_item(
  actor_id uuid,
  target_pharmacy_id uuid,
  mutation_id uuid,
  medicine_data jsonb,
  item_data jsonb
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  existing_entity_id uuid;
  medicine_record_id uuid;
  inventory_record_id uuid;
  initial_quantity integer := coalesce((item_data ->> 'quantity')::integer, 0);
begin
  if not exists (
    select 1
    from public.pharmacy_staff
    where pharmacy_id = target_pharmacy_id
      and profile_id = actor_id
  ) then
    raise exception using errcode = '42501', message = 'Not a pharmacy member';
  end if;

  select entity_id into existing_entity_id
  from public.sync_events
  where sync_events.mutation_id = create_inventory_item.mutation_id
    and actor_profile_id = actor_id;

  if existing_entity_id is not null then
    return existing_entity_id;
  end if;

  medicine_record_id := nullif(medicine_data ->> 'id', '')::uuid;

  if medicine_record_id is null
    and nullif(medicine_data ->> 'barcode', '') is not null then
    select id into medicine_record_id
    from public.medicines
    where barcode = medicine_data ->> 'barcode';
  end if;

  if medicine_record_id is null then
    insert into public.medicines (
      canonical_name,
      generic_name,
      brand_name,
      strength,
      dosage_form,
      barcode,
      manufacturer,
      requires_prescription
    )
    values (
      medicine_data ->> 'canonical_name',
      medicine_data ->> 'generic_name',
      medicine_data ->> 'brand_name',
      medicine_data ->> 'strength',
      medicine_data ->> 'dosage_form',
      nullif(medicine_data ->> 'barcode', ''),
      medicine_data ->> 'manufacturer',
      coalesce((medicine_data ->> 'requires_prescription')::boolean, false)
    )
    returning id into medicine_record_id;
  elsif not exists (
    select 1 from public.medicines where id = medicine_record_id
  ) then
    raise exception 'Medicine does not exist';
  end if;

  insert into public.inventory_items (
    pharmacy_id,
    medicine_id,
    batch_number,
    quantity,
    reorder_level,
    expiry_date,
    unit_price,
    currency
  )
  values (
    target_pharmacy_id,
    medicine_record_id,
    coalesce(item_data ->> 'batch_number', ''),
    initial_quantity,
    coalesce((item_data ->> 'reorder_level')::integer, 0),
    nullif(item_data ->> 'expiry_date', '')::date,
    nullif(item_data ->> 'unit_price', '')::numeric,
    coalesce(item_data ->> 'currency', 'GHS')
  )
  returning id into inventory_record_id;

  if initial_quantity > 0 then
    insert into public.inventory_movements (
      inventory_item_id,
      pharmacy_id,
      actor_profile_id,
      movement_type,
      quantity_delta,
      resulting_quantity,
      reason,
      mutation_id
    )
    values (
      inventory_record_id,
      target_pharmacy_id,
      actor_id,
      'initial',
      initial_quantity,
      initial_quantity,
      'Initial inventory quantity',
      mutation_id
    );
  end if;

  insert into public.sync_events (
    mutation_id,
    actor_profile_id,
    entity_type,
    entity_id,
    operation,
    payload,
    resulting_version
  )
  values (
    mutation_id,
    actor_id,
    'inventory_item',
    inventory_record_id,
    'create',
    item_data,
    1
  );

  return inventory_record_id;
end;
$$;

create or replace function public.adjust_inventory_stock(
  actor_id uuid,
  inventory_id uuid,
  mutation_id uuid,
  quantity_delta integer,
  movement_kind text,
  movement_reason text,
  expected_version bigint
)
returns public.inventory_items
language plpgsql
security definer
set search_path = ''
as $$
declare
  item public.inventory_items;
  existing_event public.sync_events;
  new_quantity integer;
begin
  select * into existing_event
  from public.sync_events
  where sync_events.mutation_id = adjust_inventory_stock.mutation_id
    and actor_profile_id = actor_id;

  if existing_event.id is not null then
    select * into item
    from public.inventory_items
    where id = existing_event.entity_id;
    return item;
  end if;

  if quantity_delta = 0 then
    raise exception 'Quantity delta cannot be zero';
  end if;

  if movement_kind not in ('receive', 'dispense', 'adjust', 'expire', 'return') then
    raise exception 'Invalid movement type';
  end if;

  select * into item
  from public.inventory_items
  where id = inventory_id
    and deleted_at is null
  for update;

  if item.id is null then
    raise exception using errcode = 'P0002', message = 'Inventory item not found';
  end if;

  if not exists (
    select 1
    from public.pharmacy_staff
    where pharmacy_id = item.pharmacy_id
      and profile_id = actor_id
  ) then
    raise exception using errcode = '42501', message = 'Not a pharmacy member';
  end if;

  if item.version <> expected_version then
    raise exception using errcode = '40001', message = 'Inventory version conflict';
  end if;

  new_quantity := item.quantity + quantity_delta;
  if new_quantity < 0 then
    raise exception using errcode = '22003', message = 'Insufficient stock';
  end if;

  update public.inventory_items
  set quantity = new_quantity
  where id = item.id
  returning * into item;

  insert into public.inventory_movements (
    inventory_item_id,
    pharmacy_id,
    actor_profile_id,
    movement_type,
    quantity_delta,
    resulting_quantity,
    reason,
    mutation_id
  )
  values (
    item.id,
    item.pharmacy_id,
    actor_id,
    movement_kind,
    quantity_delta,
    item.quantity,
    movement_reason,
    mutation_id
  );

  insert into public.sync_events (
    mutation_id,
    actor_profile_id,
    entity_type,
    entity_id,
    operation,
    payload,
    base_version,
    resulting_version
  )
  values (
    mutation_id,
    actor_id,
    'inventory_item',
    item.id,
    'update',
    jsonb_build_object(
      'quantity_delta', quantity_delta,
      'movement_type', movement_kind,
      'reason', movement_reason
    ),
    expected_version,
    item.version
  );

  return item;
end;
$$;

create or replace function public.update_inventory_item(
  actor_id uuid,
  inventory_id uuid,
  mutation_id uuid,
  patch_data jsonb,
  expected_version bigint
)
returns public.inventory_items
language plpgsql
security definer
set search_path = ''
as $$
declare
  item public.inventory_items;
  existing_event public.sync_events;
begin
  select * into existing_event
  from public.sync_events
  where sync_events.mutation_id = update_inventory_item.mutation_id
    and actor_profile_id = actor_id;

  if existing_event.id is not null then
    select * into item
    from public.inventory_items
    where id = existing_event.entity_id;
    return item;
  end if;

  select * into item
  from public.inventory_items
  where id = inventory_id
  for update;

  if item.id is null then
    raise exception using errcode = 'P0002', message = 'Inventory item not found';
  end if;

  if not exists (
    select 1
    from public.pharmacy_staff
    where pharmacy_id = item.pharmacy_id
      and profile_id = actor_id
  ) then
    raise exception using errcode = '42501', message = 'Not a pharmacy member';
  end if;

  if item.version <> expected_version then
    raise exception using errcode = '40001', message = 'Inventory version conflict';
  end if;

  update public.inventory_items
  set batch_number = coalesce(patch_data ->> 'batch_number', batch_number),
      reorder_level = coalesce(
        (patch_data ->> 'reorder_level')::integer,
        reorder_level
      ),
      expiry_date = case
        when patch_data ? 'expiry_date'
          then nullif(patch_data ->> 'expiry_date', '')::date
        else expiry_date
      end,
      unit_price = case
        when patch_data ? 'unit_price'
          then nullif(patch_data ->> 'unit_price', '')::numeric
        else unit_price
      end,
      currency = coalesce(patch_data ->> 'currency', currency),
      deleted_at = case
        when coalesce((patch_data ->> 'deleted')::boolean, false) then now()
        else deleted_at
      end
  where id = item.id
  returning * into item;

  insert into public.sync_events (
    mutation_id,
    actor_profile_id,
    entity_type,
    entity_id,
    operation,
    payload,
    base_version,
    resulting_version
  )
  values (
    mutation_id,
    actor_id,
    'inventory_item',
    item.id,
    case
      when coalesce((patch_data ->> 'deleted')::boolean, false)
        then 'delete'
      else 'update'
    end,
    patch_data,
    expected_version,
    item.version
  );

  return item;
end;
$$;

revoke all on function public.create_inventory_item(
  uuid, uuid, uuid, jsonb, jsonb
) from public, anon, authenticated;
grant execute on function public.create_inventory_item(
  uuid, uuid, uuid, jsonb, jsonb
) to service_role;

revoke all on function public.adjust_inventory_stock(
  uuid, uuid, uuid, integer, text, text, bigint
) from public, anon, authenticated;
grant execute on function public.adjust_inventory_stock(
  uuid, uuid, uuid, integer, text, text, bigint
) to service_role;

revoke all on function public.update_inventory_item(
  uuid, uuid, uuid, jsonb, bigint
) from public, anon, authenticated;
grant execute on function public.update_inventory_item(
  uuid, uuid, uuid, jsonb, bigint
) to service_role;

commit;
