Result: **REVIEW_ACCEPTED**

## Plan path

`docs/iterations/044-shared-app-shell/plan.md`

## Base SHA and reviewed commit range

- Base SHA: `c8b1a4e95361504e41a1984cfacef631a1b56784`
- Published reviewed/polished commit: `701f06cdcbafd8a606678298351a567ea2b09ca1`
- Reviewed range: `c8b1a4e95361504e41a1984cfacef631a1b56784..701f06cdcbafd8a606678298351a567ea2b09ca1`

## Final artifact gate evidence

The final artifact gate confirmed implementation evidence and passed:

- “Final artifact evidence confirmed.”
- “Final artifact gate passed.”
- No acceptance `.feature` changes detected.
- Changed files since base SHA were reported as:

  - `docs/code-health.md`
  - `styles.css`
  - `web/lib/memba_web/components/layouts.ex`
  - `web/test/memba_web/app_shell_css_test.exs`
  - `web/test/memba_web/club_site_shell_surfaces_test.exs`
  - `web/test/memba_web/components/layouts_test.exs`

Change summary from the gate:

```text
docs/code-health.md                                | 11 -----
styles.css                                         | 20 +++++++++
web/lib/memba_web/components/layouts.ex            | 15 ++-----
web/test/memba_web/app_shell_css_test.exs          | 22 +++++++++-
.../memba_web/club_site_shell_surfaces_test.exs    | 35 ++++++++++++++++
web/test/memba_web/components/layouts_test.exs     | 49 ++++++++++++++++++++++
6 files changed, 128 insertions(+), 24 deletions(-)
```

## ADR conformance summary

Independent reviews and synthesis found **no ADR violations**.

The implementation was judged to be limited to Phoenix layout/component, HEEx, CSS, and tests. It did not appear to alter domain modeling, aggregates, commands, events, projections, CQRS boundaries, read models, or infrastructure decisions.

The implementation conformed to the plan’s explicit technical decisions:

- Port design-system app-shell classes directly.
- Use shared `club_site` shell with `app-frame`, `app-bar`, `app-card`, `app-menu`, and `app-foot`.
- Gate identity dropdown to signed-in member surfaces.
- Provide member-name/email-local-part fallback and initials behavior.
- Render signed-out public club pages without identity controls.
- Wire Sign out through `POST /auth` with `_method=delete` and CSRF protection.

## Independent review outcome

All independent reviews recommended **ACCEPT**.

- Claude review: **ACCEPT**, high confidence.
- Codex review: **ACCEPT**, medium confidence.
- Gemini review: **ACCEPT**, medium confidence.
- Synthesis result: `implementation_accepted: true`, `review_fixes_available: false`.

The reviewers agreed that the synthesized blockers were not true merge blockers:

1. CSRF protection was already covered by test evidence.
2. Member display-name fallback duplication was, at most, a small non-blocking maintainability concern.

## Finding disposition

### Fixed / already covered

- **CSRF protection for club-site sign-out form**
  - Disposition: **Dismissed as already covered / effectively fixed by existing evidence.**
  - Evidence showed the layout test asserts:
    - `form#club-site-sign-out-form[action='/auth'][method='post']`
    - hidden `_method=delete`
    - hidden `_csrf_token`
    - non-empty CSRF token value.
  - Reviewers agreed this should not block merge.

- **Shared shell renders across club-site surfaces**
  - Disposition: **Fixed.**
  - Evidence included tests for club home, conversation, compose, invitation, and public club page rendering under the new shell.

- **Design-system app-shell class usage**
  - Disposition: **Fixed.**
  - Evidence included CSS/test coverage for `app-frame`, `app-bar`, `app-card`, `app-menu`, `app-foot`, and absence of legacy inline `--club-site-` styling.

- **Signed-out public page identity gating**
  - Disposition: **Fixed.**
  - Evidence showed signed-out layout renders the app bar but omits the member identity dropdown.

### Dismissed with reason

- **Member display-name fallback duplication**
  - Disposition: **Dismissed as non-blocking polish.**
  - Reviewers treated it as a small maintainability concern, not a behavioral, architectural, ADR, or safety issue.
  - Review polish may have touched related layout code, but the final gate only supports citing files listed there.

### Unhandled / workflow gap

The following judgement-worthy non-blocking findings were raised by reviewers but were **not recorded in `docs/code-health.md` during the review recording stage**, according to the `record_code_health` output. Because the critical instructions require this to be called out, this is a workflow gap:

- **Flash assign accepted by `club_site` but not visibly rendered**
  - Not fixed.
  - Not recorded during `record_code_health`.
  - Reviewers considered it non-blocking because flash handling may be owned elsewhere or out of scope.

- **Identity dropdown coverage is structural rather than interaction-level**
  - Not fixed.
  - Not recorded during `record_code_health`.
  - Reviewers considered structural layout tests adequate for this iteration, with a possible future a11y/interaction follow-up.

- **Sign-out from the new menu is structurally tested, not end-to-end**
  - Not fixed.
  - Not recorded during `record_code_health`.
  - Reviewers considered existing route/controller coverage plus form-structure coverage sufficient for merge.

- **Manual visual validation artifact not shown**
  - Not fixed in code.
  - Not recorded during `record_code_health`.
  - Reviewers did not block on this, but recommended gallery/wireframe comparison because this is a visual shell iteration.

## Repairs applied during review

The publish step reports a review-polish commit:

```text
[701f06c] review polish: iteration 044
2 files changed, 12 insertions(+), 12 deletions(-)
```

Files that may be cited for review repair/polish, constrained to final artifact gate evidence:

- `web/lib/memba_web/components/layouts.ex`
- `web/test/memba_web/components/layouts_test.exs`

The repair verification stage reported no working-tree diff change since repair start, so the run contains some workflow inconsistency around whether the attempted repair produced a detectable patch at that point. The final publish step nevertheless pushed a review-polish commit.

## Code-health note status

`record_code_health` reported:

- `docs/code-health.md` was not updated during that stage.
- No code-health entry was considered needed by that agent.
- `code_health_recording_ok: true`.

However, the final artifact gate shows `docs/code-health.md` changed relative to the base SHA with `11` deletions. That file therefore appears in the implementation artifact, but the review stage did **not** record the non-blocking review findings there.

Workflow gap: non-blocking reviewer findings listed above were neither fixed nor recorded in `docs/code-health.md` during the code-health recording stage.

## Key files reviewed or repaired

Matching final artifact gate evidence:

- `docs/code-health.md`
- `styles.css`
- `web/lib/memba_web/components/layouts.ex`
- `web/test/memba_web/app_shell_css_test.exs`
- `web/test/memba_web/club_site_shell_surfaces_test.exs`
- `web/test/memba_web/components/layouts_test.exs`

## Publish outcome

Review polish was pushed to `main`.

Publish output:

```text
To https://github.com/mattwynne/memba
   c6e7149..701f06c  HEAD -> main
Published review polish to main: 701f06cdcbafd8a606678298351a567ea2b09ca1
```

Finalization found the iteration already marked merged and made no finalization commit:

```text
Iteration 044 already marked merged; no finalization commit needed.
```

## Tests and validation run

Validation passed.

- Sandbox preflight passed.
- `dev ci` / `dev check` passed.
- Acceptance suite passed:

```text
85 scenarios (85 passed)
523 steps (523 passed)
```

Evidence showed automated coverage for:

- Shared `club_site` app frame.
- App bar rendering the club name.
- App card wrapping page content.
- Identity dropdown present for signed-in member surfaces.
- Identity dropdown omitted for signed-out public page.
- Sign-out form targets `/auth`.
- Method override `_method=delete`.
- Non-empty hidden CSRF token.
- Submit button labelled “Sign out”.
- App-shell CSS class usage.
- All relevant club-site surfaces rendering under the new shell.

## Manual demo/checks still recommended

Still recommended, because no gallery-walk artifact was shown in the review evidence:

- Run `./bin/dev gallery-walk`.
- Compare club-home and conversation screenshots against:
  - `design-system/wireframes/club-home.html`
  - `design-system/wireframes/member-conversation.html`
- Manually verify:
  - Signed-in club home and conversation show the app bar.
  - Identity dropdown opens/closes as expected.
  - Sign out works from the dropdown.
  - Public club page shows the app bar without identity dropdown.

## Non-blocking follow-ups

- Decide whether `club_site` should render the project-standard flash component or whether flash remains outside this layout.
- Add manual or automated accessibility/interaction validation for the identity dropdown if it becomes a reusable pattern.
- Consider an integration/browser test that submits sign out from the club-site shell if auth-entry regressions become likely.
- Centralize identity display-name/initials derivation if identity presentation grows with role badges, richer member profiles, avatars, or privacy rules.