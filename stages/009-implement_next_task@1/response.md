1. **Selected todo line**
   - `001 Add a member-scoped route live "/messages/:message_id/delivery", MemberMessageDeliveryLive.Show in web/lib/memba_web/router.ex, in the same authenticated member scope as the message Show route.`

2. **Changes made**
   - Added the member delivery LiveView route in `web/lib/memba_web/router.ex` inside the existing authenticated club-member `live_session`, next to the existing message show route:
     - `/messages/:message_id/delivery` → `MembaWeb.MemberMessageDeliveryLive.Show`
   - Added a router test in `web/test/memba_web/router_test.exs` proving:
     - the route exists;
     - it is under `[:browser, :club_member_required]`;
     - it targets `MembaWeb.MemberMessageDeliveryLive.Show`;
     - it captures `message_id`.

3. **Validation run**
   - TDD failing check:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/router_test.exs`
     - Failed as expected before the route existed: route returned `:error`.
   - Focused passing check:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/router_test.exs`
     - Passed: `14 tests, 0 failures`.
   - Full required route/UI validation:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed, including acceptance run: `85 scenarios (85 passed)`, `523 steps (523 passed)`.
   - Final whitespace check:
     - `git diff --check`
     - Passed.

4. **Todo check-off made**
   - Changed exactly this line:
     - `- [ ] 001 Add a member-scoped route ...`
   - To:
     - `- [x] 001 Add a member-scoped route ...`

5. **Todo splits/additions/reordering**
   - None. I implemented only the first unchecked task and left all later tasks unchecked.

6. **ADR conformance evidence**
   - No ADRs were explicitly referenced by the plan.
   - I inspected relevant accepted ADRs:
     - ADR 0001: Phoenix is the core application stack.
     - ADR 0015: member application pages should use LiveView by default.
     - ADR 0023: visible member app state should be URL-addressable where practical.
   - The change conforms by adding a Phoenix LiveView route for the member-facing delivery details surface under the existing authenticated member routing/session structure.