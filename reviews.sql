-- Cyberbishop visitor reviews / testimonials
-- Run this in the Supabase SQL Editor after your existing tables/policies.

create table if not exists public.reviews (
  id uuid primary key default gen_random_uuid(),
  target_type text not null check (target_type in ('site','book','song','video')),
  target_id uuid,
  reviewer_name text not null,
  rating int not null check (rating between 1 and 5),
  comment text,
  approved boolean not null default false,
  created_at timestamptz not null default now(),
  constraint reviews_target_id_required check (
    (target_type = 'site' and target_id is null) or
    (target_type <> 'site' and target_id is not null)
  )
);

create index if not exists reviews_target_idx on public.reviews (target_type, target_id, approved);

alter table public.reviews enable row level security;

-- Anyone can submit a review, but it always lands unapproved.
drop policy if exists "Cyberbishop public review submission" on public.reviews;
create policy "Cyberbishop public review submission"
on public.reviews for insert
to anon, authenticated
with check (approved = false);

-- The public can only read reviews the admin has approved.
drop policy if exists "Cyberbishop public read approved reviews" on public.reviews;
create policy "Cyberbishop public read approved reviews"
on public.reviews for select
to anon, authenticated
using (approved = true);

-- Only the designated Cyberbishop admin may read every review (including pending).
drop policy if exists "Cyberbishop admin read all reviews" on public.reviews;
create policy "Cyberbishop admin read all reviews"
on public.reviews for select
to authenticated
using (auth.uid() = 'ca155628-a765-434e-85ad-d52f25cae573'::uuid);

-- Only the admin may approve/edit reviews.
drop policy if exists "Cyberbishop admin update reviews" on public.reviews;
create policy "Cyberbishop admin update reviews"
on public.reviews for update
to authenticated
using (auth.uid() = 'ca155628-a765-434e-85ad-d52f25cae573'::uuid)
with check (auth.uid() = 'ca155628-a765-434e-85ad-d52f25cae573'::uuid);

-- Only the admin may delete reviews (spam removal, etc.)
drop policy if exists "Cyberbishop admin delete reviews" on public.reviews;
create policy "Cyberbishop admin delete reviews"
on public.reviews for delete
to authenticated
using (auth.uid() = 'ca155628-a765-434e-85ad-d52f25cae573'::uuid);
