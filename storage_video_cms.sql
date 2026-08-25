-- Cyberbishop video schema + storage CMS migration
-- Run once in Supabase SQL Editor.
-- This migration is safe for an existing videos table: it adds the CMS fields
-- needed for uploaded media without removing existing video_url data.

create extension if not exists pgcrypto;

create table if not exists public.videos (
  id uuid primary key default gen_random_uuid(),
  category_id uuid references public.categories(id) on delete set null,
  title text not null,
  description text,
  video_url text,
  link_label text default 'Watch',
  thumbnail_url text,
  source_type text not null default 'external' check (source_type in ('upload','external')),
  storage_path text,
  original_filename text,
  mime_type text,
  file_size bigint,
  duration_seconds integer,
  tags text[] not null default '{}',
  featured boolean not null default false,
  display_order integer not null default 0,
  published boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.videos add column if not exists thumbnail_url text;
alter table public.videos add column if not exists source_type text not null default 'external';
alter table public.videos add column if not exists storage_path text;
alter table public.videos add column if not exists original_filename text;
alter table public.videos add column if not exists mime_type text;
alter table public.videos add column if not exists file_size bigint;
alter table public.videos add column if not exists duration_seconds integer;
alter table public.videos add column if not exists tags text[] not null default '{}';
alter table public.videos add column if not exists featured boolean not null default false;
alter table public.videos add column if not exists updated_at timestamptz not null default now();

update public.videos set source_type = case when storage_path is not null then 'upload' else 'external' end
where source_type is null or source_type not in ('upload','external');

alter table public.videos drop constraint if exists videos_source_type_check;
alter table public.videos add constraint videos_source_type_check check (source_type in ('upload','external'));

create or replace function public.set_videos_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end; $$;

drop trigger if exists videos_updated_at on public.videos;
create trigger videos_updated_at before update on public.videos
for each row execute function public.set_videos_updated_at();

create index if not exists videos_published_order_idx on public.videos (published, display_order);
create index if not exists videos_featured_idx on public.videos (featured) where featured = true;

-- RLS: public visitors can read published videos; only the designated admin can write.
alter table public.videos enable row level security;
drop policy if exists "Cyberbishop public published videos" on public.videos;
create policy "Cyberbishop public published videos" on public.videos
for select to anon, authenticated using (published = true);

drop policy if exists "Cyberbishop admin read videos" on public.videos;
create policy "Cyberbishop admin read videos" on public.videos
for select to authenticated using (auth.uid() = 'ca155628-a765-434e-85ad-d52f25cae573'::uuid);

drop policy if exists "Cyberbishop admin insert videos" on public.videos;
create policy "Cyberbishop admin insert videos" on public.videos
for insert to authenticated with check (auth.uid() = 'ca155628-a765-434e-85ad-d52f25cae573'::uuid);

drop policy if exists "Cyberbishop admin update videos" on public.videos;
create policy "Cyberbishop admin update videos" on public.videos
for update to authenticated using (auth.uid() = 'ca155628-a765-434e-85ad-d52f25cae573'::uuid)
with check (auth.uid() = 'ca155628-a765-434e-85ad-d52f25cae573'::uuid);

drop policy if exists "Cyberbishop admin delete videos" on public.videos;
create policy "Cyberbishop admin delete videos" on public.videos
for delete to authenticated using (auth.uid() = 'ca155628-a765-434e-85ad-d52f25cae573'::uuid);

-- Storage bucket for uploaded video files.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('videos','videos',true,524288000,array['video/mp4','video/webm','video/ogg','video/quicktime','video/x-m4v'])
on conflict (id) do update set
  public = true,
  file_size_limit = 524288000,
  allowed_mime_types = array['video/mp4','video/webm','video/ogg','video/quicktime','video/x-m4v'];

drop policy if exists "Cyberbishop admin video uploads" on storage.objects;
create policy "Cyberbishop admin video uploads" on storage.objects for insert to authenticated
with check (bucket_id='videos' and auth.uid()='ca155628-a765-434e-85ad-d52f25cae573'::uuid);

drop policy if exists "Cyberbishop admin video updates" on storage.objects;
create policy "Cyberbishop admin video updates" on storage.objects for update to authenticated
using (bucket_id='videos' and auth.uid()='ca155628-a765-434e-85ad-d52f25cae573'::uuid)
with check (bucket_id='videos' and auth.uid()='ca155628-a765-434e-85ad-d52f25cae573'::uuid);

drop policy if exists "Cyberbishop admin video deletes" on storage.objects;
create policy "Cyberbishop admin video deletes" on storage.objects for delete to authenticated
using (bucket_id='videos' and auth.uid()='ca155628-a765-434e-85ad-d52f25cae573'::uuid);

drop policy if exists "Cyberbishop public video playback" on storage.objects;
create policy "Cyberbishop public video playback" on storage.objects for select to anon, authenticated
using (bucket_id='videos');
