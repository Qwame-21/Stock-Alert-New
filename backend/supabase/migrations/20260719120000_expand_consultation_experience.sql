begin;

alter table public.consultation_providers
  add column if not exists video_fee numeric(12,2) not null default 100 check (video_fee >= 0),
  add column if not exists in_person_fee numeric(12,2) not null default 150 check (in_person_fee >= 0),
  add column if not exists currency char(3) not null default 'GHS';

alter table public.appointments
  add column if not exists consultation_mode text check (consultation_mode in ('video', 'in_person')),
  add column if not exists clinical_reason text,
  add column if not exists patient_condition text,
  add column if not exists requested_support text,
  add column if not exists consultation_fee numeric(12,2) check (consultation_fee is null or consultation_fee >= 0),
  add column if not exists deposit_amount numeric(12,2) check (deposit_amount is null or deposit_amount >= 0),
  add column if not exists payment_status text not null default 'unpaid'
    check (payment_status in ('unpaid', 'initialized', 'paid', 'refund_pending', 'refunded', 'failed')),
  add column if not exists cancellation_category text,
  add column if not exists patient_archived_at timestamptz,
  add column if not exists provider_archived_at timestamptz;

alter table public.payment_transactions
  add column if not exists appointment_id uuid references public.appointments(id) on delete set null,
  add column if not exists purpose text check (purpose in ('consultation_deposit', 'interaction_change', 'general')),
  add column if not exists refund_status text check (refund_status in ('pending', 'processed', 'failed'));

create table if not exists public.saved_places (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  label text not null,
  address text not null,
  latitude double precision,
  longitude double precision,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(profile_id, label)
);

alter table public.saved_places enable row level security;
create policy saved_places_owner_all on public.saved_places for all to authenticated
using (profile_id = auth.uid()) with check (profile_id = auth.uid());

commit;
