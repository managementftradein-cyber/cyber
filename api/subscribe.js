// POST /api/subscribe  { email }
// Server-side subscribe flow. Uses the Supabase SERVICE ROLE key (never exposed to
// the browser) so this is the only path that can write to the subscribers table.
// Set SUPABASE_SERVICE_ROLE_KEY in Vercel -> Settings -> Environment Variables.

const { setCors, isValidEmail, supabaseAdmin } = require('./_lib');

module.exports = async (req, res) => {
  setCors(res);
  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

  let body = req.body;
  if (typeof body === 'string') { try { body = JSON.parse(body); } catch { body = {}; } }
  const email = String(body?.email || '').trim().toLowerCase();

  if (!isValidEmail(email)) return res.status(400).json({ error: 'Please enter a valid email address.' });

  try {
    const existing = await supabaseAdmin(`subscribers?email=eq.${encodeURIComponent(email)}&select=id,status`);

    if (existing.length) {
      const row = existing[0];
      if (row.status === 'active') {
        return res.status(200).json({ ok: true, message: "You're already subscribed — thank you!" });
      }
      // They're opting back in — this is a fresh, explicit consent action.
      await supabaseAdmin(`subscribers?id=eq.${row.id}`, {
        method: 'PATCH',
        body: { status: 'active', unsubscribed_at: null },
      });
      return res.status(200).json({ ok: true, message: "Welcome back — you're subscribed again!" });
    }

    await supabaseAdmin('subscribers', {
      method: 'POST',
      body: { email, status: 'active' },
      prefer: 'return=minimal',
    });
    return res.status(200).json({ ok: true, message: "You're subscribed! We'll let you know about new updates." });
  } catch (err) {
    return res.status(500).json({ error: 'Could not subscribe right now. Please try again shortly.' });
  }
};
