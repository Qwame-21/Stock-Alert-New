begin;

create table if not exists public.api_rate_limits (
  bucket_key text primary key,
  window_started_at timestamptz not null,
  request_count integer not null check (request_count >= 0),
  updated_at timestamptz not null default now()
);

create index if not exists api_rate_limits_updated_index
  on public.api_rate_limits (updated_at);

create table if not exists public.audit_events (
  id bigint generated always as identity primary key,
  actor_profile_id uuid references public.profiles(id) on delete set null,
  action text not null,
  entity_type text not null,
  entity_id text,
  request_id text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists audit_events_actor_index
  on public.audit_events (actor_profile_id, created_at desc);

create index if not exists audit_events_entity_index
  on public.audit_events (entity_type, entity_id, created_at desc);

alter table public.api_rate_limits enable row level security;
alter table public.audit_events enable row level security;

create or replace function public.consume_rate_limit(
  rate_key text,
  maximum_requests integer,
  window_seconds integer
)
returns table (
  allowed boolean,
  remaining integer,
  reset_at timestamptz
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  bucket public.api_rate_limits;
  current_time timestamptz := now();
begin
  if maximum_requests < 1 or window_seconds < 1 then
    raise exception 'Invalid rate-limit configuration';
  end if;

  insert into public.api_rate_limits (
    bucket_key,
    window_started_at,
    request_count
  )
  values (rate_key, current_time, 1)
  on conflict (bucket_key) do update
  set window_started_at = case
        when public.api_rate_limits.window_started_at
          + make_interval(secs => window_seconds) <= current_time
          then current_time
        else public.api_rate_limits.window_started_at
      end,
      request_count = case
        when public.api_rate_limits.window_started_at
          + make_interval(secs => window_seconds) <= current_time
          then 1
        else public.api_rate_limits.request_count + 1
      end,
      updated_at = current_time
  returning * into bucket;

  return query select
    bucket.request_count <= maximum_requests,
    greatest(maximum_requests - bucket.request_count, 0),
    bucket.window_started_at + make_interval(secs => window_seconds);
end;
$$;

create or replace function public.record_audit_event(
  actor_id uuid,
  event_action text,
  event_entity_type text,
  event_entity_id text,
  event_request_id text,
  event_metadata jsonb default '{}'::jsonb
)
returns void
language sql
security definer
set search_path = ''
as $$
  insert into public.audit_events (
    actor_profile_id,
    action,
    entity_type,
    entity_id,
    request_id,
    metadata
  )
  values (
    actor_id,
    event_action,
    event_entity_type,
    event_entity_id,
    event_request_id,
    coalesce(event_metadata, '{}'::jsonb)
  );
$$;

revoke all on function public.consume_rate_limit(text, integer, integer)
  from public, anon, authenticated;
grant execute on function public.consume_rate_limit(text, integer, integer)
  to service_role;

revoke all on function public.record_audit_event(
  uuid, text, text, text, text, jsonb
) from public, anon, authenticated;
grant execute on function public.record_audit_event(
  uuid, text, text, text, text, jsonb
) to service_role;

commit;
