Implemented the next unchecked iteration task.

1. **Selected todo line**
   - `- [ ] 007 Keep custom-group behaviour unavailable through the public UI/API in this slice.`

2. **Changes made**
   - Clarified the three group command module docs as internal foundation commands, not public custom-group APIs:
     - `web/lib/memba/membership/commands/create_group.ex`
     - `web/lib/memba/membership/commands/add_group_member.ex`
     - `web/lib/memba/membership/commands/remove_group_member.ex`
   - Added a Membership public API regression test proving no custom/group mutation functions are exported from `Memba.Membership`.
   - Added a router regression test proving representative custom-group UI/API paths are not routed.

3. **Focused validation**
   - Ran:
     - `PATH="$PWD/bin:$PATH" dev test test/memba/membership/public_api_test.exs test/memba_web/router_test.exs`
     - Result: `46 tests, 0 failures`
   - Ran:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Result: command exited `0`; output still includes the same unrelated/pre-existing 2 `MembaWeb.PageControllerTest` public-footer failures noted by prior checkpoints.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 007 Keep custom-group behaviour unavailable through the public UI/API in this slice.`
   - To:
     - `- [x] 007 Keep custom-group behaviour unavailable through the public UI/API in this slice.`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - ADR 0007: preserves the Membership bounded-context public boundary by keeping group mutation details behind internal commands and confirming external callers have no `Memba.Membership` custom-group API or web route access in this slice.