begin;

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles
  add column if not exists role text,
  add column if not exists email text,
  add column if not exists full_name text,
  add column if not exists phone_number text,
  add column if not exists dob date,
  add column if not exists gender text,
  add column if not exists pharmacy_name text,
  add column if not exists license_number text,
  add column if not exists location text,
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now();

create table if not exists public.patients (
  profile_id uuid primary key references public.profiles(id) on delete cascade,
  blood_group text,
  known_allergies text[] not null default '{}',
  chronic_conditions text[] not null default '{}',
  current_medication text,
  emergency_contact_name text,
  emergency_contact_phone text,
  emergency_contact_email text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.pharmacies (
  id uuid primary key default gen_random_uuid(),
  owner_profile_id uuid not null unique references public.profiles(id) on delete restrict,
  name text not null,
  license_number text,
  registration_authority text,
  location text not null,
  latitude double precision,
  longitude double precision,
  operating_hours text,
  supplier_preference text,
  verification_status text not null default 'pending'
    check (verification_status in ('pending', 'verified', 'rejected', 'suspended')),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  version bigint not null default 1
);

create unique index if not exists pharmacies_license_number_unique
  on public.pharmacies (lower(license_number))
  where license_number is not null;

create index if not exists pharmacies_location_index
  on public.pharmacies (location);

create table if not exists public.pharmacy_staff (
  pharmacy_id uuid not null references public.pharmacies(id) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  staff_role text not null default 'staff'
    check (staff_role in ('owner', 'pharmacist', 'staff')),
  created_at timestamptz not null default now(),
  primary key (pharmacy_id, profile_id)
);

create index if not exists pharmacy_staff_profile_index
  on public.pharmacy_staff (profile_id);

create table if not exists public.medicines (
  id uuid primary key default gen_random_uuid(),
  canonical_name text not null,
  generic_name text,
  brand_name text,
  strength text,
  dosage_form text,
  barcode text,
  manufacturer text,
  requires_prescription boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists medicines_barcode_unique
  on public.medicines (barcode)
  where barcode is not null;

create index if not exists medicines_search_index
  on public.medicines using gin (
    to_tsvector(
      'simple',
      coalesce(canonical_name, '') || ' ' ||
      coalesce(generic_name, '') || ' ' ||
      coalesce(brand_name, '')
    )
  );

create table if not exists public.inventory_items (
  id uuid primary key default gen_random_uuid(),
  pharmacy_id uuid not null references public.pharmacies(id) on delete cascade,
  medicine_id uuid not null references public.medicines(id) on delete restrict,
  batch_number text not null default '',
  quantity integer not null default 0 check (quantity >= 0),
  reorder_level integer not null default 0 check (reorder_level >= 0),
  expiry_date date,
  unit_price numeric(12, 2) check (unit_price is null or unit_price >= 0),
  currency char(3) not null default 'GHS',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  version bigint not null default 1,
  unique (pharmacy_id, medicine_id, batch_number)
);

create index if not exists inventory_items_pharmacy_index
  on public.inventory_items (pharmacy_id, deleted_at);

create index if not exists inventory_items_medicine_index
  on public.inventory_items (medicine_id, deleted_at);

create index if not exists inventory_items_expiry_index
  on public.inventory_items (expiry_date)
  where deleted_at is null;

create table if not exists public.inventory_movements (
  id uuid primary key default gen_random_uuid(),
  inventory_item_id uuid not null references public.inventory_items(id) on delete restrict,
  pharmacy_id uuid not null references public.pharmacies(id) on delete restrict,
  actor_profile_id uuid references public.profiles(id) on delete set null,
  movement_type text not null
    check (movement_type in ('initial', 'receive', 'dispense', 'adjust', 'expire', 'return')),
  quantity_delta integer not null check (quantity_delta <> 0),
  resulting_quantity integer not null check (resulting_quantity >= 0),
  reason text,
  mutation_id uuid unique,
  created_at timestamptz not null default now()
);

create index if not exists inventory_movements_item_index
  on public.inventory_movements (inventory_item_id, created_at desc);

create table if not exists public.appointments (
  id uuid primary key default gen_random_uuid(),
  patient_profile_id uuid not null references public.patients(profile_id) on delete restrict,
  pharmacy_id uuid references public.pharmacies(id) on delete set null,
  provider_name text not null,
  specialty text,
  scheduled_at timestamptz not null,
  duration_minutes integer not null default 30
    check (duration_minutes between 5 and 480),
  status text not null default 'pending'
    check (status in ('pending', 'confirmed', 'completed', 'cancelled', 'no_show')),
  video_link text,
  notes text,
  cancellation_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  version bigint not null default 1
);

create index if not exists appointments_patient_index
  on public.appointments (patient_profile_id, scheduled_at desc)
  where deleted_at is null;

create index if not exists appointments_pharmacy_index
  on public.appointments (pharmacy_id, scheduled_at desc)
  where deleted_at is null;

create table if not exists public.notification_preferences (
  profile_id uuid primary key references public.profiles(id) on delete cascade,
  booking_reminders boolean not null default true,
  medication_reminders boolean not null default true,
  low_stock_alerts boolean not null default true,
  expiry_alerts boolean not null default true,
  push_enabled boolean not null default true,
  email_enabled boolean not null default true,
  updated_at timestamptz not null default now()
);

create table if not exists public.verification_documents (
  id uuid primary key default gen_random_uuid(),
  owner_profile_id uuid not null references public.profiles(id) on delete cascade,
  document_type text not null,
  storage_bucket text not null default 'verification-documents',
  storage_path text not null,
  review_status text not null default 'pending'
    check (review_status in ('pending', 'approved', 'rejected')),
  reviewed_by uuid references public.profiles(id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  unique (storage_bucket, storage_path)
);

create table if not exists public.sync_events (
  id bigint generated always as identity primary key,
  mutation_id uuid not null unique,
  actor_profile_id uuid not null references public.profiles(id) on delete cascade,
  entity_type text not null,
  entity_id uuid not null,
  operation text not null check (operation in ('create', 'update', 'delete')),
  payload jsonb not null default '{}'::jsonb,
  base_version bigint,
  resulting_version bigint,
  created_at timestamptz not null default now()
);

create index if not exists sync_events_actor_cursor_index
  on public.sync_events (actor_profile_id, id);

create or replace function public.set_updated_at_and_version()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  if to_jsonb(new) ? 'version' then
    new.version = old.version + 1;
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at_and_version();

drop trigger if exists patients_set_updated_at on public.patients;
create trigger patients_set_updated_at
before update on public.patients
for each row execute function public.set_updated_at_and_version();

drop trigger if exists pharmacies_set_updated_at on public.pharmacies;
create trigger pharmacies_set_updated_at
before update on public.pharmacies
for each row execute function public.set_updated_at_and_version();

drop trigger if exists medicines_set_updated_at on public.medicines;
create trigger medicines_set_updated_at
before update on public.medicines
for each row execute function public.set_updated_at_and_version();

drop trigger if exists inventory_items_set_updated_at on public.inventory_items;
create trigger inventory_items_set_updated_at
before update on public.inventory_items
for each row execute function public.set_updated_at_and_version();

drop trigger if exists appointments_set_updated_at on public.appointments;
create trigger appointments_set_updated_at
before update on public.appointments
for each row execute function public.set_updated_at_and_version();

drop trigger if exists notification_preferences_set_updated_at
  on public.notification_preferences;
create trigger notification_preferences_set_updated_at
before update on public.notification_preferences
for each row execute function public.set_updated_at_and_version();

create or replace function public.is_pharmacy_member(target_pharmacy_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.pharmacy_staff staff
    where staff.pharmacy_id = target_pharmacy_id
      and staff.profile_id = auth.uid()
  );
$$;

revoke all on function public.is_pharmacy_member(uuid) from public;
grant execute on function public.is_pharmacy_member(uuid) to authenticated;

create or replace function public.sync_profile_domain()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  pharmacy_record_id uuid;
begin
  insert into public.notification_preferences (profile_id)
  values (new.id)
  on conflict (profile_id) do nothing;

  if new.role = 'patient' then
    insert into public.patients (profile_id)
    values (new.id)
    on conflict (profile_id) do nothing;
  elsif new.role = 'pharmacy'
    and new.pharmacy_name is not null
    and new.location is not null then
    insert into public.pharmacies (
      owner_profile_id,
      name,
      license_number,
      location
    )
    values (
      new.id,
      new.pharmacy_name,
      new.license_number,
      new.location
    )
    on conflict (owner_profile_id) do update
      set name = excluded.name,
          license_number = excluded.license_number,
          location = excluded.location
    returning id into pharmacy_record_id;

    insert into public.pharmacy_staff (
      pharmacy_id,
      profile_id,
      staff_role
    )
    values (pharmacy_record_id, new.id, 'owner')
    on conflict (pharmacy_id, profile_id) do update
      set staff_role = 'owner';
  end if;

  return new;
end;
$$;

drop trigger if exists profiles_sync_domain on public.profiles;
create trigger profiles_sync_domain
after insert or update of role, pharmacy_name, license_number, location
on public.profiles
for each row execute function public.sync_profile_domain();

insert into public.patients (profile_id)
select id
from public.profiles
where role = 'patient'
on conflict (profile_id) do nothing;

insert into public.pharmacies (
  owner_profile_id,
  name,
  license_number,
  location
)
select
  id,
  pharmacy_name,
  license_number,
  location
from public.profiles
where role = 'pharmacy'
  and pharmacy_name is not null
  and location is not null
on conflict (owner_profile_id) do update
  set name = excluded.name,
      license_number = excluded.license_number,
      location = excluded.location;

insert into public.pharmacy_staff (pharmacy_id, profile_id, staff_role)
select id, owner_profile_id, 'owner'
from public.pharmacies
on conflict (pharmacy_id, profile_id) do update
  set staff_role = 'owner';

insert into public.notification_preferences (profile_id)
select id from public.profiles
on conflict (profile_id) do nothing;

create or replace function public.create_account_profile(
  user_id uuid,
  profile_data jsonb,
  details_data jsonb default '{}'::jsonb
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  account_role text := profile_data ->> 'role';
  pharmacy_record_id uuid;
begin
  if not exists (select 1 from auth.users where id = user_id) then
    raise exception 'Auth user does not exist';
  end if;

  if account_role not in ('patient', 'pharmacy') then
    raise exception 'Invalid account role';
  end if;

  insert into public.profiles (
    id,
    role,
    email,
    full_name,
    phone_number,
    dob,
    gender,
    pharmacy_name,
    license_number,
    location
  )
  values (
    user_id,
    account_role,
    profile_data ->> 'email',
    profile_data ->> 'full_name',
    profile_data ->> 'phone_number',
    nullif(profile_data ->> 'dob', '')::date,
    profile_data ->> 'gender',
    profile_data ->> 'pharmacy_name',
    profile_data ->> 'license_number',
    profile_data ->> 'location'
  )
  on conflict (id) do update set
    email = excluded.email,
    full_name = excluded.full_name,
    phone_number = excluded.phone_number,
    dob = excluded.dob,
    gender = excluded.gender,
    pharmacy_name = excluded.pharmacy_name,
    license_number = excluded.license_number,
    location = excluded.location;

  if account_role = 'patient' then
    insert into public.patients (
      profile_id,
      blood_group,
      known_allergies,
      chronic_conditions,
      current_medication,
      emergency_contact_name,
      emergency_contact_phone,
      emergency_contact_email
    )
    values (
      user_id,
      details_data ->> 'blood_group',
      coalesce(
        array(select jsonb_array_elements_text(details_data -> 'known_allergies')),
        '{}'
      ),
      coalesce(
        array(select jsonb_array_elements_text(details_data -> 'chronic_conditions')),
        '{}'
      ),
      details_data ->> 'current_medication',
      details_data ->> 'emergency_contact_name',
      details_data ->> 'emergency_contact_phone',
      details_data ->> 'emergency_contact_email'
    )
    on conflict (profile_id) do update set
      blood_group = excluded.blood_group,
      known_allergies = excluded.known_allergies,
      chronic_conditions = excluded.chronic_conditions,
      current_medication = excluded.current_medication,
      emergency_contact_name = excluded.emergency_contact_name,
      emergency_contact_phone = excluded.emergency_contact_phone,
      emergency_contact_email = excluded.emergency_contact_email;
  else
    select id into pharmacy_record_id
    from public.pharmacies
    where owner_profile_id = user_id;

    update public.pharmacies
    set registration_authority = details_data ->> 'registration_authority',
        operating_hours = details_data ->> 'operating_hours',
        supplier_preference = details_data ->> 'supplier_preference'
    where id = pharmacy_record_id;
  end if;

  if nullif(details_data ->> 'document_path', '') is not null then
    insert into public.verification_documents (
      owner_profile_id,
      document_type,
      storage_path
    )
    values (
      user_id,
      coalesce(details_data ->> 'document_type', 'Unknown'),
      details_data ->> 'document_path'
    )
    on conflict (storage_bucket, storage_path) do nothing;
  end if;
end;
$$;

revoke all on function public.create_account_profile(uuid, jsonb, jsonb)
  from public, anon, authenticated;
grant execute on function public.create_account_profile(uuid, jsonb, jsonb)
  to service_role;

alter table public.profiles enable row level security;
alter table public.patients enable row level security;
alter table public.pharmacies enable row level security;
alter table public.pharmacy_staff enable row level security;
alter table public.medicines enable row level security;
alter table public.inventory_items enable row level security;
alter table public.inventory_movements enable row level security;
alter table public.appointments enable row level security;
alter table public.notification_preferences enable row level security;
alter table public.verification_documents enable row level security;
alter table public.sync_events enable row level security;

drop policy if exists profiles_select_own on public.profiles;
create policy profiles_select_own on public.profiles
for select to authenticated
using (id = auth.uid());

drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own on public.profiles
for update to authenticated
using (id = auth.uid())
with check (id = auth.uid());

drop policy if exists patients_own_access on public.patients;
create policy patients_own_access on public.patients
for all to authenticated
using (profile_id = auth.uid())
with check (profile_id = auth.uid());

drop policy if exists pharmacies_public_read on public.pharmacies;
create policy pharmacies_public_read on public.pharmacies
for select to authenticated
using (is_active);

drop policy if exists pharmacies_member_update on public.pharmacies;
create policy pharmacies_member_update on public.pharmacies
for update to authenticated
using (public.is_pharmacy_member(id))
with check (public.is_pharmacy_member(id));

drop policy if exists pharmacy_staff_member_read on public.pharmacy_staff;
create policy pharmacy_staff_member_read on public.pharmacy_staff
for select to authenticated
using (public.is_pharmacy_member(pharmacy_id));

drop policy if exists medicines_authenticated_read on public.medicines;
create policy medicines_authenticated_read on public.medicines
for select to authenticated
using (true);

drop policy if exists inventory_authenticated_read on public.inventory_items;
create policy inventory_authenticated_read on public.inventory_items
for select to authenticated
using (deleted_at is null);

drop policy if exists inventory_member_write on public.inventory_items;
create policy inventory_member_write on public.inventory_items
for all to authenticated
using (public.is_pharmacy_member(pharmacy_id))
with check (public.is_pharmacy_member(pharmacy_id));

drop policy if exists inventory_movements_member_read
  on public.inventory_movements;
create policy inventory_movements_member_read on public.inventory_movements
for select to authenticated
using (public.is_pharmacy_member(pharmacy_id));

drop policy if exists appointments_participant_access on public.appointments;
create policy appointments_participant_access on public.appointments
for all to authenticated
using (
  patient_profile_id = auth.uid()
  or (
    pharmacy_id is not null
    and public.is_pharmacy_member(pharmacy_id)
  )
)
with check (
  patient_profile_id = auth.uid()
  or (
    pharmacy_id is not null
    and public.is_pharmacy_member(pharmacy_id)
  )
);

drop policy if exists notification_preferences_own_access
  on public.notification_preferences;
create policy notification_preferences_own_access
on public.notification_preferences
for all to authenticated
using (profile_id = auth.uid())
with check (profile_id = auth.uid());

drop policy if exists verification_documents_own_read
  on public.verification_documents;
create policy verification_documents_own_read
on public.verification_documents
for select to authenticated
using (owner_profile_id = auth.uid());

drop policy if exists sync_events_own_read on public.sync_events;
create policy sync_events_own_read on public.sync_events
for select to authenticated
using (actor_profile_id = auth.uid());

commit;
