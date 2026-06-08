Implemented the review repair pass. No acceptance feature files were edited.

## 1. Review issue mapping

| Review issue | Status | Fix / justification |
|---|---:|---|
| `backfill-person-email-addresses` | Fixed | Tightened the existing backfill migration so legacy `membership_people.email` data is copied safely into `membership_person_email_addresses`, skipping blank emails, avoiding duplicate normalized emails, avoiding a second primary email for a person, and preserving legacy row timestamps. Added regression coverage. |
| `cleanup-empty-accept-invitation-plug` | No change needed | Current tree has no `MembaWeb.Authentication.AcceptInvitationPlug` file and no router pipeline using it. The synthesized issue appears already absent in this implementation. |
| `use-verified-club-route` | No change needed | Current `MembaWeb.ClubMemberInvitationController` does not have a hardcoded `club_path/1`; it redirects through `ClubSite.url(club, "/")` and uses verified routes for fallback/auth paths. |
| `escape-invitation-email-html` | No change needed | Current `Memba.Membership.ClubMemberInvitationEmail` composes HTML via `Memba.EmailTemplates`, which escapes dynamic text. Existing tests already cover malicious club names like `West <Coast>\r\nBcc: ...`. |

## 2. Files changed

### Backfill existing `people.email` values into `person_email_addresses`

- `web/priv/repo/migrations/20260602024629_backfill_membership_person_email_addresses.exs`
  - Uses a normalized source subquery.
  - Skips blank legacy email values.
  - Uses `DISTINCT ON (lower(btrim(person.email)))` to avoid duplicate normalized email inserts.
  - Skips rows whose normalized email already exists.
  - Skips rows for people who already have a primary email address.
  - Preserves `membership_people.inserted_at` / `updated_at` instead of using `now()`.

- `web/test/memba/membership/person_email_address_projection_test.exs`
  - Added coverage that the backfill skips blank legacy emails.
  - Added coverage that duplicate normalized legacy emails do not create duplicate projection rows.
  - Added coverage that existing primary email rows are not duplicated.

## 3. Tests run

- `PATH="$PWD/bin:$PATH" dev check`
  - Passed.
  - ExUnit: `722 tests, 0 failures`
  - Acceptance: `69 scenarios (69 passed)`, `466 steps (466 passed)`

Notes:
- I also attempted a direct focused command, `cd web && mix test test/memba/membership/person_email_address_projection_test.exs`, but direct `mix test` outside the dev helper could not connect to the sandbox-managed Postgres socket at `/tmp/devenv/postgres/.s.PGSQL.15432`. The required `dev check` path started/managed services correctly and passed.

## 4. Remaining gaps / human questions

- No remaining gaps for the selected automatic repair issues.
- If production legacy data contains multiple people with the same normalized email, the backfill now avoids breaking the new unique index by backfilling one deterministic row. Human/data cleanup may still be useful later to reconcile those duplicate legacy people, but that is outside this bounded repair.