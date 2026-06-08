Implemented task `014` and checked it off in `docs/iterations/028-staff-member-invitations/todo.md`.

Changes made:
- Added browser Cucumber step definitions for `club_member_invitations.feature`.
- Added browser support helpers for:
  - creating/remembering clubs and invitees,
  - sending/resending member invitations,
  - reading invitation emails,
  - following invitation links,
  - completing invited-member profile flow,
  - asserting pending/active membership state.
- Added domain Cucumber step definitions for the same invitation lifecycle.
- Updated shared request-account assertion helpers to respect a scenario’s remembered person email, needed for invites like `robin@example.com` instead of the default `robin@example.test`.

Validation:
- Targeted browser Cucumber run for `club_member_invitations.feature` with temporary config: `7 scenarios, 45 steps passed`.
- Elixir format check for new domain step file passed.
- Focused domain Cucumber runner/config tests passed: `5 tests, 0 failures`.
- Required `dev check` passed:
  - `714` ExUnit tests passed.
  - `62` browser acceptance scenarios passed.

Left unchanged:
- Did not remove/narrow `@todo-domain` or `@todo-ui`; task `015` remains unchecked.
- Task `016` remains unchecked.
- No commit was made.