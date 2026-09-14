Implemented the first unchecked task and left it ready for independent review.

1. Selected task

`- [ ] 014 Add the new-group LiveView/form using shared inputs and route helpers.`

2. Changes made

- Added the admin-only new-group LiveView in [new.ex](/workspace/memba/web/lib/memba_web/live/member_group_live/new.ex:1).
  - Resolves the club from the canonical club-site context.
  - Requires an active member with club-management authority.
  - Renders the reviewed name-only form using `to_form/2`, `<.form>`, `<.input>`, `<.button>`, and `<.icon>`.
  - Includes the neutral email-preview region and no client-supplied club, actor, or slug fields.
  - Uses verified routes and `ClubSite.url/2` for navigation.
- Registered `/groups/new` before the dynamic `/groups/:group_id` route in [router.ex](/workspace/memba/web/lib/memba_web/router.ex:69).
- Added the admin-only “New group” rail action in [club.html.heex](/workspace/memba/web/lib/memba_web/controllers/page_html/club.html.heex:76).
- Added host-aware new-group route generation in [page_html.ex](/workspace/memba/web/lib/memba_web/controllers/page_html.ex:198).
- Added the reviewed divider and add-action styles in [app.css](/workspace/memba/web/assets/css/app.css:138).
- Added focused browser-style PhoenixTest/LiveView coverage in [new_test.exs](/workspace/memba/web/test/memba_web/live/member_group_live/new_test.exs:1), proving:
  - an authorized admin can navigate from the group rail to the form;
  - the exact route wins over `/groups/:group_id`;
  - ordinary members cannot see or directly open it;
  - signed-out visitors retain the club-site return URL;
  - the form accepts only the group name.

Live validation, submission, and success/error states remain for tasks 015 and 016.

3. Focused validation

- TDD red run: 4 tests, 3 expected failures for the missing link, route, and surface.
- New-group focused suite: 4 tests, 0 failures.
- New-group, member-dashboard, router, and CSS regression set: 76 tests, 0 failures.
- `mix format --check-formatted` on all changed Elixir/HEEx files: passed.
- `git diff --check`: passed.

Per the per-task workflow, full `dev check` was not run in this node.

4. Todo state

The exact selected line remains unchanged and unchecked in [todo.md](/workspace/memba/docs/iterations/062-create-custom-groups/todo.md:16):

`- [ ] 014 Add the new-group LiveView/form using shared inputs and route helpers.`

5. Todo changes

None. No tasks were split, added, reordered, or checked off.

6. ADR conformance

- ADR 0001 and ADR 0015: the authenticated member surface is implemented as Phoenix LiveView.
- ADR 0013: user-facing navigation and form behavior were test-driven through the PhoenixTest-style browser journey, with lower-level LiveView coverage for authorization.
- ADR 0019: canonical club-subdomain context is preserved; route helpers support the established `ClubSite.url/2` fallback.
- ADR 0023: the new surface has a dedicated `/groups/new` URL and uses LiveView navigation.
- ADR 0024: this presentation layer only gates access for the UI; it does not move authoritative creation or identity decisions out of the existing Club consistency boundary.