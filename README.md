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
