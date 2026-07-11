# Panel administrador — plan de arquitectura

> Estado: **base de datos implementada** (migraciones + RLS + seed). La app del
> panel y el consumo del sitio público están **pendientes** de: (a) credenciales
> del Supabase Self-Hosted, (b) exponer el schema en la VPS, (c) decisión de
> framework/deploy y que Vercel vuelva a desplegar. Ver "Bloqueos" abajo.

## Enfoque recomendado (refactor gradual y seguro)

El sitio público **no tiene fuente** — es un bundle compilado. Reescribirlo
entero para consumir Supabase es riesgoso (se puede perder la apariencia). Por
eso proponemos un refactor **gradual**:

1. **Panel** como app propia bajo `/admin` (Next.js App Router, TypeScript,
   `@supabase/supabase-js` apuntando explícitamente a `schema('altamagiadaniel')`).
   Rutas protegidas reales (validación de sesión + `admin_profiles` activo en
   cada acceso, no solo ocultando componentes).
2. **Sitio público**: en lugar de rehacer el bundle, se reemplazan
   progresivamente los *arrays de datos embebidos* (servicios, catálogo,
   trabajos, redes, textos) por lecturas a Supabase vía un pequeño loader JS,
   conservando exactamente el diseño negro/dorado, las tipografías (Cinzel,
   Cormorant Garamond, Great Vibes), animaciones y responsive. Con fallback al
   contenido actual si Supabase no responde.

## Autenticación (`/admin/login`)

- Supabase Auth (email + password). Diseño negro/dorado, logo MD, tarjeta
  elegante, mostrar/ocultar contraseña, estados de carga y error, responsive,
  botón "volver al sitio".
- Flujo: login → verificar `admin_profiles` activo → si no, cerrar sesión y
  "No tienes acceso al panel administrativo"; si sí, actualizar `last_login_at`
  y redirigir a `/admin`.
- Recuperación de contraseña, cierre de sesión, sesión persistente/segura,
  manejo de expiración.

## Módulos del panel (`/admin`)

Dashboard · Portada · Sobre mí · Servicios · Tarot · Catálogo (Categorías /
Productos) · Trabajos · Testimonios · Redes sociales · Navegación ·
Configuración · Mensajes · Administradores (solo `super_admin`).

Cada módulo: listado, búsqueda/filtros, crear, editar, activar/desactivar,
destacar, reordenar (`sort_order`), vista previa, eliminar con confirmación
(borrado permanente solo `super_admin`), carga de imágenes, validación,
notificaciones. Editor de texto enriquecido **sanitizado** (negrita, cursiva,
listas, enlaces) para descripciones largas.

## Storage

Bucket `altamagiadaniel-media` con carpetas `site/ hero/ about/ services/
products/ works/ testimonials/ admin/`. Validar MIME, tamaño, extensión, nombre
seguro y nombres únicos. Admins suben/borran; el público lee. Nada de base64
pesado en Postgres.

## Roles

`super_admin` (todo + admins + config) · `admin` (contenido + borrar) ·
`editor` (crear/editar, sin borrado permanente ni gestión de admins). Las reglas
se aplican en **RLS** (ver `DATABASE.md`), no solo en la UI.

## Bloqueos actuales (requieren acción del cliente / Neura)

1. **Credenciales del Supabase Self-Hosted**: `NEXT_PUBLIC_SUPABASE_URL`,
   `NEXT_PUBLIC_SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_DB_URL`
   (por canal seguro, nunca al repo).
2. **Correr migraciones + exponer el schema** en la VPS (`exponer-schema.sh`).
3. **Decisión de framework/deploy** para `/admin` (Next.js recomendado) y que
   **Vercel vuelva a desplegar** (incidencia 404 actual).
4. **Crear el primer `super_admin`** (ver `DATABASE.md`).
