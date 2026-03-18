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

  const apiKey = process.env.RESEND_API_KEY;

  if (!apiKey) {
    return res.status(500).json({ error: "Server configuration error" });
  }

  try {
    // Send confirmation email to the person who signed up
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
        from: "KISE <hello@contact.kise-app.com>",
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

    // Notify you about the signup
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
