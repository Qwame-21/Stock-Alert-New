begin;

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
  now_at timestamptz := now();
begin
  if maximum_requests < 1 or window_seconds < 1 then
    raise exception 'Invalid rate-limit configuration';
  end if;

  insert into public.api_rate_limits (
    bucket_key,
    window_started_at,
    request_count
  )
  values (rate_key, now_at, 1)
  on conflict (bucket_key) do update
  set window_started_at = case
        when public.api_rate_limits.window_started_at
          + make_interval(secs => window_seconds) <= now_at
          then now_at
        else public.api_rate_limits.window_started_at
      end,
      request_count = case
        when public.api_rate_limits.window_started_at
          + make_interval(secs => window_seconds) <= now_at
          then 1
        else public.api_rate_limits.request_count + 1
      end,
      updated_at = now_at
  returning * into bucket;

  return query select
    bucket.request_count <= maximum_requests,
    greatest(maximum_requests - bucket.request_count, 0),
    bucket.window_started_at + make_interval(secs => window_seconds);
end;
$$;

revoke all on function public.consume_rate_limit(text, integer, integer)
  from public, anon, authenticated;
grant execute on function public.consume_rate_limit(text, integer, integer)
  to service_role;

commit;
