// POST /api/send-broadcast
// Body: { mode: 'test'|'broadcast', subject, title, content, testEmail? }
// Header: Authorization: Bearer <supabase access token of the signed-in admin>
//
// Admin-only. Verifies the caller is the designated Cyberbishop administrator
// before doing anything. Sends via Resend using RESEND_API_KEY (server-only).
//
// Required Vercel env vars: SUPABASE_SERVICE_ROLE_KEY, RESEND_API_KEY, UNSUBSCRIBE_SECRET
// Optional: RESEND_FROM (defaults to "Cyberbishop <hello@cyberbishop.org>")

const { setCors, supabaseAdmin, requireAdmin, unsubscribeToken } = require('./_lib');
const { buildEmailHtml } = require('./_email-template');

const FROM = process.env.RESEND_FROM || 'Cyberbishop <hello@cyberbishop.org>';

async function resendSend(payload) {
  const apiKey = process.env.RESEND_API_KEY;
  if (!apiKey) throw new Error('Server is missing RESEND_API_KEY.');
  const r = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: { authorization: `Bearer ${apiKey}`, 'content-type': 'application/json' },
    body: JSON.stringify(payload),
  });
  const data = await r.json().catch(() => ({}));
  if (!r.ok) throw new Error(data?.message || 'Resend API error');
  return data;
}

async function resendBatch(items) {
  const apiKey = process.env.RESEND_API_KEY;
  if (!apiKey) throw new Error('Server is missing RESEND_API_KEY.');
  const r = await fetch('https://api.resend.com/emails/batch', {
    method: 'POST',
    headers: { authorization: `Bearer ${apiKey}`, 'content-type': 'application/json' },
    body: JSON.stringify(items),
  });
  const data = await r.json().catch(() => ({}));
  if (!r.ok) throw new Error(data?.message || 'Resend API error');
  return data;
}

module.exports = async (req, res) => {
  setCors(res);
  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

  let admin;
  try {
    admin = await requireAdmin(req);
  } catch (err) {
    return res.status(err.status || 401).json({ error: err.message });
  }

  let body = req.body;
  if (typeof body === 'string') { try { body = JSON.parse(body); } catch { body = {}; } }
  const { mode, subject, title, content } = body || {};
  const testEmail = String(body?.testEmail || admin.email || '').trim().toLowerCase();

  if (!subject || !title || !content) {
    return res.status(400).json({ error: 'Subject, title and content are all required.' });
  }
  if (mode !== 'test' && mode !== 'broadcast') {
    return res.status(400).json({ error: 'Invalid mode.' });
  }

  const siteUrl = `https://${req.headers['x-forwarded-host'] || req.headers.host}`.replace('https://localhost', 'http://localhost');

  try {
    if (mode === 'test') {
      if (!testEmail) return res.status(400).json({ error: 'No test email address available.' });
      const unsubscribeUrl = `${siteUrl}/api/unsubscribe?email=${encodeURIComponent(testEmail)}&token=${unsubscribeToken(testEmail)}`;
      const html = buildEmailHtml({ title, content, unsubscribeUrl, siteUrl });
      await resendSend({ from: FROM, to: testEmail, subject: `[TEST] ${subject}`, html });
      return res.status(200).json({ ok: true, testSentTo: testEmail });
    }

    // mode === 'broadcast'
    const subscribers = await supabaseAdmin('subscribers?status=eq.active&select=email');
    if (!subscribers.length) return res.status(200).json({ ok: true, sent: 0, message: 'No active subscribers yet.' });

    const emails = subscribers.map(s => {
      const unsubscribeUrl = `${siteUrl}/api/unsubscribe?email=${encodeURIComponent(s.email)}&token=${unsubscribeToken(s.email)}`;
      return {
        from: FROM,
        to: s.email,
        subject,
        html: buildEmailHtml({ title, content, unsubscribeUrl, siteUrl }),
      };
    });

    // Resend's batch endpoint accepts up to 100 emails per call.
    let sent = 0;
    for (let i = 0; i < emails.length; i += 100) {
      await resendBatch(emails.slice(i, i + 100));
      sent += emails.slice(i, i + 100).length;
    }
    return res.status(200).json({ ok: true, sent });
  } catch (err) {
    return res.status(500).json({ error: err.message || 'Could not send.' });
  }
};
