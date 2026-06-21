### Decision
**VALID**

### Evidence
- Completed todo/check-off evidence found:
  - Live working tree has no ordinary diff; only untracked `.fabro/tmp/`.
  - Recent implement checkpoint `7087553` changed exactly one ordinary todo line:
    - `- [ ] 004 Accept only local_part == "everyone" for now.`
    - to `- [x] 004 Accept only local_part == "everyone" for now.`
  - The parent of `7087553` shows task `004` was the first unchecked task.

- Implementation artifacts found:
  - `web/lib/memba/messaging/inbound_club_destination.ex` now requires the subdomain-route local part to be normalized exactly as `"everyone"` before accepting a club candidate.
  - Unsupported local parts at club subdomains now fall through to the existing unsupported-recipient candidate path.
  - Resolver docs were updated to describe the supported `everyone` local part.
  - `web/test/memba/messaging/inbound_club_destination_test.exs` adds coverage rejecting `committee@kmc.clubs.memba.io`.
  - No `*.feature` files were edited in the implement checkpoint.

- Tests run/results found:
  - Implementor reported focused formatting, focused resolver tests, and `git diff --check` passing.
  - I reran the focused test:
    - `PATH="$PWD/bin:$PATH" devenv shell -- bash -lc 'cd web && mix test test/memba/messaging/inbound_club_destination_test.exs'`
    - Result: `7 tests, 0 failures`.
  - `git diff --check` is clean.

- ADR/plan conformance notes:
  - The task is the planned next slice and is small enough to stand independently.
  - It preserves the configured inbound namespace and the new `everyone@<club>.<namespace>` shape.
  - It continues to resolve actual clubs through `Membership.get_club_by_slug/1`, preserving the Membership boundary.
  - It does not change provider-specific parser boundaries.
  - Deferring hard rejection of the old flat address remains consistent with unchecked task `006`.

{"context_updates":{"task_valid":true,"task_retry_available":false}}