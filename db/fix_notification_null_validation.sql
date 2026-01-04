-- ============================================================
-- FIX: Validación de user_id NULL en funciones de notificación
-- ============================================================
-- Este script agrega validaciones para prevenir inserts con user_id NULL
-- en la tabla notification_jobs
-- ============================================================

-- Función 1: enqueue_event_update
-- Agrega validación en el loop para saltarse user_id NULL
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
    -- ✅ VALIDACIÓN: Saltarse si user_id es NULL
    IF reg.user_id IS NOT NULL THEN
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
    ELSE
      RAISE LOG 'Saltando notificación para registro con user_id NULL en evento %', NEW.id;
    END IF;
  END LOOP;

  RETURN NEW;
END;
$function$;


-- Función 2: enqueue_registration_notifications
-- Agrega validación temprana y corrige combinación de date+time
CREATE OR REPLACE FUNCTION public.enqueue_registration_notifications()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  ev RECORD;
  reminder_at timestamptz;
  event_dt timestamptz;
BEGIN
  RAISE LOG 'enqueue_registration_notifications disparado para registro: %', NEW.id;
  
  -- ✅ VALIDACIÓN TEMPRANA: Si user_id es NULL, salir
  IF NEW.user_id IS NULL THEN
    RAISE LOG 'user_id es NULL en registro %, saltando notificaciones', NEW.id;
    RETURN NEW;
  END IF;
  
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

  -- ✅ CORRECCIÓN: Combinar date+time correctamente
  -- Convertir date a timestamp primero, luego sumar time, luego convertir a timestamptz
  event_dt := (ev.event_date::timestamp + ev.event_time)::timestamptz;
  reminder_at := event_dt - interval '1 hour';
  
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
$function$;


-- Función 3: enqueue_role_request_notifications
-- Agrega validación en el loop
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
    -- ✅ VALIDACIÓN: Saltarse si id es NULL
    IF admin_rec.id IS NOT NULL THEN
      INSERT INTO public.notification_jobs (user_id, type, payload, scheduled_at)
      VALUES (
        admin_rec.id,
        'role_request',
        jsonb_build_object(
          'request_id', NEW.id,
          'user_id', NEW.user_id,
          'requested_role', NEW.requested_role,
          'message', NEW.message,
          'created_at', NEW.created_at,
          'status', NEW.status
        ),
        now()
      );
      RAISE LOG 'Notificación de solicitud de rol enviada al admin %', admin_rec.id;
    ELSE
      RAISE LOG 'Saltando notificación para admin con id NULL';
    END IF;
  END LOOP;

  RETURN NEW;
END;
$function$;
