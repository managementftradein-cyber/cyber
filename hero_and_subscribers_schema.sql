-- Cyberbishop: editable homepage hero + email subscribers
-- Run this in the Supabase SQL Editor after your existing tables/policies.

-- Homepage hero: editable heading, highlighted phrase, subtext, and a set of
-- background photos the homepage cross-fades between automatically.
alter table public.site_settings
  add column if not exists hero_heading text,
  add column if not exists hero_highlight text,
  add column if not exists hero_subtext text,
  add column if not exists hero_images text[] not null default '{}';

-- Email subscribers ("Subscribe to get notifications of updates").
create table if not exists public.subscribers (
  id uuid primary key default gen_random_uuid(),
  email text not null unique,
  created_at timestamptz not null default now()
);

alter table public.subscribers enable row level security;

-- Anyone can subscribe.
drop policy if exists "Cyberbishop public subscribe" on public.subscribers;
create policy "Cyberbishop public subscribe"
on public.subscribers for insert
to anon, authenticated
with check (true);

-- Only the admin can see or export the subscriber list.
drop policy if exists "Cyberbishop admin read subscribers" on public.subscribers;
create policy "Cyberbishop admin read subscribers"
on public.subscribers for select
to authenticated
using (auth.uid() = 'ca155628-a765-434e-85ad-d52f25cae573'::uuid);

drop policy if exists "Cyberbishop admin delete subscribers" on public.subscribers;
create policy "Cyberbishop admin delete subscribers"
on public.subscribers for delete
to authenticated
using (auth.uid() = 'ca155628-a765-434e-85ad-d52f25cae573'::uuid);
