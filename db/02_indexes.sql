-- ================================================
-- ÍNDICES PARA OPTIMIZACIÓN
-- ================================================

-- Índices únicos (PRIMARY KEYS)
CREATE UNIQUE INDEX carreras_pkey ON public.carreras USING btree (id);
CREATE UNIQUE INDEX departamentos_pkey ON public.departamentos USING btree (id);
CREATE UNIQUE INDEX event_interests_pkey ON public.event_interests USING btree (event_id, interest_id);
CREATE UNIQUE INDEX event_registrations_pkey ON public.event_registrations USING btree (id);
CREATE UNIQUE INDEX events_pkey ON public.events USING btree (id);
CREATE UNIQUE INDEX interests_pkey ON public.interests USING btree (id);
CREATE UNIQUE INDEX locations_pkey ON public.locations USING btree (id);
CREATE UNIQUE INDEX profiles_pkey ON public.profiles USING btree (id);
CREATE UNIQUE INDEX role_history_pkey ON public.role_history USING btree (id);
CREATE UNIQUE INDEX role_requests_pkey ON public.role_requests USING btree (id);
CREATE UNIQUE INDEX user_carrera_pkey ON public.user_carrera USING btree (id);
CREATE UNIQUE INDEX user_departamento_pkey ON public.user_departamento USING btree (id);
CREATE UNIQUE INDEX user_interests_pkey ON public.user_interests USING btree (id);

-- Índices únicos (UNIQUE CONSTRAINTS)
CREATE UNIQUE INDEX carreras_name_key ON public.carreras USING btree (name);
CREATE UNIQUE INDEX departamentos_name_key ON public.departamentos USING btree (name);
CREATE UNIQUE INDEX locations_name_key ON public.locations USING btree (name);
CREATE UNIQUE INDEX profiles_username_key ON public.profiles USING btree (username);
CREATE UNIQUE INDEX role_requests_user_id_key ON public.role_requests USING btree (user_id);
CREATE UNIQUE INDEX user_carrera_user_id_carrera_id_key ON public.user_carrera USING btree (user_id, carrera_id);
CREATE UNIQUE INDEX user_departamento_user_id_departamento_id_key ON public.user_departamento USING btree (user_id, departamento_id);
CREATE UNIQUE INDEX user_interests_user_id_interest_id_key ON public.user_interests USING btree (user_id, interest_id);
CREATE UNIQUE INDEX ux_event_registrations_event_user ON public.event_registrations USING btree (event_id, user_id);

-- Índices de performance
CREATE INDEX idx_event_interests_event ON public.event_interests USING btree (event_id);
CREATE INDEX idx_event_interests_interest ON public.event_interests USING btree (interest_id);
CREATE INDEX idx_event_registrations_event_id ON public.event_registrations USING btree (event_id);
CREATE INDEX idx_event_registrations_user_id ON public.event_registrations USING btree (user_id);
CREATE INDEX idx_events_event_datetime ON public.events USING btree (event_datetime);
CREATE INDEX idx_events_organizer_id ON public.events USING btree (organizer_id);
CREATE INDEX idx_role_history_user ON public.role_history USING btree (user_id, changed_at DESC);
CREATE INDEX idx_role_requests_user_id ON public.role_requests USING btree (user_id);
