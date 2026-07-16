begin;

create or replace function public.pull_sync_events(
  actor_id uuid,
  after_cursor bigint default 0,
  page_size integer default 100
)
returns table (
  cursor bigint,
  mutation_id uuid,
  entity_type text,
  entity_id uuid,
  operation text,
  payload jsonb,
  base_version bigint,
  resulting_version bigint,
  created_at timestamptz
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    event.id as cursor,
    event.mutation_id,
    event.entity_type,
    event.entity_id,
    event.operation,
    event.payload,
    event.base_version,
    event.resulting_version,
    event.created_at
  from public.sync_events event
  where event.id > greatest(after_cursor, 0)
    and (
      event.actor_profile_id = actor_id
      or (
        event.entity_type = 'inventory_item'
        and exists (
          select 1
          from public.inventory_items item
          join public.pharmacy_staff staff
            on staff.pharmacy_id = item.pharmacy_id
          where item.id = event.entity_id
            and staff.profile_id = actor_id
        )
      )
      or (
        event.entity_type = 'appointment'
        and exists (
          select 1
          from public.appointments appointment
          where appointment.id = event.entity_id
            and (
              appointment.patient_profile_id = actor_id
              or (
                appointment.pharmacy_id is not null
                and exists (
                  select 1
                  from public.pharmacy_staff staff
                  where staff.pharmacy_id = appointment.pharmacy_id
                    and staff.profile_id = actor_id
                )
              )
            )
        )
      )
    )
  order by event.id
  limit least(greatest(page_size, 1), 200);
$$;

revoke all on function public.pull_sync_events(uuid, bigint, integer)
  from public, anon, authenticated;
grant execute on function public.pull_sync_events(uuid, bigint, integer)
  to service_role;

commit;
