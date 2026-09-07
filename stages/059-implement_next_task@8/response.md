Implemented and checked off task 008. Selected-group context now survives dashboard tabs, conversation links, delivery navigation, and invitation round trips. The exact staged state passes `dev check`.

1. Selected task

   `008 Ensure tabs, message links, invitation affordances, and return navigation preserve the selected group where applicable.`

2. Changes made

   - Group-scoped Conversations and Members tabs now remain on `/groups/:group_id` routes when patched.
   - Conversation rows carry the selected group into message detail through `?group_id=...`.
   - Message detail returns to the selected group and carries group context into delivery-detail links.
   - Delivery detail returns to the containing conversation with the group context intact.
   - The member-invitation affordance carries the group context; its Club home and Cancel links return to that selected group.
   - Existing Everyone routes remain unchanged when there is no explicit group route.
   - Compose audience behavior was left for tasks 013–015.

   Main implementation: [page_html.ex](/workspace/memba/web/lib/memba_web/controllers/page_html.ex:13), [club.html.heex](/workspace/memba/web/lib/memba_web/controllers/page_html/club.html.heex:1), [message.html.heex](/workspace/memba/web/lib/memba_web/controllers/page_html/message.html.heex:15), [invitation new.ex](/workspace/memba/web/lib/memba_web/live/member_invitation_live/new.ex:352), and [delivery show.ex](/workspace/memba/web/lib/memba_web/live/member_message_delivery_live/show.ex:65).

3. Validation

   - Initial focused red run: 62 tests, 5 expected failures covering the missing navigation continuity.
   - Focused green run:

     `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_dashboard_live_test.exs test/memba_web/live/member_message_live/show_test.exs test/memba_web/live/member_message_delivery_live/show_test.exs test/memba_web/live/member_invitation_live/new_test.exs`

     Result: 62 tests, 0 failures.

   - Final `PATH="$PWD/bin:$PATH" dev check` passed on the exact staged diff, including ExUnit and browser acceptance.
   - `git diff --cached --check` passed, with no unstaged changes.

   Coverage was added in [member_dashboard_live_test.exs](/workspace/memba/web/test/memba_web/live/member_dashboard_live_test.exs:134), [message show_test.exs](/workspace/memba/web/test/memba_web/live/member_message_live/show_test.exs:155), [delivery show_test.exs](/workspace/memba/web/test/memba_web/live/member_message_delivery_live/show_test.exs:345), and [invitation new_test.exs](/workspace/memba/web/test/memba_web/live/member_invitation_live/new_test.exs:115).

4. Todo check-off

   Changed exactly:

   `- [ ] 008 ...` → `- [x] 008 ...`

   See [todo.md](/workspace/memba/docs/iterations/058-generic-group-scoped-club-home/todo.md:10).

5. Todo structure

   No tasks were split, added, removed, or reordered. Task 009 remains the next unchecked task.

6. ADR conformance

   The plan names no explicit ADRs. The implementation conforms to the relevant accepted decisions:

   - ADR 0013: behavior is covered through user-visible LiveView tests.
   - ADR 0015: all member application surfaces remain LiveViews.
   - ADR 0019: club identity remains host-selected; no `club_id` query navigation was introduced.
   - ADR 0023: group-scoped tabs remain URL-addressable LiveView patch transitions.