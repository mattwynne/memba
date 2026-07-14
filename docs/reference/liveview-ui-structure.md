# LiveView UI structure and component factoring

Use this page when structuring LiveView screens, extracting reusable UI, or deciding where Tailwind/CSS should live.

## LiveViews are screen coordinators

A LiveView should usually own the behaviour of a routed screen:

- loading route params and session data,
- assigning view state,
- handling events,
- managing forms,
- managing streams,
- pushing navigation or client events,
- calling contexts/domain modules.

Keep the LiveView render tree focused on describing the page. If `render/1` becomes hard to scan because it contains repeated chrome, repeated cards, or repeated state-specific markup, extract presentation code into Phoenix components.

Do not move domain decisions into HEEx just to keep everything close to the markup. Prefer small private helpers or dedicated presentation modules for formatting, labels, state mapping, and CSS class selection.

## Prefer Phoenix components for stateless UI

Use `Phoenix.Component` components for reusable, stateless presentation:

- page headers,
- cards and panels,
- badges,
- buttons and links,
- empty states,
- navigation items,
- table wrappers,
- identity cells,
- repeated form sections,
- shared layout/chrome pieces.

Define explicit component interfaces with `attr/3` and `slot/3`. This gives compile-time feedback and makes components easier for humans and agents to use safely.

```elixir
attr :title, :string, required: true
attr :description, :string, default: nil
slot :actions
slot :inner_block, required: true

def panel(assigns) do
  ~H"""
  <section class="rounded-xl border border-line bg-paper p-5">
    <header class="flex items-start justify-between gap-4">
      <div>
        <h2 class="text-lg font-semibold text-ink">{@title}</h2>
        <p :if={@description} class="mt-1 text-sm text-ink-3">{@description}</p>
      </div>
      <div :if={@actions != []} class="flex items-center gap-2">
        {render_slot(@actions)}
      </div>
    </header>
    <div class="mt-4">
      {render_slot(@inner_block)}
    </div>
  </section>
  """
end
```

## Avoid LiveComponents unless stateful encapsulation is needed

Do not introduce a `Phoenix.LiveComponent` merely because markup is long. Prefer stateless Phoenix components for markup extraction.

Use a LiveComponent only when there is a strong, specific need for component-local LiveView behaviour, such as:

- component-local events,
- component-local form state,
- upload state,
- many independently interactive instances,
- complex widget lifecycle,
- a parent LiveView becoming clearer because a stateful child owns a cohesive workflow.

If the component only receives assigns and renders HTML, it should be a Phoenix component, not a LiveComponent.

## Organize components by ownership

Keep component modules organized by surface and responsibility.

Recommended shape:

```text
lib/memba_web/components/
  core_components.ex       # generic app-wide primitives
  layouts.ex               # app/admin/member/public shells
  brand.ex                 # logo and brand primitives
  admin_components.ex      # staff/admin surface components
  member_components.ex     # signed-in member surface components
  marketing_components.ex  # public/marketing surface components
```

Guidelines:

- Put truly generic primitives in `CoreComponents`.
- Put surface-specific patterns in a surface module, not `CoreComponents`.
- Do not turn a component module into a miscellaneous dumping ground.
- Keep component names semantic and product-facing where possible, e.g. `admin_page_header`, `member_empty_state`, `conversation_card`.
- Private one-off helpers may stay inside a LiveView when they are not reused and are tightly coupled to that screen.

For app-wide imports, add component modules to `MembaWeb.html_helpers/0` only when the components are broadly useful across the app. Otherwise alias/import them locally.

## When to extract UI

Extract markup when at least one of these is true:

- the same structure appears in multiple screens,
- a repeated pattern needs consistent spacing, typography, or interaction states,
- a render function is difficult to scan,
- tests need stable, named structure,
- a block has a clear semantic name in the product language,
- class lists are duplicated or becoming error-prone.

Avoid extraction when:

- the markup is used once and still readable,
- the extracted name would be vague (`box`, `thing`, `wrapper`),
- the component would need a large bag of unrelated assigns,
- the abstraction hides important page-specific behaviour.

## Tailwind and CSS factoring

Prefer Tailwind utility classes in HEEx for local styling. This keeps structure and styling together and works well with Phoenix components.

Use HEEx class list syntax for conditional classes:

```heex
<a class={[
  "rounded-full px-4 py-2 text-sm font-semibold transition",
  @active && "bg-sage-600 text-cream",
  !@active && "text-ink-2 hover:bg-sage-50 hover:text-ink"
]}>
  {@label}
</a>
```

Use helpers for repeated conditional classes:

```elixir
defp tab_class(true), do: ["bg-sage-600 text-cream", base_tab_class()]
defp tab_class(false), do: ["text-ink-2 hover:bg-sage-50", base_tab_class()]
defp base_tab_class, do: "rounded-full px-4 py-2 text-sm font-semibold transition"
```

Use custom CSS classes sparingly for:

- repeated structural patterns,
- large class bundles that obscure HEEx readability,
- global layout behaviours,
- vendor integration styles,
- states that are awkward to express directly in utilities.

Do not use custom CSS as a substitute for a clear component boundary. If markup and styling form a reusable UI concept, prefer a component.

## Design tokens and brand classes

Prefer project design tokens and brand utilities over raw hex colors in templates:

- `text-ink`, `text-ink-2`, `text-ink-3`,
- `bg-paper`, `bg-cream`,
- `text-sage-700`, `bg-sage-600`,
- `border-line`, `border-line-strong`,
- `text-error`, `bg-error-soft`, etc.

Raw hex values in HEEx are acceptable for short-lived prototypes or precise one-off migrations, but should not become the default style language.

## daisyUI policy

This app currently uses daisyUI as a themed foundation for common primitives such as `btn`, `badge`, `alert`, and `toast`. That is allowed.

Use daisyUI intentionally:

- keep the Memba theme tokens in `assets/css/app.css` coherent,
- combine daisyUI primitives with Tailwind utilities for product-specific polish,
- avoid copy-pasting generic daisyUI examples that do not match Memba's design language,
- prefer Memba components when a daisyUI pattern repeats across screens.

Do not add new third-party component systems without explicit agreement.

## IDs, accessibility, and tests

Add stable DOM IDs to key elements: forms, submit buttons, tab panels, stream containers, destructive actions, and test-critical regions.

Use semantic HTML and ARIA relationships for interactive structures:

- `role="tablist"`, `role="tab"`, `role="tabpanel"`,
- `aria-selected`, `aria-controls`, `aria-labelledby`,
- `aria-label` for icon-only or ambiguous links/buttons.

Tests should target these stable IDs and semantic selectors rather than fragile text or raw HTML structure.

## Lists and streams

For collections that LiveView updates incrementally, use LiveView streams and follow `liveview.md` stream rules.

For small, static, read-only collections, ordinary assigns and `:for` are fine.

## Forms

Use `to_form/2` in the LiveView and pass form assigns to `<.form>`. Access fields as `@form[:field]`. Prefer the shared `<.input>` component when available.

Do not pass changesets directly to templates.

## Practical checklist

Before finishing a LiveView UI change, ask:

- Is the LiveView mostly coordinating behaviour rather than containing reusable UI internals?
- Did repeated markup become a named Phoenix component?
- Are component interfaces declared with `attr` and `slot`?
- Did we avoid unnecessary LiveComponents?
- Are Tailwind classes readable and token-based?
- Are repeated conditional classes helperized or componentized?
- Are key elements stable and testable with IDs?
- Are accessibility relationships explicit for interactive UI?
