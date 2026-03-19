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
        { title: "Cadastre suas peças", body: "Cor, tecido, caimento — o KISE conhece cada peça." },
        { title: "Receba sugestões", body: "Clima, ocasião e estilo combinados para o seu dia." },
        { title: "Vista com intenção", body: "Menos decisões, mais confiança ao se vestir." },
      ],
    },
    understands: {
      title: "O que o KISE entende",
      items: [
        { number: "01", title: "Seu estilo", body: "Os arquétipos que você escolhe no onboarding definem a personalidade das sugestões." },
        { number: "02", title: "O clima agora", body: "Temperatura real, umidade, vento, sensação térmica. Inteligência climática granular." },
        { number: "03", title: "Cada peça", body: "Cor, tecido, caimento, peso, formalidade. O KISE sabe como cada peça se comporta." },
        { number: "04", title: "Seu histórico", body: "O que você gostou, o que não funcionou. As sugestões melhoram com o tempo." },
      ],
    },
    system: {
      title: "Seu guarda-roupa é um sistema",
      body: "A maioria dos apps de moda te diz o que vestir. O KISE entende o que você tem — e faz cada peça trabalhar mais. Menos peças paradas. Mais combinações com o que já é seu. E quando for hora de comprar, você sabe exatamente o que falta.",
      pullQuote: "Não é sobre ter mais. É sobre usar melhor.",
    },
    philosophy: {
      title: "Intenção, não acaso",
      body: "Seu guarda-roupa é um sistema, não uma coleção. Cada peça tem um papel — cor, peso, formalidade. O KISE entende essas relações e sugere combinações que funcionam juntas, não por acaso, mas por intenção.",
      pullQuote: "Menos roupas, mais possibilidades.",
    },
    credibility: {
      statements: [
        "Construído com Apple Intelligence e IA avançada",
        "100% on-device. Seus dados nunca saem do celular.",
        "Paletas inspiradas em 和色 — séculos de tradição cromática japonesa.",
      ],
    },
    palette: {
      label: "Sua paleta agora",
      fallbackCity: "São Paulo",
      description: "Uma composição de cores gerada pelo KISE para o clima de {city} agora. Cada dia, cada cidade, uma paleta diferente.",
    },
    waitlist: {
      title: "Quero experimentar",
      body: "Seja avisado quando o KISE estiver disponível.",
      cta: "Me avise no lançamento",
      success: "Você está na lista!",
    },
    footer: {
      tagline: "Vista com intenção.",
      appStore: "Em breve na App Store",
      copyright: "© 2026 KISE",
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
        { title: "Register your pieces", body: "Color, fabric, fit — KISE knows each piece." },
        { title: "Get daily suggestions", body: "Weather, occasion, and style combined for your day." },
        { title: "Dress with intention", body: "Fewer decisions, more confidence getting dressed." },
      ],
    },
    understands: {
      title: "What KISE understands",
      items: [
        { number: "01", title: "Your style", body: "The archetypes you choose during onboarding define the personality of every suggestion." },
        { number: "02", title: "Weather right now", body: "Real temperature, humidity, wind, feels-like. Granular weather intelligence." },
        { number: "03", title: "Every piece", body: "Color, fabric, fit, weight, formality. KISE knows how each piece behaves." },
        { number: "04", title: "Your history", body: "What you liked, what didn't work. Suggestions improve over time." },
      ],
    },
    system: {
      title: "Your wardrobe is a system",
      body: "Most fashion apps tell you what to wear. KISE understands what you have — and makes every piece work harder. Fewer idle garments. More combinations from what's already yours. And when it's time to buy, you know exactly what's missing.",
      pullQuote: "It's not about having more. It's about using better.",
    },
    philosophy: {
      title: "Intention, not chance",
      body: "Your wardrobe is a system, not a collection. Every piece has a role — color, weight, formality. KISE understands these relationships and suggests combinations that work together, not by chance, but by intention.",
      pullQuote: "Fewer clothes, more possibilities.",
    },
    credibility: {
      statements: [
        "Built with Apple Intelligence and advanced AI",
        "100% on-device. Your data never leaves your phone.",
        "Palettes inspired by 和色 — centuries of Japanese color tradition.",
      ],
    },
    palette: {
      label: "Your palette right now",
      fallbackCity: "São Paulo",
      description: "A color composition generated by KISE for the weather in {city} right now. Every day, every city, a different palette.",
    },
    waitlist: {
      title: "I want to try it",
      body: "Get notified when KISE is available.",
      cta: "Notify me at launch",
      success: "You're on the list!",
    },
    footer: {
      tagline: "Dress with intention.",
      appStore: "Coming soon to the App Store",
      copyright: "© 2026 KISE",
    },
  },
} as const;

export type Locale = keyof typeof strings;

export function t(locale: Locale) {
  return strings[locale];
}
