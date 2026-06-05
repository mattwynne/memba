# Gum CLI notes

Gum is Charm's command-line UI helper. Use it from project scripts when a small amount of terminal formatting improves readability without changing command semantics.

## Project usage

`bin/dev fabro progress <run_id> [plan_path]` uses `gum style` for terminal output.

For project scripts that run through `bin/dev`, Gum is part of the expected devenv toolchain. Commands that must run outside `bin/dev` should avoid depending on Gum unless they arrange their own tool availability.

## Common commands

### `gum style`

Style text with color, bold, borders, padding, and alignment.

Examples:

```sh
gum style --bold --foreground 212 "Fabro run 01ABC..."
gum style --foreground 42 "Progress: [████░░░] 4/10 (40%)"
gum style --border rounded --padding "0 1" "Delivery running"
```

Useful options used by this project:

- `--bold` — bold text.
- `--foreground <color>` — set foreground color. Gum accepts ANSI color numbers such as `42`, `212`, `214`, and `245`.
- `--border rounded` — draw a rounded border.
- `--padding "Y X"` — add vertical/horizontal padding.

### `gum format`

Render Markdown-like text in the terminal.

```sh
gum format <<'MD'
# Progress

- Task 001 complete
- Task 002 running
MD
```

### `gum choose`, `gum confirm`, `gum input`

Interactive prompts. Avoid these in unattended Fabro workflow scripts because they can block automation.

## Dependency

`gum` is included in `devenv.nix` for local `dev` commands. If a command runs outside the project devenv shell, enter through `bin/dev` or arrange `gum` separately.
