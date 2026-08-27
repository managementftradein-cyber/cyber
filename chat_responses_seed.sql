-- Cyberbishop chatbot: starter canned responses.
-- Run this in the Supabase SQL Editor (after chat_responses_schema.sql).
-- Everything here is fully editable afterward from Admin → Chatbot — this is just a starting point.

insert into public.chat_responses (trigger_phrases, response, priority, active) values

('hello, good morning, good afternoon, good evening',
 'Hey! 👋 Welcome to Cyberbishop — faith, identity and Christ, all in one place. Ask me about our books, music, videos, or how to stay connected.',
 0, true),

('who is, about cyberbishop, what is this, your mission',
 'Cyberbishop is a growing message rooted in Scripture — helping you see who you are in Christ through books, music, videos and teachings. Check out the About page for more.',
 0, true),

('book, books, ebook',
 'You can browse all our books on the Books page — tap "Books" in the menu up top. Each one links straight to where you can get it.',
 0, true),

('music, song, songs, listen',
 'Our music is on the Music page — tap "Music" in the menu, or find the full catalogue on Spotify via the Connect page.',
 0, true),

('video, videos, watch, teaching, teachings, sermon, sermons',
 'You''ll find all our videos and teachings on the Videos page — tap "Videos" in the menu to start watching.',
 0, true),

('catalog, browse everything, full library, search',
 'The Catalog page has everything in one place — books, music and videos, searchable and filterable by category.',
 0, true),

('whatsapp',
 'You can join our official WhatsApp channel from the Connect page — tap "Connect" in the menu and then "WhatsApp".',
 0, true),

('telegram',
 'Our Telegram channel is linked on the Connect page — tap "Connect" in the menu and then "Telegram".',
 0, true),

('spotify',
 'You can listen to the full catalogue on Spotify — the link is on the Connect page under "Spotify".',
 0, true),

('connect, contact, reach you, get in touch, phone number, email address',
 'You can reach us through WhatsApp, Telegram or Spotify — all the links are on the Connect page in the menu.',
 0, true),

('subscribe, newsletter, notify me, get notified, notifications',
 'You can subscribe for updates right on the homepage — scroll to "Stay in the loop" and pop your email in. We''ll let you know whenever something new is published.',
 0, true),

('review, reviews, testimonial, testimonials, leave feedback',
 'You can read what others are saying — and leave your own — in the "What people are saying" section on the homepage, or on any book, song or video page.',
 0, true),

('favorite, favourite, wishlist, saved items',
 'Tap the ♡ on any book, song or video to save it, then find everything you''ve saved on the Saved page.',
 0, true),

('price, pricing, cost, how much, payment',
 'Pricing varies by item — books are available for purchase with pricing shown on each book''s page, while our music and videos are free to enjoy.',
 0, true),

('thank you, thanks, appreciate it',
 'You''re most welcome! 🙏 Let us know if there''s anything else you need.',
 0, true);
