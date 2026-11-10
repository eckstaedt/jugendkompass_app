-- public.is_admin() read the role from auth.users, where it is always
-- 'authenticated' – so it was never true and every policy using it blocked
-- admins too (popups, announcement images, audio translations, verse pool,
-- translation panel reads …). Check public.users like is_admin(uuid) does.
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.is_admin(auth.uid());
$$;
