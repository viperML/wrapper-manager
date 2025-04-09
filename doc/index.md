---
# https://vitepress.dev/reference/default-theme-home-page
layout: home

hero:
  name: "wrapper-manager"
  text: "Post-modern configuration management"
  # tagline: My great project tagline
  actions:
    - theme: brand
      text: Documentation
      link: /documentation
    - theme: alt
      text: API Reference
      link: /api

  image:
    src: /wrapper.svg
    alt: wrapper-manager

features:
  - title: "⚙️ Customizability"
    details: "Tailor each wrapper to your unique environment with extensive options."
  - title: "🔄 Robust Wrapping"
    details: "Seamlessly integrate with Nix for reliable and reproducible builds."
  - title: "📁 Zero Configuration Files"
    details: "Eliminate the need for files in ~/.config by bundling configurations directly with your applications."
---

<style>
.image-bg::after {
  display: block;
  content: '';
  background: oklch(0.64 0.27 275deg);
  background: radial-gradient(circle,
    oklch(0.64 0.27 275deg) 5%,
    oklch(0.62 0.31 315deg) 10%,
    oklch(0.66 0.36 190deg / 0) 70%);
  height: 100%;
  width: 100%;
}

:root {
  --vp-home-hero-name-color: transparent;
  --vp-home-hero-name-background: -webkit-linear-gradient(120deg, #bd34fe, #41d1ff);
}

.VPImage {
  max-width: 200px !important;
  min-width: 150px !important;
}
</style>
