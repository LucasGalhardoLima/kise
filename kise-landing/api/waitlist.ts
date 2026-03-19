// kise-landing/api/waitlist.ts
import type { VercelRequest, VercelResponse } from "@vercel/node";

function waitlistHtml(lang: "en" | "pt-BR") {
  const heading = lang === "en" ? "You're on the list." : "Você está na lista.";
  const body = lang === "en"
    ? "We'll let you know as soon as KISE is ready. In the meantime, your wardrobe is still waiting for intention."
    : "Vamos te avisar assim que o KISE estiver pronto. Enquanto isso, seu guarda-roupa continua esperando por intenção.";
  const tagline = lang === "en" ? "Dress with intention." : "Vista com intenção.";

  return `
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color:#F5F3EF;font-family:'DM Sans',Helvetica,Arial,sans-serif">
  <tr><td align="center" style="padding:60px 20px">
    <table role="presentation" width="480" cellpadding="0" cellspacing="0" style="max-width:480px;width:100%">
      <tr><td align="center" style="padding-bottom:48px">
        <span style="font-family:'Cormorant Garamond',Georgia,serif;font-weight:300;font-size:32px;color:#344E41;letter-spacing:0.02em">KISE 着せ</span>
      </td></tr>
      <tr><td style="padding-bottom:32px">
        <p style="margin:0;font-size:15px;line-height:1.7;color:#344E41">${heading}</p>
        <p style="margin:16px 0 0;font-size:15px;line-height:1.7;color:#6B6B6B">${body}</p>
      </td></tr>
      <tr><td align="center" style="padding:16px 0 32px">
        <div style="width:60px;height:1px;background-color:#A3B18A;opacity:0.4"></div>
      </td></tr>
      <tr><td align="center">
        <p style="margin:0;font-family:'Cormorant Garamond',Georgia,serif;font-weight:300;font-size:14px;color:#9B9B9B;font-style:italic">${tagline}</p>
        <p style="margin:12px 0 0;font-size:11px;color:#9B9B9B">kise-app.com</p>
      </td></tr>
    </table>
  </td></tr>
</table>`;
}

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  const { email } = req.body;

  if (!email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    return res.status(400).json({ error: "Invalid email" });
  }

  const apiKey = process.env.RESEND_API_KEY;

  if (!apiKey) {
    return res.status(500).json({ error: "Server configuration error" });
  }

  try {
    const lang = req.headers["accept-language"]?.includes("en") ? "en" as const : "pt-BR" as const;
    const subject = lang === "en" ? "You're on the list!" : "Você está na lista!";

    await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: "KISE <hello@contact.kise-app.com>",
        to: email,
        subject,
        html: waitlistHtml(lang),
      }),
    });

    // Notify admin
    await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: "KISE <hello@contact.kise-app.com>",
        to: "lucas.galhardo.lima@pm.me",
        subject: `New waitlist signup: ${email}`,
        html: `<p>${email} joined the KISE waitlist.</p>`,
      }),
    });

    return res.status(200).json({ ok: true });
  } catch (err) {
    console.error("Waitlist error:", err);
    return res.status(500).json({ error: "Failed to join waitlist" });
  }
}
