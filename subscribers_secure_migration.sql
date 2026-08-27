-- Cyberbishop: extend the EXISTING subscribers table (created in
-- hero_and_subscribers_schema.sql) to support the newsletter/broadcast system.
-- This does not create a new table — it reuses what's already there.

alter table public.subscribers
  add column if not exists status text not null default 'active',
  add column if not exists unsubscribed_at timestamptz;

alter table public.subscribers
  add constraint subscribers_status_check check (status in ('active','unsubscribed'));

create index if not exists subscribers_status_idx on public.subscribers (status);

-- Tighten RLS: subscribing/unsubscribing now goes through server-side API routes
-- (api/subscribe.js, api/unsubscribe.js) using the service-role key, which bypasses
-- RLS entirely. So the browser no longer needs — or gets — direct insert access.
drop policy if exists "Cyberbishop public subscribe" on public.subscribers;

-- Let the admin update a subscriber's status manually from the dashboard if needed.
drop policy if exists "Cyberbishop admin update subscribers" on public.subscribers;
create policy "Cyberbishop admin update subscribers"
on public.subscribers for update
to authenticated
using (auth.uid() = 'ca155628-a765-434e-85ad-d52f25cae573'::uuid)
with check (auth.uid() = 'ca155628-a765-434e-85ad-d52f25cae573'::uuid);

-- (admin read + admin delete policies from hero_and_subscribers_schema.sql are unchanged)
