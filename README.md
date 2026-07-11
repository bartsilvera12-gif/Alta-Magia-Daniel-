# Alta Magia Daniel

Sitio web oficial de **Alta Magia Daniel** — Tarot y Trabajos Espirituales (Paraguay).
Página negra y dorada, mística y elegante, con contacto directo por WhatsApp.

## Estructura del repo

```
index.html                 # sitio público (bundle React compilado + parches __amd*)
servicios/ catalogo/        # rutas físicas (index.html propio con su data JS)
politicadeprivacidad/
*.jpg *.png *.mp4           # imágenes / videos / favicon
supabase/
  migrations/              # 0001 schema · 0002 RLS (schema aislado altamagiadaniel)
  seed/                    # 0001 seed del contenido actual (idempotente)
  create_first_admin.sql   # vincular primer super_admin (sin passwords)
docs/                      # DATABASE.md · DEPLOYMENT.md · ADMIN_PANEL.md
.env.example               # variables (Supabase Self-Hosted) — sin secretos
```

## Panel administrador (en curso — rama `feature/admin-panel-supabase`)

Se está incorporando un panel en `/admin` con **Supabase Self-Hosted** y un
schema PostgreSQL aislado `altamagiadaniel`. Estado y arquitectura:
[`docs/ADMIN_PANEL.md`](docs/ADMIN_PANEL.md). Base de datos:
[`docs/DATABASE.md`](docs/DATABASE.md). Despliegue:
[`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md).

- Todas las tablas viven en `altamagiadaniel` (nunca en `public`).
- Auth con `auth.users`; enlace vía `altamagiadaniel.admin_profiles.user_id`.
- RLS: público solo lee `is_active`; escritura solo admins activos por rol.
- Secretos por `.env` (git-ignored); la `service_role` nunca va al navegador.

## Variables de entorno

Copiá `.env.example` → `.env` y completá con tu Supabase. Ver `docs/DATABASE.md`
para correr migraciones/seed y exponer el schema.

## Contacto

WhatsApp: +595 972 542230
