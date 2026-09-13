Implemented task 006 and checked off only that task.

1. Selected todo

   `006 Extend the existing stateless tabs/frame/list composition in page_html/club.html.heex and member_dashboard_group_tabs.ex.`

2. Changes made

   - [club.html.heex](/workspace/memba/web/lib/memba_web/controllers/page_html/club.html.heex:1) now renders the reviewed access-specific compositions:
     - Participating members get Conversations and Members.
     - Ordinary non-members get group identity, privacy guidance, and the club Admin email address, with no tabs or private panels.
     - Outside admins get a Members-only surface and explanatory notice, with no conversation panel or compose action.
   - The group rail is partitioned into “Your groups” and “Other groups”; non-participating groups have a lock marker.
   - [member_dashboard_group_tabs.ex](/workspace/memba/web/lib/memba_web/components/member_dashboard_group_tabs.ex:11) supports a stateless Members-only configuration.
   - [member_dashboard_presentation.ex](/workspace/memba/web/lib/memba_web/member_dashboard_presentation.ex:80) annotates the web presentation’s discovery summaries with current-user participation, based on the existing public participation query.
   - [app.css](/workspace/memba/web/assets/css/app.css:120) adds the reviewed rail, access-guidance, outside-admin, and responsive styles.
   - Added focused component and routed LiveView regressions. No acceptance feature files were changed.

3. Validation

   - TDD red run: 47 tests, 3 expected behavioral failures.
   - Focused component, presentation, LiveView, UI-contract, and design-alignment suite: 64 tests, 0 failures.
   - Targeted browser scenario:
     `dev acceptance --name "An Admin member views Admin conversations and members"`
     — 1 scenario, 10 steps, all passed.
   - `dev check --quick` exited successfully: 1,265 tests, 0 failures.
   - Focused `mix format --check-formatted`: passed.
   - `git diff --check`: passed.
   - Full browser-inclusive `dev check` remains explicitly assigned to final task 011.

4. Todo check-off

   [todo.md](/workspace/memba/docs/iterations/061-discover-club-groups/todo.md:8) now contains:

   ```markdown
   - [x] 006 Extend the existing stateless tabs/frame/list composition in `page_html/club.html.heex` and `member_dashboard_group_tabs.ex`.
   ```

5. Todo structure

   No tasks were split, added, removed, or reordered. Task 007 remains the first unchecked task.

6. ADR conformance

   - ADR 0007/0009: the web presentation continues to use public Membership APIs; no projection schemas or web-layer joins were introduced.
   - ADR 0013: user-visible behavior is covered through routed Phoenix/LiveView tests plus targeted browser evidence.
   - ADR 0015: the member dashboard remains a LiveView-coordinated application surface using stateless Phoenix components.
   - ADR 0023: existing LiveView patch links and URL-addressable group/section state remain intact; no client-only application state was introduced.