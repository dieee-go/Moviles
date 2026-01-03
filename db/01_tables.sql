-- ================================================
-- TABLAS DE LA BASE DE DATOS
-- ================================================

-- Extensiones
drop extension if exists "pg_net";

-- ================================================
-- TABLAS CATÁLOGO
-- ================================================

-- Carreras académicas
create table "public"."carreras" (
  "id" uuid not null default gen_random_uuid(),
  "name" text not null,
  "created_at" timestamp with time zone default now(),
  "updated_at" timestamp with time zone default now()
);

alter table "public"."carreras" enable row level security;

-- Departamentos institucionales
create table "public"."departamentos" (
  "id" uuid not null default gen_random_uuid(),
  "name" text not null,
  "created_at" timestamp with time zone default now(),
  "updated_at" timestamp with time zone default now()
);

alter table "public"."departamentos" enable row level security;

-- Intereses/Categorías
create table "public"."interests" (
  "id" uuid not null default gen_random_uuid(),
  "name" text not null
);

alter table "public"."interests" enable row level security;

-- Ubicaciones
create table "public"."locations" (
  "id" uuid not null default gen_random_uuid(),
  "name" text not null,
  "created_at" timestamp with time zone default now()
);

alter table "public"."locations" enable row level security;

-- ================================================
-- TABLA DE PERFILES
-- ================================================

create table "public"."profiles" (
  "id" uuid not null,
  "updated_at" timestamp with time zone,
  "username" text,
  "email" text,
  "nombre" text,
  "primer_apellido" text,
  "verified" boolean default false,
  "created_at" timestamp without time zone default now(),
  "avatar_url" text,
  "website" text,
  "segundo_apellido" text,
  "telefono" text,
  "role" text default 'student'::text
);

alter table "public"."profiles" enable row level security;

-- ================================================
-- TABLAS DE EVENTOS
-- ================================================

create table "public"."events" (
  "id" uuid not null default gen_random_uuid(),
  "name" text not null,
  "description" text,
  "capacity" integer default 0,
  "image_url" text,
  "organizer_id" uuid not null,
  "event_datetime" timestamp with time zone not null,
  "location_id" uuid,
  "created_at" timestamp with time zone default now(),
  "updated_at" timestamp with time zone default now(),
  "status" text not null default 'active'::text
);

alter table "public"."events" enable row level security;

-- Relación eventos-intereses
create table "public"."event_interests" (
  "event_id" uuid not null,
  "interest_id" uuid not null
);

alter table "public"."event_interests" enable row level security;

-- Registros de usuarios a eventos
create table "public"."event_registrations" (
  "id" uuid not null default gen_random_uuid(),
  "event_id" uuid not null,
  "user_id" uuid not null,
  "registration_datetime" timestamp with time zone not null default now(),
  "checked_in_at" timestamp with time zone
);

alter table "public"."event_registrations" enable row level security;

-- ================================================
-- TABLAS DE USUARIOS (RELACIONES)
-- ================================================

-- Relación usuario-carrera
create table "public"."user_carrera" (
  "id" uuid not null default gen_random_uuid(),
  "user_id" uuid not null,
  "carrera_id" uuid not null,
  "created_at" timestamp with time zone default now()
);

alter table "public"."user_carrera" enable row level security;

-- Relación usuario-departamento
create table "public"."user_departamento" (
  "id" uuid not null default gen_random_uuid(),
  "user_id" uuid not null,
  "departamento_id" uuid not null,
  "created_at" timestamp with time zone default now()
);

alter table "public"."user_departamento" enable row level security;

-- Relación usuario-intereses
create table "public"."user_interests" (
  "id" uuid not null default gen_random_uuid(),
  "user_id" uuid not null,
  "interest_id" uuid not null,
  "created_at" timestamp with time zone default now()
);

alter table "public"."user_interests" enable row level security;

-- ================================================
-- TABLAS DE ROLES
-- ================================================

-- Historial de cambios de rol
create table "public"."role_history" (
  "id" uuid not null default gen_random_uuid(),
  "user_id" uuid not null,
  "role" text not null,
  "action" text not null,
  "changed_at" timestamp with time zone default now(),
  "changed_by" uuid,
  "notes" text
);

alter table "public"."role_history" enable row level security;

-- Solicitudes de cambio de rol
create table "public"."role_requests" (
  "id" uuid not null default gen_random_uuid(),
  "user_id" uuid not null,
  "status" text not null default 'pending'::text,
  "message" text,
  "created_at" timestamp with time zone not null default now(),
  "updated_at" timestamp with time zone not null default now()
);

alter table "public"."role_requests" enable row level security;
