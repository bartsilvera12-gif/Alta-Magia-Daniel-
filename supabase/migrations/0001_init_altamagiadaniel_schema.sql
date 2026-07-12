-- =============================================================================
--  Alta Magia Daniel — Admin panel schema
--  Migration 0001: schema, shared function, tables, constraints, indexes, triggers
--
--  ALL objects live in the isolated schema `altamagiadaniel`.
--  Nothing is created in `public`. Auth stays in `auth.users`; the link is
--  altamagiadaniel.admin_profiles.user_id -> auth.users.id.
--
--  Idempotent: safe to run multiple times.
-- =============================================================================

create schema if not exists altamagiadaniel;

-- pgcrypto provides gen_random_uuid(). Supabase enables it by default; create
-- only if available and only in the extensions/public location already used by
-- the platform (do NOT relocate a shared extension).
create extension if not exists pgcrypto;

-- -----------------------------------------------------------------------------
--  Shared trigger function (schema-scoped, never in public)
-- -----------------------------------------------------------------------------
create or replace function altamagiadaniel.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- Helper to (re)attach the updated_at trigger without duplicating it.
create or replace function altamagiadaniel.attach_updated_at(p_table regclass)
returns void
language plpgsql
as $$
declare
  v_name text := 'set_updated_at_' || split_part(p_table::text, '.', 2);
begin
  execute format('drop trigger if exists %I on %s', v_name, p_table);
  execute format(
    'create trigger %I before update on %s for each row execute function altamagiadaniel.set_updated_at()',
    v_name, p_table);
end;
$$;

-- =============================================================================
--  TABLES
-- =============================================================================

-- 1. admin_profiles ------------------------------------------------------------
create table if not exists altamagiadaniel.admin_profiles (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null unique references auth.users(id) on delete cascade,
  full_name    text,
  role         text not null default 'editor' check (role in ('super_admin','admin','editor')),
  avatar_url   text,
  is_active    boolean not null default true,
  last_login_at timestamptz,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

-- 2. site_settings -------------------------------------------------------------
create table if not exists altamagiadaniel.site_settings (
  id                        uuid primary key default gen_random_uuid(),
  site_name                 text,
  site_subtitle             text,
  logo_url                  text,
  favicon_url               text,
  primary_phone             text,
  whatsapp_number           text,
  whatsapp_default_message  text,
  contact_email             text,
  address                   text,
  business_hours            text,
  seo_title                 text,
  seo_description           text,
  seo_keywords              text,
  og_image_url              text,
  footer_text               text,
  developed_by_text         text,
  developed_by_url          text,
  is_active                 boolean not null default true,
  created_by                uuid references altamagiadaniel.admin_profiles(id),
  updated_by                uuid references altamagiadaniel.admin_profiles(id),
  created_at                timestamptz not null default now(),
  updated_at                timestamptz not null default now()
);
-- Only one active settings row.
create unique index if not exists site_settings_single_active
  on altamagiadaniel.site_settings (is_active) where is_active;

-- 3. navigation_items ----------------------------------------------------------
create table if not exists altamagiadaniel.navigation_items (
  id          uuid primary key default gen_random_uuid(),
  label       text not null check (length(trim(label)) > 0),
  href        text not null check (length(trim(href)) > 0),
  target      text default '_self' check (target in ('_self','_blank')),
  icon        text,
  sort_order  integer not null default 0 check (sort_order >= 0),
  is_visible  boolean not null default true,
  is_active   boolean not null default true,
  created_by  uuid references altamagiadaniel.admin_profiles(id),
  updated_by  uuid references altamagiadaniel.admin_profiles(id),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- 4. hero_slides ---------------------------------------------------------------
create table if not exists altamagiadaniel.hero_slides (
  id                    uuid primary key default gen_random_uuid(),
  eyebrow               text,
  title                 text,
  subtitle              text,
  description           text,
  desktop_image_url     text,
  mobile_image_url      text,
  background_video_url  text,
  primary_button_text   text,
  primary_button_url    text,
  secondary_button_text text,
  secondary_button_url  text,
  overlay_opacity       numeric(3,2) default 0.60 check (overlay_opacity >= 0 and overlay_opacity <= 1),
  sort_order            integer not null default 0 check (sort_order >= 0),
  is_active             boolean not null default true,
  created_by            uuid references altamagiadaniel.admin_profiles(id),
  updated_by            uuid references altamagiadaniel.admin_profiles(id),
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now()
);

-- 5. about_sections ------------------------------------------------------------
create table if not exists altamagiadaniel.about_sections (
  id                  uuid primary key default gen_random_uuid(),
  section_key         text not null unique check (length(trim(section_key)) > 0),
  eyebrow             text,
  title               text,
  subtitle            text,
  content             text,
  quote               text,
  signature           text,
  image_url           text,
  secondary_image_url text,
  sort_order          integer not null default 0 check (sort_order >= 0),
  is_active           boolean not null default true,
  created_by          uuid references altamagiadaniel.admin_profiles(id),
  updated_by          uuid references altamagiadaniel.admin_profiles(id),
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

-- 6. service_categories --------------------------------------------------------
create table if not exists altamagiadaniel.service_categories (
  id          uuid primary key default gen_random_uuid(),
  name        text not null check (length(trim(name)) > 0),
  slug        text not null unique check (length(trim(slug)) > 0),
  description text,
  image_url   text,
  sort_order  integer not null default 0 check (sort_order >= 0),
  is_active   boolean not null default true,
  created_by  uuid references altamagiadaniel.admin_profiles(id),
  updated_by  uuid references altamagiadaniel.admin_profiles(id),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- 7. services ------------------------------------------------------------------
create table if not exists altamagiadaniel.services (
  id                uuid primary key default gen_random_uuid(),
  category_id       uuid references altamagiadaniel.service_categories(id) on delete set null,
  name              text not null check (length(trim(name)) > 0),
  slug              text not null unique check (length(trim(slug)) > 0),
  short_description text,
  full_description  text,
  image_url         text,
  cover_image_url   text,
  video_url         text,
  duration_text     text,
  price             numeric(12,2) check (price is null or price >= 0),
  currency          text not null default 'PYG',
  show_price        boolean not null default false,
  button_text       text,
  whatsapp_message  text,
  is_featured       boolean not null default false,
  sort_order        integer not null default 0 check (sort_order >= 0),
  is_active         boolean not null default true,
  created_by        uuid references altamagiadaniel.admin_profiles(id),
  updated_by        uuid references altamagiadaniel.admin_profiles(id),
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

-- 8. service_gallery -----------------------------------------------------------
create table if not exists altamagiadaniel.service_gallery (
  id            uuid primary key default gen_random_uuid(),
  service_id    uuid not null references altamagiadaniel.services(id) on delete cascade,
  media_type    text not null check (media_type in ('image','video')),
  media_url     text not null check (length(trim(media_url)) > 0),
  thumbnail_url text,
  alt_text      text,
  sort_order    integer not null default 0 check (sort_order >= 0),
  is_active     boolean not null default true,
  created_at    timestamptz not null default now()
);

-- 9. tarot_services ------------------------------------------------------------
create table if not exists altamagiadaniel.tarot_services (
  id                uuid primary key default gen_random_uuid(),
  name              text not null check (length(trim(name)) > 0),
  slug              text not null unique check (length(trim(slug)) > 0),
  short_description text,
  full_description  text,
  image_url         text,
  consultation_type text,
  duration_text     text,
  price             numeric(12,2) check (price is null or price >= 0),
  show_price        boolean not null default false,
  whatsapp_message  text,
  sort_order        integer not null default 0 check (sort_order >= 0),
  is_active         boolean not null default true,
  created_by        uuid references altamagiadaniel.admin_profiles(id),
  updated_by        uuid references altamagiadaniel.admin_profiles(id),
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

-- 10. product_categories (self-referencing for sub-categories) -----------------
create table if not exists altamagiadaniel.product_categories (
  id          uuid primary key default gen_random_uuid(),
  parent_id   uuid references altamagiadaniel.product_categories(id) on delete set null,
  name        text not null check (length(trim(name)) > 0),
  slug        text not null unique check (length(trim(slug)) > 0),
  description text,
  image_url   text,
  sort_order  integer not null default 0 check (sort_order >= 0),
  is_active   boolean not null default true,
  created_by  uuid references altamagiadaniel.admin_profiles(id),
  updated_by  uuid references altamagiadaniel.admin_profiles(id),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  constraint product_categories_no_self_parent check (parent_id is null or parent_id <> id)
);

-- 11. products -----------------------------------------------------------------
create table if not exists altamagiadaniel.products (
  id                uuid primary key default gen_random_uuid(),
  category_id       uuid references altamagiadaniel.product_categories(id) on delete set null,
  name              text not null check (length(trim(name)) > 0),
  slug              text not null unique check (length(trim(slug)) > 0),
  sku               text,
  short_description text,
  full_description  text,
  price             numeric(12,2) check (price is null or price >= 0),
  promotional_price numeric(12,2) check (promotional_price is null or promotional_price >= 0),
  show_price        boolean not null default false,
  stock             integer check (stock is null or stock >= 0),
  manage_stock      boolean not null default false,
  cover_image_url   text,
  whatsapp_message  text,
  is_featured       boolean not null default false,
  sort_order        integer not null default 0 check (sort_order >= 0),
  is_active         boolean not null default true,
  created_by        uuid references altamagiadaniel.admin_profiles(id),
  updated_by        uuid references altamagiadaniel.admin_profiles(id),
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  -- when stock is managed it must be present and non-negative
  constraint products_stock_when_managed check (not manage_stock or stock is not null)
);

-- 12. product_images -----------------------------------------------------------
create table if not exists altamagiadaniel.product_images (
  id          uuid primary key default gen_random_uuid(),
  product_id  uuid not null references altamagiadaniel.products(id) on delete cascade,
  image_url   text not null check (length(trim(image_url)) > 0),
  alt_text    text,
  sort_order  integer not null default 0 check (sort_order >= 0),
  is_primary  boolean not null default false,
  is_active   boolean not null default true,
  created_at  timestamptz not null default now()
);
-- At most one primary image per product.
create unique index if not exists product_images_one_primary
  on altamagiadaniel.product_images (product_id) where is_primary;

-- 13. product_attributes -------------------------------------------------------
create table if not exists altamagiadaniel.product_attributes (
  id              uuid primary key default gen_random_uuid(),
  product_id      uuid not null references altamagiadaniel.products(id) on delete cascade,
  attribute_name  text not null check (length(trim(attribute_name)) > 0),
  attribute_value text,
  sort_order      integer not null default 0 check (sort_order >= 0),
  created_at      timestamptz not null default now()
);

-- 14. works (trabajos realizados) ----------------------------------------------
create table if not exists altamagiadaniel.works (
  id            uuid primary key default gen_random_uuid(),
  title         text,
  slug          text unique,
  description   text,
  media_type    text not null default 'video' check (media_type in ('image','video','embed')),
  media_url     text,
  thumbnail_url text,
  external_url  text,
  sort_order    integer not null default 0 check (sort_order >= 0),
  is_featured   boolean not null default false,
  is_active     boolean not null default true,
  created_by    uuid references altamagiadaniel.admin_profiles(id),
  updated_by    uuid references altamagiadaniel.admin_profiles(id),
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

-- 15. testimonials -------------------------------------------------------------
create table if not exists altamagiadaniel.testimonials (
  id              uuid primary key default gen_random_uuid(),
  client_name     text not null check (length(trim(client_name)) > 0),
  client_location text,
  content         text,
  rating          integer check (rating is null or (rating between 1 and 5)),
  avatar_url      text,
  sort_order      integer not null default 0 check (sort_order >= 0),
  is_featured     boolean not null default false,
  is_active       boolean not null default true,
  created_by      uuid references altamagiadaniel.admin_profiles(id),
  updated_by      uuid references altamagiadaniel.admin_profiles(id),
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

-- 16. social_links -------------------------------------------------------------
create table if not exists altamagiadaniel.social_links (
  id          uuid primary key default gen_random_uuid(),
  platform    text not null check (length(trim(platform)) > 0),
  label       text,
  url         text not null check (length(trim(url)) > 0),
  icon        text,
  username    text,
  sort_order  integer not null default 0 check (sort_order >= 0),
  is_visible  boolean not null default true,
  is_active   boolean not null default true,
  created_by  uuid references altamagiadaniel.admin_profiles(id),
  updated_by  uuid references altamagiadaniel.admin_profiles(id),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- 17. contact_messages ---------------------------------------------------------
create table if not exists altamagiadaniel.contact_messages (
  id         uuid primary key default gen_random_uuid(),
  full_name  text,
  phone      text,
  email      text,
  subject    text,
  message    text not null check (length(trim(message)) > 0),
  source     text,
  status     text not null default 'new' check (status in ('new','read','replied','archived')),
  notes      text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 18. page_sections (generic blocks that don't fit a specific table) -----------
create table if not exists altamagiadaniel.page_sections (
  id          uuid primary key default gen_random_uuid(),
  page_key    text not null check (length(trim(page_key)) > 0),
  section_key text not null check (length(trim(section_key)) > 0),
  title       text,
  subtitle    text,
  content     text,
  image_url   text,
  metadata    jsonb not null default '{}'::jsonb,
  sort_order  integer not null default 0 check (sort_order >= 0),
  is_active   boolean not null default true,
  created_by  uuid references altamagiadaniel.admin_profiles(id),
  updated_by  uuid references altamagiadaniel.admin_profiles(id),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  unique (page_key, section_key)
);

-- =============================================================================
--  updated_at triggers (only tables that have updated_at)
-- =============================================================================
select altamagiadaniel.attach_updated_at('altamagiadaniel.admin_profiles');
select altamagiadaniel.attach_updated_at('altamagiadaniel.site_settings');
select altamagiadaniel.attach_updated_at('altamagiadaniel.navigation_items');
select altamagiadaniel.attach_updated_at('altamagiadaniel.hero_slides');
select altamagiadaniel.attach_updated_at('altamagiadaniel.about_sections');
select altamagiadaniel.attach_updated_at('altamagiadaniel.service_categories');
select altamagiadaniel.attach_updated_at('altamagiadaniel.services');
select altamagiadaniel.attach_updated_at('altamagiadaniel.tarot_services');
select altamagiadaniel.attach_updated_at('altamagiadaniel.product_categories');
select altamagiadaniel.attach_updated_at('altamagiadaniel.products');
select altamagiadaniel.attach_updated_at('altamagiadaniel.works');
select altamagiadaniel.attach_updated_at('altamagiadaniel.testimonials');
select altamagiadaniel.attach_updated_at('altamagiadaniel.social_links');
select altamagiadaniel.attach_updated_at('altamagiadaniel.contact_messages');
select altamagiadaniel.attach_updated_at('altamagiadaniel.page_sections');

-- =============================================================================
--  INDEXES  (slug, is_active, sort_order, fks, is_featured, created_at, user_id)
-- =============================================================================
create index if not exists idx_admin_profiles_user_id     on altamagiadaniel.admin_profiles (user_id);
create index if not exists idx_admin_profiles_active       on altamagiadaniel.admin_profiles (is_active);

create index if not exists idx_nav_active_sort             on altamagiadaniel.navigation_items (is_active, sort_order);

create index if not exists idx_hero_active_sort            on altamagiadaniel.hero_slides (is_active, sort_order);

create index if not exists idx_about_active_sort           on altamagiadaniel.about_sections (is_active, sort_order);

create index if not exists idx_service_cat_active_sort     on altamagiadaniel.service_categories (is_active, sort_order);

create index if not exists idx_services_active_sort        on altamagiadaniel.services (is_active, sort_order);
create index if not exists idx_services_category           on altamagiadaniel.services (category_id);
create index if not exists idx_services_featured           on altamagiadaniel.services (is_featured) where is_featured;

create index if not exists idx_service_gallery_service     on altamagiadaniel.service_gallery (service_id, sort_order);

create index if not exists idx_tarot_active_sort           on altamagiadaniel.tarot_services (is_active, sort_order);

create index if not exists idx_prod_cat_active_sort        on altamagiadaniel.product_categories (is_active, sort_order);
create index if not exists idx_prod_cat_parent             on altamagiadaniel.product_categories (parent_id);

create index if not exists idx_products_active_sort        on altamagiadaniel.products (is_active, sort_order);
create index if not exists idx_products_category           on altamagiadaniel.products (category_id);
create index if not exists idx_products_featured           on altamagiadaniel.products (is_featured) where is_featured;

create index if not exists idx_product_images_product      on altamagiadaniel.product_images (product_id, sort_order);
create index if not exists idx_product_attributes_product  on altamagiadaniel.product_attributes (product_id, sort_order);

create index if not exists idx_works_active_sort           on altamagiadaniel.works (is_active, sort_order);
create index if not exists idx_works_featured              on altamagiadaniel.works (is_featured) where is_featured;

create index if not exists idx_testimonials_active_sort    on altamagiadaniel.testimonials (is_active, sort_order);
create index if not exists idx_testimonials_featured       on altamagiadaniel.testimonials (is_featured) where is_featured;

create index if not exists idx_social_active_sort          on altamagiadaniel.social_links (is_active, sort_order);

create index if not exists idx_contact_status_created      on altamagiadaniel.contact_messages (status, created_at desc);

create index if not exists idx_page_sections_page          on altamagiadaniel.page_sections (page_key, is_active, sort_order);
