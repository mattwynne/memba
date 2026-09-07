Implemented task 009 and left the exact staged diff passing `dev check`, with no unstaged changes.

1. Selected task

   `009 Adapt MemberDashboardLive and PageHTML.club to render the generic rail, group header, selected state, accessible metadata, and selected-group Conversations / Members panels from assigns.`

2. Changes made

   - Added a generic “Your groups” rail rendered directly from the authorised `@groups` assign.
   - Added opaque-ID LiveView patch links and selected styling based on `@selected_group`, including correct Everyone selection on fallback routes.
   - Added a selected-group header with accessible name, pluralised active-member count, and optional mailto group address.
   - Nested the existing Conversations and Members tabs and panels inside an explicit selected-group content region.
   - Omitted open-to-join, New group, and group-settings controls as required.
   - Added presentation helpers for selected state and member-count labels.
   - No `MemberDashboardLive` source change was necessary: earlier completed tasks already load and refresh the required assigns; the new integration coverage verifies those assigns through the routed LiveView.

   Main implementation: [club.html.heex](/workspace/memba/web/lib/memba_web/controllers/page_html/club.html.heex:11) and [page_html.ex](/workspace/memba/web/lib/memba_web/controllers/page_html.ex:86).

3. Validation

   - Initial focused red run: 35 tests, 2 expected failures for the missing rail/selected-group UI.
   - Focused green run:

     `PATH="$PWD/bin:$PATH" dev test test/memba_web/live/member_dashboard_live_test.exs`

     Result: 35 tests, 0 failures.

   - Formatting checks and `git diff --check` passed.
   - Final `PATH="$PWD/bin:$PATH" dev check` passed on the exact staged diff, including ExUnit and browser acceptance.

   Coverage is in [member_dashboard_live_test.exs](/workspace/memba/web/test/memba_web/live/member_dashboard_live_test.exs:71).

4. Todo check-off

   Changed exactly:

   `- [ ] 009 ...` → `- [x] 009 ...`

   See [todo.md](/workspace/memba/docs/iterations/058-generic-group-scoped-club-home/todo.md:11).

5. Todo structure

   No tasks were split, added, removed, or reordered. Task 010 remains next and retains ownership of the final desktop/mobile layout and navigation/tab accessibility refinement.

6. ADR conformance

   - ADR 0013: added user-visible routed LiveView coverage before implementation.
   - ADR 0015: the member club home remains LiveView-backed.
   - ADR 0019: rail links preserve host-selected club routing without introducing club query parameters.
   - ADR 0023: group selection uses opaque, URL-addressable LiveView patch routes.