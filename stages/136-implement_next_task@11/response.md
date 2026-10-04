Implemented packet `task-009e-7cb6a78-invitation-binding-1` with result `ready_for_review`.

Changes:

- Migrated [new.ex](/workspace/memba/web/lib/memba_web/live/member_invitation_live/new.ex:20) to one `:invitation_context` live-query binding.
- Added relevant notification refresh handling and fresh pre-command reauthorization.
- Removed independent projection-backed socket assigns for club, current member, and member count.
- Preserved invitation forms, validation, resend/delivery feedback, group-aware routes, and navigation.
- Added focused coverage in [new_test.exs](/workspace/memba/web/test/memba_web/live/member_invitation_live/new_test.exs:185) and [send_test.exs](/workspace/memba/web/test/memba_web/live/member_invitation_live/send_test.exs:210) for count entry/exit, transient-state preservation, unrelated-club isolation, access loss, and submit-time authorization.
- Wrote [latest-worker-result.json](/workspace/memba/docs/iterations/067-live-projection-queries/.delivery/latest-worker-result.json) with no unresolved items.

Validation:

- Focused packet suite: `70 tests, 0 failures`
- Formatting check: passed
- `git diff --check`: passed
- Task 009E remains unchecked as required.

`dev check` was not run because this packet explicitly reserves the full-suite gate for the deterministic workflow node.