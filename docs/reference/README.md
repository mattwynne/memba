# Reference index

Use this directory as the detailed rulebook for coding agents working on Memba. `AGENTS.md` stays short; the pages here hold the expanded guidance.

## Start here

- [Project guidelines](project-guidelines.md) — project-level defaults: run `devenv shell mix precommit`; use `Req` for HTTP.
- [Phoenix 1.8](phoenix-1-8.md) — layouts, flash, icons, inputs, routing aliases, and removed `Phoenix.View` patterns.

## By task

### Building or changing UI

- [Frontend, CSS, and design](frontend-design.md) — Tailwind v4 imports, CSS/JS bundle rules, no `@apply`, no daisyUI, visual quality expectations.
- [Phoenix HTML and HEEx](phoenix-html.md) — `~H`/HEEx syntax, forms, IDs, interpolation, class lists, comments, and loops.
- [Phoenix LiveView](liveview.md) — LiveView naming, links/navigation, streams, hooks, pushed events, LiveView tests, and form handling.

### Working with server-side Elixir

- [Elixir, Mix, and tests](elixir-mix-tests.md) — list access, rebinding, module boundaries, struct access, date/time, atoms, OTP names, `Task.async_stream`, Mix, and process-test rules.
- [Ecto](ecto.md) — preloads, schemas, changesets, generated migrations, and secure field assignment.

## Common lookups

| If you are looking for... | Read... |
| --- | --- |
| `current_scope`, `<Layouts.app>`, or `<.flash_group>` errors | [Phoenix 1.8](phoenix-1-8.md) |
| Tailwind v4 `app.css` import syntax | [Frontend, CSS, and design](frontend-design.md) |
| HEEx syntax, `{...}` interpolation, class lists, or comments | [Phoenix HTML and HEEx](phoenix-html.md) |
| Form setup with `to_form/2` and `<.input>` | [Phoenix HTML and HEEx](phoenix-html.md), [Phoenix LiveView](liveview.md) |
| LiveView streams, empty states, and `phx-update="stream"` | [Phoenix LiveView](liveview.md) |
| LiveView hooks, colocated JS, or `push_event/3` | [Phoenix LiveView](liveview.md) |
| LiveView testing selectors and `LazyHTML` | [Phoenix LiveView](liveview.md) |
| Ecto preloads, changesets, or migrations | [Ecto](ecto.md) |
| General Elixir gotchas and test-process synchronization | [Elixir, Mix, and tests](elixir-mix-tests.md) |
