# Frontend, CSS, and design guidelines

## JS and CSS

- **Use Tailwind CSS classes and custom CSS rules** to create polished, responsive, and visually stunning interfaces.
- For LiveView UI structure, component extraction, and Tailwind factoring rules, also read [LiveView UI structure](liveview-ui-structure.md).
- Tailwindcss v4 **no longer needs a tailwind.config.js** and uses a new import syntax in `app.css`:

      @import "tailwindcss" source(none);
      @source "../css";
      @source "../js";
      @source "../../lib/my_app_web";

- **Always use and maintain this import syntax** in the app.css file for projects generated with `phx.new`.
- **Never** use `@apply` when writing raw css.
- Prefer project design tokens and brand utilities (`text-ink`, `bg-paper`, `border-line`, `bg-sage-600`, etc.) over raw hex colors in templates.
- Use custom CSS classes sparingly for repeated structural patterns, global layout behaviours, vendor integration styles, or utility bundles that make HEEx hard to read.
- This app currently uses daisyUI as a themed foundation for primitives such as `btn`, `badge`, `alert`, and `toast`. Use it intentionally and keep it aligned with Memba's theme; do not copy generic daisyUI examples blindly or add another component system without explicit agreement.
- Out of the box **only the app.js and app.css bundles are supported**:
  - You cannot reference an external vendor'd script `src` or link `href` in the layouts.
  - You must import the vendor deps into app.js and app.css to use them.
  - **Never write inline `<script>custom js</script>` tags within templates.**

## UI/UX and design

- **Produce world-class UI designs** with a focus on usability, aesthetics, and modern design principles.
- Implement **subtle micro-interactions** (e.g. button hover effects, and smooth transitions).
- Ensure **clean typography, spacing, and layout balance** for a refined, premium look.
- Focus on **delightful details** like hover effects, loading states, and smooth page transitions.
