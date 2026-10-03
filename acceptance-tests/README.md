# Acceptance tests

The Cucumber feature tree in `features/` serves two runners:

- the Elixir/domain runner used by `dev check` executes focused business-rule examples by default;
- the browser runner here (`npm test`) drives Phoenix through Playwright only for selected user journeys.

Keep rule examples in their domain feature files. Put each coherent, possibly cross-feature browser journey in its own `features/journeys/*.feature` file, tagged `@journey` at feature level. A journey may adapt existing scenarios but should protect a named real-browser risk, not repeat every rule permutation. Both runners discover the tree; they select different scenarios. See [ADR 0026](../docs/adr/0026-keep-browser-journeys-distinct-from-domain-examples.md).

## Tags

- Untagged scenarios run at the domain/application layer only.
- `@journey` selects a browser-only scenario; the domain runner excludes it. Use it only for deliberately selected journeys, not to hide unsupported domain steps.
- `@todo` excludes a genuinely future/unimplemented scenario from both runners until its intended layer is ready. Validated future iteration plans may retain these scenarios on main. Do not use it to hide broken current behaviour.
- `@wip` marks the one agreed scenario currently driving delivery. The workflow removes that scenario's `@todo`, runs it with an explicit pre-run predicted failure and keeps `@wip` while it is red; when green, the workflow removes `@wip` and normal regression coverage continues. `@wip` does **not** exempt a scenario from the normal runner, and neither a red scenario nor an outstanding `@wip` may be published. The current focused WIP runner supports domain/application examples, not `@journey` browser journeys.
- `@iteration-NNN` records provenance, not runner selection.

## Responsive check

`dev check` also invokes `npm run test:responsive`, a narrow direct-Playwright check for objective responsive regressions. It is not Gherkin/Cucumber and it does not use pixel baselines.

The browser check runs only when the trigger sees relevant style/layout changes: `styles.css`, `web/assets/css/**`, visual theme/icon vendor inputs under `web/assets/vendor/`, HEEx under `web/lib/memba_web/**`, and presentation/layout `.ex` files under `web/lib/memba_web` components, LiveViews, HTML modules, or `*_presentation.ex`. The trigger checks staged, unstaged, untracked files, and committed CI diff when a base ref/sha is available. In CI, an unknown or missing base fails open and runs the check with a logged reason rather than silently skipping a relevant committed change. Locally without a base, it also compares HEAD with the previous commit so a clean checkout of a layout-changing commit still runs the check. When no previous commit exists, it runs rather than silently skipping.
