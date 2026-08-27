# Cyberbishop Discovery Platform — Video CMS

This build extends Cyberbishop into an explorable media platform with a Supabase-backed CMS.

## Video CMS

The admin dashboard now supports a first-class video workflow:

1. Sign in as the designated Cyberbishop administrator.
2. Open **Admin → Videos**.
3. Select a category and enter the title/description.
4. Upload MP4, WebM, OGG, QuickTime/M4V media directly to the Supabase `videos` Storage bucket, or provide an external video URL.
5. The CMS records the public playback URL, storage path, original filename, MIME type, file size and detected duration.
6. Add an optional poster/thumbnail URL, tags, featured status and publication status.
7. Save the video. Published videos automatically appear on the public Videos, Catalog and discovery experiences.

## Supabase setup

Run **`video_schema.sql`** once in the Supabase SQL Editor. It:

- creates the `videos` table if it does not exist;
- safely adds the video-upload metadata columns to an existing `videos` table;
- enables RLS;
- permits public visitors to read published videos;
- restricts video CRUD to the designated administrator UID;
- creates/configures the public-playback `videos` Storage bucket;
- restricts Storage writes/deletes to the administrator;
- allows common video MIME types;
- sets a 500 MB bucket file-size limit;
- adds indexes for published/featured discovery.

`storage_video_cms.sql` contains the same migration for convenience.

## Important upload note

The CMS uses Supabase's browser upload API. This is suitable for normal-sized uploads. For very large production videos, use resumable/TUS uploads or a dedicated video/CDN pipeline; the schema already supports the resulting URL and metadata.

## Security

The browser contains only the Supabase publishable key. The service-role key must never be placed in this project. Database and Storage RLS policies are the actual security boundary.

## Newsletter / Subscriber Broadcasts (Resend)

Cyberbishop can send daily prayers, devotionals, teachings and updates to
subscribers via [Resend](https://resend.com). All secrets stay server-side —
the browser never sees your Resend API key or Supabase service-role key.

### 1. Run the database migrations

In the Supabase SQL Editor, run (in this order, if not already run):

1. `hero_and_subscribers_schema.sql` — creates the `subscribers` table.
2. `subscribers_secure_migration.sql` — adds `status`/`unsubscribed_at` and
   locks down write access so only the server-side API can insert/update rows.

### 2. Set up Resend

1. Create a Resend account at resend.com.
2. Go to **Domains → Add Domain** and add `cyberbishop.org`.
3. Resend will generate DNS records for you (typically an SPF/"send" TXT
   record, a DKIM TXT or CNAME record, and a recommended DMARC TXT record —
   the exact values are generated per-domain, so copy them from your Resend
   dashboard). Add each one in your domain registrar's DNS settings.
4. Wait for Resend to show the domain as **Verified** (can take a few
   minutes to a few hours depending on DNS propagation).
5. Go to **API Keys → Create API Key** and copy it.

### 3. Add environment variables in Vercel

Go to your Vercel project → **Settings → Environment Variables** and add:

| Name | Value |
|---|---|
| `SUPABASE_SERVICE_ROLE_KEY` | From Supabase → Settings → API → `service_role` key. **Never** put this in any committed file. |
| `RESEND_API_KEY` | From Resend → API Keys. |
| `UNSUBSCRIBE_SECRET` | Any long random string (e.g. generate one with `openssl rand -hex 32`). Used to sign unsubscribe links. |
| `RESEND_FROM` *(optional)* | Defaults to `Cyberbishop <hello@cyberbishop.org>`. |

Redeploy after adding these (Vercel picks up new env vars on the next deploy).

### 4. Test the subscribe form

Submit an email on the homepage's "Stay in the loop" section. Check
**Admin → Subscribers** to confirm it appears with status "Active".

### 5. Send a test prayer email

Go to **Admin → Broadcast**, write a subject/title/content, click **Preview**
to check it looks right, then **Send test email** — it goes to your own
admin login email (or whatever you type into "Send test to"). No real
subscribers are contacted by this button.

### 6. Send to subscribers

Once you're happy with a test, **Send to active subscribers** sends the
broadcast to everyone with status "Active", using Resend's batch API. This
requires confirmation and only works for the signed-in administrator.

### 7. Test unsubscribe

Click the "Unsubscribe" link at the bottom of a test email. It should show a
confirmation page and flip that subscriber's status to "Unsubscribed" in
**Admin → Subscribers**.

### Notes

- Daily/scheduled sending isn't wired up yet — every send is a manual admin
  action. Vercel Cron (or a similar scheduler) can be added later to call
  `/api/send-broadcast` automatically once you're ready.
- `RESEND_FROM` won't actually deliver from `hello@cyberbishop.org` until
  step 2 shows the domain as verified in Resend.

## AI Chat Widget

Every public page now shows a floating chat bubble (bottom-right). It greets
first-time-this-session visitors automatically after a short delay, and lets
them chat with an AI assistant powered by the Claude API.

Setup:

1. In your Vercel project, go to **Settings → Environment Variables** and add
   `ANTHROPIC_API_KEY` with your Anthropic API key. Redeploy after adding it.
2. That's it — `api/chat.js` is a serverless function that proxies chat
   messages to Claude (model `claude-haiku-4-5-20251001` by default, chosen
   for low cost; edit the model string in `api/chat.js` to upgrade).
3. The API key is never exposed to the browser — only the serverless
   function reads it.

Conversation history is kept per-browser-session (sessionStorage), not saved
to a database.

## Visitor Log

Run **`visits_schema.sql`** once in the Supabase SQL Editor. It creates a
`visits` table that records one entry per visitor per browser session
(page landed on, referrer, and user agent) — not one per page view.

Check **Admin → Visitors** to see who has visited, with a running count of
visits shown and visits today. There's a "Clear log" button for housekeeping.
