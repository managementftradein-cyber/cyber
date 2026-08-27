// Shared server-side helpers for the Cyberbishop subscriber/broadcast system.
// Nothing in this file is exposed to the browser — it only runs inside Vercel's
// serverless functions.

const crypto = require('crypto');

// Not secret — same public values already committed in config.js for the browser.
const SUPABASE_URL = 'https://qtmqjgibubwwbpedmmwa.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_vrKp5F0RElrCFbMmbEithA_TQfu8ZWt';
const ADMIN_UID = 'ca155628-a765-434e-85ad-d52f25cae573';

function setCors(res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
}

function isValidEmail(email) {
  return typeof email === 'string' && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim());
}

// --- Supabase REST (PostgREST), using the SERVICE ROLE key. Server-only, bypasses RLS. ---
async function supabaseAdmin(path, { method = 'GET', body, prefer } = {}) {
  const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!serviceKey) throw new Error('Server is missing SUPABASE_SERVICE_ROLE_KEY.');
  const headers = {
    apikey: serviceKey,
    Authorization: `Bearer ${serviceKey}`,
    'content-type': 'application/json',
  };
  if (prefer) headers.Prefer = prefer;
  const r = await fetch(`${SUPABASE_URL}/rest/v1/${path}`, { method, headers, body: body ? JSON.stringify(body) : undefined });
  const text = await r.text();
  const data = text ? JSON.parse(text) : null;
  if (!r.ok) throw new Error((data && (data.message || data.error)) || `Supabase error (${r.status})`);
  return data;
}

// --- Verify a Supabase Auth access token belongs to the designated admin. ---
async function requireAdmin(req) {
  const auth = req.headers.authorization || '';
  const token = auth.startsWith('Bearer ') ? auth.slice(7) : null;
  if (!token) { const e = new Error('Not signed in.'); e.status = 401; throw e; }
  const r = await fetch(`${SUPABASE_URL}/auth/v1/user`, {
    headers: { apikey: SUPABASE_ANON_KEY, Authorization: `Bearer ${token}` },
  });
  if (!r.ok) { const e = new Error('Session expired — please sign in again.'); e.status = 401; throw e; }
  const user = await r.json();
  if (!user || user.id !== ADMIN_UID) { const e = new Error('Not authorized.'); e.status = 403; throw e; }
  return user;
}

// --- Signed, unguessable unsubscribe tokens (no extra DB lookups needed to verify). ---
function unsubscribeToken(email) {
  const secret = process.env.UNSUBSCRIBE_SECRET;
  if (!secret) throw new Error('Server is missing UNSUBSCRIBE_SECRET.');
  return crypto.createHmac('sha256', secret).update(email.trim().toLowerCase()).digest('hex');
}
function verifyUnsubscribeToken(email, token) {
  const expected = Buffer.from(unsubscribeToken(email));
  const given = Buffer.from(String(token || ''));
  if (expected.length !== given.length) return false;
  return crypto.timingSafeEqual(expected, given);
}

module.exports = { setCors, isValidEmail, supabaseAdmin, requireAdmin, unsubscribeToken, verifyUnsubscribeToken };
