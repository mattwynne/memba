# Problem: dev check can validate the wrong checkout

Date: 2026-09-12

## Observation

During the Toronto footer worktree validation, `./bin/dev check` was launched from the worktree while the parent agent environment still carried context from the main checkout:

- `PATH` contained `/Users/matt/git/mattwynne/memba/bin` before the worktree's `bin` directory;
- `MEMBA_DEVENV_SHELL=1` said the shell was already prepared;
- `DEVENV_*`, `PGHOST`, `PGPORT`, and `PGDATA` pointed at the main checkout's devenv/Postgres context.

`bin/dev check` printed a passing Mix quality gate, including 1,210 passing tests, but those tests were run through the main checkout's `bin/mix`. That wrapper intentionally changes directory to its own `repo_root/web`, so the Mix phase validated the wrong code. Browser acceptance later used the worktree's explicit `bin/mix` path and exposed missing worktree dependencies.

Evidence:

- `/tmp/toronto-footer-final-check.log` shows the final full check eventually ran 134 browser scenarios successfully after the environment was isolated.
- The prior diagnosis transcript records the causal path: `bin/dev` trusted `MEMBA_DEVENV_SHELL=1`, skipped devenv re-entry, and its bare `mix` calls resolved through the inherited main-checkout `PATH`.

## Cause analysis

Occurrence:

- `bin/dev` treated `MEMBA_DEVENV_SHELL=1` as sufficient proof that the current process was inside this checkout's devenv shell.
- The script did not compare `DEVENV_ROOT` with its own checkout root before deciding to skip re-entry.
- Several dev commands invoked bare `mix`; when `PATH` came from another checkout, that checkout's wrapper won.

Escape:

- The Mix quality gate looked plausible because the main checkout's test suite was healthy.
- The existing dev quality-gate regression covered exit-status composition, not checkout identity or inherited service/database context.
- Browser acceptance used a more explicit lifecycle command and therefore failed differently, making the earlier Mix success easy to misread as valid.

## Target condition

A dev command launched from a worktree must either run with that worktree's wrapper and service/database context or stop with a clear diagnostic. A boolean shell marker inherited from another checkout must not make a foreign `DEVENV_ROOT`, `PGHOST`, or `PATH` trustworthy.

## Resolution

Date: 2026-09-12

Root cause: the `bin/dev` environment boundary trusted a checkout-agnostic boolean marker and then used command lookup for `mix`, allowing another checkout's wrapper and Postgres/devenv context to satisfy the quality gate.

Fix applied:

- `bin/dev`: canonicalises its own root, treats a devenv shell as valid only when `DEVENV_ROOT` canonicalises to that root, clears inherited `DEVENV_*`/`PG*` context before invoking `devenv`, and refuses to continue if re-entry still does not yield the expected root.
- `bin/dev`: changes to its own root before re-entry, invokes the re-entered script through the canonical absolute `$repo_root/bin/dev` path, prepends its own `bin` to `PATH` after the boundary, and defines `mix` to call its own `bin/mix`, so `env mix ...` and direct shell calls both resolve to the current checkout.
- `.fabro/workflows/scripts/test_dev_checkout_boundary.sh`: creates two fake checkout roots and proves a mismatched inherited `MEMBA_DEVENV_SHELL`/`DEVENV_ROOT`/`PGHOST` re-enters safely, does not invoke the foreign `mix`, handles relative `source-checkout/bin/dev` invocation from outside the checkout, and still allows same-checkout nested dev commands.
- `.fabro/workflows/scripts/test_dev_quality_gate_exit_status.sh`: marks its synthetic sourced context as active so the new startup guard does not re-enter while the existing helper-function regression is being sourced from process substitution.

Validation:

- The initial checkout-boundary regression failed against `e68019eae70d9c98b4dddbd3e27f0a0c5fb64d06` with exit status 77, the fake foreign `mix` status.
- Parent review found a follow-on regression in local commit `f785d92fe`: relative invocation from outside the checkout re-entered after `cd "$repo_root"` but still used `$0`, so `source-checkout/bin/dev` became `source-checkout/source-checkout/bin/dev`. The expanded regression failed against `f785d92fe` with exit status 127 before the absolute-script-path repair.
- `bash -n bin/dev .fabro/workflows/scripts/test_dev_quality_gate_exit_status.sh .fabro/workflows/scripts/test_dev_checkout_boundary.sh` — passed.
- `.fabro/workflows/scripts/test_dev_quality_gate_exit_status.sh` — passed.
- `.fabro/workflows/scripts/test_dev_checkout_boundary.sh` — passed.
- `cd acceptance-tests && node --test test/lifecycle.test.js` — passed, 9 lifecycle tests.
- `./bin/dev check` — Mix precommit passed with 1,225 tests and 0 failures; browser acceptance did not complete because the default Erlang node name `memba_acceptance_server@MattBook-Air` was already in use by another local acceptance run.
- `ACCEPTANCE_SERVER_NODE=memba_kaizen_checkout_validation ./bin/dev check` — Mix precommit passed again with 1,225 tests and 0 failures; browser acceptance started with the distinct node but failed in `features/group_conversations.feature:43`, where the compose form reached `data-compose-state="send_failed"` instead of `sent`.
- `ACCEPTANCE_SERVER_NODE=memba_kaizen_checkout_validation_retry ./bin/dev acceptance features/group_conversations.feature:43` — reproduced the same acceptance failure; no production, main-checkout, or other-worktree services were stopped or reconfigured.
- After the absolute re-entry target repair, `ACCEPTANCE_SERVER_NODE=memba_kaizen_checkout_validation_final ./bin/dev check` on a clean committed state re-entered this worktree's devenv from the inherited main-checkout environment, passed Mix precommit with 1,225 tests and 0 failures, then failed browser acceptance in the same known race scenario: 134 scenarios, 1 failed and 133 passed.
- Separate diagnostics in `/tmp/toronto-footer-join-experiment.log` and `/tmp/toronto-footer-ready-control.log` showed the browser failures are a test-harness readiness race: Playwright can see `isConnected` while the LiveView root is still `phx-loading`, and the initial LiveView render then overwrites values typed too early (subject, name, or slug). Four normal replays passed, forced delayed join reproduced the failures, and waiting for `.phx-connected` fixed the diagnostic set. CI on the exact Toronto footer base `e68019eae70d9c98b4dddbd3e27f0a0c5fb64d06` passed and was deployed.
- `ACCEPTANCE_SERVER_NODE=memba_kaizen_checkout_validation_final2 ./bin/dev check` on clean committed state `00e46f99` passed once: Mix precommit reported 1,225 tests and 0 failures; browser acceptance reported 134 scenarios and 951 steps passed. The startup diagnostic confirmed it discarded the inherited main-checkout `DEVENV_ROOT` and re-entered this worktree.
- `ACCEPTANCE_SERVER_NODE=memba_kaizen_checkout_validation_final3 ./bin/dev check` on clean committed state `47392a231` failed in the known browser readiness race: Mix precommit passed with 1,225 tests and 0 failures; browser acceptance reported 134 scenarios with 2 failures (`features/group_conversations.feature:43` and `features/person_email_addresses.feature:16`).

Remaining follow-up:

- The known acceptance test-harness readiness race is tracked and repaired separately in `docs/kaizen/2026-09-12-acceptance-inputs-race-liveview-join.md`; do not fold that product/test-harness change into this checkout-boundary tooling fix.
- Watch future worktree quality gates for the new startup diagnostic; if it appears repeatedly in valid shells, tighten the shell-entry contract rather than weakening the root check.
