# SGVC – Sistema de Gestión de Contratos y Control de Vencimientos

Proyecto de grado – Ingeniería de Sistemas, UNIFRANZ (El Alto).
Caso de aplicación: Gobierno Autónomo Municipal de Viacha.

## Estructura
- `db/01_schema.sql` – esquema PostgreSQL (12 tablas, PK/FK, CHECK, índices)
- `db/02_seed.sql` – datos de prueba
- `db/03_queries.sql` – vista y consultas SELECT del proyecto
- `docs/modelo-relacional.md` – modelo relacional y decisiones de diseño
- `docs/diagrama-er.png` – diagrama entidad-relación

## Ejecutar
```bash
createdb sgvc
psql -d sgvc -f db/01_schema.sql
psql -d sgvc -f db/02_seed.sql
psql -d sgvc -f db/03_queries.sql
```

## Flujo de ramas
`main` (estable) ← `develop` (integración) ← `feature/*` (trabajo).
