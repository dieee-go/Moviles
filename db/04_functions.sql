CREATE OR REPLACE FUNCTION public.approve_organizer_request(request_id uuid, approve boolean)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  target_user_id uuid;
  current_user_role text;
BEGIN
  -- Verificar que el usuario actual es admin
  SELECT role INTO current_user_role
  FROM profiles
  WHERE id = auth.uid();

  IF current_user_role IS NULL OR current_user_role != 'admin' THEN
    RAISE EXCEPTION 'Solo los administradores pueden aprobar solicitudes';
  END IF;

  -- Obtener el user_id de la solicitud
  SELECT user_id INTO target_user_id
  FROM role_requests
  WHERE id = request_id;

  IF target_user_id IS NULL THEN
    RAISE EXCEPTION 'Solicitud no encontrada';
  END IF;

  -- Si se aprueba, actualizar el rol en profiles
  IF approve THEN
    UPDATE profiles
    SET role = 'organizer'
    WHERE id = target_user_id;

    -- Actualizar el estado de la solicitud a approved
    UPDATE role_requests
    SET status = 'approved',
        updated_at = now()
    WHERE id = request_id;
  ELSE
    -- Si se rechaza, solo actualizar el estado
    UPDATE role_requests
    SET status = 'rejected',
        updated_at = now()
    WHERE id = request_id;
  END IF;
END;
$function$
;



CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
begin
  insert into public.profiles (
    id, 
    email, 
    nombre, 
    primer_apellido, 
    segundo_apellido, 
    telefono
  )
  values (
    new.id, 
    new.email,
    new.raw_user_meta_data->>'nombre',
    new.raw_user_meta_data->>'primer_apellido',
    new.raw_user_meta_data->>'segundo_apellido',
    new.raw_user_meta_data->>'telefono'
  )
  on conflict (id) do nothing;
  return new;
end;
$function$
;



CREATE OR REPLACE FUNCTION public.is_current_admin()
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  admin_role text;
BEGIN
  -- Lee perfiles como owner del objeto (bypassa RLS)
  SELECT role INTO admin_role
  FROM profiles
  WHERE id = auth.uid();

  RETURN admin_role = 'admin';
END;
$function$
;



CREATE OR REPLACE FUNCTION public.set_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$function$
;



CREATE OR REPLACE FUNCTION public.track_role_changes()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  IF OLD.role IS DISTINCT FROM NEW.role THEN
    INSERT INTO public.role_history (user_id, role, action, changed_by)
    VALUES (NEW.id, NEW.role, 'granted', auth.uid());
    
    IF OLD.role IS NOT NULL AND OLD.role != '' THEN
      INSERT INTO public.role_history (user_id, role, action, changed_by)
      VALUES (NEW.id, OLD.role, 'revoked', auth.uid());
    END IF;
  END IF;
  RETURN NEW;
END;
$function$
;


CREATE OR REPLACE FUNCTION public.enqueue_event_update()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  reg RECORD;
  notif_type text;
  change_type text;
  reg_count int;
BEGIN
  RAISE LOG 'enqueue_event_update disparado para evento: %', NEW.id;
  
  -- Detectar qué cambió
  IF NEW.status != OLD.status THEN
    change_type := 'status_change';
    notif_type := CASE 
      WHEN NEW.status = 'cancelled' THEN 'event_cancelled' 
      ELSE 'event_updated' 
    END;
  ELSIF NEW.event_date IS DISTINCT FROM OLD.event_date OR NEW.event_time IS DISTINCT FROM OLD.event_time THEN
    change_type := 'datetime_change';
    notif_type := 'event_updated';
  ELSIF NEW.location_id IS DISTINCT FROM OLD.location_id THEN
    change_type := 'location_change';
    notif_type := 'event_updated';
  ELSIF NEW.name IS DISTINCT FROM OLD.name THEN
    change_type := 'name_change';
    notif_type := 'event_updated';
  ELSIF NEW.description IS DISTINCT FROM OLD.description THEN
    change_type := 'description_change';
    notif_type := 'event_updated';
  ELSE
    RAISE LOG 'Sin cambios relevantes en evento %', NEW.id;
    RETURN NEW;
  END IF;

  RAISE LOG 'Tipo de cambio detectado: % en evento %', change_type, NEW.id;

  SELECT COUNT(*) INTO reg_count FROM public.event_registrations WHERE event_id = NEW.id;
  RAISE LOG 'Registros encontrados para evento %: %', NEW.id, reg_count;

  -- Crear notificaciones para todos los registrados
  FOR reg IN
    SELECT user_id FROM public.event_registrations WHERE event_id = NEW.id
  LOOP
    INSERT INTO public.notification_jobs (user_id, event_id, type, payload, scheduled_at)
    VALUES (
      reg.user_id,
      NEW.id,
      notif_type,
      jsonb_build_object(
        'event_id', NEW.id,
        'event_name', NEW.name,
        'change_type', change_type,
        'old_date', OLD.event_date,
        'new_date', NEW.event_date,
        'old_time', OLD.event_time,
        'new_time', NEW.event_time,
        'old_location_id', OLD.location_id,
        'new_location_id', NEW.location_id,
        'old_status', OLD.status,
        'new_status', NEW.status,
        'old_name', OLD.name,
        'new_name', NEW.name
      ),
      now()
    );
    RAISE LOG 'Notificación % creada para usuario % en evento %', notif_type, reg.user_id, NEW.id;
  END LOOP;

  RETURN NEW;
END;
$function$
;


CREATE OR REPLACE FUNCTION public.enqueue_registration_notifications()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  ev RECORD;
  reminder_at timestamptz;
BEGIN
  RAISE LOG 'enqueue_registration_notifications disparado para registro: %', NEW.id;
  
  SELECT id, name, organizer_id, event_date, event_time INTO ev
  FROM public.events
  WHERE id = NEW.event_id;

  IF ev.id IS NULL THEN
    RAISE LOG 'Evento no encontrado para registro %', NEW.id;
    RETURN NEW;
  END IF;

  RAISE LOG 'Evento encontrado: % (organizer: %)', ev.id, ev.organizer_id;

  -- Notificar al organizador
  IF ev.organizer_id IS NOT NULL THEN
    INSERT INTO public.notification_jobs (user_id, event_id, type, payload, scheduled_at)
    VALUES (
      ev.organizer_id,
      ev.id,
      'new_registration',
      jsonb_build_object(
        'event_id', ev.id,
        'event_name', ev.name,
        'user_id', NEW.user_id,
        'registration_id', NEW.id,
        'registered_at', NEW.registration_datetime
      ),
      now()
    );
    RAISE LOG 'Notificación de nueva registración enviada al organizador %', ev.organizer_id;
  END IF;

  -- Enviar recordatorio al usuario registrado
  reminder_at := (ev.event_date::timestamptz + ev.event_time) - interval '1 hour';
  IF reminder_at < now() THEN
    reminder_at := now();
  END IF;

  INSERT INTO public.notification_jobs (user_id, event_id, type, payload, scheduled_at)
  VALUES (
    NEW.user_id,
    ev.id,
    'event_reminder',
    jsonb_build_object(
      'event_id', ev.id,
      'event_name', ev.name,
      'event_date', ev.event_date,
      'event_time', ev.event_time,
      'registration_id', NEW.id,
      'reminder_at', reminder_at
    ),
    reminder_at
  );
  RAISE LOG 'Recordatorio programado para usuario % en %', NEW.user_id, reminder_at;

  RETURN NEW;
END;
$function$
;


CREATE OR REPLACE FUNCTION public.enqueue_role_request_notifications()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  admin_rec RECORD;
  admin_count int;
BEGIN
  RAISE LOG 'enqueue_role_request_notifications disparado para solicitud: %', NEW.id;
  
  SELECT COUNT(*) INTO admin_count FROM public.profiles WHERE role = 'admin';
  RAISE LOG 'Admins encontrados: %', admin_count;

  -- Notificar a todos los admins
  FOR admin_rec IN SELECT id FROM public.profiles WHERE role = 'admin'
  LOOP
    INSERT INTO public.notification_jobs (user_id, type, payload, scheduled_at)
    VALUES (
      admin_rec.id,
      'role_request',
      jsonb_build_object(
        'request_id', NEW.id,
        'user_id', NEW.user_id,
        'message', NEW.message,
        'created_at', NEW.created_at,
        'status', NEW.status
      ),
      now()
    );
    RAISE LOG 'Notificación de solicitud de rol enviada al admin %', admin_rec.id;
  END LOOP;

  RETURN NEW;
END;
$function$
;

grant delete on table "public"."carreras" to "anon";

grant insert on table "public"."carreras" to "anon";

grant references on table "public"."carreras" to "anon";

grant select on table "public"."carreras" to "anon";

grant trigger on table "public"."carreras" to "anon";

grant truncate on table "public"."carreras" to "anon";

grant update on table "public"."carreras" to "anon";

grant delete on table "public"."carreras" to "authenticated";

grant insert on table "public"."carreras" to "authenticated";

grant references on table "public"."carreras" to "authenticated";

grant select on table "public"."carreras" to "authenticated";

grant trigger on table "public"."carreras" to "authenticated";

grant truncate on table "public"."carreras" to "authenticated";

grant update on table "public"."carreras" to "authenticated";

grant delete on table "public"."carreras" to "service_role";

grant insert on table "public"."carreras" to "service_role";

grant references on table "public"."carreras" to "service_role";

grant select on table "public"."carreras" to "service_role";

grant trigger on table "public"."carreras" to "service_role";

grant truncate on table "public"."carreras" to "service_role";

grant update on table "public"."carreras" to "service_role";

grant delete on table "public"."departamentos" to "anon";

grant insert on table "public"."departamentos" to "anon";

grant references on table "public"."departamentos" to "anon";

grant select on table "public"."departamentos" to "anon";

grant trigger on table "public"."departamentos" to "anon";

grant truncate on table "public"."departamentos" to "anon";

grant update on table "public"."departamentos" to "anon";

grant delete on table "public"."departamentos" to "authenticated";

grant insert on table "public"."departamentos" to "authenticated";

grant references on table "public"."departamentos" to "authenticated";

grant select on table "public"."departamentos" to "authenticated";

grant trigger on table "public"."departamentos" to "authenticated";

grant truncate on table "public"."departamentos" to "authenticated";

grant update on table "public"."departamentos" to "authenticated";

grant delete on table "public"."departamentos" to "service_role";

grant insert on table "public"."departamentos" to "service_role";

grant references on table "public"."departamentos" to "service_role";

grant select on table "public"."departamentos" to "service_role";

grant trigger on table "public"."departamentos" to "service_role";

grant truncate on table "public"."departamentos" to "service_role";

grant update on table "public"."departamentos" to "service_role";

grant delete on table "public"."event_interests" to "anon";

grant insert on table "public"."event_interests" to "anon";

grant references on table "public"."event_interests" to "anon";

grant select on table "public"."event_interests" to "anon";

grant trigger on table "public"."event_interests" to "anon";

grant truncate on table "public"."event_interests" to "anon";

grant update on table "public"."event_interests" to "anon";

grant delete on table "public"."event_interests" to "authenticated";

grant insert on table "public"."event_interests" to "authenticated";

grant references on table "public"."event_interests" to "authenticated";

grant select on table "public"."event_interests" to "authenticated";

grant trigger on table "public"."event_interests" to "authenticated";

grant truncate on table "public"."event_interests" to "authenticated";

grant update on table "public"."event_interests" to "authenticated";

grant delete on table "public"."event_interests" to "service_role";

grant insert on table "public"."event_interests" to "service_role";

grant references on table "public"."event_interests" to "service_role";

grant select on table "public"."event_interests" to "service_role";

grant trigger on table "public"."event_interests" to "service_role";

grant truncate on table "public"."event_interests" to "service_role";

grant update on table "public"."event_interests" to "service_role";

grant delete on table "public"."event_registrations" to "anon";

grant insert on table "public"."event_registrations" to "anon";

grant references on table "public"."event_registrations" to "anon";

grant select on table "public"."event_registrations" to "anon";

grant trigger on table "public"."event_registrations" to "anon";

grant truncate on table "public"."event_registrations" to "anon";

grant update on table "public"."event_registrations" to "anon";

grant delete on table "public"."event_registrations" to "authenticated";

grant insert on table "public"."event_registrations" to "authenticated";

grant references on table "public"."event_registrations" to "authenticated";

grant select on table "public"."event_registrations" to "authenticated";

grant trigger on table "public"."event_registrations" to "authenticated";

grant truncate on table "public"."event_registrations" to "authenticated";

grant update on table "public"."event_registrations" to "authenticated";

grant delete on table "public"."event_registrations" to "service_role";

grant insert on table "public"."event_registrations" to "service_role";

grant references on table "public"."event_registrations" to "service_role";

grant select on table "public"."event_registrations" to "service_role";

grant trigger on table "public"."event_registrations" to "service_role";

grant truncate on table "public"."event_registrations" to "service_role";

grant update on table "public"."event_registrations" to "service_role";

grant delete on table "public"."events" to "anon";

grant insert on table "public"."events" to "anon";

grant references on table "public"."events" to "anon";

grant select on table "public"."events" to "anon";

grant trigger on table "public"."events" to "anon";

grant truncate on table "public"."events" to "anon";

grant update on table "public"."events" to "anon";

grant delete on table "public"."events" to "authenticated";

grant insert on table "public"."events" to "authenticated";

grant references on table "public"."events" to "authenticated";

grant select on table "public"."events" to "authenticated";

grant trigger on table "public"."events" to "authenticated";

grant truncate on table "public"."events" to "authenticated";

grant update on table "public"."events" to "authenticated";

grant delete on table "public"."events" to "service_role";

grant insert on table "public"."events" to "service_role";

grant references on table "public"."events" to "service_role";

grant select on table "public"."events" to "service_role";

grant trigger on table "public"."events" to "service_role";

grant truncate on table "public"."events" to "service_role";

grant update on table "public"."events" to "service_role";

grant delete on table "public"."interests" to "anon";

grant insert on table "public"."interests" to "anon";

grant references on table "public"."interests" to "anon";

grant select on table "public"."interests" to "anon";

grant trigger on table "public"."interests" to "anon";

grant truncate on table "public"."interests" to "anon";

grant update on table "public"."interests" to "anon";

grant delete on table "public"."interests" to "authenticated";

grant insert on table "public"."interests" to "authenticated";

grant references on table "public"."interests" to "authenticated";

grant select on table "public"."interests" to "authenticated";

grant trigger on table "public"."interests" to "authenticated";

grant truncate on table "public"."interests" to "authenticated";

grant update on table "public"."interests" to "authenticated";

grant delete on table "public"."interests" to "service_role";

grant insert on table "public"."interests" to "service_role";

grant references on table "public"."interests" to "service_role";

grant select on table "public"."interests" to "service_role";

grant trigger on table "public"."interests" to "service_role";

grant truncate on table "public"."interests" to "service_role";

grant update on table "public"."interests" to "service_role";

grant delete on table "public"."locations" to "anon";

grant insert on table "public"."locations" to "anon";

grant references on table "public"."locations" to "anon";

grant select on table "public"."locations" to "anon";

grant trigger on table "public"."locations" to "anon";

grant truncate on table "public"."locations" to "anon";

grant update on table "public"."locations" to "anon";

grant delete on table "public"."locations" to "authenticated";

grant insert on table "public"."locations" to "authenticated";

grant references on table "public"."locations" to "authenticated";

grant select on table "public"."locations" to "authenticated";

grant trigger on table "public"."locations" to "authenticated";

grant truncate on table "public"."locations" to "authenticated";

grant update on table "public"."locations" to "authenticated";

grant delete on table "public"."locations" to "service_role";

grant insert on table "public"."locations" to "service_role";

grant references on table "public"."locations" to "service_role";

grant select on table "public"."locations" to "service_role";

grant trigger on table "public"."locations" to "service_role";

grant truncate on table "public"."locations" to "service_role";

grant update on table "public"."locations" to "service_role";

grant delete on table "public"."profiles" to "anon";

grant insert on table "public"."profiles" to "anon";

grant references on table "public"."profiles" to "anon";

grant select on table "public"."profiles" to "anon";

grant trigger on table "public"."profiles" to "anon";

grant truncate on table "public"."profiles" to "anon";

grant update on table "public"."profiles" to "anon";

grant delete on table "public"."profiles" to "authenticated";

grant insert on table "public"."profiles" to "authenticated";

grant references on table "public"."profiles" to "authenticated";

grant select on table "public"."profiles" to "authenticated";

grant trigger on table "public"."profiles" to "authenticated";

grant truncate on table "public"."profiles" to "authenticated";

grant update on table "public"."profiles" to "authenticated";

grant delete on table "public"."profiles" to "service_role";

grant insert on table "public"."profiles" to "service_role";

grant references on table "public"."profiles" to "service_role";

grant select on table "public"."profiles" to "service_role";

grant trigger on table "public"."profiles" to "service_role";

grant truncate on table "public"."profiles" to "service_role";

grant update on table "public"."profiles" to "service_role";

grant delete on table "public"."role_history" to "anon";

grant insert on table "public"."role_history" to "anon";

grant references on table "public"."role_history" to "anon";

grant select on table "public"."role_history" to "anon";

grant trigger on table "public"."role_history" to "anon";

grant truncate on table "public"."role_history" to "anon";

grant update on table "public"."role_history" to "anon";

grant delete on table "public"."role_history" to "authenticated";

grant insert on table "public"."role_history" to "authenticated";

grant references on table "public"."role_history" to "authenticated";

grant select on table "public"."role_history" to "authenticated";

grant trigger on table "public"."role_history" to "authenticated";

grant truncate on table "public"."role_history" to "authenticated";

grant update on table "public"."role_history" to "authenticated";

grant delete on table "public"."role_history" to "service_role";

grant insert on table "public"."role_history" to "service_role";

grant references on table "public"."role_history" to "service_role";

grant select on table "public"."role_history" to "service_role";

grant trigger on table "public"."role_history" to "service_role";

grant truncate on table "public"."role_history" to "service_role";

grant update on table "public"."role_history" to "service_role";

grant delete on table "public"."role_requests" to "anon";

grant insert on table "public"."role_requests" to "anon";

grant references on table "public"."role_requests" to "anon";

grant select on table "public"."role_requests" to "anon";

grant trigger on table "public"."role_requests" to "anon";

grant truncate on table "public"."role_requests" to "anon";

grant update on table "public"."role_requests" to "anon";

grant delete on table "public"."role_requests" to "authenticated";

grant insert on table "public"."role_requests" to "authenticated";

grant references on table "public"."role_requests" to "authenticated";

grant select on table "public"."role_requests" to "authenticated";

grant trigger on table "public"."role_requests" to "authenticated";

grant truncate on table "public"."role_requests" to "authenticated";

grant update on table "public"."role_requests" to "authenticated";

grant delete on table "public"."role_requests" to "service_role";

grant insert on table "public"."role_requests" to "service_role";

grant references on table "public"."role_requests" to "service_role";

grant select on table "public"."role_requests" to "service_role";

grant trigger on table "public"."role_requests" to "service_role";

grant truncate on table "public"."role_requests" to "service_role";

grant update on table "public"."role_requests" to "service_role";

grant delete on table "public"."user_carrera" to "anon";

grant insert on table "public"."user_carrera" to "anon";

grant references on table "public"."user_carrera" to "anon";

grant select on table "public"."user_carrera" to "anon";

grant trigger on table "public"."user_carrera" to "anon";

grant truncate on table "public"."user_carrera" to "anon";

grant update on table "public"."user_carrera" to "anon";

grant delete on table "public"."user_carrera" to "authenticated";

grant insert on table "public"."user_carrera" to "authenticated";

grant references on table "public"."user_carrera" to "authenticated";

grant select on table "public"."user_carrera" to "authenticated";

grant trigger on table "public"."user_carrera" to "authenticated";

grant truncate on table "public"."user_carrera" to "authenticated";

grant update on table "public"."user_carrera" to "authenticated";

grant delete on table "public"."user_carrera" to "service_role";

grant insert on table "public"."user_carrera" to "service_role";

grant references on table "public"."user_carrera" to "service_role";

grant select on table "public"."user_carrera" to "service_role";

grant trigger on table "public"."user_carrera" to "service_role";

grant truncate on table "public"."user_carrera" to "service_role";

grant update on table "public"."user_carrera" to "service_role";

grant delete on table "public"."user_departamento" to "anon";

grant insert on table "public"."user_departamento" to "anon";

grant references on table "public"."user_departamento" to "anon";

grant select on table "public"."user_departamento" to "anon";

grant trigger on table "public"."user_departamento" to "anon";

grant truncate on table "public"."user_departamento" to "anon";

grant update on table "public"."user_departamento" to "anon";

grant delete on table "public"."user_departamento" to "authenticated";

grant insert on table "public"."user_departamento" to "authenticated";

grant references on table "public"."user_departamento" to "authenticated";

grant select on table "public"."user_departamento" to "authenticated";

grant trigger on table "public"."user_departamento" to "authenticated";

grant truncate on table "public"."user_departamento" to "authenticated";

grant update on table "public"."user_departamento" to "authenticated";

grant delete on table "public"."user_departamento" to "service_role";

grant insert on table "public"."user_departamento" to "service_role";

grant references on table "public"."user_departamento" to "service_role";

grant select on table "public"."user_departamento" to "service_role";

grant trigger on table "public"."user_departamento" to "service_role";

grant truncate on table "public"."user_departamento" to "service_role";

grant update on table "public"."user_departamento" to "service_role";

grant delete on table "public"."user_interests" to "anon";

grant insert on table "public"."user_interests" to "anon";

grant references on table "public"."user_interests" to "anon";

grant select on table "public"."user_interests" to "anon";

grant trigger on table "public"."user_interests" to "anon";

grant truncate on table "public"."user_interests" to "anon";

grant update on table "public"."user_interests" to "anon";

grant delete on table "public"."user_interests" to "authenticated";

grant insert on table "public"."user_interests" to "authenticated";

grant references on table "public"."user_interests" to "authenticated";

grant select on table "public"."user_interests" to "authenticated";

grant trigger on table "public"."user_interests" to "authenticated";

grant truncate on table "public"."user_interests" to "authenticated";

grant update on table "public"."user_interests" to "authenticated";

grant delete on table "public"."user_interests" to "service_role";

grant insert on table "public"."user_interests" to "service_role";

grant references on table "public"."user_interests" to "service_role";

grant select on table "public"."user_interests" to "service_role";

grant trigger on table "public"."user_interests" to "service_role";

grant truncate on table "public"."user_interests" to "service_role";

grant update on table "public"."user_interests" to "service_role";


  create policy "Anyone can read carreras"
  on "public"."carreras"
  as permissive
  for select
  to public
using (true);



  create policy "Anyone can read departamentos"
  on "public"."departamentos"
  as permissive
  for select
  to public
using (true);



  create policy "Organizer/Admin insert event_interests"
  on "public"."event_interests"
  as permissive
  for insert
  to authenticated
with check ((EXISTS ( SELECT 1
   FROM public.events e
  WHERE ((e.id = event_interests.event_id) AND ((e.organizer_id = auth.uid()) OR (( SELECT profiles.role
           FROM public.profiles
          WHERE (profiles.id = auth.uid())) = 'admin'::text))))));



  create policy "Read all event_interests"
  on "public"."event_interests"
  as permissive
  for select
  to authenticated
using (true);



  create policy "Organizadores y admins pueden ver registros"
  on "public"."event_registrations"
  as permissive
  for select
  to authenticated
using (((EXISTS ( SELECT 1
   FROM public.profiles
  WHERE ((profiles.id = auth.uid()) AND (profiles.role = 'admin'::text)))) OR (EXISTS ( SELECT 1
   FROM public.events
  WHERE ((events.id = event_registrations.event_id) AND (events.organizer_id = auth.uid()))))));



  create policy "Users read own registrations"
  on "public"."event_registrations"
  as permissive
  for select
  to authenticated
using ((auth.uid() = user_id));



  create policy "Users register themselves"
  on "public"."event_registrations"
  as permissive
  for insert
  to authenticated
with check ((auth.uid() = user_id));



  create policy "Users unregister themselves"
  on "public"."event_registrations"
  as permissive
  for delete
  to authenticated
using ((auth.uid() = user_id));



  create policy "Users update own registrations"
  on "public"."event_registrations"
  as permissive
  for update
  to authenticated
using ((auth.uid() = user_id))
with check ((auth.uid() = user_id));



  create policy "Organizer/Admin delete own events"
  on "public"."events"
  as permissive
  for delete
  to authenticated
using (((organizer_id = auth.uid()) OR (( SELECT profiles.role
   FROM public.profiles
  WHERE (profiles.id = auth.uid())) = 'admin'::text)));



  create policy "Organizer/Admin update own events"
  on "public"."events"
  as permissive
  for update
  to authenticated
using (((organizer_id = auth.uid()) OR (( SELECT profiles.role
   FROM public.profiles
  WHERE (profiles.id = auth.uid())) = 'admin'::text)))
with check (((organizer_id = auth.uid()) OR (( SELECT profiles.role
   FROM public.profiles
  WHERE (profiles.id = auth.uid())) = 'admin'::text)));



  create policy "Organizers and admins create events"
  on "public"."events"
  as permissive
  for insert
  to authenticated
with check (((( SELECT profiles.role
   FROM public.profiles
  WHERE (profiles.id = auth.uid())) = ANY (ARRAY['organizer'::text, 'admin'::text])) AND (organizer_id = auth.uid())));



  create policy "Read all events"
  on "public"."events"
  as permissive
  for select
  to authenticated
using (true);



  create policy "Public read interests"
  on "public"."interests"
  as permissive
  for select
  to public
using (true);



  create policy "Admins delete locations"
  on "public"."locations"
  as permissive
  for delete
  to authenticated
using ((( SELECT profiles.role
   FROM public.profiles
  WHERE (profiles.id = auth.uid())) = 'admin'::text));



  create policy "Admins insert locations"
  on "public"."locations"
  as permissive
  for insert
  to authenticated
with check ((( SELECT profiles.role
   FROM public.profiles
  WHERE (profiles.id = auth.uid())) = 'admin'::text));



  create policy "Admins update locations"
  on "public"."locations"
  as permissive
  for update
  to authenticated
using ((( SELECT profiles.role
   FROM public.profiles
  WHERE (profiles.id = auth.uid())) = 'admin'::text))
with check ((( SELECT profiles.role
   FROM public.profiles
  WHERE (profiles.id = auth.uid())) = 'admin'::text));



  create policy "Read all locations"
  on "public"."locations"
  as permissive
  for select
  to authenticated
using (true);



  create policy "Usuarios autenticados pueden ver todos los perfiles"
  on "public"."profiles"
  as permissive
  for select
  to authenticated
using (true);



  create policy "admins read profiles"
  on "public"."profiles"
  as permissive
  for select
  to authenticated
using (public.is_current_admin());



  create policy "admins update profiles"
  on "public"."profiles"
  as permissive
  for update
  to public
using (public.is_current_admin())
with check (public.is_current_admin());



  create policy "profiles insert own"
  on "public"."profiles"
  as permissive
  for insert
  to authenticated
with check ((auth.uid() = id));



  create policy "profiles select own"
  on "public"."profiles"
  as permissive
  for select
  to authenticated
using ((auth.uid() = id));



  create policy "profiles update own"
  on "public"."profiles"
  as permissive
  for update
  to authenticated
using ((auth.uid() = id))
with check ((auth.uid() = id));



  create policy "read own profile"
  on "public"."profiles"
  as permissive
  for select
  to authenticated
using ((id = auth.uid()));



  create policy "Admins can view all history"
  on "public"."role_history"
  as permissive
  for select
  to public
using ((EXISTS ( SELECT 1
   FROM public.profiles
  WHERE ((profiles.id = auth.uid()) AND (profiles.role = 'admin'::text)))));



  create policy "Users can view own history"
  on "public"."role_history"
  as permissive
  for select
  to public
using ((auth.uid() = user_id));



  create policy "Admins can update requests"
  on "public"."role_requests"
  as permissive
  for update
  to public
using (((auth.jwt() ->> 'role'::text) = ANY (ARRAY['service_role'::text, 'admin'::text])));



  create policy "Admins can update role requests"
  on "public"."role_requests"
  as permissive
  for update
  to public
using ((EXISTS ( SELECT 1
   FROM public.profiles
  WHERE ((profiles.id = auth.uid()) AND (profiles.role = 'admin'::text)))));



  create policy "Users can insert their own request"
  on "public"."role_requests"
  as permissive
  for insert
  to public
with check ((auth.uid() = user_id));



  create policy "Users can view their own requests"
  on "public"."role_requests"
  as permissive
  for select
  to public
using ((auth.uid() = user_id));



  create policy "admins read role requests"
  on "public"."role_requests"
  as permissive
  for select
  to authenticated
using (public.is_current_admin());



  create policy "read own role requests"
  on "public"."role_requests"
  as permissive
  for select
  to authenticated
using ((user_id = auth.uid()));



  create policy "Users can delete own user_carrera"
  on "public"."user_carrera"
  as permissive
  for delete
  to public
using ((auth.uid() = user_id));



  create policy "Users can insert own user_carrera"
  on "public"."user_carrera"
  as permissive
  for insert
  to public
with check ((auth.uid() = user_id));



  create policy "Users can read own user_carrera"
  on "public"."user_carrera"
  as permissive
  for select
  to public
using ((auth.uid() = user_id));



  create policy "Users can update own user_carrera"
  on "public"."user_carrera"
  as permissive
  for update
  to public
using ((auth.uid() = user_id))
with check ((auth.uid() = user_id));



  create policy "Users can delete own user_departamento"
  on "public"."user_departamento"
  as permissive
  for delete
  to public
using ((auth.uid() = user_id));



  create policy "Users can insert own user_departamento"
  on "public"."user_departamento"
  as permissive
  for insert
  to public
with check ((auth.uid() = user_id));



  create policy "Users can read own user_departamento"
  on "public"."user_departamento"
  as permissive
  for select
  to public
using ((auth.uid() = user_id));



  create policy "Users can update own user_departamento"
  on "public"."user_departamento"
  as permissive
  for update
  to public
using ((auth.uid() = user_id))
with check ((auth.uid() = user_id));



  create policy "Users can delete own interests"
  on "public"."user_interests"
  as permissive
  for delete
  to public
using ((auth.uid() = user_id));



  create policy "Users can insert own interests"
  on "public"."user_interests"
  as permissive
  for insert
  to public
with check ((auth.uid() = user_id));



  create policy "Users can read own interests"
  on "public"."user_interests"
  as permissive
  for select
  to public
using ((auth.uid() = user_id));


CREATE TRIGGER events_updated_at_trigger BEFORE UPDATE ON public.events FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER on_role_change AFTER UPDATE OF role ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.track_role_changes();

CREATE TRIGGER role_requests_set_updated_at BEFORE UPDATE ON public.role_requests FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


  create policy "Admin deletes any event image"
  on "storage"."objects"
  as permissive
  for delete
  to authenticated
using (((bucket_id = 'event-images'::text) AND (EXISTS ( SELECT 1
   FROM public.profiles p
  WHERE ((p.id = auth.uid()) AND (p.role = 'admin'::text))))));



  create policy "Admin updates any event image"
  on "storage"."objects"
  as permissive
  for update
  to authenticated
using (((bucket_id = 'event-images'::text) AND (EXISTS ( SELECT 1
   FROM public.profiles p
  WHERE ((p.id = auth.uid()) AND (p.role = 'admin'::text))))))
with check ((bucket_id = 'event-images'::text));



  create policy "Anyone can upload an avatar."
  on "storage"."objects"
  as permissive
  for insert
  to public
with check ((bucket_id = 'avatars'::text));



  create policy "Avatar images are publicly accessible."
  on "storage"."objects"
  as permissive
  for select
  to public
using ((bucket_id = 'avatars'::text));



  create policy "Organizer deletes own event images"
  on "storage"."objects"
  as permissive
  for delete
  to authenticated
using (((bucket_id = 'event-images'::text) AND ((storage.foldername(name))[1] = (auth.uid())::text) AND (EXISTS ( SELECT 1
   FROM public.profiles p
  WHERE ((p.id = auth.uid()) AND (p.role = ANY (ARRAY['organizer'::text, 'admin'::text])))))));



  create policy "Organizer updates own event images"
  on "storage"."objects"
  as permissive
  for update
  to authenticated
using (((bucket_id = 'event-images'::text) AND ((storage.foldername(name))[1] = (auth.uid())::text) AND (EXISTS ( SELECT 1
   FROM public.profiles p
  WHERE ((p.id = auth.uid()) AND (p.role = ANY (ARRAY['organizer'::text, 'admin'::text])))))))
with check (((bucket_id = 'event-images'::text) AND ((storage.foldername(name))[1] = (auth.uid())::text)));



  create policy "Public read event images"
  on "storage"."objects"
  as permissive
  for select
  to public
using ((bucket_id = 'event-images'::text));



  create policy "Upload event images to own folder (organizer/admin)"
  on "storage"."objects"
  as permissive
  for insert
  to authenticated
with check (((bucket_id = 'event-images'::text) AND ((storage.foldername(name))[1] = (auth.uid())::text) AND (EXISTS ( SELECT 1
   FROM public.profiles p
  WHERE ((p.id = auth.uid()) AND (p.role = ANY (ARRAY['organizer'::text, 'admin'::text])))))));




