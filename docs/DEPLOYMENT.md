# Despliegue

## Estado actual (sitio público)

- **Sitio 100% estático** servido por **Vercel** desde este repo (push a `main`
  → deploy automático). Rutas físicas por carpeta: `/`, `/servicios/`,
  `/catalogo/`, `/politicadeprivacidad/` (cada una un `index.html`).
- `index.html` es un **bundle compilado** (React empaquetado como manifiesto
  base64 + template, decodificado en runtime) más parches DOM `__amd*`.
- **No hay** `package.json` ni build: Vercel sirve los archivos tal cual.

### ⚠️ Incidencia activa de Vercel
Al momento de este trabajo, `alta-magia-daniel.vercel.app` devuelve
`404 DEPLOYMENT_NOT_FOUND`: se alcanzó el **límite diario de deploys del plan
gratuito** y el deployment de producción quedó huérfano. Se restablece al
reiniciarse el límite (~24 h), re-importando el repo en Vercel, o subiendo de
plan. El código está intacto en Git; no se perdió nada.

Servidor local para previsualizar mientras tanto (script en el repo de sesión):
`http://127.0.0.1:8791/`.

## Rutas y fallback

El hosting **no** resuelve todas las rutas igual. Reglas:

- Rutas con carpeta física + `index.html` funcionan directo y al recargar
  (Vercel sirve `/x/` → `/x/index.html`).
- `/admin/login`, `/admin/...` deben **funcionar al recargar directamente**.
  - Si el panel se sirve como **app aparte** (Next.js/Vite bajo `/admin`), usar
    su router + config de rewrites del proveedor.
  - Si se sirve estático, agregar `index.html` físicos o un `vercel.json` con
    rewrite de `/admin/(.*)` → el entrypoint del panel.
- Auditar el deploy real (Vercel/Coolify/Nginx) antes de asumir el fallback.

## Base de datos / Supabase

Ver [`DATABASE.md`](./DATABASE.md): correr migraciones + seed y exponer el
schema `altamagiadaniel` en PostgREST desde la VPS.

## Variables de entorno

Copiar `.env.example` → `.env` y completar con los valores del Supabase
Self-Hosted. **Nunca** commitear secretos (`.env*` está en `.gitignore`). La
`service_role` es **solo servidor**: jamás en el bundle del navegador.
