-- Cyberbishop RLS verification
-- Run in Supabase SQL Editor before production deployment.

SELECT
  schemaname,
  tablename,
  policyname,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE schemaname IN ('public', 'storage')
  AND (
    tablename IN ('categories', 'books', 'songs', 'videos', 'site_settings')
    OR (schemaname = 'storage' AND tablename = 'objects')
  )
ORDER BY schemaname, tablename, policyname;

-- The administrator UID that should be used by the write policies is:
-- ca155628-a765-434e-85ad-d52f25cae573
--
-- Do NOT deploy if write policies use WITH CHECK (true) or USING (true)
-- for the authenticated role without restricting the administrator.
