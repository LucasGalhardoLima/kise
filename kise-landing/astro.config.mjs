// kise-landing/astro.config.mjs
import { defineConfig } from "astro/config";
import tailwind from "@astrojs/tailwind";
import vercel from "@astrojs/vercel";
import react from "@astrojs/react";

export default defineConfig({
  output: "static",
  adapter: vercel(),
  integrations: [tailwind(), react()],
  i18n: {
    defaultLocale: "pt-BR",
    locales: ["pt-BR", "en-US"],
    routing: {
      prefixDefaultLocale: false,
    },
  },
});
