1. **Selected todo line**
   - `- [ ] 002 Add the typed Group ID and the Group command/event modules using the project’s existing ID and event conventions.`

2. **Changes made**
   - Added `:group` to `Memba.ID` with the `grp_` typed ID prefix.
   - Added Membership group command structs:
     - `Memba.Membership.Commands.CreateGroup`
     - `Memba.Membership.Commands.AddGroupMember`
     - `Memba.Membership.Commands.RemoveGroupMember`
   - Added Membership group event structs with `Jason.Encoder` derivation:
     - `Memba.Membership.Events.GroupCreated`
     - `Memba.Membership.Events.GroupMemberAdded`
     - `Memba.Membership.Events.GroupMemberRemoved`
   - Added focused tests in:
     - `web/test/memba/membership/group_command_event_modules_test.exs`
   - Updated only the selected task line in `todo.md`.

3. **Focused validation**
   - Passed:
     - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/group_command_event_modules_test.exs`
     - Result: `4 tests, 0 failures`
   - Ran broad quick gate:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
     - ExUnit reported `1025 tests, 2 failures`, both in `MembaWeb.PageControllerTest` footer assertions expecting `"Red Donkey Technology Corp"`.
     - I also reran those specific footer tests and reproduced the same 2 failures.
     - I did not change footer/page code or tests because those failures are unrelated to the selected task and the ownership rules say not to fix unrelated issues.
     - Therefore I cannot truthfully report `dev check --quick` as cleanly passing, despite the wrapper returning exit code 0.

4. **Exact todo check-off made**
   - Changed:
     - `- [ ] 002 Add the typed Group ID and the Group command/event modules using the project’s existing ID and event conventions.`
   - To:
     - `- [x] 002 Add the typed Group ID and the Group command/event modules using the project’s existing ID and event conventions.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - Read and followed ADR 0007: group command/event modules live entirely in the Membership context; no Messaging storage/API coupling was introduced.
   - Read and followed ADR 0011: group identities are caller-generated or deterministic through `Memba.ID`, not generated inside aggregates.
   - Followed event-sourcing/CQRS guidance: events are past-tense domain facts and JSON encodable; commands express intent and carry explicit identities.