# Memba agent guide

This is a web application written using the Phoenix web framework.

Keep this file short. Detailed project rules live in [docs/reference/](docs/reference/README.md).

## Required workflow

- Use `dev check` when you are done with code, config, dependency, migration, acceptance-test, or app-behaviour changes, and fix any pending issues.
- Do not run `dev check` for docs-only, planning-only, prose-only, or kaizen-note edits unless Matt explicitly asks for it or the edit changes executable examples/scripts.
- Use the included `:req` (`Req`) library for HTTP requests. Avoid `:httpoison`, `:tesla`, and `:httpc`.

## Reference map

- Start with the semantic index: [docs/reference/README.md](docs/reference/README.md).
- Project-wide defaults: [docs/reference/project-guidelines.md](docs/reference/project-guidelines.md).
- Phoenix 1.8 layout, routing, icon, and input rules: [docs/reference/phoenix-1-8.md](docs/reference/phoenix-1-8.md).
- Tailwind, JS/CSS bundles, and design standards: [docs/reference/frontend-design.md](docs/reference/frontend-design.md).
- Elixir, Mix, and testing rules: [docs/reference/elixir-mix-tests.md](docs/reference/elixir-mix-tests.md).
- Ecto rules: [docs/reference/ecto.md](docs/reference/ecto.md).
- HEEx and Phoenix HTML rules: [docs/reference/phoenix-html.md](docs/reference/phoenix-html.md).
- LiveView, streams, hooks, forms, and LiveView tests: [docs/reference/liveview.md](docs/reference/liveview.md).

When a task touches one of these areas, read the relevant reference page before editing code.
