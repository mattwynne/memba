Implemented task 008 and left it unchecked for independent review.

1. Selected task

   `- [ ] 008 Use explicit component attributes/slots, not a copied full-page template.`

2. Changes made

   - Added required `:candidate_action` and `:add_self_action` slots to the custom-group components in [member_components.ex](/workspace/memba/web/lib/memba_web/components/member_components.ex:237).
   - Moved candidate-add and admin self-add controls into caller-owned slots in [club.html.heex](/workspace/memba/web/lib/memba_web/controllers/page_html/club.html.heex:289). The shared components retain presentation while the dashboard remains responsible for workflow actions.
   - Added component tests proving that caller-supplied actions receive candidate data and render inside the appropriate shared UI.
   - Did not implement submission or membership mutations belonging to task 009.
   - No acceptance feature files were changed.

3. Validation

   - TDD red phase: component suite initially failed both new slot assertions.
   - Focused component test: 11 tests, 0 failures.
   - Component, LiveView, and member UI contract suite: 65 tests, 0 failures.
   - Targeted browser scenario, `Bob has Members but no Conversations while outside Board`: 1 scenario, 7 steps, all passed.
   - `mix format --check-formatted` on all touched files: passed.
   - `git diff --check`: passed.
   - `dev check --quick`: 1,430 tests, 0 failures.
   - Full `dev check` remains owned by task 016.

4. Task remains unchecked

   `- [ ] 008 Use explicit component attributes/slots, not a copied full-page template.`

5. Todo changes

   None. No tasks were split, reordered, added, or checked off.

6. ADR conformance

   - ADR 0013: component behavior is covered by focused user-interface tests and a targeted browser scenario.
   - ADR 0015: the member dashboard remains LiveView-owned; stateless components only render explicit attributes and caller-supplied actions.
   - ADR 0023: no URL-addressable state or navigation behavior changed.
   - ADRs 0021 and 0024: no projection, authorization, aggregate, or read-model behavior changed.