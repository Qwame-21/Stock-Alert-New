begin;

create or replace function public.create_appointment(
  actor_id uuid,
  mutation_id uuid,
  target_pharmacy_id uuid,
  provider_name text,
  provider_specialty text,
  appointment_time timestamptz,
  appointment_duration integer,
  appointment_notes text
)
returns public.appointments
language plpgsql
security definer
set search_path = ''
as $$
declare
  appointment public.appointments;
  existing_event public.sync_events;
  appointment_end timestamptz;
begin
  select * into existing_event
  from public.sync_events
  where sync_events.mutation_id = create_appointment.mutation_id
    and actor_profile_id = actor_id;

  if existing_event.id is not null then
    select * into appointment
    from public.appointments
    where id = existing_event.entity_id;
    return appointment;
  end if;

  if not exists (
    select 1 from public.patients where profile_id = actor_id
  ) then
    raise exception using errcode = '42501', message = 'Patient account required';
  end if;

  if appointment_time <= now() then
    raise exception 'Appointment must be in the future';
  end if;

  if appointment_duration < 5 or appointment_duration > 480 then
    raise exception 'Invalid appointment duration';
  end if;

  if target_pharmacy_id is not null and not exists (
    select 1
    from public.pharmacies
    where id = target_pharmacy_id
      and is_active
  ) then
    raise exception using errcode = 'P0002', message = 'Pharmacy not found';
  end if;

  perform pg_advisory_xact_lock(
    hashtextextended(
      coalesce(target_pharmacy_id::text, 'global') || ':' ||
      lower(provider_name),
      0
    )
  );
  perform pg_advisory_xact_lock(hashtextextended(actor_id::text, 0));

  appointment_end :=
    appointment_time + make_interval(mins => appointment_duration);

  if exists (
    select 1
    from public.appointments existing
    where lower(existing.provider_name) = lower(create_appointment.provider_name)
      and existing.pharmacy_id is not distinct from target_pharmacy_id
      and existing.status in ('pending', 'confirmed')
      and existing.deleted_at is null
      and existing.scheduled_at < appointment_end
      and existing.scheduled_at
        + make_interval(mins => existing.duration_minutes) > appointment_time
  ) then
    raise exception using errcode = '23P01', message = 'Provider time conflict';
  end if;

  if exists (
    select 1
    from public.appointments existing
    where existing.patient_profile_id = actor_id
      and existing.status in ('pending', 'confirmed')
      and existing.deleted_at is null
      and existing.scheduled_at < appointment_end
      and existing.scheduled_at
        + make_interval(mins => existing.duration_minutes) > appointment_time
  ) then
    raise exception using errcode = '23P01', message = 'Patient time conflict';
  end if;

  insert into public.appointments (
    patient_profile_id,
    pharmacy_id,
    provider_name,
    specialty,
    scheduled_at,
    duration_minutes,
    notes
  )
  values (
    actor_id,
    target_pharmacy_id,
    provider_name,
    provider_specialty,
    appointment_time,
    appointment_duration,
    appointment_notes
  )
  returning * into appointment;

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
    'appointment',
    appointment.id,
    'create',
    jsonb_build_object(
      'scheduled_at', appointment.scheduled_at,
      'provider_name', appointment.provider_name
    ),
    appointment.version
  );

  return appointment;
end;
$$;

create or replace function public.update_appointment(
  actor_id uuid,
  appointment_id uuid,
  mutation_id uuid,
  patch_data jsonb,
  expected_version bigint
)
returns public.appointments
language plpgsql
security definer
set search_path = ''
as $$
declare
  appointment public.appointments;
  existing_event public.sync_events;
  is_patient boolean;
  is_pharmacy_member boolean;
  new_time timestamptz;
  new_duration integer;
  new_status text;
  new_end timestamptz;
begin
  select * into existing_event
  from public.sync_events
  where sync_events.mutation_id = update_appointment.mutation_id
    and actor_profile_id = actor_id;

  if existing_event.id is not null then
    select * into appointment
    from public.appointments
    where id = existing_event.entity_id;
    return appointment;
  end if;

  select * into appointment
  from public.appointments
  where id = appointment_id
    and deleted_at is null
  for update;

  if appointment.id is null then
    raise exception using errcode = 'P0002', message = 'Appointment not found';
  end if;

  is_patient := appointment.patient_profile_id = actor_id;
  is_pharmacy_member := appointment.pharmacy_id is not null and exists (
    select 1
    from public.pharmacy_staff
    where pharmacy_id = appointment.pharmacy_id
      and profile_id = actor_id
  );

  if not is_patient and not is_pharmacy_member then
    raise exception using errcode = '42501', message = 'Not an appointment participant';
  end if;

  if appointment.version <> expected_version then
    raise exception using errcode = '40001', message = 'Appointment version conflict';
  end if;

  if appointment.status in ('completed', 'cancelled', 'no_show') then
    raise exception 'Finalized appointment cannot be changed';
  end if;

  if is_patient and (
    patch_data ? 'status'
    or patch_data ? 'video_link'
  ) then
    raise exception using errcode = '42501', message = 'Patient cannot change managed fields';
  end if;

  new_time := coalesce(
    nullif(patch_data ->> 'scheduled_at', '')::timestamptz,
    appointment.scheduled_at
  );
  new_duration := coalesce(
    (patch_data ->> 'duration_minutes')::integer,
    appointment.duration_minutes
  );
  new_status := coalesce(patch_data ->> 'status', appointment.status);

  if new_time <= now() and new_status in ('pending', 'confirmed') then
    raise exception 'Appointment must be in the future';
  end if;

  if new_duration < 5 or new_duration > 480 then
    raise exception 'Invalid appointment duration';
  end if;

  if new_status not in ('pending', 'confirmed', 'completed', 'cancelled', 'no_show') then
    raise exception 'Invalid appointment status';
  end if;

  if appointment.status = 'pending'
    and new_status not in ('pending', 'confirmed', 'cancelled') then
    raise exception 'Invalid appointment status transition';
  end if;

  if appointment.status = 'confirmed'
    and new_status not in ('confirmed', 'completed', 'cancelled', 'no_show') then
    raise exception 'Invalid appointment status transition';
  end if;

  if new_time <> appointment.scheduled_at
    or new_duration <> appointment.duration_minutes then
    perform pg_advisory_xact_lock(
      hashtextextended(
        coalesce(appointment.pharmacy_id::text, 'global') || ':' ||
        lower(appointment.provider_name),
        0
      )
    );
    perform pg_advisory_xact_lock(
      hashtextextended(appointment.patient_profile_id::text, 0)
    );

    new_end := new_time + make_interval(mins => new_duration);

    if exists (
      select 1
      from public.appointments existing
      where existing.id <> appointment.id
        and (
          (
            lower(existing.provider_name) = lower(appointment.provider_name)
            and existing.pharmacy_id is not distinct from appointment.pharmacy_id
          )
          or existing.patient_profile_id = appointment.patient_profile_id
        )
        and existing.status in ('pending', 'confirmed')
        and existing.deleted_at is null
        and existing.scheduled_at < new_end
        and existing.scheduled_at
          + make_interval(mins => existing.duration_minutes) > new_time
    ) then
      raise exception using errcode = '23P01', message = 'Appointment time conflict';
    end if;
  end if;

  update public.appointments
  set scheduled_at = new_time,
      duration_minutes = new_duration,
      notes = case
        when patch_data ? 'notes' then patch_data ->> 'notes'
        else notes
      end,
      video_link = case
        when patch_data ? 'video_link' then patch_data ->> 'video_link'
        else video_link
      end,
      status = new_status
  where id = appointment.id
  returning * into appointment;

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
    'appointment',
    appointment.id,
    'update',
    patch_data,
    expected_version,
    appointment.version
  );

  return appointment;
end;
$$;

create or replace function public.cancel_appointment(
  actor_id uuid,
  appointment_id uuid,
  mutation_id uuid,
  cancellation_text text,
  expected_version bigint
)
returns public.appointments
language plpgsql
security definer
set search_path = ''
as $$
declare
  appointment public.appointments;
  existing_event public.sync_events;
begin
  select * into existing_event
  from public.sync_events
  where sync_events.mutation_id = cancel_appointment.mutation_id
    and actor_profile_id = actor_id;

  if existing_event.id is not null then
    select * into appointment
    from public.appointments
    where id = existing_event.entity_id;
    return appointment;
  end if;

  select * into appointment
  from public.appointments
  where id = appointment_id
    and deleted_at is null
  for update;

  if appointment.id is null then
    raise exception using errcode = 'P0002', message = 'Appointment not found';
  end if;

  if appointment.patient_profile_id <> actor_id
    and not (
      appointment.pharmacy_id is not null
      and exists (
        select 1
        from public.pharmacy_staff
        where pharmacy_id = appointment.pharmacy_id
          and profile_id = actor_id
      )
    ) then
    raise exception using errcode = '42501', message = 'Not an appointment participant';
  end if;

  if appointment.version <> expected_version then
    raise exception using errcode = '40001', message = 'Appointment version conflict';
  end if;

  if appointment.status in ('completed', 'no_show') then
    raise exception 'Finalized appointment cannot be cancelled';
  end if;

  update public.appointments
  set status = 'cancelled',
      cancellation_reason = cancellation_text
  where id = appointment.id
  returning * into appointment;

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
    'appointment',
    appointment.id,
    'delete',
    jsonb_build_object('cancellation_reason', cancellation_text),
    expected_version,
    appointment.version
  );

  return appointment;
end;
$$;

revoke all on function public.create_appointment(
  uuid, uuid, uuid, text, text, timestamptz, integer, text
) from public, anon, authenticated;
grant execute on function public.create_appointment(
  uuid, uuid, uuid, text, text, timestamptz, integer, text
) to service_role;

revoke all on function public.update_appointment(
  uuid, uuid, uuid, jsonb, bigint
) from public, anon, authenticated;
grant execute on function public.update_appointment(
  uuid, uuid, uuid, jsonb, bigint
) to service_role;

revoke all on function public.cancel_appointment(
  uuid, uuid, uuid, text, bigint
) from public, anon, authenticated;
grant execute on function public.cancel_appointment(
  uuid, uuid, uuid, text, bigint
) to service_role;

commit;
