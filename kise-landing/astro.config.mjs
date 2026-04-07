// kise-landing/astro.config.mjs
import { defineConfig } from "astro/config";
import tailwind from "@astrojs/tailwind";
import cloudflare from "@astrojs/cloudflare";
import react from "@astrojs/react";

export default defineConfig({
  output: "static",
  adapter: cloudflare(),
  integrations: [tailwind(), react()],
  i18n: {
    defaultLocale: "pt-BR",
    locales: ["pt-BR", "en-US"],
    routing: {
      prefixDefaultLocale: false,
    },
  },
});
