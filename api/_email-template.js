function escapeHtml(s) {
  return String(s || '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
}

// Plain text -> paragraphs. Blank lines separate paragraphs; single newlines become <br>.
function contentToHtml(content) {
  return String(content || '')
    .split(/\n{2,}/)
    .map(block => `<p style="margin:0 0 18px;color:#3a352c;font-size:16px;line-height:1.7">${escapeHtml(block).replace(/\n/g, '<br>')}</p>`)
    .join('');
}

function buildEmailHtml({ title, content, unsubscribeUrl, siteUrl = 'https://cyberbishop.org' }) {
  const safeTitle = escapeHtml(title);
  return `<!doctype html>
<html>
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"></head>
<body style="margin:0;padding:0;background:#0d0e10;font-family:Arial,Helvetica,sans-serif">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#0d0e10;padding:32px 16px">
<tr><td align="center">
<table role="presentation" width="100%" style="max-width:560px;background:#fdfbf6;border-radius:16px;overflow:hidden" cellpadding="0" cellspacing="0">
<tr><td style="background:linear-gradient(135deg,#111214,#1c1a22);padding:28px 32px;text-align:center">
<span style="font-family:Georgia,serif;font-weight:bold;letter-spacing:.08em;font-size:20px;color:#d6a64d">CYBER<span style="color:#a78bfa">BISHOP</span></span>
</td></tr>
<tr><td style="padding:36px 32px 8px">
<h1 style="margin:0 0 20px;font-size:24px;line-height:1.35;color:#17140f;font-family:Georgia,serif">${safeTitle}</h1>
${contentToHtml(content)}
<div style="margin:28px 0 8px">
<a href="${siteUrl}" style="display:inline-block;background:#d6a64d;color:#171308;text-decoration:none;font-weight:bold;padding:12px 22px;border-radius:10px;font-size:14px">Visit Cyberbishop</a>
</div>
</td></tr>
<tr><td style="padding:24px 32px 32px;border-top:1px solid #ece6d8;margin-top:20px">
<p style="margin:16px 0 0;color:#9a9384;font-size:12px;line-height:1.6">
You're receiving this because you subscribed to Cyberbishop updates.
${unsubscribeUrl ? `<a href="${unsubscribeUrl}" style="color:#9a9384;text-decoration:underline">Unsubscribe</a>` : ''}
</p>
</td></tr>
</table>
</td></tr>
</table>
</body>
</html>`;
}

module.exports = { buildEmailHtml, escapeHtml };
