Result: REVIEW_ACCEPTED

Plan path: `docs/iterations/044-shared-app-shell/plan.md`

Base SHA: `ab7d47a642afc7f29774f681d30ad635ac6043ba`

Reviewed commit range: `ab7d47a642afc7f29774f681d30ad635ac6043ba..c8b1a4e95361504e41a1984cfacef631a1b56784`

## Final artifact gate evidence

The final artifact gate confirmed implementation artifact evidence for the reviewed range.

It reported files changed since base SHA `ab7d47a642afc7f29774f681d30ad635ac6043ba`:

- `.fabro/workflows/iteration-review/workflow.toml`
- `acceptance-tests/features/support/authentication.js`
- `design-system/README.md`
- `docs/code-health.md`
- `styles.css`
- `web/assets/css/app.css`
- `web/lib/memba_web/components/layouts.ex`
- `web/lib/memba_web/live/member_message_live/show.ex`
- `web/test/memba_web/app_shell_css_test.exs`
- `web/test/memba_web/components/layouts_test.exs`
- `web/test/memba_web/live/member_message_live/show_test.exs`

The gate also reported:

- “No acceptance `.feature` changes detected.”
- “Final artifact evidence confirmed.”
- “Final artifact gate passed.”

## ADR conformance summary

Independent reviews did not identify ADR violations.

- Claude: ADR conformance could not be fully assessed because no ADR files were included in context, but no obvious violations were detected.
- Codex: ADR conformance PASS.
- Gemini: ADR conformance PASS.
- Synthesis: accepted the implementation.

Overall ADR disposition: no ADR violations found in the available review evidence.

## Independent review outcome

All three independent reviewers initially returned `REJECT` because they identified a plan-conformance concern around the missing email-local-part fallback for `member_name`.

The synthesis stage nevertheless marked:

```json
{
  "implementation_accepted": true,
  "review_fixes_available": false
}
```

So the workflow proceeded to acceptance/publish despite the independent reviewer rejection.

## Finding disposition

### 1. Missing email-local-part fallback for signed-in member identity

Disposition: **unhandled workflow gap**

All three independent reviewers flagged this as blocking.

The plan explicitly required `member_name` to use an email-local-part fallback when `member.name` is absent. Reviewers reported that implementation evidence showed direct use of `member.name`, which could hide the identity dropdown and Sign out action for signed-in members without names.

No review repair evidence shows this finding was fixed. It was also not the finding recorded in `docs/code-health.md`.

Because this reviewer finding was neither fixed nor recorded as code health, this is a workflow gap.

### 2. `Layouts.initials/1` blank or whitespace string hardening

Disposition: **unhandled workflow gap**

Reviewers suggested hardening initials generation so blank or whitespace-only names produce a fallback such as `"?"`.

No review repair evidence shows this was fixed, and it was not recorded in `docs/code-health.md`.

### 3. CSS-hover / touch-device identity dropdown concern

Disposition: **unhandled workflow gap**

Reviewers noted the identity dropdown appears CSS-driven and may be fragile on touch devices or for accessibility expectations.

This was presented as judgement-worthy and non-blocking, but it was not recorded in `docs/code-health.md` and no repair evidence shows it was fixed.

### 4. Repeated shared shell assigns across signed-in club surfaces

Disposition: **unhandled workflow gap**

Reviewers noted small duplication around assigning shared shell data such as `club_name` / `member_name` across multiple signed-in surfaces.

This was non-blocking, but it was not recorded in `docs/code-health.md` and no repair evidence shows it was fixed.

### 5. Static design-system preview token dependency

Disposition: **recorded**

The code-health recording stage updated `docs/code-health.md` with a dated Iteration 044 entry for a judgement-worthy, non-blocking issue:

- The shared repo-root `styles.css` used by static design-system previews depends on Memba design tokens that the linked previews do not define.

This was explicitly recorded as code health. No `dev check` was run for that docs-only recording step, which is consistent with the project workflow.

## Repairs applied during review

Review polish was applied only as a documentation/code-health update.

The publish step reported:

```text
[fabro/run/01KWRY2P5YRT9H7R2TSTNPH1Y9 c8b1a4e] review polish: iteration 044
 1 file changed, 11 insertions(+)
```

The final artifact gate evidence includes `docs/code-health.md`, so the repair/polish file to cite is:

- `docs/code-health.md`

No code repair should be inferred beyond files listed in the final artifact gate evidence.

## Code-health note status

`docs/code-health.md` was updated.

Recorded finding:

- Static design-system previews using repo-root `styles.css` depend on design tokens that the linked previews do not define.

Important gap:

- The independent reviewers’ other judgement-worthy findings — identity dropdown touch/accessibility concern and repeated shell assigns — were not recorded in `docs/code-health.md`.
- The independent reviewers’ blocking fallback concern and initials hardening suggestion were also not fixed or recorded.

## Key files reviewed or repaired

Matching the final artifact gate evidence, key implementation/test/design files in the reviewed range were:

- `web/lib/memba_web/components/layouts.ex`
- `web/lib/memba_web/live/member_message_live/show.ex`
- `web/assets/css/app.css`
- `styles.css`
- `web/test/memba_web/app_shell_css_test.exs`
- `web/test/memba_web/components/layouts_test.exs`
- `web/test/memba_web/live/member_message_live/show_test.exs`
- `acceptance-tests/features/support/authentication.js`
- `design-system/README.md`
- `docs/code-health.md`
- `.fabro/workflows/iteration-review/workflow.toml`

Review polish/repair specifically evidenced:

- `docs/code-health.md`

## Publish outcome

Review polish was pushed to `main`.

Publish output:

```text
To https://github.com/mattwynne/memba
   245e74a..c8b1a4e  HEAD -> main
Published review polish to main: c8b1a4e95361504e41a1984cfacef631a1b56784
```

The iteration finalization step then marked `docs/iterations/044-shared-app-shell/plan.md` as merged in the plan and iteration index, with no additional finalization commit required.

## Tests and validation run

Preflight:

- Clean working tree required before review.
- `dev sandbox-check` passed.

Automated validation:

- `dev ci` / dev check passed.
- Acceptance output reported:

```text
85 scenarios (85 passed)
523 steps (523 passed)
4m00.192s
```

Final artifact validation:

- Final artifact gate passed.
- No acceptance `.feature` changes detected.

## Manual demo/checks still recommended

The plan requested a visual/manual check with:

- `./bin/dev gallery-walk`
- Compare club-home and conversation screenshots to:
  - `design-system/wireframes/club-home.html`
  - `design-system/wireframes/member-conversation.html`

The provided review evidence does not include the gallery-walk output or screenshot comparison result, so this remains recommended if not already performed outside the captured evidence.

Also recommended manually verify:

- Signed-in club home shows app bar and identity dropdown.
- Conversation surface shows app shell alignment.
- Sign out works from the dropdown.
- Public club page shows app bar without identity dropdown.
- A signed-in member with no stored name still has a usable identity/sign-out affordance — this is especially important because reviewers flagged the fallback as unhandled.

## Non-blocking follow-ups

1. Fix or explicitly resolve the email-local-part fallback gap for `member_name`.
2. Add focused coverage for a signed-in member with `name: nil`.
3. Harden `Layouts.initials/1` for blank/whitespace names.
4. Decide whether CSS-only dropdown interaction is acceptable for touch/accessibility, or add click/keyboard behaviour.
5. Consider a shared helper/plug for repeated club shell assigns if future identity metadata grows.
6. Resolve the recorded code-health issue around design-system previews and missing design token definitions.