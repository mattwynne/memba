Implemented task 007 and left it unchecked for independent review.

1. Selected todo line

`- [ ] 007 Make new user-facing operations distinguish custom groups structurally, not by arbitrary display-name checks.`

2. Changes made

- Added `SystemGroups.custom_group?/1` in [system_groups.ex](/workspace/memba/web/lib/memba/membership/system_groups.ex:44). It classifies groups using the club-scoped deterministic Everyone/Admin identities, independent of display name, email slug, or caller-supplied group key.
- Updated the member-facing group presentation in [page_html.ex](/workspace/memba/web/lib/memba_web/controllers/page_html.ex:99) to use that centralized structural classification for private-group metadata.
- Added domain-level classification coverage in [system_groups_test.exs](/workspace/memba/web/test/memba/membership/system_groups_test.exs:53), including misleading names and group keys.
- Added rendered LiveView coverage in [member_dashboard_live_test.exs](/workspace/memba/web/test/memba_web/live/member_dashboard_live_test.exs:1336), proving:
  - a custom group remains private even when its display metadata resembles Everyone;
  - a structurally identified system group does not become private when renamed.

3. Focused validation

- TDD red run:
  - `dev test test/memba/membership/system_groups_test.exs`
  - Failed as expected because `SystemGroups.custom_group?/1` did not yet exist.
- Focused domain and rendered-LiveView tests:
  - `dev test test/memba/membership/system_groups_test.exs test/memba_web/live/member_dashboard_live_test.exs`
  - 55 tests, 0 failures.
- Broad non-browser validation:
  - `dev check --quick`
  - 1,313 tests, 0 failures.
- `git diff --check` passed.
- The workflow’s final gate retains responsibility for full browser-inclusive `dev check`.

4. Todo state

The selected line remains unchanged and unchecked:

`- [ ] 007 Make new user-facing operations distinguish custom groups structurally, not by arbitrary display-name checks.`

5. Todo changes

None. No tasks were split, added, removed, reordered, or checked.

6. ADR conformance

- ADR 0002: this remains explicit domain behavior rather than presentation logic inferred from mutable text.
- ADR 0007: classification stays within Membership’s public domain vocabulary; the web layer does not inspect Membership projection storage.
- ADR 0009: no projection schema or query-side authority was introduced.
- ADR 0011: existing deterministic, club-scoped identities remain the stable structural identifiers.
- ADR 0024: no aggregate ownership, event history, or Club consistency-boundary behavior changed.