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
