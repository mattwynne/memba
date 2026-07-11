# Iteration Review Report

## Decision: ACCEPT

## Confidence: Medium

The implementation appears focused, plan-aligned, and low-risk. Confidence is Medium rather than High because this iteration is primarily visual desktop alignment, and the provided evidence is stronger for DOM structure and regression coverage than for pixel/spacing fidelity. No code-health or ADR issue blocks merge.

## ADR conformance: PASS

## ADR violations

None identified.

The implementation appears limited to Phoenix LiveView/HEEx/Tailwind presentation changes and related LiveView tests. No evidence indicates changes to domain modeling, Commanded aggregates, projections, event streams, CQRS boundaries, persistence infrastructure, or object responsibility boundaries. No accepted ADR decision appears to be bypassed or contradicted.

## Blocking issues

None identified.

## Bounded-safe fixes

1. **Extract repeated message-detail test setup helpers**

   The collected evidence shows repeated setup patterns around:

   - creating an active member;
   - creating a message;
   - signing in on the club host;
   - opening `~p"/messages/#{message.message_id}"`.

   A private helper in `member_message_detail_live_test.exs`, such as `open_message_detail(conn, opts)`, would reduce noise while preserving the same assertions and behavior.

2. **Wrap long structural selectors in named test helpers**

   Some assertions intentionally verify precise layout placement, for example the subject heading inside the detail header:

   ```elixir
   "#member-message-heading-row.detail-head > .detail-head__main h1#member-message-subject.page-title"
   ```

   This is useful coverage for this iteration, but it is hard to scan. Private helpers like `assert_subject_in_detail_head(view, subject)` and `assert_follow_control_in_detail_head(view)` would make the layout contract clearer without weakening the test.

3. **Review stale selector naming for the conversations back link**

   Evidence shows:

   ```elixir
   a#back-to-club-home-link[href='/conversations']
   ```

   with visible text `"All conversations"`.

   If this id is not intentionally stable for tests, CSS, hooks, or external tooling, consider renaming it to something closer to its current meaning, such as `back-to-conversations-link`. If it is already treated as a stable selector, leaving it unchanged is acceptable.

4. **Consider shared assertions for compact member-app footer behavior**

   The compact member-app footer and absence of the public footer are now important layout invariants across several member screens. If similar assertions are duplicated across message detail, conversations, and club home tests, a shared test helper such as `assert_compact_member_footer_only(view)` would improve maintainability.

## Judgement-worthy non-blocking code-health findings

1. **File(s): member message detail LiveView/template/component and related tests**

   **Smell:** Structural DOM selectors are being used as layout contracts.

   **Why it may need human judgement:** For this iteration, exact structural assertions are appropriate because the goal is desktop layout alignment. Longer term, these tests may make harmless markup refactors expensive. The team may want a convention distinguishing semantic UI assertions from intentional layout-contract assertions.

2. **File(s): member message detail, club home, conversations LiveViews/templates**

   **Smell:** Member-app layout patterns appear to be spreading screen-by-screen: compact app shell, compact footer, tab/action alignment, detail header, and contextual action placement.

   **Why it may need human judgement:** This is acceptable for a focused design-alignment iteration, but if the pattern continues to expand, it may be worth extracting shared member-app layout components or documenting member-app shell conventions.

3. **File(s): changed HEEx templates/components and related CSS classes**

   **Smell:** Wireframe-to-implementation mapping is implicit.

   **Why it may need human judgement:** The code appears to directly implement specific design-system wireframes, but future maintainers may not know which markup/classes correspond to which wireframe sections. A lightweight mapping or selective comments could help, though over-commenting visual code can create maintenance noise.

4. **File(s): LiveView tests for member message detail and club home**

   **Smell:** Automated tests cover semantic structure and presence/absence well, but cannot fully prove visual fidelity for spacing, elevation, desktop width, and alignment.

   **Why it may need human judgement:** This is expected for a visual alignment iteration. The team may eventually want screenshot regression checks or an explicit human visual-review gate for design-system alignment work.

## Suggested fixes

No required fixes before merge.

Optional bounded-safe follow-ups:

1. Add private helpers for repeated message-detail LiveView test setup.
2. Wrap long layout selectors in named assertion helpers.
3. Audit and, if safe, rename `#back-to-club-home-link` to match the current `/conversations` destination.
4. Add shared compact-footer assertions if duplication continues across member-app tests.

## Validation notes

- `dev ci` passed successfully.
- Acceptance suite passed:
  - `109 scenarios`
  - `109 passed`
  - `783 steps`
  - `783 passed`
- Sandbox/runtime preflight passed.
- Evidence shows targeted LiveView test coverage for:
  - message detail route identity via club/message data attributes;
  - back link text and `/conversations` href;
  - absence of stale `club_id` query parameter on the back link;
  - follow control placement beside the message subject;
  - page title using normal page-title treatment rather than hero scale;
  - inline `Replying as` composer treatment;
  - absence of removed helper sentence/prominent posted alert;
  - absence of the `Prefer email?` card;
  - compact member-app footer behavior.
- No evidence of out-of-scope domain, persistence, routing architecture, CQRS, event-sourcing, or infrastructure changes.
- Manual desktop visual validation remains important for final product/design confidence, especially spacing, card treatment, footer compactness, and wireframe fidelity.