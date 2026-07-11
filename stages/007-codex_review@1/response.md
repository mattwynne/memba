# Iteration Review Report

## Decision: ACCEPT

## Confidence: Medium

Confidence is reduced only because the core goal is visual desktop alignment, and the provided evidence is mostly automated DOM/test output rather than full screenshot/manual inspection. From the implementation evidence and successful `dev ci`, the code-health and ADR risk looks low.

## ADR conformance: PASS

The iteration appears presentation-layer focused: Phoenix LiveView templates/components, HEEx structure, Tailwind styling, and LiveView tests for member-app UI alignment.

No cited ADRs or nearby domain/CQRS/event-sourcing concerns appear to be implicated by the provided evidence. The implementation does not appear to change aggregates, commands, projections, event streams, read models, authorization boundaries, or infrastructure choices.

## ADR violations

None identified.

## Blocking issues

None identified.

## Bounded-safe fixes

1. **Extract repeated LiveView test setup helpers**

   **Files:** `member_message_detail_live_test.exs`, possibly related member app LiveView tests.

   The evidence shows repeated setup patterns around creating an active member, creating a message, signing in on a club host, and opening the message detail route. A small private helper such as `open_message_detail(conn, opts)` or `setup_member_message_detail/2` would reduce test noise without changing product behavior.

2. **Name long structural selector assertions**

   **Files:** `member_message_detail_live_test.exs`

   Selectors such as:

   ```elixir
   "#member-message-heading-row.detail-head > .detail-head__main h1#member-message-subject.page-title"
   ```

   are precise, but hard to scan and maintain. Private assertion helpers like `assert_subject_in_detail_head(view, subject)` or `assert_follow_control_in_detail_head(view)` would preserve the same coverage while improving readability.

3. **Review selector naming drift around the back link**

   **Files:** message detail LiveView/template and related tests.

   Evidence shows:

   ```elixir
   a#back-to-club-home-link[href='/conversations']
   ```

   with visible text `"All conversations"`.

   If this DOM id is not used by JS hooks, CSS, browser acceptance helpers, or external tooling, renaming it to something closer to the current behavior, such as `back-to-conversations-link`, would reduce semantic drift. If it is already treated as a stable selector, leaving it as-is is acceptable.

4. **Consider shared compact-footer assertions**

   **Files:** member-app LiveView tests covering message detail, conversations, and club home.

   Several plan requirements concern the compact member-app footer and absence of the public footer. If those assertions are repeated across tests, a shared test helper like `assert_compact_member_footer_only(view)` would make future layout checks easier to maintain.

## Judgement-worthy non-blocking code-health findings

1. **Member-app layout patterns may be spreading across individual screens**

   **Files:** member message detail LiveView/component, club home LiveView/template, conversations LiveView/template.

   **Smell:** The iteration aligns multiple screens around shared concepts: compact app shell, detail header, compact footer, tab/action alignment, and desktop card width.

   **Why it may need human judgement:** This is fine for a focused iteration, but if these patterns continue to spread screen-by-screen, the project may benefit from explicit reusable member-app layout components or documented member-app shell conventions. That decision should be design/product-aware, not forced as part of this merge.

2. **Visual conformance is only partially represented by DOM tests**

   **Files:** LiveView tests for message detail and club home.

   **Smell:** Tests validate important semantic structure and absence/presence of elements, but pixel-level concerns from the plan — spacing, card elevation, desktop width, alignment, footer compactness, and wireframe fidelity — cannot be fully proven by `has_element?/refute has_element?`.

   **Why it may need human judgement:** This is expected for a UI-alignment iteration, but the team may eventually want screenshot regression checks or a clearer human visual-review checklist as a release gate for design-alignment work.

3. **Wireframe-to-implementation mapping is implicit**

   **Files:** changed HEEx/templates/components and related tests.

   **Smell:** The implementation appears to track specific design-system wireframes, but the mapping from wireframe sections to implementation files/classes is not obvious from the code evidence.

   **Why it may need human judgement:** Inline comments or a lightweight design-to-code mapping can help future iterations understand why certain markup/classes exist. However, adding too many comments around visual layout can create maintenance noise, so this should be a team convention decision.

4. **Structural CSS selectors in tests may ossify markup**

   **Files:** `member_message_detail_live_test.exs` and related LiveView tests.

   **Smell:** Some tests assert exact DOM hierarchy and class placement.

   **Why it may need human judgement:** For this iteration, that precision is useful because the goal is desktop layout alignment. Long-term, tests that over-specify structure can make harmless markup refactors expensive. The team may want a convention distinguishing semantic assertions from intentional layout-contract assertions.

## Suggested fixes

Non-blocking, safe follow-ups:

1. Add private test helpers for common member message detail setup.
2. Wrap long selector assertions in clearly named helper functions.
3. Audit the `#back-to-club-home-link` id; rename to match current semantics if it is not externally depended on.
4. Add shared test helpers for recurring member-app layout/footer assertions if duplication continues.

No implementation changes are required before merge.

## Validation notes

- `dev ci` passed.
- Acceptance output shows `109 scenarios`, `109 passed`; `783 steps`, `783 passed`.
- Sandbox/runtime preflight passed.
- The implementation evidence shows targeted LiveView tests for:
  - routed message detail identity via club/message data attributes;
  - back link text and `/conversations` href;
  - absence of stale `club_id` query parameter on the back link;
  - follow control placement beside the subject in the detail head;
  - removal/absence-oriented UI assertions required by the plan.
- No domain, CQRS, event-sourcing, read-model, migration, or integration changes are apparent from the evidence.
- Manual visual validation remains important for the plan’s desktop screenshot goals, especially spacing, card styling, footer treatment, and wireframe fidelity.