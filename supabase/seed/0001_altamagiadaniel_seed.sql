-- =============================================================================
--  Alta Magia Daniel — Seed of the CURRENT public content (Fase 9)
--  Idempotent: stable slugs/keys + ON CONFLICT / WHERE NOT EXISTS.
--  No invented content. No prices re-introduced (show_price = false everywhere).
--  Image URLs are the current root-relative asset paths already deployed.
-- =============================================================================
begin;

-- ---- site_settings (single active row) --------------------------------------
insert into altamagiadaniel.site_settings
  (site_name, site_subtitle, logo_url, favicon_url, whatsapp_number,
   whatsapp_default_message, seo_title, footer_text, developed_by_text, developed_by_url, is_active)
select
  'Alta Magia Daniel', 'Tarot y Trabajos Espirituales · Paraguay',
  '/logo-md.jpg', '/favicon-md.png', '595972542230',
  'Hola, me interesa el servicio: ', 'Alta Magia Daniel',
  '© 2026 Alta Magia Daniel. Todos los derechos reservados.',
  'Desarrollado por Neura', 'https://neura.com.py', true
where not exists (select 1 from altamagiadaniel.site_settings);

-- ---- navigation_items -------------------------------------------------------
insert into altamagiadaniel.navigation_items (label, href, target, sort_order)
select v.label, v.href, v.target, v.sort_order
from (values
  ('SOBRE MÍ', '#sobre', '_self', 1),
  ('SERVICIOS', '/servicios', '_self', 2),
  ('CATÁLOGO', '/catalogo', '_self', 3),
  ('TAROT', '#tarot', '_self', 4),
  ('CONTACTO', '#contacto', '_self', 5),
  ('WHATSAPP', 'https://wa.me/595972542230', '_blank', 6)
) as v(label, href, target, sort_order)
where not exists (
  select 1 from altamagiadaniel.navigation_items n where n.label = v.label and n.href = v.href);

-- ---- hero_slides ------------------------------------------------------------
insert into altamagiadaniel.hero_slides (eyebrow, title, subtitle, description, sort_order)
select 'TAROT Y TRABAJOS ESPIRITUALES', 'ALTA MAGIA DANIEL',
       'El mejor tarotista del Paraguay', '"El éxito no es suerte, es decisión."', 1
where not exists (select 1 from altamagiadaniel.hero_slides where title = 'ALTA MAGIA DANIEL');

-- ---- about_sections ---------------------------------------------------------
insert into altamagiadaniel.about_sections (section_key, title, image_url, sort_order)
values ('sobre', 'Sobre Mí', '/card-maestro-sobre.jpg', 1)
on conflict (section_key) do update
  set title = excluded.title, image_url = excluded.image_url;

-- ---- service + product categories -------------------------------------------
insert into altamagiadaniel.service_categories (name, slug, sort_order) values
  ('Servicios Espirituales', 'servicios-espirituales', 1)
on conflict (slug) do update set name = excluded.name;

insert into altamagiadaniel.product_categories (name, slug, sort_order) values
  ('Perfumes', 'perfumes', 1),
  ('Figuras',  'figuras',  2),
  ('Amuletos', 'amuletos', 3),
  ('Otros',    'otros',    4)
on conflict (slug) do update set name = excluded.name, sort_order = excluded.sort_order;

-- ---- services ---------------------------------------------------------------
with cat as (select id from altamagiadaniel.service_categories where slug = 'servicios-espirituales')
insert into altamagiadaniel.services
  (category_id, name, slug, short_description, cover_image_url, whatsapp_message, is_featured, sort_order)
select cat.id, s.name, s.slug, s.short_description, s.cover_image_url,
       'Hola, me interesa el servicio: ' || s.name, s.is_featured, s.sort_order
from cat, (values
  ('Maestro Daniel · Tarot y Energías','maestro-daniel-tarot-energias','Lecturas personalizadas, energías, apertura de caminos, orientación espiritual y amor. Atención seria y confidencial.','/card-daniel.jpg', false, 1),
  ('Agenda tu Lectura de Tarot','agenda-lectura-tarot','Descubrí las respuestas que estás buscando. Disponible por videollamada o audio personalizado. Reservá tu turno.','/card-agenda-tarot.jpg', false, 2),
  ('Destrabe y Apertura de Caminos','destrabe-apertura-caminos','Rompe bloqueos económicos y abre caminos de prosperidad, oportunidades y estabilidad.','/card-destrabe-maestro.jpg', true, 3),
  ('Destrabe de Dinero','destrabe-de-dinero','¿Sientes que el dinero se estanca? Rompé bloqueos económicos, abrí caminos de prosperidad y protegé tu energía contra envidias y brujerías.','/card-destrabe-altar.jpg', false, 4),
  ('Ritual de Alta Potencia','ritual-de-alta-potencia','Riqueza, abundancia y poder. Activa caminos, rompe bloqueos y decreta prosperidad constante.','/card-ritual.jpg', true, 5),
  ('Pacto · Cambia tu Vida','pacto-cambia-tu-vida','¿Estás listo para el pacto y cambiar tu vida? Ritual poderoso para transformar tu destino.','/card-pacto.jpg', true, 6),
  ('Liberación','liberacion','Renueva, abre y atrae. Rompé lo que te ata y abrí camino a la prosperidad.','/card-liberacion.jpg', true, 7),
  ('Endulzamiento Premium','endulzamiento-premium','Endulzamiento de dominio total: no vuelve igual… vuelve necesitado, obsesionado y completamente entregado a ti.','/card-endulzamiento-premium.jpg', false, 8),
  ('Perfume Pomba Gira','perfume-pomba-gira-servicio','Perfume de Pomba Gira con feromonas — para atraer al hombre. Despierta atención, atrae hombres, irresistible y poderosa. 100 mL.','/card-pomba-gira.jpg', false, 9),
  ('Agenda Abierta','agenda-abierta','Lectura de cartas · Baños · Amuletos · Trabajos personalizados. Reservá tu consulta.','/card-agenda.jpg', false, 10)
) as s(name, slug, short_description, cover_image_url, is_featured, sort_order)
on conflict (slug) do update
  set name = excluded.name, short_description = excluded.short_description,
      cover_image_url = excluded.cover_image_url, is_featured = excluded.is_featured,
      sort_order = excluded.sort_order;

-- ---- tarot_services (two reading modalities, prices hidden) ------------------
insert into altamagiadaniel.tarot_services
  (name, slug, short_description, consultation_type, show_price, whatsapp_message, sort_order)
select t.name, t.slug, t.short_description, t.consultation_type, false,
       'Hola, quiero agendar una ' || t.name, t.sort_order
from (values
  ('Lectura Normal','lectura-normal','Lectura de tarot personalizada.','Videollamada o audio', 1),
  ('Lectura Extensa','lectura-extensa','Lectura de tarot extensa y detallada.','Videollamada o audio', 2)
) as t(name, slug, short_description, consultation_type, sort_order)
on conflict (slug) do update
  set name = excluded.name, short_description = excluded.short_description;

-- ---- products ---------------------------------------------------------------
insert into altamagiadaniel.products
  (category_id, name, slug, short_description, cover_image_url, whatsapp_message, show_price, is_featured, sort_order)
select (select id from altamagiadaniel.product_categories where slug = p.cat),
       p.name, p.slug, p.short_description, p.cover_image_url,
       'Hola, me interesa el producto: ' || p.name, false, p.is_featured, p.sort_order
from (values
  -- perfumes
  ('perfumes','San La Muerte (SLM)','perfume-san-la-muerte','Perfume devocional esotérico con feromonas. Uso masculino y femenino · 50 mL.','/perfume-san-la-muerte.jpg', false, 1),
  ('perfumes','Ven Dinero','perfume-ven-dinero','Perfume esotérico para atraer dinero y prosperidad. Para mujeres y uso masculino · 50 mL.','/perfume-ven-dinero.jpg', false, 2),
  ('perfumes','Pombagira','perfume-pombagira','Perfume emocional esotérico, edición especial con feromona. Atracción y seducción · 100 mL.','/perfume-pombagira.jpg', true, 3),
  ('perfumes','Noche Ardiente','perfume-noche-ardiente','Perfume místico uso femenino con feromonas. Enciende la pasión · 50 mL.','/perfume-noche-ardiente.jpg', false, 4),
  ('perfumes','Diosa','perfume-diosa','Con feromonas. Eleva tu líbido y tu capacidad de atracción, convertite en una femme fatale. Uso femenino · 50 mL.','/perfume-diosa.jpg', false, 5),
  -- figuras
  ('figuras','Baphomet','figura-baphomet','Estatua de Baphomet (Solve · Coagula), negro con detalles dorados. Resina pintada a mano.','/figura-baphomet.jpg', true, 6),
  ('figuras','Pomba Gira','figura-pomba-gira','Figura de Pomba Gira con vestido azul y detalles dorados. Resina pintada a mano.','/figura-pomba-gira.jpg', false, 7),
  ('figuras','San La Muerte del Dinero','figura-san-la-muerte-dolar','Figura de San La Muerte vestida en billetes, con guadaña. Para atraer dinero y prosperidad.','/figura-san-la-muerte-dolar.jpg', false, 8),
  ('figuras','San La Muerte Roja','figura-san-la-muerte-roja','Figura de San La Muerte con manto rojo, sosteniendo el mundo y la guadaña. Protección y peticiones.','/figura-san-la-muerte-roja.jpg', true, 9),
  ('figuras','San La Muerte Blanca','figura-san-la-muerte-blanca','Figura de San La Muerte con manto blanco, sosteniendo el mundo y la guadaña. Protección, paz y limpieza.','/figura-san-la-muerte-blanca.jpg', false, 10),
  ('figuras','Portavela San La Muerte · Negra','figura-portavela-negra','Portavela (candelero) de San La Muerte en cerámica, color negro. Sostiene la vela entre sus manos.','/figura-portavela-negra.jpg', false, 11),
  ('figuras','Portavela San La Muerte · Dorada','figura-portavela-dorada','Portavela (candelero) de San La Muerte en cerámica, color dorado. Sostiene la vela entre sus manos.','/figura-portavela-dorada.jpg', false, 12),
  ('figuras','Portavela San La Muerte · Roja','figura-portavela-roja','Portavela (candelero) de San La Muerte en cerámica, color rojo. Sostiene la vela entre sus manos.','/figura-portavela-roja.jpg', false, 13),
  ('figuras','Portavela San La Muerte · Blanca','figura-portavela-blanca','Portavela (candelero) de San La Muerte en cerámica, color blanco. Sostiene la vela entre sus manos.','/figura-portavela-blanca.jpg', false, 14),
  -- amuletos
  ('amuletos','Mammón · Diablo del Dinero','amuleto-mammon','Amuleto sellado de Mammón, el diablo del dinero. Para atraer riqueza, negocios y prosperidad.','/amuleto-mammon.jpg', true, 15),
  ('amuletos','Set de Amuletos · Riqueza y Protección','amuleto-prosperidad','Kit de amuletos: mano de Hamsa, herradura, signo de dinero, medallas y semillas. Para protección, suerte rápida, abre camino y riqueza.','/amuleto-prosperidad.jpg', false, 16),
  -- otros
  ('otros','Vaso Calavera · Crystal Head','vaso-calavera-crystal-head','Vaso shot con forma de calavera, vidrio transparente (Crystal Head). Apto para uso alimentario.','/vaso-calavera.jpg', false, 17),
  ('otros','Vasos Calavera · Doomed (Set x4)','vaso-calavera-doomed','Set de 4 vasos shot con forma de calavera, vidrio transparente (Doomed). Dale un toque paranormal a tu próxima fiesta.','/vaso-doomed.jpg', false, 18)
) as p(cat, name, slug, short_description, cover_image_url, is_featured, sort_order)
on conflict (slug) do update
  set category_id = excluded.category_id, name = excluded.name,
      short_description = excluded.short_description, cover_image_url = excluded.cover_image_url,
      is_featured = excluded.is_featured, sort_order = excluded.sort_order;

-- primary product image mirrors the cover (idempotent per product)
insert into altamagiadaniel.product_images (product_id, image_url, alt_text, is_primary, sort_order)
select pr.id, pr.cover_image_url, pr.name, true, 0
from altamagiadaniel.products pr
where pr.cover_image_url is not null
  and not exists (
    select 1 from altamagiadaniel.product_images pi
    where pi.product_id = pr.id and pi.is_primary);

-- ---- works (trabajos realizados — videos) -----------------------------------
insert into altamagiadaniel.works (title, slug, media_type, media_url, thumbnail_url, sort_order)
values
  ('Baño Dulce','bano-dulce','video','/trabajo-1.mp4','/trabajo-1-poster.jpg', 1),
  ('Perfumes con feromonas','perfumes-con-feromonas','video','/trabajo-2.mp4','/trabajo-2-poster.jpg', 2),
  ('Nuestra tienda','nuestra-tienda','video','/trabajo-3.mp4','/trabajo-3-poster.jpg', 3)
on conflict (slug) do update
  set title = excluded.title, media_url = excluded.media_url,
      thumbnail_url = excluded.thumbnail_url, sort_order = excluded.sort_order;

-- ---- social_links -----------------------------------------------------------
insert into altamagiadaniel.social_links (platform, label, url, username, sort_order)
select v.platform, v.label, v.url, v.username, v.sort_order
from (values
  ('tiktok','Seguime en TikTok','https://www.tiktok.com/@cartas_y_tarot_py_ofic._','@cartas_y_tarot_py_ofic._', 1),
  ('whatsapp','WhatsApp','https://wa.me/595972542230','+595 972 542230', 2)
) as v(platform, label, url, username, sort_order)
where not exists (select 1 from altamagiadaniel.social_links s where s.platform = v.platform);

commit;
