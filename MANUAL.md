# Manual de uso — Alta Magia Daniel

Sitio web oficial de **Alta Magia Daniel** (Tarot y Trabajos Espirituales, Paraguay) con
su **panel de administración** para cargar contenido sin tocar código.

Este manual explica cómo está armado el proyecto, cómo administrarlo día a día y cómo
publicarlo. Está pensado tanto para quien carga contenido como para quien mantiene el código.

---

## 1. Qué es este proyecto

Son **dos cosas** que viven en la misma carpeta:

1. **El sitio público** — páginas estáticas (HTML/CSS/JS, sin build) que ven los clientes.
2. **El panel admin** (`/admin`) — una app para cargar servicios, productos, trabajos,
   portada, etc.

Ambos leen y escriben en una base de datos **Supabase** (self-hosted en Neura). El sitio
público **lee**; el panel admin **lee y escribe** (con login).

```
Cliente (navegador)  ──lee──►  Supabase (api.neura.com.py)  ◄──lee/escribe──  Panel admin (con login)
        ▲                        schema: altamagiadaniel                              ▲
        │                        bucket:  altamagiadaniel-media                       │
   páginas públicas                                                            /admin (requiere cuenta)
```

Si la base de datos no responde, el sitio público **no se rompe**: muestra un contenido
de respaldo ya incluido en cada página.

---

## 2. Estructura de carpetas

Todo lo que se publica está dentro de `github/`:

```
github/
├── index.html                  Página principal (home)
├── servicios/index.html        Página de servicios
├── catalogo/index.html         Catálogo de productos (con carrito + WhatsApp)
├── politicadeprivacidad/…      Política de privacidad
├── fondos/galeria.html         Galería de fondos/gráficos (referencia interna)
│
├── admin/                      PANEL DE ADMINISTRACIÓN
│   ├── login/index.html        Pantalla de ingreso
│   ├── index.html              Estructura del panel (menú + estilos)
│   ├── app.js                  Motor del panel (toda la lógica CRUD)
│   └── config.js               Configuración de Supabase para el panel
│
├── supabase-config.js          Configuración de Supabase para el sitio público
│
├── *.jpg / *.mp4 / *.svg       Imágenes, videos y gráficos del sitio
├── fondos/*.svg                Fondos decorativos
├── favicon-md.png, logo-md.jpg Marca
└── README.md                   Guía corta de publicación
```

> Regla práctica: **el sitio que se sube a producción es el contenido de `github/`.** La
> carpeta raíz del repositorio solo agrega configuración de herramientas (`.claude/`).

---

## 3. Arquitectura y backend

- **Backend:** Supabase self-hosted en `https://api.neura.com.py`.
- **Schema aislado:** `altamagiadaniel` (todas las tablas del proyecto viven ahí, separadas de otros proyectos del servidor).
- **Bucket de archivos:** `altamagiadaniel-media` (imágenes y videos que se suben desde el panel).
- **Autenticación:** Supabase Auth (email + contraseña) solo para el panel admin.

### Claves

- La **anon key** (clave pública) aparece en `supabase-config.js` y `admin/config.js`.
  **Es pública por diseño** y es seguro que esté en el navegador.
- La **service role key** (clave secreta) **NUNCA** va en estos archivos ni en ningún
  archivo del frontend. Si alguien te pide ponerla acá, no lo hagas.

### Tablas principales (schema `altamagiadaniel`)

| Módulo en el panel   | Tabla                 | Para qué sirve |
|----------------------|-----------------------|----------------|
| Portada              | `hero_slides`         | Imagen y textos del encabezado principal |
| Sobre mí             | `about_sections`      | Secciones de presentación |
| Cat. de servicios    | `service_categories`  | Categorías para agrupar servicios |
| Servicios            | `services`            | Servicios espirituales |
| Tarot                | `tarot_services`      | Consultas de tarot |
| Categorías (catálogo)| `product_categories`  | Categorías de productos |
| Productos            | `products`            | Productos del catálogo |
| Trabajos             | `works`               | Galería de trabajos (fotos/videos) |
| Redes sociales       | `social_links`        | Links a redes |
| Navegación           | `navigation_items`    | Orden y etiquetas del menú del sitio |
| Configuración        | `site_settings`       | Datos globales (WhatsApp, logo, SEO…) |
| Mensajes             | `contact_messages`    | Mensajes que envían los visitantes |
| Administradores      | `admin_profiles`      | Usuarios del panel y sus roles |

---

## 4. Panel de administración

### 4.1 Ingreso

1. Entrá a `https://TU-SITIO/admin/login`.
2. Ingresá con tu **correo y contraseña** autorizados.
3. El sistema verifica que exista un **perfil de administrador activo**. Si no lo tenés,
   te niega el acceso aunque el correo y la contraseña sean correctos.

> Las cuentas se crean en Supabase (Auth) y se les asigna un perfil en la tabla
> `admin_profiles`. Un usuario sin perfil activo no puede entrar.

### 4.2 Roles

| Rol           | Puede editar contenido | Puede eliminar | Ve "Administradores" |
|---------------|:---------------------:|:--------------:|:--------------------:|
| `super_admin` | ✅ | ✅ | ✅ |
| `admin`       | ✅ | ✅ | ❌ |
| `editor`      | ✅ | ❌ | ❌ |

- Solo `super_admin` y `admin` ven el botón **Eliminar**.
- Solo `super_admin` ve el módulo **Administradores**.

### 4.3 Cómo trabajar en cada módulo

Al entrar ves un **Dashboard** con contadores (servicios, productos, categorías, trabajos,
mensajes nuevos) y accesos rápidos. En el menú lateral están todos los módulos.

Dentro de un módulo (por ejemplo **Productos**):

- **+ Nuevo** — crea un registro nuevo.
- **Buscar** — filtra la lista al escribir.
- **▲ / ▼** — cambia el orden en que aparece en el sitio (renumera automáticamente).
- **Destacar** — marca el ítem como destacado.
- **Activo / Inactivo** — muestra u oculta el ítem en el sitio **sin borrarlo** (recomendado
  en vez de eliminar).
- **Editar** — abre el formulario.
- **Eliminar** — borra definitivamente (no se puede deshacer; solo `admin`/`super_admin`).

**Al crear/editar:**

- El **slug** (identificador único en la URL) se genera solo a partir del nombre; podés
  ajustarlo. Si repetís un slug, el panel avisa: *"Ya existe un registro con ese slug."*
- Los campos de **precio, orden y stock** no aceptan valores negativos.
- **Precio en el catálogo:** el precio se muestra en la web **solo si el producto tiene un valor
  cargado (mayor a 0)**. Si dejás el campo **Precio** vacío, ese producto **no muestra ningún
  precio** (queda "a consultar"). Así controlás producto por producto cuáles muestran precio.
- **"Activo"** encendido = visible en el sitio.

### 4.4 Subir imágenes y videos

En los campos de imagen:

1. Hacé clic en **Elegir archivo** y seleccioná la imagen/video.
2. Se muestra una **vista previa inmediata** y el estado *"subiendo…"* → **✓** cuando termina.
3. La URL pública queda guardada automáticamente al guardar el registro.

Restricciones:

- **Formatos:** JPG, PNG, WEBP, GIF y MP4.
- **Tamaño máximo:** 20 MB por archivo.
- Los archivos se guardan en el bucket `altamagiadaniel-media`.

### 4.5 Mensajes de contacto

El módulo **Mensajes** muestra lo que envían los visitantes (solo lectura del contenido).
Podés cambiar su **estado** (`new`, `read`, `replied`, `archived`) y agregar **notas** internas.

---

## 5. Sitio público

| Página | Archivo | Qué muestra |
|--------|---------|-------------|
| Inicio | `index.html` | Portada, presentación, servicios destacados, tarot, trabajos, catálogo (preview) |
| Servicios | `servicios/index.html` | Lista completa de servicios |
| Catálogo | `catalogo/index.html` | Productos con **carrito** y **checkout por WhatsApp** |
| Privacidad | `politicadeprivacidad/index.html` | Política de privacidad |

- **Contacto principal:** WhatsApp **+595 972 542230** (`https://wa.me/595972542230`).
- El **catálogo** arma un carrito en el navegador y, al finalizar, abre WhatsApp con el
  pedido ya escrito.
- Cada página carga contenido **en vivo** desde Supabase. Si falla la conexión, usa el
  contenido de respaldo incluido en el propio HTML, así que nunca queda en blanco.

> Nota técnica: `index.html` es una página compilada (bundle) sobre la que se aplican
> mejoras y contenido en vivo mediante un script de post-procesamiento (funciones `__amd…`).
> Por eso, para cambiar textos/servicios de la home, en general se edita el **contenido en
> Supabase** (vía panel), no el HTML.

---

## 6. Desarrollo local

No hay paso de build: son archivos estáticos. Solo necesitás servirlos con un servidor
web local (abrir el HTML con doble clic **no** alcanza, porque usa rutas absolutas como
`/admin/…` y módulos ES).

Desde la carpeta `github/`, cualquiera de estas opciones:

```bash
# Python
python -m http.server 4173

# Node (npx)
npx serve -l 4173
```

Luego abrí `http://localhost:4173/` (sitio) y `http://localhost:4173/admin/login` (panel).

---

## 7. Publicación (deploy)

- **Repositorio:** `github.com/bartsilvera12-gif/Alta-Magia-Daniel-`
- **Hosting:** **Vercel**, conectado a ese repositorio.
- **Sitio en vivo:** `https://alta-magia-daniel-psi.vercel.app`

### Cómo se publica (flujo real)

El deploy es **automático**: cada vez que se hace **`git push` a la rama `main`**, Vercel
detecta el cambio, construye (sin build step, es estático) y publica en 30–60 segundos.

```bash
# desde la carpeta github/ (o la raíz del repo, según cómo esté clonado)
git add .
git commit -m "descripción del cambio"
git push            # ← esto dispara el deploy en Vercel
```

No hay que tocar el panel de Vercel para publicar; alcanza con el push.

> **Importante — el schema debe estar expuesto:** para que el panel y el sitio traigan datos,
> el schema `altamagiadaniel` debe estar **expuesto en PostgREST** en el servidor Supabase, con
> sus políticas de acceso (RLS). Si el panel carga pero no muestra datos, revisá eso primero.

### ⚠️ Después de publicar: la caché del navegador

Este es el punto que más confunde. Cuando publicás un cambio, **el servidor ya tiene lo nuevo
al instante**, pero tu navegador puede seguir mostrando la versión **vieja guardada en caché**.
No es que el cambio "no se aplicó" — es que tu navegador no volvió a bajar la página.

**Para ver los cambios recién publicados, forzá la recarga (cualquiera de estas):**

1. **Recarga forzada:** parado en la página, apretá **Ctrl + Shift + R** (Windows) o
   **Cmd + Shift + R** (Mac).
2. **Ventana de incógnito** (lo más seguro): **Ctrl + Shift + N** y entrá al sitio. El incógnito
   no usa nada de caché.
3. **URL anti-caché:** agregá `?v=2` (o cualquier número) al final de la dirección, por ejemplo
   `alta-magia-daniel-psi.vercel.app/?v=2`.

**Datos importantes:**

- La caché es **por página**. Si cambiás algo del panel, forzá la recarga **en `/admin`**; si es
  del sitio, forzá la recarga **en la home o en la página correspondiente**.
- El **navegador interno de WhatsApp** (abrir el link desde un chat) cachea muy fuerte. Mejor abrir
  el sitio directamente en Chrome/Safari, en modo incógnito.
- Nota: **el contenido** (servicios, productos, orden del menú, etc.) se lee **en vivo** desde
  Supabase en cada visita. Lo que se cachea es el **archivo de la página** (HTML/JS). Por eso, una
  vez que el navegador cargó la versión nueva de la página, los cambios de contenido posteriores
  aparecen solos, sin volver a forzar recarga.

### Alternativa (hosting estático genérico)

Al ser 100% estático, también funciona en Netlify, Cloudflare Pages o GitHub Pages. Solo hay
que subir el contenido de `github/` como raíz del sitio.

---

## 8. Configuración a tener en cuenta

- **Cambiar la URL o clave de Supabase:** editá **los dos** archivos, `supabase-config.js`
  (sitio) y `admin/config.js` (panel). Deben apuntar a la misma `url`, `anonKey` y `schema`.
- **Número de WhatsApp:** figura en el módulo **Configuración** del panel
  (`site_settings`) y, para la home, también dentro de `index.html`.
- **Orden del menú del sitio:** se controla desde el módulo **Navegación**. La home lee ese
  orden en vivo desde `navigation_items` y reordena el menú del encabezado automáticamente.
- **No publiques** nunca la service role key ni contraseñas en estos archivos.

### Notas para quien mantiene el código

- **Al editar `admin/app.js`, subí el número de versión en `admin/index.html`.** El panel carga
  el motor con `…/admin/app.js?v=N`. Ese `?v=N` fuerza al navegador a bajar la versión nueva.
  Si editás `app.js` y **no** cambiás el número, los usuarios pueden seguir usando la versión
  vieja por caché. Regla: cada cambio en `app.js` → subir `v=N` a `v=N+1` en `admin/index.html`.
- **La home (`index.html`) es un bundle compilado.** No se editan textos "a mano" ahí: el
  contenido se administra desde el panel (Supabase). Los ajustes de diseño/estructura se aplican
  con funciones de post-procesamiento `__amd…` que corren después de que la página se renderiza
  (y se re-aplican solas ante los re-render de la página). Si necesitás tocar el HTML de la home,
  buscá esas funciones dentro del `<script>` principal.
- **Motor CRUD genérico:** todos los módulos del panel se definen en el arreglo `ENTITIES` de
  `admin/app.js` (columnas, campos, tabla, etc.). Para agregar/quitar un módulo o un campo, se
  edita ese arreglo — no hay pantallas hechas a mano por módulo.

---

## 9. Resolución de problemas

| Síntoma | Posible causa / solución |
|---------|--------------------------|
| No puedo entrar al panel pese a datos correctos | No tenés perfil activo en `admin_profiles`. Un `super_admin` debe crearlo/activarlo. |
| El panel carga pero no muestra datos | El schema `altamagiadaniel` no está expuesto en PostgREST o falta permiso (RLS). |
| Error al subir imagen | Formato no permitido (usá JPG/PNG/WEBP/GIF/MP4) o supera 20 MB. |
| "Ya existe un registro con ese slug" | El slug debe ser único; cambialo. |
| El sitio muestra contenido viejo/estático | No hay conexión con Supabase; se está usando el respaldo. Revisá la red y las claves. |
| **"Hice un cambio y no se ve"** | Caché del navegador. Forzá recarga con **Ctrl+Shift+R** o abrí en **incógnito** (ver sección 7 → "Después de publicar: la caché"). El cambio ya está publicado; falta que tu navegador lo baje. |
| Cambié algo en `app.js` y los usuarios no lo ven | Faltó subir el `?v=N` en `admin/index.html` (ver "Notas para quien mantiene el código"). |
| La imagen no sube ("Failed to fetch") | Suele ser CORS/red del servicio de Storage. La subida usa `fetch` directo con headers permitidos; si reaparece, revisá la config CORS del Storage en el VPS. |
| Los botones ▲/▼ "no ordenan" | Ya corregido: el orden se renumera al mover. Si no lo ves, es caché (forzá recarga en `/admin`). |
| Abrí un HTML con doble clic y no carga | Servilo con un servidor local (ver sección 6); no funciona con `file://`. |

---

## 10. Contacto

- **WhatsApp:** +595 972 542230
- **Backend:** Supabase self-hosted — `https://api.neura.com.py` (schema `altamagiadaniel`)
