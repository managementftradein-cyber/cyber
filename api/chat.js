// Vercel serverless function: proxies visitor chat messages to the Claude API.
// The ANTHROPIC_API_KEY is read from a server-side environment variable and
// is never exposed to the browser.
//
// Set it in your Vercel project: Settings -> Environment Variables ->
// ANTHROPIC_API_KEY = sk-ant-... (then redeploy).

const SYSTEM_PROMPT = `You are the friendly on-site assistant for Cyberbishop, a faith-and-identity
media platform where visitors can explore music, books, and videos.
Be warm, brief, and welcoming — most replies should be 1-3 sentences unless the
visitor clearly wants more detail. You can:
- Greet visitors and help them find music, books, videos, or categories on the site.
- Answer general questions about the site's content and purpose (faith, identity, Christ-centered).
- Point people to the Connect page if they want to reach out directly, or the Catalog
  page to browse everything.
If you don't know something specific about the catalog (exact titles, prices, links),
say so honestly and suggest they browse the Music, Books, Videos, or Catalog pages, or
use the Connect page. Never invent specific titles, prices, or URLs.`;

module.exports = async (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

  const apiKey = process.env.ANTHROPIC_API_KEY;
  if (!apiKey) {
    return res.status(500).json({ error: 'Chat is not configured yet. Missing ANTHROPIC_API_KEY.' });
  }

  let body = req.body;
  if (typeof body === 'string') {
    try { body = JSON.parse(body); } catch { body = {}; }
  }
  const messages = Array.isArray(body?.messages) ? body.messages : [];
  if (!messages.length) return res.status(400).json({ error: 'No messages provided.' });

  // Keep the request small and cheap: cap history length and message size.
  const trimmed = messages.slice(-12).map(m => ({
    role: m.role === 'assistant' ? 'assistant' : 'user',
    content: String(m.content || '').slice(0, 2000),
  }));

  try {
    const r = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify({
        model: 'claude-haiku-4-5-20251001',
        max_tokens: 400,
        system: SYSTEM_PROMPT,
        messages: trimmed,
      }),
    });
    const data = await r.json();
    if (!r.ok) {
      return res.status(502).json({ error: data?.error?.message || 'Chat service error.' });
    }
    const text = (data.content || []).filter(b => b.type === 'text').map(b => b.text).join('\n').trim();
    return res.status(200).json({ reply: text || "Sorry, I didn't catch that — could you rephrase?" });
  } catch (err) {
    return res.status(500).json({ error: 'Could not reach the chat service.' });
  }
};
