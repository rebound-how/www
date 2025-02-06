/** @type {import("prettier").Config} */
export default {
  semi: true,
  singleQuote: false,
  printWidth: 80,
  plugins: ["prettier-plugin-astro"],
  overrides: [
    {
      files: "*.astro",
      options: {
        parser: "astro",
      },
    },
  ],
};
