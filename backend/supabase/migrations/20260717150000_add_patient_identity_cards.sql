begin;

create table if not exists public.patient_identity_cards (
  patient_profile_id uuid primary key references public.patients(profile_id) on delete cascade,
  public_id text not null unique default ('PAT-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 12))),
  qr_token uuid not null unique default gen_random_uuid(),
  sharing_enabled boolean not null default true,
  share_full_name boolean not null default true,
  share_date_of_birth boolean not null default false,
  share_emergency_contact boolean not null default false,
  updated_at timestamptz not null default now()
);

alter table public.patient_identity_cards enable row level security;

create table if not exists public.payment_transactions (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete restrict,
  provider text not null default 'paystack',
  reference text not null unique,
  amount_minor bigint not null check (amount_minor > 0),
  currency char(3) not null default 'GHS',
  status text not null default 'initialized' check (status in ('initialized', 'success', 'failed', 'abandoned')),
  provider_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.payment_transactions enable row level security;
create policy payment_owner_read on public.payment_transactions for select to authenticated
using (profile_id = auth.uid());

create policy patient_identity_owner_read on public.patient_identity_cards
for select to authenticated using (patient_profile_id = auth.uid());

create policy patient_identity_owner_update on public.patient_identity_cards
for update to authenticated using (patient_profile_id = auth.uid())
with check (patient_profile_id = auth.uid());

commit;
