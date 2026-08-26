-- Cyberbishop visitor log
-- Run this once in the Supabase SQL Editor.
-- Records a lightweight entry once per browser session (not per page view)
-- so the admin can see that someone visited the platform.

create table if not exists public.visits (
  id uuid primary key default gen_random_uuid(),
  page text,
  referrer text,
  user_agent text,
  created_at timestamptz not null default now()
);

create index if not exists visits_created_at_idx on public.visits (created_at desc);

alter table public.visits enable row level security;

-- Anyone (including anonymous visitors) can log a visit.
drop policy if exists "Cyberbishop public visit logging" on public.visits;
create policy "Cyberbishop public visit logging"
on public.visits for insert
to anon, authenticated
with check (true);

-- Only the designated Cyberbishop admin may read the visitor log.
drop policy if exists "Cyberbishop admin read visits" on public.visits;
create policy "Cyberbishop admin read visits"
on public.visits for select
to authenticated
using (auth.uid() = 'ca155628-a765-434e-85ad-d52f25cae573'::uuid);

-- Only the admin may clear the log.
drop policy if exists "Cyberbishop admin delete visits" on public.visits;
create policy "Cyberbishop admin delete visits"
on public.visits for delete
to authenticated
using (auth.uid() = 'ca155628-a765-434e-85ad-d52f25cae573'::uuid);
