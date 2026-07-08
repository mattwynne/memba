Result: IMPLEMENTED_AND_PUBLISHED

Plan path: `docs/iterations/049-member-role-badges/plan.md`

## Summary of delivered capability

Iteration 049 delivered member role badges on the club home Members tab:

- Active club members now include assigned active roles in the membership query result.
- Each member’s role names are sorted alphabetically.
- Members with no roles render without role badges.
- Removed members remain excluded, even if they had roles.
- The Members tab renders each role as a badge using `member-row__role badge badge-primary badge-soft`.
- Acceptance support was added so the `list_members.feature` scenarios run in both domain and browser runners, with the temporary TODO tags removed.

## Plan conformance summary

The implementation conforms to the plan:

- The todo list for `docs/iterations/049-member-role-badges/todo.md` shows all 10 implementation tasks checked off.
- Plan conformance gate reported:
  - `plan_conformant: true`
  - `plan_rework_available: false`
- Final artifact gate confirmed implementation evidence against base SHA `e53905406f896358e6f5a253ce09cb3b65578c35` and HEAD `6a9159da864a552f526c189048e2678b39d80bed`.
- Final artifact gate explicitly confirmed the acceptance feature edit was permitted by the plan:
  - `Acceptance .feature changes are explicitly permitted by the plan`
  - `Final artifact evidence confirmed.`
  - `Final artifact gate passed.`

## Key files changed

From final artifact gate evidence, files changed since implementation base:

### Acceptance tests and Cucumber support

- `acceptance-tests/features/list_members.feature`
- `acceptance-tests/features/step_definitions/list_members_steps.js`
- `acceptance-tests/features/support/list_members.js`
- `acceptance-tests/features/support/server_commands.js`
- `acceptance-tests/test/cucumber_config.test.js`

### Membership/domain and presentation

- `web/lib/memba/membership.ex`
- `web/lib/memba_web/member_dashboard_presentation.ex`

### Club home UI

- `web/lib/memba_web/controllers/page_html/club.html.heex`

### Web/domain tests

- `web/test/features/list_members_steps_test.exs`
- `web/test/features/step_definitions/membership_steps.exs`
- `web/test/memba/membership/query_test.exs`
- `web/test/memba_web/live/member_dashboard_live_test.exs`
- `web/test/memba_web/member_dashboard_presentation_test.exs`

### Iteration tracking

- `docs/iterations/049-member-role-badges/todo.md`

### Iteration metadata updated during publish

Publish output also reports the plan was marked as merged in the plan and iteration index:

- `docs/iterations/049-member-role-badges/plan.md`
- iteration index file updated by the publish script

## Published commit on main

Published to `main` successfully.

Main commit SHA:

- `9e9019803238c106d1cc1f7e2bcf662080167959`

Publish evidence:

- Commit created:
  - `iteration 049: 049 — Club home Members: role badges`
- Push result:
  - `e539054..9e90198  HEAD -> main`
- Publish script confirmed:
  - `Published implementation to main: 9e9019803238c106d1cc1f7e2bcf662080167959`

## Commit trailer metadata present

The publish step produced the final implementation commit:

- `9e90198 iteration 049: 049 — Club home Members: role badges`

No explicit commit trailer lines were shown in the provided publish output. The workflow did include Fabro checkpoint metadata in recent commits and the published commit came from run ID:

- `01KX040524KWGG9B8HHYG9WBS8`

## Tests and validation run

Validation completed successfully.

### Full dev/CI check

The workflow ran:

- `PATH="$PWD/bin:$PATH" dev ci`

Result: passed.

### Acceptance tests

Browser acceptance output reported:

- `87 scenarios (87 passed)`
- `536 steps (536 passed)`
- Duration: `3m58.502s`

Earlier final task validation also reported `dev check` passing on the final task state, including the same acceptance summary:

- `87 scenarios (87 passed)`
- `536 steps (536 passed)`

### Visual check

The todo list shows the visual check task completed:

- `Run ./bin/dev gallery-walk and compare the Members tab to design-system/wireframes/club-home.html`

## Manual demo/checks still recommended

Although the planned gallery-walk task is checked off, a final human smoke check is still useful:

- Open the club home Members tab as Alice.
- Verify Bob’s roles appear alphabetically.
- Verify Carol’s role appears.
- Verify Alice has no role badges.
- Verify removed members are absent.
- Confirm the badges visually match the intended design-system treatment.

## Non-blocking follow-ups

No blocking follow-ups are indicated.

Potential non-blocking follow-up from the plan’s risks section:

- Long member lists with many roles remain a simple list; pagination or virtualisation remains out of scope for this iteration.