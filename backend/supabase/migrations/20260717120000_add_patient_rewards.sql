begin;

create table if not exists public.reward_transactions (
  id uuid primary key default gen_random_uuid(),
  patient_profile_id uuid not null references public.patients(profile_id) on delete cascade,
  title text not null check (char_length(trim(title)) between 2 and 180),
  description text,
  points integer not null check (points <> 0),
  status text not null default 'pending'
    check (status in ('pending', 'confirmed', 'reversed')),
  source_type text not null
    check (source_type in ('medicine_return', 'prescription_refill', 'consultation', 'promotion', 'adjustment')),
  source_reference text,
  occurred_at timestamptz not null default now(),
  confirmed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint reward_confirmation_consistent check (
    (status = 'confirmed' and confirmed_at is not null)
    or (status <> 'confirmed')
  )
);

create unique index if not exists reward_transactions_source_unique
  on public.reward_transactions (source_type, source_reference)
  where source_reference is not null;

create index if not exists reward_transactions_patient_activity_index
  on public.reward_transactions (patient_profile_id, occurred_at desc);

drop trigger if exists reward_transactions_set_updated_at
  on public.reward_transactions;
create trigger reward_transactions_set_updated_at
before update on public.reward_transactions
for each row execute function public.set_updated_at_and_version();

alter table public.reward_transactions enable row level security;

drop policy if exists reward_transactions_patient_read
  on public.reward_transactions;
create policy reward_transactions_patient_read
on public.reward_transactions
for select
to authenticated
using (patient_profile_id = auth.uid());

revoke insert, update, delete on public.reward_transactions from anon, authenticated;
grant select on public.reward_transactions to authenticated;

commit;
