begin;

alter table public.profiles drop constraint if exists profiles_role_check;
alter table public.profiles
  add constraint profiles_role_check
  check (role in ('patient', 'pharmacy', 'provider'));

create table if not exists public.consultation_providers (
  profile_id uuid primary key references public.profiles(id) on delete cascade,
  display_name text not null,
  specialty text not null,
  professional_license text not null unique,
  registration_authority text not null,
  years_experience integer not null default 0 check (years_experience between 0 and 80),
  bio text,
  consultation_mode text not null default 'video'
    check (consultation_mode in ('video', 'in_person', 'both')),
  location text,
  consultation_duration integer not null default 30
    check (consultation_duration between 10 and 180),
  verification_status text not null default 'pending'
    check (verification_status in ('pending', 'verified', 'rejected', 'suspended')),
  is_accepting_bookings boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.provider_availability (
  id uuid primary key default gen_random_uuid(),
  provider_profile_id uuid not null
    references public.consultation_providers(profile_id) on delete cascade,
  weekday integer not null check (weekday between 1 and 7),
  start_time time not null,
  end_time time not null,
  is_active boolean not null default true,
  check (end_time > start_time),
  unique (provider_profile_id, weekday, start_time, end_time)
);

alter table public.appointments
  add column if not exists provider_profile_id uuid
  references public.consultation_providers(profile_id) on delete set null;

create index if not exists appointments_provider_time_index
  on public.appointments(provider_profile_id, scheduled_at)
  where deleted_at is null and status in ('pending', 'confirmed');

alter table public.consultation_providers enable row level security;
alter table public.provider_availability enable row level security;

drop policy if exists consultation_providers_public_read on public.consultation_providers;
create policy consultation_providers_public_read
on public.consultation_providers for select to authenticated
using (verification_status = 'verified' or profile_id = auth.uid());

drop policy if exists consultation_providers_owner_update on public.consultation_providers;
create policy consultation_providers_owner_update
on public.consultation_providers for update to authenticated
using (profile_id = auth.uid()) with check (profile_id = auth.uid());

drop policy if exists provider_availability_authenticated_read on public.provider_availability;
create policy provider_availability_authenticated_read
on public.provider_availability for select to authenticated using (true);

drop policy if exists provider_availability_owner_write on public.provider_availability;
create policy provider_availability_owner_write
on public.provider_availability for all to authenticated
using (provider_profile_id = auth.uid())
with check (provider_profile_id = auth.uid());

commit;
