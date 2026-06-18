Implemented the plan-conformance repair and reran validation.

## 1. Plan requirement gap from the gate

The gate output available in the prompt only reported `plan_conformant=false` without a textual repair brief. Reviewing the plan + current implementation showed this concrete gap:

- Some changed member-facing surfaces still used bespoke initials/action markup instead of shared design-system components:
  - Member invitation page current-member initials used a hand-rolled `<span>`.
  - Member invitation submit/cancel actions included bespoke button/link styling.
  - Compose page “From” current-member initials used a hand-rolled `<span>`.
  - Message receipt toggle used `<.button>` but supplied a full bespoke `btn btn-ghost` class override, weakening variant-based component usage.

## 2. Concrete changes made

### Shared button component
- Updated `<.button>` so callers can add layout classes while preserving design-system base classes (`btn`, variant class, size class).
- This lets member pages use `variant`/`size` mapping and still add layout-only classes where needed.

### Member invitation page
- Replaced current-member initials `<span>` with `<.avatar>`.
- Replaced bespoke submit button styling with `<.button variant="primary" size="lg">`.
- Replaced cancel `<.link>` with `<.button href=... variant="secondary" size="lg">`.

### Compose page
- Replaced “From” initials `<span>` with `<.avatar>`.

### Message detail page
- Removed manual `btn btn-ghost` classes from the receipt group toggle and left variant styling to `<.button variant="ghost">`.

## 3. Files changed, grouped by requirement

### Shared button/avatar usage on member pages
- `web/lib/memba_web/components/core_components.ex`
- `web/lib/memba_web/live/member_invitation_live/new.ex`
- `web/lib/memba_web/live/member_message_live/new.ex`
- `web/lib/memba_web/controllers/page_html/message.html.heex`

### Automated proof of repaired conformance
- `web/test/memba_web/components/core_components_test.exs`
- `web/test/memba_web/live/member_invitation_live/new_test.exs`
- `web/test/memba_web/live/member_message_live/new_test.exs`
- `web/test/memba_web/member_page_design_system_alignment_test.exs`

## 4. Tests added/updated

- Added CoreComponents coverage proving custom layout classes no longer replace `btn`/variant/size classes.
- Extended member source conformance test to include:
  - `member_invitation_live/new.ex`
  - Compose LiveView avatar usage
- Added LiveView assertions proving:
  - Member invitation current-member avatar renders via shared avatar classes.
  - Member invitation submit/cancel render via shared button classes.
  - Compose “From” avatar renders via shared avatar classes.

## 5. Validation run

Passed:

- `devenv shell -- bash -lc 'cd web && mix format --check-formatted'`
- Focused ExUnit:
  - `43 tests, 0 failures`
- Full required validation:
  - `PATH="$PWD/bin:$PATH" dev check`
  - Passed
  - Acceptance summary: `82 scenarios (82 passed)`, `493 steps (493 passed)`

Notes on validation runtime:

- `PATH="$PWD/bin:$PATH" dev gallery-walk` was attempted twice.
- It failed due sandbox/toolchain/runtime issues, not application failures:
  - `bin/dev gallery-walk` timed out waiting for Phoenix even though the server log showed Phoenix started.
  - Retry hit `:eaddrinuse` because the first timed-out gallery server left port 4000 occupied.
  - The devenv shell lacks `curl`/`ps`/`pkill`, which `bin/dev` relies on for gallery readiness and forced cleanup.
- I did not patch tooling to compensate. I cleared the stale runtime process so `dev check` could run, and the final `dev check` passed.

## 6. Remaining gaps / human questions

- No remaining code/test plan gaps found.
- Sandbox follow-up: the gallery-walk environment needs required runtime tools (`curl`, and likely `ps`/process cleanup tools) available inside the devenv shell so `./bin/dev gallery-walk` can complete reliably.