# Base de datos — `altamagiadaniel`

Todo el modelo vive en un **schema PostgreSQL aislado** llamado `altamagiadaniel`
dentro del Supabase Self-Hosted de Neura. **Nada** se crea en `public`. La
autenticación sigue usando `auth.users`; el vínculo es
`altamagiadaniel.admin_profiles.user_id → auth.users.id`.

> No se usa `company_id` / `tenant_id`: el aislamiento es por schema.

## Migraciones

```
supabase/migrations/0001_init_altamagiadaniel_schema.sql   -- schema, función set_updated_at, 18 tablas, constraints, índices, triggers
supabase/migrations/0002_altamagiadaniel_rls.sql           -- funciones de rol + RLS + grants
supabase/seed/0001_altamagiadaniel_seed.sql                -- contenido actual del sitio (idempotente)
```

Ejecutar (en orden), usando la conexión directa de Postgres:

```bash
psql "$SUPABASE_DB_URL" -f supabase/migrations/0001_init_altamagiadaniel_schema.sql
psql "$SUPABASE_DB_URL" -f supabase/migrations/0002_altamagiadaniel_rls.sql
psql "$SUPABASE_DB_URL" -f supabase/seed/0001_altamagiadaniel_seed.sql
```

Todo es **idempotente** (`create ... if not exists`, `on conflict`, guards
`where not exists`): correr dos veces no duplica ni rompe.

## Tablas (18)

| Tabla | Uso |
|---|---|
| `admin_profiles` | administradores (rol) enlazados a `auth.users`. Sin password. |
| `site_settings` | config general, WhatsApp, footer, SEO (una fila activa). |
| `navigation_items` | menú del header. |
| `hero_slides` | portada. |
| `about_sections` | "Sobre mí". |
| `service_categories`, `services`, `service_gallery` | servicios + galería. |
| `tarot_services` | modalidades de tarot (precios ocultos). |
| `product_categories`, `products`, `product_images`, `product_attributes` | catálogo. |
| `works` | trabajos realizados (videos). |
| `testimonials` | testimonios. |
| `social_links` | TikTok / WhatsApp / Instagram / etc. |
| `contact_messages` | formulario de contacto (insert público, lectura solo admin). |
| `page_sections` | bloques genéricos (JSONB) para lo que no encaje en una tabla específica. |

Columnas comunes (cuando aplican): `id uuid pk`, `created_at`, `updated_at`,
`created_by`, `updated_by`, `is_active`, `sort_order`. `updated_at` se actualiza
por trigger `altamagiadaniel.set_updated_at()`.

## Seguridad (RLS)

- **Público (anon):** solo `SELECT` de filas `is_active = true`. Puede `INSERT`
  en `contact_messages` (no leerlo). Sin acceso administrativo.
- **Admin (`authenticated` con fila activa en `admin_profiles`):**
  - `editor`: ver todo + crear + editar (sin borrado permanente).
  - `admin`: + borrar.
  - `super_admin`: + gestionar `admin_profiles` / configuración.
- El rol se deriva **en el servidor** con `altamagiadaniel.current_admin_role()`
  y `altamagiadaniel.is_admin()` (`SECURITY DEFINER`, `search_path = ''`). Nunca
  se confía en un rol enviado por el cliente.
- `anon` **no** recibe `GRANT ALL`; solo `SELECT` en tablas públicas e `INSERT`
  en `contact_messages`.

## Exponer el schema a PostgREST (Fase 21)

En la VPS de Supabase (Neura), con el script existente — **no** editar la lista
a mano, **no** usar Coolify:

```bash
cd /root/supabase/docker
./exponer-schema.sh altamagiadaniel
grep '^PGRST_DB_SCHEMAS=' .env
docker compose exec rest env | grep PGRST_DB_SCHEMAS
docker compose logs rest --tail=100
```

El schema debe **existir** (correr las migraciones) antes de exponerlo.

## Primer administrador (Fase 22)

1. Crear el usuario en **Supabase Auth** (Dashboard → Authentication → Add user).
2. Vincularlo como `super_admin`:

```bash
psql "$SUPABASE_DB_URL" -v email='daniel@altamagiadaniel.com' \
     -f supabase/create_first_admin.sql
```

Nunca insertar contraseñas por SQL ni usar credenciales por defecto.
