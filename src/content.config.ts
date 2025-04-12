// 1. Import utilities from `astro:content`
import { defineCollection, z } from "astro:content";

// 2. Import loader(s)
import { glob, file } from "astro/loaders";

// 3. Define your collection(s)
const articles = defineCollection({
  loader: glob({ pattern: "**/*.(md|mdx)", base: "./src/data/articles" }),
  schema: ({ image }) =>
    z.object({
      title: z.string(),
      description: z.string(),
      pubDate: z.coerce.date(),
      cover: image().optional(),
      coverAlt: z.string().optional(),
      isDraft: z.boolean().optional(),
    }),
});

// 4. Export a single `collections` object to register your collection(s)
export const collections = { articles };
