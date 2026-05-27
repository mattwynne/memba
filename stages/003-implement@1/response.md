Got it — I can’t safely complete this implementation in the current environment because the required Elixir toolchain is missing.

### Blocker encountered

I verified the workspace and then tried to run the baseline test loop, but:

- `mix` is not installed (`mix: command not found`)
- `devenv` is not installed (`devenv: command not found`)
- `nix` is not installed (`nix: command not found`)

That means I cannot:

- add deps and resolve lock updates safely,
- run TDD cycles (`mix test`),
- run Cucumber compilation/execution,
- run `dev check` / `mix precommit` as required by the plan.

Per your rules, this is a **real infrastructure blocker** (missing sandbox/toolchain), and I should stop and report rather than guess or patch scripts to work around it.

---

### What I need to proceed

Please provide an environment where at least one of the following works:

1. `devenv shell mix test` / `devenv shell mix precommit`, or
2. plain `mix test` / `mix precommit` in `web/`.

Once that’s available, I’ll implement the full iteration top-to-bottom with tests first and drive it to green `dev check`.