// kise-landing/api/waitlist.ts
import type { VercelRequest, VercelResponse } from "@vercel/node";

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  const { email } = req.body;

  if (!email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    return res.status(400).json({ error: "Invalid email" });
  }

  const audienceId = process.env.RESEND_AUDIENCE_ID;
  const apiKey = process.env.RESEND_API_KEY;

  if (!audienceId || !apiKey) {
    return res.status(500).json({ error: "Server configuration error" });
  }

  try {
    // Add to Resend audience
    await fetch(`https://api.resend.com/audiences/${audienceId}/contacts`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ email, unsubscribed: false }),
    });

    // Send confirmation email
    const lang = req.headers["accept-language"]?.includes("en") ? "en" : "pt-BR";
    const subject =
      lang === "en" ? "You're on the list!" : "Você está na lista!";
    const body =
      lang === "en"
        ? "We'll let you know when KISE is ready."
        : "Vamos te avisar quando o KISE estiver pronto.";

    await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: "KISE <hello@kise-app.com>",
        to: email,
        subject,
        html: `
          <div style="font-family:sans-serif;max-width:480px">
            <h1 style="font-family:'Cormorant Garamond',serif;font-weight:300;font-size:28px">KISE 着せ</h1>
            <p>${body}</p>
          </div>
        `,
      }),
    });

    return res.status(200).json({ ok: true });
  } catch (err) {
    console.error("Waitlist error:", err);
    return res.status(500).json({ error: "Failed to join waitlist" });
  }
}
