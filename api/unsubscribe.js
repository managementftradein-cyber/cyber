// GET /api/unsubscribe?email=...&token=...
// Reached by clicking the unsubscribe link in an email. Verifies a signed token
// (no login required) so nobody can unsubscribe someone else by guessing an email.

const { setCors, verifyUnsubscribeToken, supabaseAdmin } = require('./_lib');

function page(title, message, ok) {
  return `<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>${title}</title></head>
<body style="margin:0;background:#0d0e10;color:#f5f5f2;font-family:Arial,sans-serif;display:flex;min-height:100vh;align-items:center;justify-content:center;padding:24px">
<div style="max-width:420px;text-align:center;background:rgba(255,255,255,.04);border:1px solid rgba(255,255,255,.1);border-radius:18px;padding:36px 28px">
<div style="font-weight:bold;letter-spacing:.08em;color:${ok ? '#d6a64d' : '#e08585'};margin-bottom:14px">CYBERBISHOP</div>
<h1 style="font-size:20px;margin:0 0 10px">${title}</h1>
<p style="color:#b9b6ae;font-size:14px;line-height:1.6;margin:0">${message}</p>
</div></body></html>`;
}

module.exports = async (req, res) => {
  setCors(res);
  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'GET') return res.status(405).send('Method not allowed');

  const email = String(req.query?.email || '').trim().toLowerCase();
  const token = String(req.query?.token || '');

  res.setHeader('content-type', 'text/html');

  if (!email || !token) return res.status(400).send(page('Invalid link', 'This unsubscribe link is missing information.', false));

  try {
    if (!verifyUnsubscribeToken(email, token)) {
      return res.status(400).send(page('Invalid or expired link', "We couldn't verify this unsubscribe link.", false));
    }
    await supabaseAdmin(`subscribers?email=eq.${encodeURIComponent(email)}`, {
      method: 'PATCH',
      body: { status: 'unsubscribed', unsubscribed_at: new Date().toISOString() },
    });
    return res.status(200).send(page("You're unsubscribed", "You won't receive any more Cyberbishop update emails. You're always welcome to subscribe again from the website.", true));
  } catch (err) {
    return res.status(500).send(page('Something went wrong', 'Please try again shortly, or contact us from the Connect page.', false));
  }
};
