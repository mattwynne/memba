### Decision
**VALID**

### Evidence
- **Completed todo/check-off evidence found.**
  - Read `/tmp/fabro-pre-validate-snapshot.md`; it recorded a clean working tree at implement checkpoint `bbc3696`.
  - Live `git status --short` and `git diff` are clean.
  - Recent log shows `471a10a pre_validate_snapshot` on top of `bbc3696 implement_next_task`.
  - `git diff bbc3696^ bbc3696 -- docs/iterations/016-person-email-addresses/todo.md` shows exactly one ordinary task line changed:
    - `015` from `- [ ]` to `- [x]`.
  - Parent todo state shows `015` was the first unchecked task before the implement checkpoint.

- **Implementation artifacts found.**
  - Added `web/lib/memba_web/live/admin/person_email_address_form.ex` with repeated email-row normalization, add/remove row state, primary radio handling, name/email validation, duplicate detection, and server-error mapping.
  - Updated `web/lib/memba_web/live/admin/people_live/new.ex` with repeated email rows, one primary radio, first row primary by default, add/remove controls, validation, and create submission using `Membership.create_person/2`.
  - Updated `web/lib/memba_web/live/admin/people_live/edit.ex` with existing email rows, primary selection, add/remove controls, validation, and save submission using `Membership.replace_person_email_addresses/2`.
  - Updated `web/test/memba_web/live/admin_people_live_test.exs` to cover new/edit rendering, create with primary+alternate addresses, malformed/no-primary/multiple-primary/duplicate validation, and replacing primary selection.
  - No acceptance feature files or `acceptance-tests/` files were changed in the implement checkpoint.

- **Tests run/results found.**
  - `git diff --check bbc3696^ bbc3696` passed.
  - Ran `PATH="$PWD/bin:$PATH" dev check`.
    - Initial validation attempts were blocked by a stale zombie repo-managed Postgres PID/lock, not by code failures.
    - After clearing the stale zombie lock/socket, `dev check` passed:
      - `343 tests, 0 failures`.
  - Working tree remained clean after validation.

- **ADR/plan conformance notes.**
  - Matches implementation plan task `015`.
  - Preserves plan-required atomic replace-all Membership workflow.
  - Uses Phoenix LiveView staff UI surfaces and Membership public APIs; no cross-context persistence reach-through found.
  - Uses generated UUID person IDs for creation, not email as identity.
  - Adds focused web-facing tests consistent with the project’s testing expectations.
  - Task is small and independently checkpointed with a clear Fabro diff trail.

{"context_updates":{"task_valid":true,"task_retry_available":false}}