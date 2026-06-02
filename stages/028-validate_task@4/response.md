### Decision
**VALID**

### Evidence
- Completed todo/check-off evidence found:
  - Working tree is clean.
  - Recent commits show `28d1fdb pre_validate_snapshot` on HEAD and recent implement checkpoint `a371f84`.
  - `a371f84` changes exactly one ordinary todo line: task `004` from `- [ ]` to `- [x]`.
  - Parent todo state had tasks `001`–`003` checked and `004` as the first unchecked task.

- Implementation artifacts found:
  - Added constraint migration `web/priv/repo/migrations/20260602025515_add_constraints_to_membership_person_email_addresses.exs` with:
    - non-null constraints for `person_id`, `email`, `normalized_email`;
    - global unique index on `normalized_email`;
    - partial unique index on `person_id WHERE is_primary = true`.
  - Added `Memba.Membership.EmailAddresses` shared validation/normalization for:
    - at least one address;
    - exactly one primary;
    - malformed/blank rejection;
    - trimmed display email;
    - lowercase normalized email;
    - duplicate normalized-address rejection within the submitted set.
  - Updated `Memba.Membership.Person` legacy create validation to use the shared email validator.
  - Added `PersonEmailAddress.changeset/2` normalization, validation, FK, uniqueness, and one-primary constraint handling.
  - Added/updated tests covering validator behavior, projection changesets, non-null constraints, duplicate normalized-email constraint, and one-primary constraint.

- Tests run/results found:
  - Live `git diff --check a371f84^ a371f84` passed.
  - Live `PATH="$PWD/bin:$PATH" dev check` passed with `311 tests, 0 failures`.
  - Working tree remained clean after validation.

- ADR/plan conformance notes:
  - Work matches task `004` and does not prematurely implement command/event replacement, query, Accounts, Messaging, or UI work reserved for later tasks.
  - Plan-required acceptance feature changes were not touched in this task; no `.feature` or `acceptance-tests/` files changed in `a371f84`.
  - Scope is small and independently useful as a Fabro checkpoint.
  - Event-sourced Membership shape and stable `person_id` identity are preserved; email remains mutable data.

{"context_updates":{"task_valid":true,"task_retry_available":false}}