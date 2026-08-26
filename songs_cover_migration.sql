-- Adds photo-cover support to songs, and ensures the "covers" storage
-- bucket (already used for book covers) exists with the right policies
-- so admin uploads work for songs too. Safe to re-run.

alter table public.songs add column if not exists cover_image_url text;

-- Ensure the covers bucket exists and is public-readable.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('covers','covers',true,10485760,array['image/jpeg','image/png','image/webp','image/gif'])
on conflict (id) do update set
  public = true,
  file_size_limit = 10485760,
  allowed_mime_types = array['image/jpeg','image/png','image/webp','image/gif'];

drop policy if exists "Cyberbishop admin cover uploads" on storage.objects;
create policy "Cyberbishop admin cover uploads" on storage.objects for insert to authenticated
with check (bucket_id='covers' and auth.uid()='ca155628-a765-434e-85ad-d52f25cae573'::uuid);

drop policy if exists "Cyberbishop admin cover updates" on storage.objects;
create policy "Cyberbishop admin cover updates" on storage.objects for update to authenticated
using (bucket_id='covers' and auth.uid()='ca155628-a765-434e-85ad-d52f25cae573'::uuid)
with check (bucket_id='covers' and auth.uid()='ca155628-a765-434e-85ad-d52f25cae573'::uuid);

drop policy if exists "Cyberbishop admin cover deletes" on storage.objects;
create policy "Cyberbishop admin cover deletes" on storage.objects for delete to authenticated
using (bucket_id='covers' and auth.uid()='ca155628-a765-434e-85ad-d52f25cae573'::uuid);

drop policy if exists "Cyberbishop public cover viewing" on storage.objects;
create policy "Cyberbishop public cover viewing" on storage.objects for select to anon, authenticated
using (bucket_id='covers');
