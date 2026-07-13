# Alta Magia Daniel

Sitio web oficial de **Alta Magia Daniel** — Tarot y Trabajos Espirituales (Paraguay),
con **panel de administración** para cargar contenido sin tocar código.

- **Sitio en vivo:** https://alta-magia-daniel-psi.vercel.app
- **Panel admin:** https://alta-magia-daniel-psi.vercel.app/admin/login
- **Backend:** Supabase self-hosted (`https://api.neura.com.py`, schema `altamagiadaniel`)

## Cómo está armado

- **Sitio público** — páginas estáticas (HTML/CSS/JS, sin build): `index.html`,
  `servicios/`, `catalogo/`, `politicadeprivacidad/`.
- **Panel admin** (`admin/`) — app estática con `@supabase/supabase-js`; CRUD de todos los
  módulos (portada, servicios, productos, trabajos, navegación, etc.).
- Ambos leen contenido **en vivo** desde Supabase; si la base no responde, cada página usa un
  **respaldo** incluido en el propio HTML (nunca queda en blanco).

## Publicar

Hosting en **Vercel**, conectado a este repositorio. El deploy es **automático**: cada
`git push` a la rama `main` publica en 30–60 segundos.

```bash
git add .
git commit -m "descripción del cambio"
git push
```

> Después de publicar, si no ves el cambio, es **caché del navegador**: forzá recarga con
> **Ctrl+Shift+R** o abrí en **incógnito**.

## Manual completo

Toda la documentación (estructura, backend, uso del panel, subida de imágenes, roles,
deploy, resolución de problemas y notas para desarrolladores) está en **[MANUAL.md](MANUAL.md)**.

## Contacto

WhatsApp: **+595 972 542230** — https://wa.me/595972542230
