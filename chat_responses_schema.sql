-- Cyberbishop chatbot: admin-editable canned responses + AI fallback toggle
-- Run this in the Supabase SQL Editor after your existing tables/policies.

create table if not exists public.chat_responses (
  id uuid primary key default gen_random_uuid(),
  trigger_phrases text not null, -- comma-separated keywords/phrases to match in the visitor's message
  response text not null,        -- the exact reply the admin wrote
  priority int not null default 0, -- higher priority wins when multiple triggers match
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create index if not exists chat_responses_active_idx on public.chat_responses (active, priority desc);

alter table public.chat_responses enable row level security;

-- The public (site visitors) can only read active canned responses.
drop policy if exists "Cyberbishop public read active chat responses" on public.chat_responses;
create policy "Cyberbishop public read active chat responses"
on public.chat_responses for select
to anon, authenticated
using (active = true);

-- Only the admin can read every response (including inactive ones), for the admin dashboard.
drop policy if exists "Cyberbishop admin read all chat responses" on public.chat_responses;
create policy "Cyberbishop admin read all chat responses"
on public.chat_responses for select
to authenticated
using (auth.uid() = 'ca155628-a765-434e-85ad-d52f25cae573'::uuid);

-- Only the admin may create/edit/delete canned responses.
drop policy if exists "Cyberbishop admin write chat responses" on public.chat_responses;
create policy "Cyberbishop admin write chat responses"
on public.chat_responses for insert
to authenticated
with check (auth.uid() = 'ca155628-a765-434e-85ad-d52f25cae573'::uuid);

drop policy if exists "Cyberbishop admin update chat responses" on public.chat_responses;
create policy "Cyberbishop admin update chat responses"
on public.chat_responses for update
to authenticated
using (auth.uid() = 'ca155628-a765-434e-85ad-d52f25cae573'::uuid)
with check (auth.uid() = 'ca155628-a765-434e-85ad-d52f25cae573'::uuid);

drop policy if exists "Cyberbishop admin delete chat responses" on public.chat_responses;
create policy "Cyberbishop admin delete chat responses"
on public.chat_responses for delete
to authenticated
using (auth.uid() = 'ca155628-a765-434e-85ad-d52f25cae573'::uuid);

-- Toggle to let the admin turn the paid AI fallback on/off from the backend.
-- When off, the widget only ever uses the canned responses above (free, no API calls).
alter table public.site_settings
  add column if not exists ai_fallback_enabled boolean not null default true;
