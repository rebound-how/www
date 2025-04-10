// @ts-check
import { defineConfig } from "astro/config";

import icon from "astro-icon";

import sitemap from "@astrojs/sitemap";

import mdx from "@astrojs/mdx";

// https://astro.build/config
export default defineConfig({
  site: "https://rebound.how",
  integrations: [icon(), sitemap({
    filter: (page) => page !== "https://rebound.how/support/sent/",
  }), mdx()],
});