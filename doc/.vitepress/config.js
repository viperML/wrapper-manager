// @ts-check
import { defineConfig } from "vitepress";

// https://vitepress.dev/reference/site-config
export default defineConfig({
  title: "wrapper-manager",
  description: "Post-modern configuration management",
  themeConfig: {
    // https://vitepress.dev/reference/default-theme-config
    nav: [
      { text: "Home", link: "/" },
      { text: "Examples", link: "/markdown-examples" },
    ],

    sidebar: [
      {
        text: "Sections",
        items: [
          { text: "Documentation", link: "/documentation" },
          { text: "API", link: "/api" },
        ],
      },
    ],

    socialLinks: [
      { icon: "github", link: "https://github.com/viperML/wrapper-manager" },
    ],

    outline: "deep",
    logo: "./wrapper.svg",
  },
  vite: {
    ssr: {
      noExternal: "easy-nix-documentation",
    },
  },
});
