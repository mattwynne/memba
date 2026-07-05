Implemented the bounded repair pass for the two review-gate issues.

## Issue-to-fix mapping

| Review issue | Fix | Files |
|---|---|---|
| `csrf-protect-club-site-sign-out` | Verified the club-site sign-out form includes a non-empty Phoenix CSRF hidden token. The implementation already used `<.form ... method="delete">`, so no product-code change was needed for CSRF protection; the test now proves it. | `web/test/memba_web/components/layouts_test.exs` |
| `dedupe-member-display-name-fallback` | Refactored club-site identity initials to derive from `club_identity_label/2`, so the member-name/email-local-part fallback logic has one source of truth. | `web/lib/memba_web/components/layouts.ex` |

## Concrete changes made

### 1. CSRF protection verification

Added an assertion that `#club-site-sign-out-form` renders:

- `input[name="_csrf_token"]`
- `type="hidden"`
- a non-empty `value`

This hardens the existing structural test without changing product behaviour.

### 2. Member display-name fallback deduplication

Changed:

```elixir
club_identity_initials/2
```

to delegate through:

```elixir
club_identity_label/2
```

before calling `initials/1`.

This preserves existing behaviour while removing duplicated member-name trimming and email-local-part fallback logic.

## Files changed

- `web/lib/memba_web/components/layouts.ex`
- `web/test/memba_web/components/layouts_test.exs`

No acceptance feature files were edited.

## Tests / checks run

- `cd web && mix format lib/memba_web/components/layouts.ex test/memba_web/components/layouts_test.exs` — passed.
- `PATH="$PWD/bin:$PATH" dev check` — passed.
  - Acceptance suite: `85 scenarios (85 passed)`, `523 steps (523 passed)`.

I also initially tried `cd web && mix test test/memba_web/components/layouts_test.exs`, but it failed because Postgres was not running at `/tmp/devenv/postgres/.s.PGSQL.15432`. The required `dev check` subsequently ran with the proper dev environment/services and passed.

## Remaining gaps / human questions

None for the two selected repair issues. The working tree still has the pre-existing untracked `.fabro/tmp/` review artifact directory from the pipeline; I left it untouched.