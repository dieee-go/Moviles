# Database Schema Documentation

Esta carpeta contiene el esquema completo de la base de datos organizado por secciones.

## Archivos

1. **01_tables.sql** - Definiciones de todas las tablas
2. **02_indexes.sql** - Índices para optimizar consultas
3. **03_constraints.sql** - Constraints (PKs, FKs, UNIQUEs, CHECKs)
4. **04_functions.sql** - Funciones de PostgreSQL
5. **05_triggers.sql** - Triggers automáticos
6. **06_permissions.sql** - Grants y permisos de usuarios
7. **07_rls_policies.sql** - Row Level Security policies
8. **08_storage_policies.sql** - Políticas de Storage

## Orden de ejecución

Para recrear la base de datos desde cero, ejecuta los archivos en orden:

```bash
psql -U postgres -d mydb -f 01_tables.sql
psql -U postgres -d mydb -f 02_indexes.sql
psql -U postgres -d mydb -f 03_constraints.sql
psql -U postgres -d mydb -f 04_functions.sql
psql -U postgres -d mydb -f 05_triggers.sql
psql -U postgres -d mydb -f 06_permissions.sql
psql -U postgres -d mydb -f 07_rls_policies.sql
psql -U postgres -d mydb -f 08_storage_policies.sql
```

## Tablas principales

- **profiles** - Perfiles de usuario
- **events** - Eventos del sistema
- **event_registrations** - Registro de usuarios a eventos
- **interests** - Categorías/intereses
- **event_interests** - Relación eventos-intereses
- **locations** - Ubicaciones físicas
- **carreras** - Carreras académicas (estudiantes)
- **departamentos** - Departamentos (organizadores)
- **user_carrera** - Relación usuario-carrera
- **user_departamento** - Relación usuario-departamento
- **user_interests** - Intereses de usuarios
- **role_requests** - Solicitudes de cambio de rol
- **role_history** - Historial de cambios de rol
