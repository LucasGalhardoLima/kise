// kise-landing/src/i18n/strings.ts

const strings = {
  "pt-BR": {
    meta: {
      title: "KISE 着せ — Vista com intenção",
      description:
        "Seu guarda-roupa, com intenção. O KISE sugere combinações diárias baseadas no clima, estilo e contexto.",
    },
    hero: {
      tagline: "Seu guarda-roupa, com intenção.",
      cta: "Entrar na lista",
      placeholder: "seu@email.com",
    },
    howItWorks: {
      title: "Como funciona",
      steps: [
        { icon: "👔", title: "Cadastre suas peças", body: "Cor, tecido, caimento — o KISE conhece cada peça." },
        { icon: "☀️", title: "Receba sugestões", body: "Clima, ocasião e estilo combinados para o seu dia." },
        { icon: "✨", title: "Vista com intenção", body: "Menos decisões, mais confiança ao se vestir." },
      ],
    },
    philosophy: {
      title: "Intenção, não acaso",
      body: "Seu guarda-roupa é um sistema, não uma coleção. Cada peça tem um papel — cor, peso, formalidade. O KISE entende essas relações e sugere combinações que funcionam juntas, não por acaso, mas por intenção.",
      pullQuote: "Menos roupas, mais possibilidades.",
    },
    palette: {
      label: "Sua paleta agora",
      fallbackCity: "São Paulo",
    },
    waitlist: {
      title: "Entre na lista",
      body: "Seja avisado quando o KISE estiver disponível.",
      cta: "Entrar na lista",
      success: "Você está na lista!",
    },
    footer: {
      tagline: "Vista com intenção.",
      threads: "Threads",
    },
  },
  en: {
    meta: {
      title: "KISE 着せ — Dress with intention",
      description:
        "Your wardrobe, with intention. KISE suggests daily outfits based on weather, style, and context.",
    },
    hero: {
      tagline: "Your wardrobe, with intention.",
      cta: "Join the waitlist",
      placeholder: "you@email.com",
    },
    howItWorks: {
      title: "How it works",
      steps: [
        { icon: "👔", title: "Register your pieces", body: "Color, fabric, fit — KISE knows each piece." },
        { icon: "☀️", title: "Get daily suggestions", body: "Weather, occasion, and style combined for your day." },
        { icon: "✨", title: "Dress with intention", body: "Fewer decisions, more confidence getting dressed." },
      ],
    },
    philosophy: {
      title: "Intention, not chance",
      body: "Your wardrobe is a system, not a collection. Every piece has a role — color, weight, formality. KISE understands these relationships and suggests combinations that work together, not by chance, but by intention.",
      pullQuote: "Fewer clothes, more possibilities.",
    },
    palette: {
      label: "Your palette right now",
      fallbackCity: "São Paulo",
    },
    waitlist: {
      title: "Join the waitlist",
      body: "Get notified when KISE is available.",
      cta: "Join the waitlist",
      success: "You're on the list!",
    },
    footer: {
      tagline: "Dress with intention.",
      threads: "Threads",
    },
  },
} as const;

export type Locale = keyof typeof strings;

export function t(locale: Locale) {
  return strings[locale];
}
