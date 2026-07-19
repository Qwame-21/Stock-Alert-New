alter table public.appointments
  add column if not exists requested_at timestamptz not null default now(),
  add column if not exists reviewed_at timestamptz,
  add column if not exists responded_at timestamptz,
  add column if not exists responded_by uuid references public.profiles(id) on delete set null,
  add column if not exists decision_note text;

update public.appointments
set requested_at = created_at
where requested_at is distinct from created_at;

create or replace function public.set_appointment_timeline()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if old.status = 'pending' and new.status <> 'pending' then
    new.reviewed_at = coalesce(new.reviewed_at, now());
    new.responded_at = coalesce(new.responded_at, now());
  end if;
  return new;
end;
$$;

drop trigger if exists appointments_set_timeline on public.appointments;
create trigger appointments_set_timeline
before update on public.appointments
for each row execute function public.set_appointment_timeline();

create index if not exists appointments_pending_provider_index
  on public.appointments (provider_profile_id, requested_at desc)
  where status = 'pending' and deleted_at is null;
