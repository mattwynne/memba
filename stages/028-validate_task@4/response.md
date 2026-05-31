### Decision
**VALID**

### Evidence
- Completed todo/check-off evidence found:
  - Working tree is clean (`git status --short` empty).
  - Recent checkpoint history shows `ec3e111 pre_validate_snapshot` on HEAD and recent implement checkpoint `4a15859 implement_next_task`.
  - `4a15859` changed exactly one ordinary todo line:
    - `004 Extend Memba.Membership query API as needed:` from `- [ ]` to `- [x]`.
  - Parent todo state had tasks 001–003 checked and task 004 as the first unchecked task.

- Implementation artifacts found:
  - `web/lib/memba/membership.ex` now exposes:
    - `list_active_clubs_for_member_email/1`
    - `active_member_of_club_by_email?/2`
  - The new queries normalize email input, compare projected person email case-insensitively, enforce active memberships, handle invalid/blank input safely, and order club results stably.
  - `web/lib/memba/accounts.ex` now delegates club listing and membership-by-email checks to the public `Memba.Membership` API instead of composing them itself.

- Tests run/results found:
  - Added focused coverage in `web/test/memba/membership/query_test.exs` for:
    - active clubs by normalized member email,
    - excluding inactive/other memberships,
    - blank/nil/unknown email handling,
    - active membership checks by club/email and invalid IDs.
  - Updated `web/test/memba/membership/no_crud_spike_test.exs` to allow the new public query APIs while preserving no-CRUD constraints.
  - I ran `env -u MEMBA_DEVENV_SHELL PATH="$PWD/bin:$PATH" dev check`; it passed:
    - `151 tests, 0 failures`.
  - Working tree remained clean afterward.

- ADR/plan conformance notes:
  - Matches implementation plan task 004: extending `Memba.Membership` query API for active clubs by email and active membership by club/email.
  - Keeps query ownership inside the Membership context, consistent with ADR 0007.
  - Uses normal Phoenix/Ecto/PostgreSQL projection queries, consistent with ADR 0001, ADR 0008, and ADR 0009.
  - No acceptance `.feature` files or `acceptance-tests/` files were changed.
  - The task is a small, independently useful checkpoint with code and test evidence.

{"context_updates":{"task_valid":true,"task_retry_available":false}}