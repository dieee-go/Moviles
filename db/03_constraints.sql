-- ================================================
-- CONSTRAINTS (Primary Keys, Foreign Keys, Uniques, Checks)
-- ================================================

-- ================================================
-- PRIMARY KEYS
-- ================================================
alter table "public"."carreras" add constraint "carreras_pkey" PRIMARY KEY using index "carreras_pkey";
alter table "public"."departamentos" add constraint "departamentos_pkey" PRIMARY KEY using index "departamentos_pkey";
alter table "public"."event_interests" add constraint "event_interests_pkey" PRIMARY KEY using index "event_interests_pkey";
alter table "public"."event_registrations" add constraint "event_registrations_pkey" PRIMARY KEY using index "event_registrations_pkey";
alter table "public"."events" add constraint "events_pkey" PRIMARY KEY using index "events_pkey";
alter table "public"."interests" add constraint "interests_pkey" PRIMARY KEY using index "interests_pkey";
alter table "public"."locations" add constraint "locations_pkey" PRIMARY KEY using index "locations_pkey";
alter table "public"."profiles" add constraint "profiles_pkey" PRIMARY KEY using index "profiles_pkey";
alter table "public"."role_history" add constraint "role_history_pkey" PRIMARY KEY using index "role_history_pkey";
alter table "public"."role_requests" add constraint "role_requests_pkey" PRIMARY KEY using index "role_requests_pkey";
alter table "public"."user_carrera" add constraint "user_carrera_pkey" PRIMARY KEY using index "user_carrera_pkey";
alter table "public"."user_departamento" add constraint "user_departamento_pkey" PRIMARY KEY using index "user_departamento_pkey";
alter table "public"."user_interests" add constraint "user_interests_pkey" PRIMARY KEY using index "user_interests_pkey";

-- ================================================
-- UNIQUE CONSTRAINTS
-- ================================================
alter table "public"."carreras" add constraint "carreras_name_key" UNIQUE using index "carreras_name_key";
alter table "public"."departamentos" add constraint "departamentos_name_key" UNIQUE using index "departamentos_name_key";
alter table "public"."locations" add constraint "locations_name_key" UNIQUE using index "locations_name_key";
alter table "public"."profiles" add constraint "profiles_username_key" UNIQUE using index "profiles_username_key";
alter table "public"."role_requests" add constraint "role_requests_user_id_key" UNIQUE using index "role_requests_user_id_key";
alter table "public"."user_carrera" add constraint "user_carrera_user_id_carrera_id_key" UNIQUE using index "user_carrera_user_id_carrera_id_key";
alter table "public"."user_departamento" add constraint "user_departamento_user_id_departamento_id_key" UNIQUE using index "user_departamento_user_id_departamento_id_key";
alter table "public"."user_interests" add constraint "user_interests_user_id_interest_id_key" UNIQUE using index "user_interests_user_id_interest_id_key";

-- ================================================
-- FOREIGN KEYS
-- ================================================

-- event_interests
alter table "public"."event_interests" add constraint "event_interests_event_id_fkey" FOREIGN KEY (event_id) REFERENCES public.events(id) ON DELETE CASCADE not valid;
alter table "public"."event_interests" validate constraint "event_interests_event_id_fkey";

alter table "public"."event_interests" add constraint "event_interests_interest_id_fkey" FOREIGN KEY (interest_id) REFERENCES public.interests(id) ON DELETE CASCADE not valid;
alter table "public"."event_interests" validate constraint "event_interests_interest_id_fkey";

-- event_registrations
alter table "public"."event_registrations" add constraint "event_registrations_event_id_fkey" FOREIGN KEY (event_id) REFERENCES public.events(id) ON DELETE CASCADE not valid;
alter table "public"."event_registrations" validate constraint "event_registrations_event_id_fkey";

alter table "public"."event_registrations" add constraint "event_registrations_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE not valid;
alter table "public"."event_registrations" validate constraint "event_registrations_user_id_fkey";

-- events
alter table "public"."events" add constraint "events_location_id_fkey" FOREIGN KEY (location_id) REFERENCES public.locations(id) ON DELETE SET NULL not valid;
alter table "public"."events" validate constraint "events_location_id_fkey";

alter table "public"."events" add constraint "events_organizer_id_fkey" FOREIGN KEY (organizer_id) REFERENCES public.profiles(id) ON DELETE CASCADE not valid;
alter table "public"."events" validate constraint "events_organizer_id_fkey";

-- profiles
alter table "public"."profiles" add constraint "profiles_id_fkey" FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;
alter table "public"."profiles" validate constraint "profiles_id_fkey";

-- role_history
alter table "public"."role_history" add constraint "role_history_changed_by_fkey" FOREIGN KEY (changed_by) REFERENCES auth.users(id) not valid;
alter table "public"."role_history" validate constraint "role_history_changed_by_fkey";

alter table "public"."role_history" add constraint "role_history_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;
alter table "public"."role_history" validate constraint "role_history_user_id_fkey";

-- role_requests
alter table "public"."role_requests" add constraint "role_requests_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE not valid;
alter table "public"."role_requests" validate constraint "role_requests_user_id_fkey";

-- user_carrera
alter table "public"."user_carrera" add constraint "user_carrera_carrera_id_fkey" FOREIGN KEY (carrera_id) REFERENCES public.carreras(id) ON DELETE CASCADE not valid;
alter table "public"."user_carrera" validate constraint "user_carrera_carrera_id_fkey";

alter table "public"."user_carrera" add constraint "user_carrera_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;
alter table "public"."user_carrera" validate constraint "user_carrera_user_id_fkey";

-- user_departamento
alter table "public"."user_departamento" add constraint "user_departamento_departamento_id_fkey" FOREIGN KEY (departamento_id) REFERENCES public.departamentos(id) ON DELETE CASCADE not valid;
alter table "public"."user_departamento" validate constraint "user_departamento_departamento_id_fkey";

alter table "public"."user_departamento" add constraint "user_departamento_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;
alter table "public"."user_departamento" validate constraint "user_departamento_user_id_fkey";

-- user_interests
alter table "public"."user_interests" add constraint "user_interests_interest_id_fkey" FOREIGN KEY (interest_id) REFERENCES public.interests(id) ON DELETE CASCADE not valid;
alter table "public"."user_interests" validate constraint "user_interests_interest_id_fkey";

alter table "public"."user_interests" add constraint "user_interests_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE not valid;
alter table "public"."user_interests" validate constraint "user_interests_user_id_fkey";

-- ================================================
-- CHECK CONSTRAINTS
-- ================================================

-- profiles
alter table "public"."profiles" add constraint "profiles_role_check" CHECK (((role IS NULL) OR (role = ANY (ARRAY['student'::text, 'organizer'::text, 'admin'::text])))) not valid;
alter table "public"."profiles" validate constraint "profiles_role_check";

alter table "public"."profiles" add constraint "username_length" CHECK ((char_length(username) >= 3)) not valid;
alter table "public"."profiles" validate constraint "username_length";

-- role_history
alter table "public"."role_history" add constraint "role_history_action_check" CHECK ((action = ANY (ARRAY['granted'::text, 'revoked'::text]))) not valid;
alter table "public"."role_history" validate constraint "role_history_action_check";

alter table "public"."role_history" add constraint "valid_role" CHECK ((role = ANY (ARRAY['student'::text, 'organizer'::text, 'admin'::text]))) not valid;
alter table "public"."role_history" validate constraint "valid_role";

-- role_requests
alter table "public"."role_requests" add constraint "role_requests_status_check" CHECK ((status = ANY (ARRAY['pending'::text, 'approved'::text, 'rejected'::text, 'revoked'::text]))) not valid;
alter table "public"."role_requests" validate constraint "role_requests_status_check";
