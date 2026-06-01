// Memba — Tailwind theme tokens ("Meadow, squared"). Tailwind v3.
// Merge this into theme.extend in assets/tailwind.config.js.
module.exports = {
  colors: {
    sage: {
      50: "#eef1e6", 100: "#dde3cf", 200: "#bccaa6", 300: "#98ab80",
      400: "#6f8760", 500: "#5a7050", 600: "#475a40", 700: "#36462f", 800: "#232e1e",
    },
    cream: "#f6f5ea",   // page canvas
    paper: "#fffef9",   // cards, inputs
    apricot: { DEFAULT: "#d2925a", soft: "#f6e8d6", deep: "#925f2e" },
    ink: { DEFAULT: "#25291d", 2: "#555a47", 3: "#878b76" },
    line: { DEFAULT: "#e8e6d4", strong: "#d9d6bf" },
    success: { DEFAULT: "#5f7a4f", soft: "#e9eedd" },
  },
  fontFamily: {
    sans: ["Figtree", "ui-sans-serif", "system-ui", "sans-serif"],
  },
  borderRadius: { btn: "6px", card: "12px", modal: "16px" },
  boxShadow: { card: "0 1px 2px rgba(37,41,29,0.05)" },
};
