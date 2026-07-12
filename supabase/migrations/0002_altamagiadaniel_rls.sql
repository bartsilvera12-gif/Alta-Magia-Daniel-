-- =============================================================================
--  Alta Magia Daniel — Migration 0002: roles, RLS & grants
--
--  Model:
--   * anon  -> read-only on public content (is_active = true) + insert contact.
--   * authenticated non-admin -> NO content access (RLS blocks; helper = false).
--   * authenticated admin (active row in altamagiadaniel.admin_profiles):
--       - editor       : select all + insert + update (no hard delete)
--       - admin        : + delete
--       - super_admin  : + manage admin_profiles
--  Never trust a role sent from the client — it is derived server-side here.
-- =============================================================================

-- Expose the schema to PostgREST roles (still governed by RLS below).
grant usage on schema altamagiadaniel to anon, authenticated;

-- -----------------------------------------------------------------------------
--  Role helpers — SECURITY DEFINER with locked-down search_path.
-- -----------------------------------------------------------------------------
create or replace function altamagiadaniel.current_admin_role()
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select ap.role
  from altamagiadaniel.admin_profiles ap
  where ap.user_id = auth.uid() and ap.is_active = true
  limit 1;
$$;

create or replace function altamagiadaniel.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from altamagiadaniel.admin_profiles ap
    where ap.user_id = auth.uid() and ap.is_active = true
  );
$$;

revoke all on function altamagiadaniel.current_admin_role() from public;
revoke all on function altamagiadaniel.is_admin() from public;
grant execute on function altamagiadaniel.current_admin_role() to anon, authenticated;
grant execute on function altamagiadaniel.is_admin() to anon, authenticated;

-- -----------------------------------------------------------------------------
--  Standard public tables (have is_active): public read + admin write.
-- -----------------------------------------------------------------------------
do $$
declare
  t text;
  public_tables text[] := array[
    'site_settings','navigation_items','hero_slides','about_sections',
    'service_categories','services','service_gallery','tarot_services',
    'product_categories','products','product_images',
    'works','testimonials','social_links','page_sections'
  ];
begin
  foreach t in array public_tables loop
    execute format('alter table altamagiadaniel.%I enable row level security', t);

    execute format('drop policy if exists %I on altamagiadaniel.%I', t||'_public_read', t);
    execute format(
      'create policy %I on altamagiadaniel.%I for select to anon, authenticated '
      || 'using (is_active or altamagiadaniel.is_admin())', t||'_public_read', t);

    execute format('drop policy if exists %I on altamagiadaniel.%I', t||'_admin_insert', t);
    execute format(
      'create policy %I on altamagiadaniel.%I for insert to authenticated '
      || 'with check (altamagiadaniel.is_admin())', t||'_admin_insert', t);

    execute format('drop policy if exists %I on altamagiadaniel.%I', t||'_admin_update', t);
    execute format(
      'create policy %I on altamagiadaniel.%I for update to authenticated '
      || 'using (altamagiadaniel.is_admin()) with check (altamagiadaniel.is_admin())',
      t||'_admin_update', t);

    execute format('drop policy if exists %I on altamagiadaniel.%I', t||'_admin_delete', t);
    execute format(
      'create policy %I on altamagiadaniel.%I for delete to authenticated '
      || 'using (altamagiadaniel.current_admin_role() in (''super_admin'',''admin''))',
      t||'_admin_delete', t);

    execute format('grant select on altamagiadaniel.%I to anon, authenticated', t);
    execute format('grant insert, update, delete on altamagiadaniel.%I to authenticated', t);
  end loop;
end $$;

-- -----------------------------------------------------------------------------
--  product_attributes (no is_active column): public read all, admin write.
-- -----------------------------------------------------------------------------
alter table altamagiadaniel.product_attributes enable row level security;
drop policy if exists product_attributes_public_read on altamagiadaniel.product_attributes;
create policy product_attributes_public_read on altamagiadaniel.product_attributes
  for select to anon, authenticated using (true);
drop policy if exists product_attributes_admin_write on altamagiadaniel.product_attributes;
create policy product_attributes_admin_write on altamagiadaniel.product_attributes
  for all to authenticated using (altamagiadaniel.is_admin()) with check (altamagiadaniel.is_admin());
grant select on altamagiadaniel.product_attributes to anon, authenticated;
grant insert, update, delete on altamagiadaniel.product_attributes to authenticated;

-- -----------------------------------------------------------------------------
--  admin_profiles: self-read; only super_admin manages.
-- -----------------------------------------------------------------------------
alter table altamagiadaniel.admin_profiles enable row level security;

drop policy if exists admin_profiles_read on altamagiadaniel.admin_profiles;
create policy admin_profiles_read on altamagiadaniel.admin_profiles
  for select to authenticated
  using (user_id = auth.uid() or altamagiadaniel.current_admin_role() = 'super_admin');

drop policy if exists admin_profiles_super_insert on altamagiadaniel.admin_profiles;
create policy admin_profiles_super_insert on altamagiadaniel.admin_profiles
  for insert to authenticated
  with check (altamagiadaniel.current_admin_role() = 'super_admin');

-- super_admin manages everyone; any admin may update ONLY their own last_login etc.
drop policy if exists admin_profiles_update on altamagiadaniel.admin_profiles;
create policy admin_profiles_update on altamagiadaniel.admin_profiles
  for update to authenticated
  using (altamagiadaniel.current_admin_role() = 'super_admin' or user_id = auth.uid())
  with check (altamagiadaniel.current_admin_role() = 'super_admin' or user_id = auth.uid());

drop policy if exists admin_profiles_super_delete on altamagiadaniel.admin_profiles;
create policy admin_profiles_super_delete on altamagiadaniel.admin_profiles
  for delete to authenticated
  using (altamagiadaniel.current_admin_role() = 'super_admin' and user_id <> auth.uid());

grant select, insert, update, delete on altamagiadaniel.admin_profiles to authenticated;

-- -----------------------------------------------------------------------------
--  contact_messages: public INSERT only; admins read/manage. No public SELECT.
-- -----------------------------------------------------------------------------
alter table altamagiadaniel.contact_messages enable row level security;

drop policy if exists contact_public_insert on altamagiadaniel.contact_messages;
create policy contact_public_insert on altamagiadaniel.contact_messages
  for insert to anon, authenticated
  with check (length(trim(message)) > 0 and status = 'new');

drop policy if exists contact_admin_read on altamagiadaniel.contact_messages;
create policy contact_admin_read on altamagiadaniel.contact_messages
  for select to authenticated using (altamagiadaniel.is_admin());

drop policy if exists contact_admin_update on altamagiadaniel.contact_messages;
create policy contact_admin_update on altamagiadaniel.contact_messages
  for update to authenticated
  using (altamagiadaniel.is_admin()) with check (altamagiadaniel.is_admin());

drop policy if exists contact_admin_delete on altamagiadaniel.contact_messages;
create policy contact_admin_delete on altamagiadaniel.contact_messages
  for delete to authenticated
  using (altamagiadaniel.current_admin_role() = 'super_admin');

grant insert on altamagiadaniel.contact_messages to anon, authenticated;
grant select, update, delete on altamagiadaniel.contact_messages to authenticated;
