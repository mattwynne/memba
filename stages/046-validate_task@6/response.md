### Decision
**VALID**

### Evidence
- Completed todo/check-off evidence found.
  - Read `/tmp/fabro-pre-validate-snapshot.md`; snapshot shows implementation checkpoint `a0a9f61` with clean working tree.
  - Live `git status --short` and `git diff` are clean.
  - `git log --oneline -5` shows recent implementation commit `a0a9f61 fabro(...): implement_next_task (succeeded)`.
  - `git show a0a9f61 -- docs/iterations/053-my-settings-email-addresses/todo.md` shows exactly one ordinary task line changed:
    - `007 Existing verified addresses for the same Person keep their verified state when staff edit the set; removed addresses lose any outstanding verification tokens.`
    - from `- [ ]` to `- [x]`.
  - Current `todo.md` has task `007` checked and `008` as the first unchecked task.

- Implementation artifacts found.
  - `web/lib/memba/membership.ex` updates:
    - `replace_person_email_addresses/2` now extracts a `:verification_revoker`, computes pending email verification requests removed by staff replacement, dispatches the replacement command, then invokes revocation for removed pending addresses.
    - `remove_person_email_address/2` applies the same revocation path for direct pending-address removal.
    - Added helpers for pending removed verification requests, revoker option handling, default no-op revoker, and accepted revoker return values.
  - `web/test/memba/membership/public_api_test.exs` adds a focused test proving replacement preserves a verified alternate address, removes a pending address, and calls the revoker with the removed pending address scope.
  - No acceptance feature files were changed in the implementation commit.

- Tests run/results found.
  - Live focused validation run passed:
    - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/public_api_test.exs:455`
    - Result: `23 tests, 0 failures, 22 excluded`.
  - Working tree remained clean after the validation test.
  - The implementation summary also reports focused Membership tests, `dev check --quick`, and full `dev check` passing.

- ADR/plan conformance notes.
  - Work stays inside the Membership context and does not introduce an Account aggregate or separate bounded context, matching the iteration plan.
  - The change preserves CQRS/event-sourced boundaries: staff replacement/removal still dispatch Membership commands/events, while revocation is application-service side-effect plumbing around successful dispatch.
  - ADR 0002/0007 constraints are respected: Membership owns Person/email-address behaviour; no Messaging mutation or cross-context ownership leak was introduced.
  - ADR 0021 is not violated; this slice does not add read-model notification behaviour.
  - Todo changes did not delete, weaken, reorder, or silently defer plan-required work.
  - The task is a small independent checkpoint with code and test evidence.

{"context_updates":{"task_valid":true,"task_retry_available":false}}