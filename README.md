# Cyberbishop Supabase version

## Files
- `index.html` — existing Cyberbishop public website, now reading catalog data from Supabase.
- `admin.html` — Supabase Auth protected admin dashboard.
- `config.js` — Supabase public URL/publishable key and administrator UID.
- `vercel.json` — makes `/admin` open the admin page.

## Deploy
Upload these files to the existing Vercel project that serves `cyberbishop.org`. Do not create a new domain.

## Before production
1. Confirm the cleaned RLS policies are installed in Supabase and restrict writes to the designated administrator UID.
2. In Supabase Authentication → Users, confirm the administrator account has UID `ca155628-a765-434e-85ad-d52f25cae573`.
3. Confirm the `covers` storage bucket exists and is public.
4. Test `/admin` before replacing the current production deployment.

The publishable key in `config.js` is intended for browser use. Never put a Supabase service-role/secret key in this project.


## Frontend enhancement — August 2026
The public `index.html` now includes a cinematic responsive design layer:
- mobile-first responsive navigation and content layouts
- glass/reflective surfaces and layered lighting
- animated ambient background and pointer glow
- scroll reveal transitions
- desktop card tilt/micro-interactions
- upgraded buttons, catalog cards, search bar and content groups
- responsive hero statistics
- reduced-motion accessibility support
- existing Supabase data loading and admin functionality preserved
