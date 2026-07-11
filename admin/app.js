/* =============================================================================
 *  Alta Magia Daniel — Admin panel engine (static + supabase-js)
 *  Generic, config-driven CRUD for every module. No build step.
 * ========================================================================== */
import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm';

const cfg = window.AMD_SUPABASE || {};
const BUCKET = 'altamagiadaniel-media';
const MAX_MB = 20;
const OK_TYPES = ['image/jpeg','image/png','image/webp','image/gif','video/mp4'];

const supabase = createClient(cfg.url, cfg.anonKey, {
  auth: { persistSession: true, autoRefreshToken: true, storageKey: 'amd-admin-auth' },
  db: { schema: cfg.schema || 'altamagiadaniel' }
});

let ME = null;               // admin profile row
const refCache = {};         // fk options cache

/* ------------------------------- entities --------------------------------- */
const F = (name, label, type, extra = {}) => ({ name, label, type, ...extra });

const ENTITIES = [
  { key:'hero', title:'Portada', table:'hero_slides', icon:'★', img:'desktop_image_url',
    columns:[['title','Título'],['subtitle','Subtítulo']],
    fields:[ F('eyebrow','Bajada (arriba del título)','text'), F('title','Título','text'),
      F('subtitle','Subtítulo','text'), F('description','Descripción','textarea'),
      F('desktop_image_url','Imagen','image',{folder:'hero'}),
      F('sort_order','Orden','number'), F('is_active','Activo','bool') ] },

  { key:'about', title:'Sobre mí', table:'about_sections', img:'image_url',
    columns:[['section_key','Clave'],['title','Título']],
    fields:[ F('section_key','Clave (única)','text',{required:true}), F('title','Título','text'),
      F('subtitle','Subtítulo','text'), F('content','Contenido','textarea'),
      F('quote','Frase','text'), F('image_url','Imagen','image',{folder:'about'}),
      F('sort_order','Orden','number'), F('is_active','Activo','bool') ] },

  { key:'service_categories', title:'Cat. de servicios', table:'service_categories',
    columns:[['name','Nombre'],['slug','Slug']],
    fields:[ F('name','Nombre','text',{required:true}), F('slug','Slug (único)','text',{required:true}),
      F('description','Descripción','textarea'), F('sort_order','Orden','number'), F('is_active','Activo','bool') ] },

  { key:'services', title:'Servicios', table:'services', img:'cover_image_url',
    columns:[['name','Nombre'],['is_featured','Dest.'],['is_active','Activo']],
    fields:[ F('name','Nombre','text',{required:true}), F('slug','Slug (único)','text',{required:true}),
      F('category_id','Categoría','fk',{ref:'service_categories',refLabel:'name'}),
      F('short_description','Descripción corta','textarea'), F('full_description','Descripción completa','textarea'),
      F('cover_image_url','Imagen','image',{folder:'services'}), F('video_url','Video (URL)','text'),
      F('whatsapp_message','Mensaje WhatsApp','text'),
      F('show_price','Mostrar precio','bool'), F('price','Precio','number'),
      F('is_featured','Destacado','bool'), F('sort_order','Orden','number'), F('is_active','Activo','bool') ] },

  { key:'tarot', title:'Tarot', table:'tarot_services',
    columns:[['name','Nombre'],['is_active','Activo']],
    fields:[ F('name','Nombre','text',{required:true}), F('slug','Slug (único)','text',{required:true}),
      F('short_description','Descripción corta','textarea'), F('full_description','Descripción','textarea'),
      F('consultation_type','Tipo de consulta','text'), F('whatsapp_message','Mensaje WhatsApp','text'),
      F('show_price','Mostrar precio','bool'), F('price','Precio','number'),
      F('sort_order','Orden','number'), F('is_active','Activo','bool') ] },

  { key:'product_categories', title:'Categorías', table:'product_categories', img:'image_url', group:'Catálogo',
    columns:[['name','Nombre'],['slug','Slug']],
    fields:[ F('name','Nombre','text',{required:true}), F('slug','Slug (único)','text',{required:true}),
      F('description','Descripción','textarea'), F('image_url','Imagen','image',{folder:'products'}),
      F('sort_order','Orden','number'), F('is_active','Activo','bool') ] },

  { key:'products', title:'Productos', table:'products', img:'cover_image_url', group:'Catálogo',
    columns:[['name','Nombre'],['is_featured','Dest.'],['is_active','Activo']],
    fields:[ F('name','Nombre','text',{required:true}), F('slug','Slug (único)','text',{required:true}),
      F('category_id','Categoría','fk',{ref:'product_categories',refLabel:'name'}),
      F('short_description','Descripción corta','textarea'), F('full_description','Descripción completa','textarea'),
      F('cover_image_url','Imagen','image',{folder:'products'}), F('whatsapp_message','Mensaje WhatsApp','text'),
      F('show_price','Mostrar precio','bool'), F('price','Precio','number'), F('promotional_price','Precio promo','number'),
      F('is_featured','Destacado','bool'), F('sort_order','Orden','number'), F('is_active','Activo','bool') ] },

  { key:'works', title:'Trabajos', table:'works', img:'thumbnail_url',
    columns:[['title','Título'],['media_type','Tipo'],['is_active','Activo']],
    fields:[ F('title','Título','text'), F('slug','Slug (único)','text'),
      F('description','Descripción','textarea'),
      F('media_type','Tipo','select',{options:['image','video','embed']}),
      F('media_url','Media (URL / mp4)','text'), F('thumbnail_url','Miniatura','image',{folder:'works'}),
      F('external_url','URL externa','text'),
      F('is_featured','Destacado','bool'), F('sort_order','Orden','number'), F('is_active','Activo','bool') ] },

  { key:'social', title:'Redes sociales', table:'social_links',
    columns:[['platform','Plataforma'],['url','URL']],
    fields:[ F('platform','Plataforma','text',{required:true}), F('label','Etiqueta','text'),
      F('url','URL','text',{required:true}), F('username','Usuario','text'),
      F('sort_order','Orden','number'), F('is_visible','Visible','bool'), F('is_active','Activo','bool') ] },

  { key:'navigation', title:'Navegación', table:'navigation_items',
    columns:[['label','Etiqueta'],['href','Destino']],
    fields:[ F('label','Etiqueta','text',{required:true}), F('href','Destino (href)','text',{required:true}),
      F('target','Abrir en','select',{options:['_self','_blank']}),
      F('sort_order','Orden','number'), F('is_visible','Visible','bool'), F('is_active','Activo','bool') ] },

  { key:'settings', title:'Configuración', table:'site_settings', singleton:true,
    fields:[ F('site_name','Nombre del sitio','text'), F('site_subtitle','Subtítulo','text'),
      F('logo_url','Logo','image',{folder:'site'}), F('favicon_url','Favicon','image',{folder:'site'}),
      F('whatsapp_number','WhatsApp (número)','text'), F('whatsapp_default_message','Mensaje WhatsApp por defecto','text'),
      F('contact_email','Email de contacto','text'), F('address','Dirección','text'),
      F('footer_text','Texto del footer','text'), F('developed_by_text','Desarrollado por (texto)','text'),
      F('developed_by_url','Desarrollado por (URL)','text'),
      F('seo_title','SEO título','text'), F('seo_description','SEO descripción','textarea') ] },

  { key:'messages', title:'Mensajes', table:'contact_messages', noCreate:true, order:'created_at',
    columns:[['full_name','Nombre'],['subject','Asunto'],['status','Estado']],
    fields:[ F('full_name','Nombre','text',{readOnly:true}), F('phone','Teléfono','text',{readOnly:true}),
      F('email','Email','text',{readOnly:true}), F('subject','Asunto','text',{readOnly:true}),
      F('message','Mensaje','textarea',{readOnly:true}),
      F('status','Estado','select',{options:['new','read','replied','archived']}), F('notes','Notas','textarea') ] },

  { key:'admins', title:'Administradores', table:'admin_profiles', superOnly:true, noCreate:true, order:'created_at',
    columns:[['full_name','Nombre'],['role','Rol'],['is_active','Activo']],
    fields:[ F('full_name','Nombre','text'), F('role','Rol','select',{options:['super_admin','admin','editor']}),
      F('is_active','Activo','bool') ] },
];
const byKey = k => ENTITIES.find(e => e.key === k);

/* ------------------------------- helpers ---------------------------------- */
const $ = s => document.querySelector(s);
const esc = s => String(s==null?'':s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
const slugify = s => String(s||'').toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g,'')
  .replace(/[^a-z0-9]+/g,'-').replace(/^-+|-+$/g,'').slice(0,60);

let toastT;
function toast(msg, type='ok') {
  let t = $('#toast'); if (!t) { t = document.createElement('div'); t.id='toast'; document.body.appendChild(t); }
  t.className = 'toast ' + type; t.textContent = msg; t.classList.add('show');
  clearTimeout(toastT); toastT = setTimeout(() => t.classList.remove('show'), 2600);
}
function confirmDialog(text) {
  return new Promise(res => {
    const ov = document.createElement('div'); ov.className = 'modal-ov';
    ov.innerHTML = `<div class="modal"><p>${esc(text)}</p><div class="modal-actions">
      <button class="btn-ghost" data-no>Cancelar</button><button class="btn-danger" data-yes>Sí, continuar</button></div></div>`;
    document.body.appendChild(ov);
    ov.addEventListener('click', e => {
      if (e.target === ov || e.target.hasAttribute('data-no')) { ov.remove(); res(false); }
      if (e.target.hasAttribute('data-yes')) { ov.remove(); res(true); }
    });
  });
}
async function refOptions(entity) {
  const ref = entity; if (refCache[ref]) return refCache[ref];
  const { data } = await supabase.from(ref).select('id, name').order('sort_order', { ascending:true });
  refCache[ref] = data || []; return refCache[ref];
}
async function uploadFile(file, folder) {
  if (!OK_TYPES.includes(file.type)) throw new Error('Tipo no permitido (jpg, png, webp, gif, mp4).');
  if (file.size > MAX_MB*1024*1024) throw new Error('El archivo supera ' + MAX_MB + ' MB.');
  const ext = (file.name.split('.').pop() || 'jpg').toLowerCase().replace(/[^a-z0-9]/g,'');
  const path = (folder||'admin') + '/f' + Date.now() + '-' + Math.random().toString(36).slice(2,8) + '.' + ext;
  // Direct fetch instead of supabase-js .upload(): the library always sends
  // `cache-control` and `x-upsert` headers, which are NOT in the storage server's
  // CORS Access-Control-Allow-Headers list, so the browser blocks the request
  // ("Failed to fetch"). Here we send only allowed headers.
  const { data: { session } } = await supabase.auth.getSession();
  const token = (session && session.access_token) || cfg.anonKey;
  const res = await fetch(`${cfg.url}/storage/v1/object/${BUCKET}/${path}`, {
    method: 'POST',
    headers: {
      'Authorization': 'Bearer ' + token,
      'apikey': cfg.anonKey,
      'Content-Type': file.type || 'application/octet-stream'
    },
    body: file
  });
  if (!res.ok) {
    let msg = 'Error ' + res.status;
    try { const j = await res.json(); msg = j.message || j.error || msg; } catch (e) {}
    throw new Error(msg);
  }
  return `${cfg.url}/storage/v1/object/public/${BUCKET}/${path}`;
}

/* --------------------------------- boot ----------------------------------- */
(async function boot() {
  if (!cfg.url || !cfg.anonKey) { location.replace('/admin/login'); return; }
  const { data: sess } = await supabase.auth.getSession();
  if (!sess || !sess.session) return location.replace('/admin/login');
  const { data: profile, error } = await supabase.from('admin_profiles')
    .select('id, full_name, role, is_active').eq('user_id', sess.session.user.id).maybeSingle();
  if (error || !profile || !profile.is_active) { await supabase.auth.signOut(); return location.replace('/admin/login'); }
  ME = profile;

  $('#adminName').textContent = profile.full_name || sess.session.user.email;
  $('#adminRole').textContent = profile.role;
  buildSidebar();
  $('#gate').style.display = 'none';
  $('#app').style.display = 'grid';
  $('#logoutBtn').addEventListener('click', async () => { await supabase.auth.signOut(); location.replace('/admin/login'); });
  window.addEventListener('hashchange', route);
  route();
})();

function canDelete() { return ME && (ME.role === 'super_admin' || ME.role === 'admin'); }

function buildSidebar() {
  const items = ENTITIES.filter(e => !e.superOnly || ME.role === 'super_admin');
  let html = `<a href="#/" data-nav>Dashboard</a>`;
  let lastGroup = null;
  for (const e of items) {
    if (e.group && e.group !== lastGroup) { html += `<div class="nav-group">${esc(e.group)}</div>`; lastGroup = e.group; }
    else if (!e.group) lastGroup = null;
    html += `<a href="#/${e.key}" data-nav data-key="${e.key}">${esc(e.title)}</a>`;
  }
  $('#nav').innerHTML = html;
}

/* -------------------------------- router ---------------------------------- */
function route() {
  const parts = (location.hash.replace(/^#\/?/, '') || '').split('/').filter(Boolean);
  document.querySelectorAll('#nav a').forEach(a => a.removeAttribute('aria-current'));
  if (!parts.length) { setActive(''); return dashboard(); }
  const [key, action, id] = parts;
  const entity = byKey(key);
  if (!entity || (entity.superOnly && ME.role !== 'super_admin')) { location.hash = '#/'; return; }
  setActive(key);
  if (action === 'new') return formView(entity, null);
  if (action === 'edit' && id) return formView(entity, id);
  if (entity.singleton) return singletonView(entity);
  return listView(entity);
}
function setActive(key) {
  document.querySelectorAll('#nav a').forEach(a => {
    if ((a.dataset.key||'') === key || (!key && a.getAttribute('href')==='#/')) a.setAttribute('aria-current','page');
  });
}
function crumb(text){ return `<div class="crumbs">${text}</div>`; }

/* ------------------------------- dashboard -------------------------------- */
async function dashboard() {
  const view = $('#view');
  view.innerHTML = crumb('Dashboard') + `<h1>Panel de control</h1><p class="lead">Bienvenido, ${esc(ME.full_name||'')}.</p>
    <div class="stats" id="stats"></div>
    <div class="qa"><a class="chip" href="#/products/new">+ Producto</a><a class="chip" href="#/services/new">+ Servicio</a>
      <a class="chip" href="#/product_categories/new">+ Categoría</a>
      <a class="chip" href="#/works/new">+ Trabajo</a><a class="chip" href="#/hero">Editar portada</a>
      <a class="chip" href="/" target="_blank" rel="noopener">Ver sitio ↗</a></div>`;
  const count = async (t, f) => { let q = supabase.from(t).select('*',{count:'exact',head:true}); if (f) q = f(q); const { count:c } = await q; return c ?? 0; };
  const cards = [
    ['Servicios activos', await count('services', q=>q.eq('is_active',true))],
    ['Productos activos', await count('products', q=>q.eq('is_active',true))],
    ['Categorías', await count('product_categories')],
    ['Trabajos', await count('works', q=>q.eq('is_active',true))],
    ['Mensajes nuevos', await count('contact_messages', q=>q.eq('status','new'))],
  ];
  $('#stats').innerHTML = cards.map(c=>`<div class="stat"><div class="n">${c[1]}</div><div class="l">${c[0]}</div></div>`).join('');
}

/* --------------------------------- list ----------------------------------- */
async function listView(entity) {
  const view = $('#view');
  view.innerHTML = crumb(entity.title) + `<div class="head-row"><h1>${esc(entity.title)}</h1>
    ${entity.noCreate?'':`<a class="btn" href="#/${entity.key}/new">+ Nuevo</a>`}</div>
    <input id="search" class="search" placeholder="Buscar…" autocomplete="off">
    <div id="tbl" class="tbl-wrap"><p class="muted">Cargando…</p></div>`;

  const order = entity.order || 'sort_order';
  const asc = order !== 'created_at';
  const { data, error } = await supabase.from(entity.table).select('*').order(order, { ascending: asc });
  if (error) { $('#tbl').innerHTML = `<p class="err">Error: ${esc(error.message)}</p>`; return; }
  let rows = data || [];

  // resolve fk labels for a "category" column if present
  const fkField = entity.fields.find(f => f.type === 'fk');
  let fkMap = {};
  if (fkField) { const opts = await refOptions(fkField.ref); opts.forEach(o => fkMap[o.id] = o.name); }

  const featField = entity.fields.find(f => f.name === 'is_featured');
  const hasActive = entity.fields.some(f => f.name === 'is_active');
  const canSort = entity.fields.some(f => f.name === 'sort_order');

  function render(list) {
    if (!list.length) { $('#tbl').innerHTML = `<p class="muted">Sin registros todavía.</p>`; return; }
    const cols = entity.columns || [['name','Nombre']];
    let h = `<table class="tbl"><thead><tr>${entity.img?'<th></th>':''}${cols.map(c=>`<th>${esc(c[1])}</th>`).join('')}<th class="ta-r">Acciones</th></tr></thead><tbody>`;
    list.forEach((r, i) => {
      h += `<tr>`;
      if (entity.img) h += `<td class="imgcell">${r[entity.img]?`<img class="thumb" src="${esc(r[entity.img])}" alt="">`:'<span class="thumb ph"></span>'}</td>`;
      cols.forEach(c => {
        let v = r[c[0]];
        if (c[0] === 'category_id') v = fkMap[v] || '—';
        else if (typeof v === 'boolean') v = v ? '✓' : '—';
        else if (c[0] === 'created_at' && v) v = new Date(v).toLocaleDateString('es-PY');
        h += `<td data-label="${esc(c[1])}">${esc(v==null?'—':v)}</td>`;
      });
      h += `<td class="ta-r acts" data-label=""><div class="actwrap">`;
      if (canSort) h += `<button title="Subir" data-move="up" data-id="${r.id}" ${i===0?'disabled':''}>▲</button>
        <button title="Bajar" data-move="down" data-id="${r.id}" ${i===list.length-1?'disabled':''}>▼</button>`;
      if (featField) h += `<button class="mini ${r.is_featured?'on':''}" data-feat="${r.id}">${r.is_featured?'Destacado':'Destacar'}</button>`;
      if (hasActive) h += `<button class="mini ${r.is_active?'on':''}" data-active="${r.id}">${r.is_active?'Activo':'Inactivo'}</button>`;
      h += `<a class="mini" href="#/${entity.key}/edit/${r.id}">Editar</a>`;
      if (canDelete()) h += `<button class="mini del" data-del="${r.id}">Eliminar</button>`;
      h += `</div></td></tr>`;
    });
    h += `</tbody></table>`;
    $('#tbl').innerHTML = h;
  }
  render(rows);

  $('#search').addEventListener('input', e => {
    const q = e.target.value.toLowerCase();
    render(rows.filter(r => JSON.stringify(r).toLowerCase().includes(q)));
  });

  $('#tbl').addEventListener('click', async e => {
    const t = e.target;
    const id = t.dataset.active || t.dataset.feat || t.dataset.del || t.dataset.id;
    if (!id) return;
    const row = rows.find(r => r.id === id);
    try {
      if (t.dataset.active != null) { await update(entity.table, id, { is_active: !row.is_active }); row.is_active = !row.is_active; render(rows); toast('Actualizado'); }
      else if (t.dataset.feat != null) { await update(entity.table, id, { is_featured: !row.is_featured }); row.is_featured = !row.is_featured; render(rows); toast('Actualizado'); }
      else if (t.dataset.del != null) {
        if (!await confirmDialog('¿Eliminar este registro? Esta acción no se puede deshacer.')) return;
        const { error } = await supabase.from(entity.table).delete().eq('id', id);
        if (error) throw error; rows = rows.filter(r => r.id !== id); render(rows); toast('Eliminado');
      } else if (t.dataset.move) {
        const idx = rows.findIndex(r => r.id === id); const j = t.dataset.move==='up'?idx-1:idx+1;
        if (j < 0 || j >= rows.length) return;
        const a = rows[idx], b = rows[j];
        await update(entity.table, a.id, { sort_order: b.sort_order });
        await update(entity.table, b.id, { sort_order: a.sort_order });
        const tmp = a.sort_order; a.sort_order = b.sort_order; b.sort_order = tmp;
        rows.sort((x,y)=>x.sort_order-y.sort_order); render(rows); toast('Orden actualizado');
      }
    } catch (err) { toast(err.message || 'Error', 'err'); }
  });
}
async function update(table, id, patch) {
  const { error } = await supabase.from(table).update(patch).eq('id', id);
  if (error) throw error;
}

/* --------------------------------- form ----------------------------------- */
async function singletonView(entity) {
  const { data } = await supabase.from(entity.table).select('*').limit(1).maybeSingle();
  return formView(entity, data ? data.id : null, data);
}

async function formView(entity, id, preloaded) {
  const view = $('#view');
  let row = preloaded || {};
  if (id && !preloaded) {
    const { data, error } = await supabase.from(entity.table).select('*').eq('id', id).maybeSingle();
    if (error) { view.innerHTML = `<p class="err">${esc(error.message)}</p>`; return; }
    row = data || {};
  }
  const isEdit = !!id;
  if (!isEdit) { if (row.is_active === undefined) row.is_active = true; if (row.is_visible === undefined) row.is_visible = true; }
  const backHash = entity.singleton ? '#/' : `#/${entity.key}`;

  // build fields html
  let fh = '';
  for (const f of entity.fields) {
    const val = row[f.name];
    fh += `<div class="field"><label for="fld_${f.name}">${esc(f.label)}${f.required?' *':''}</label>`;
    if (f.type === 'textarea') fh += `<textarea id="fld_${f.name}" ${f.readOnly?'readonly':''} rows="4">${esc(val)}</textarea>`;
    else if (f.type === 'bool') fh += `<label class="switch"><input type="checkbox" id="fld_${f.name}" ${val?'checked':''}> <span>${val?'Sí':'No'}</span></label>`;
    else if (f.type === 'number') fh += `<input id="fld_${f.name}" type="number" step="any" min="${f.min!=null?f.min:0}" value="${val==null?'':esc(val)}">`;
    else if (f.type === 'select') fh += `<select id="fld_${f.name}">${f.options.map(o=>`<option value="${o}" ${val===o?'selected':''}>${o}</option>`).join('')}</select>`;
    else if (f.type === 'fk') fh += `<select id="fld_${f.name}"><option value="">— sin categoría —</option>${(await refOptions(f.ref)).map(o=>`<option value="${o.id}" ${val===o.id?'selected':''}>${esc(o.name)}</option>`).join('')}</select>`;
    else if (f.type === 'image') fh += `<div class="img-field"><div class="img-prev" id="prev_${f.name}">${val?`<img src="${esc(val)}" alt="">`:'<span>sin imagen</span>'}</div>
        <input type="file" id="file_${f.name}" accept="image/*,video/mp4"><input type="hidden" id="fld_${f.name}" value="${esc(val)}">
        <button type="button" class="mini" data-clear="${f.name}">Quitar</button></div>`;
    else fh += `<input id="fld_${f.name}" type="text" ${f.readOnly?'readonly':''} value="${esc(val)}">`;
    if (f.help) fh += `<div class="help">${esc(f.help)}</div>`;
    fh += `</div>`;
  }

  view.innerHTML = crumb(`<a href="${backHash}">${esc(entity.title)}</a> › ${isEdit?'Editar':'Nuevo'}`) +
    `<div class="head-row"><h1>${isEdit?'Editar':'Nuevo'} · ${esc(entity.title)}</h1></div>
     <form id="entForm" class="form">${fh}
       <div class="form-actions"><a class="btn-ghost" href="${backHash}">Cancelar</a>
         <button class="btn" type="submit">${isEdit?'Guardar cambios':'Crear'}</button></div>
       <div class="msg" id="formMsg"></div></form>`;

  // bool label live
  entity.fields.filter(f=>f.type==='bool').forEach(f=>{
    const cb = $('#fld_'+f.name); if (cb) cb.addEventListener('change', ()=> cb.nextElementSibling.textContent = cb.checked?'Sí':'No');
  });
  // auto slug from name/title
  const nameFld = $('#fld_name') || $('#fld_title'); const slugFld = $('#fld_slug');
  if (nameFld && slugFld && !isEdit) nameFld.addEventListener('input', () => { if (!slugFld.dataset.touched) slugFld.value = slugify(nameFld.value); });
  if (slugFld) slugFld.addEventListener('input', () => slugFld.dataset.touched = '1');
  // image upload
  entity.fields.filter(f=>f.type==='image').forEach(f=>{
    const file = $('#file_'+f.name), hidden = $('#fld_'+f.name), prev = $('#prev_'+f.name);
    file.addEventListener('change', async () => {
      const fl = file.files[0]; if (!fl) return;
      // vista previa local instantánea (antes de subir)
      const localUrl = URL.createObjectURL(fl);
      const isVideo = (fl.type||'').startsWith('video');
      prev.innerHTML = isVideo
        ? `<video src="${localUrl}" muted playsinline></video>`
        : `<img src="${localUrl}" alt="">`;
      prev.insertAdjacentHTML('beforeend', '<span class="upstat">subiendo…</span>');
      try {
        const url = await uploadFile(fl, f.folder);
        hidden.value = url;
        const s = prev.querySelector('.upstat'); if (s) { s.textContent = '✓'; s.classList.add('ok'); }
        toast('Imagen subida');
      } catch (err) {
        hidden.value = '';
        const s = prev.querySelector('.upstat');
        const txt = err.message || 'Error al subir';
        if (s) { s.textContent = txt; s.className = 'upstat bad'; }
        else prev.insertAdjacentHTML('beforeend', `<span class="upstat bad">${esc(txt)}</span>`);
        toast(txt, 'err');
      }
    });
  });
  $('#entForm').addEventListener('click', e => { const k = e.target.dataset && e.target.dataset.clear; if (k) { $('#fld_'+k).value=''; $('#prev_'+k).innerHTML='<span>sin imagen</span>'; } });

  $('#entForm').addEventListener('submit', async ev => {
    ev.preventDefault();
    const payload = {};
    for (const f of entity.fields) {
      if (f.readOnly) continue;
      const el = $('#fld_'+f.name); if (!el) continue;
      let v;
      if (f.type === 'bool') v = el.checked;
      else if (f.type === 'number') v = el.value === '' ? null : Number(el.value);
      else if (f.type === 'fk') v = el.value || null;
      else v = el.value === '' ? null : el.value;
      if (f.name === 'sort_order' && v == null) v = 0;   // NOT NULL column
      // number validation: no NaN, no negatives (DB constraints require >= 0)
      if (f.type === 'number' && v != null) {
        if (Number.isNaN(v)) { toast('Valor numérico inválido en: ' + f.label, 'err'); return; }
        const min = f.min != null ? f.min : 0;
        if (v < min) { toast(f.label + ' no puede ser menor que ' + min + '.', 'err'); return; }
      }
      payload[f.name] = v;
    }
    // required check
    for (const f of entity.fields) if (f.required && !payload[f.name]) { toast('Completá: ' + f.label, 'err'); return; }
    try {
      let res;
      if (isEdit) res = await supabase.from(entity.table).update(payload).eq('id', id);
      else res = await supabase.from(entity.table).insert(payload);
      if (res.error) throw res.error;
      delete refCache[entity.table]; // in case name/category changed
      toast(isEdit ? 'Guardado' : 'Creado');
      location.hash = backHash;
    } catch (err) {
      const raw = err.message || '';
      let m = raw || 'Error al guardar';
      if (/duplicate key|unique/i.test(raw)) m = 'Ya existe un registro con ese slug.';
      else if (/price_check/i.test(raw)) m = 'El precio no puede ser negativo.';
      else if (/promotional_price_check/i.test(raw)) m = 'El precio promocional no puede ser negativo.';
      else if (/stock_check/i.test(raw)) m = 'El stock no puede ser negativo.';
      else if (/sort_order_check/i.test(raw)) m = 'El orden no puede ser negativo.';
      else if (/check constraint/i.test(raw)) m = 'Un valor no cumple las reglas del formulario. Revisá los campos numéricos.';
      toast(m, 'err');
    }
  });
}
