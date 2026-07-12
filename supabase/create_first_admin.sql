-- =============================================================================
--  Create the FIRST super-admin profile (Fase 22).
--
--  Passwords are NEVER stored here. Create the user first in Supabase Auth
--  (Dashboard > Authentication > Add user, or the Admin API), then run this to
--  link that auth user to an active super_admin profile.
--
--  Usage:
--    psql "$SUPABASE_DB_URL" -v email='daniel@altamagiadaniel.com' \
--         -f supabase/create_first_admin.sql
--
--  Idempotent: re-running just re-asserts super_admin + active.
-- =============================================================================
insert into altamagiadaniel.admin_profiles (user_id, full_name, role, is_active)
select u.id,
       coalesce(nullif(u.raw_user_meta_data->>'full_name',''), 'Administrador'),
       'super_admin', true
from auth.users u
where u.email = :'email'
on conflict (user_id) do update
  set role = 'super_admin', is_active = true, updated_at = now();

-- Confirm:
select ap.id, u.email, ap.role, ap.is_active
from altamagiadaniel.admin_profiles ap
join auth.users u on u.id = ap.user_id
where u.email = :'email';
