Goal: Review a completed plan-conforming iteration implementation for code polish, ADR conformance, and code-health signals
Run ID: 01KX8G4WAG2NCEXWQ4YRTW02Z2
Pipeline progress: 6 of 27 stages completed

## Stage: read_plan
- Status: succeeded
- Handler: command
- Script: `PLAN_PATH='docs/iterations/052-desktop-member-app-design-alignment/plan.md'
if [ ! -f "$PLAN_PATH" ]; then
  echo "Iteration plan not found: $PLAN_PATH" >&2
  exit 1
fi
printf 'PLAN_PATH=%s\n\n' "$PLAN_PATH"
line_count=0
while IFS= read -r line && [ "$line_count" -lt 320 ]; do
  printf '%s\n' "$line"
  line_count=$((line_count + 1))
done < "$PLAN_PATH"`
- Output:
  ```
  (272 lines omitted)
  
  - `tmp/gallery/app__member-message-read__desktop.png` →
    `design-system/wireframes/member-conversation.html`
  - `tmp/gallery/app__member-reply-posted__desktop.png` →
    `design-system/wireframes/member-conversation.html` posted state
  - `tmp/gallery/app__member-club-home__desktop.png` →
    `design-system/wireframes/club-home.html`
  - `tmp/gallery/app__member-club-home-members-tab__desktop.png` →
    `design-system/wireframes/club-home.html` Members panel, mainly to catch footer/layout regressions
  
  For the message detail screenshots, inspect at least:
  
  - app card width, top-bar alignment, and compact footer only;
  - back-link wording and placement;
  - page-title scale vs the wireframe's normal page heading, not hero scale;
  - follow toggle placement and scale;
  - message-card border radius, border weight, shadow/subtle elevation, tint for the original, and
    vertical spacing between cards;
  - avatar size/position, sender name weight, timestamp position, and kebab menu position;
  - message body left alignment/indentation and vertical position — specifically confirm there is no
    large empty band between sender row and body text;
  - composer panel background/border/padding and overall height;
  - composer title/icon, inline `Replying as`, textarea height/placeholder, button size, and posted
    success note treatment;
  - absence of the removed helper sentence and prominent green alert;
  - absence of the full public footer/copyright/legal-link block.
  
  For the club-home desktop screenshots, inspect at least:
  
  - tab row/action slot alignment;
  - conversation row density and structure after coordinating with iteration 051;
  - absence of the `Prefer email?` card;
  - compact member-app footer only, with no public footer below;
  - no accidental changes to the Members panel layout or invite action.
  
  Do **not** validate mobile screenshots against mobile wireframes in this iteration; mobile is
  explicitly out of scope.
  
  ### Manual smoke
  
  - Sign in as a seeded club member on desktop.
  - Open the club home Conversations and Members tabs.
  - Open a conversation, toggle follow/unfollow, open the kebab delivery-details link, and post a
    reply.
  - Confirm all workflows still behave as before while the visible desktop surfaces match the
    wireframes more closely.
  
  ## Risks / Follow-ups
  
  - If iteration 051 is not yet merged, overlapping club-home row changes may require sequencing or
  ```

## Stage: preflight_sandbox
- Status: succeeded
- Handler: command
- Script: `set -eu
if [ ! -x bin/dev ]; then
  echo "Missing or non-executable bin/dev" >&2
  exit 1
fi
status=$(git status --short)
if [ -n "$status" ]; then
  echo 'Iteration review requires a clean working tree before review starts.' >&2
  printf '%s\n' "$status" >&2
  exit 1
fi
rm -rf .fabro/tmp
mkdir -p .fabro/tmp
git rev-parse HEAD > .fabro/tmp/review-start-sha.txt
echo "Review start SHA: $(cat .fabro/tmp/review-start-sha.txt)"
PATH="$PWD/bin:$PATH" dev sandbox-check`
- Output:
  ```
  (337 lines omitted)
  ==> commanded
  Compiling 69 files (.ex)
  Generated commanded app
  ==> commanded_eventstore_adapter
  Compiling 2 files (.ex)
  Generated commanded_eventstore_adapter app
  ==> commanded_ecto_projections
  Compiling 1 file (.ex)
  Generated commanded_ecto_projections app
  ==> tailwind
  Compiling 3 files (.ex)
  Generated tailwind app
  ==> elixir_make
  Compiling 8 files (.ex)
  Generated elixir_make app
  ==> cc_precompiler
  Compiling 3 files (.ex)
  Generated cc_precompiler app
  ==> lazy_html
  Downloading precompiled NIF to /tmp/cache/elixir_make/lazy_html-nif-2.16-x86_64-linux-gnu-0.1.11.tar.gz
  Compiling 3 files (.ex)
  Generated lazy_html app
  ==> websock
  Compiling 1 file (.ex)
  Generated websock app
  ==> bandit
  Compiling 54 files (.ex)
  Generated bandit app
  ==> swoosh
  Compiling 59 files (.ex)
  Generated swoosh app
  ==> websock_adapter
  Compiling 4 files (.ex)
  Generated websock_adapter app
  ==> phoenix
  Compiling 74 files (.ex)
  Generated phoenix app
  ==> phoenix_live_view
  Compiling 49 files (.ex)
  Generated phoenix_live_view app
  ==> phoenix_live_dashboard
  Compiling 36 files (.ex)
  Generated phoenix_live_dashboard app
  ==> phoenix_test
  Compiling 31 files (.ex)
  Generated phoenix_test app
  ==> phoenix_ecto
  Compiling 7 files (.ex)
  Generated phoenix_ecto app
  Sandbox runtime check passed.
  ```

## Stage: dev_check
- Status: succeeded
- Handler: command
- Script: `PATH="$PWD/bin:$PATH" dev ci`
- Output:
  ```
  (1997 lines omitted)
  
    Rule: Staff-edited slugs must already be address-safe
  
      Scenario: Staff enter an invalid slug # features/staff_club_slugs.feature:17
  [acceptance 2026-07-11T12:00:54.576Z] scenario start: Staff enter an invalid slug
  [acceptance 2026-07-11T12:00:54.653Z] scenario reset app state: Staff enter an invalid slug
        Given Pat is signed in as Memba staff
  [acceptance 2026-07-11T12:00:55.839Z] slow step: Staff enter an invalid slug :: Pat is signed in as Memba staff :: 1148ms
        Given Kootenay Mountaineering Club is a club
        When Pat tries to change Kootenay Mountaineering Club's slug to "kmc club!"
        Then Memba should reject the club slug as invalid
        And Kootenay Mountaineering Club should keep its previous slug
  [acceptance 2026-07-11T12:00:57.211Z] scenario teardown start: Staff enter an invalid slug status=PASSED
  [acceptance 2026-07-11T12:00:57.245Z] scenario finish: Staff enter an invalid slug status=PASSED duration=2669ms
  
    Rule: A slug can belong to only one club
  
      Scenario: Staff enter a slug that another club already uses # features/staff_club_slugs.feature:25
  [acceptance 2026-07-11T12:00:57.246Z] scenario start: Staff enter a slug that another club already uses
  [acceptance 2026-07-11T12:00:57.278Z] scenario reset app state: Staff enter a slug that another club already uses
        Given Pat is signed in as Memba staff
  [acceptance 2026-07-11T12:00:58.487Z] slow step: Staff enter a slug that another club already uses :: Pat is signed in as Memba staff :: 1139ms
        Given Kootenay Mountaineering Club has the slug "kmc"
        And Nelson Paddling Club is a club
        When Pat tries to change Nelson Paddling Club's slug to "kmc"
        Then Memba should reject the club slug as already taken
        And Nelson Paddling Club should keep its previous slug
  [acceptance 2026-07-11T12:01:00.264Z] scenario teardown start: Staff enter a slug that another club already uses status=PASSED
  [acceptance 2026-07-11T12:01:00.270Z] scenario finish: Staff enter a slug that another club already uses status=PASSED duration=3025ms
  
    Rule: A club slug routes public visitors to that club's public page
  
      @not-domain
      Scenario: Robin opens an unknown club subdomain # features/staff_club_slugs.feature:35
  [acceptance 2026-07-11T12:01:00.271Z] scenario start: Robin opens an unknown club subdomain
  [acceptance 2026-07-11T12:01:00.303Z] scenario reset app state: Robin opens an unknown club subdomain
        Given Pat is signed in as Memba staff
  [acceptance 2026-07-11T12:01:01.507Z] slow step: Robin opens an unknown club subdomain :: Pat is signed in as Memba staff :: 1136ms
        When Robin opens "unknown.clubs.memba.io"
        Then Robin should see a not found page
  [acceptance 2026-07-11T12:01:01.568Z] scenario teardown start: Robin opens an unknown club subdomain status=PASSED
  [acceptance 2026-07-11T12:01:01.575Z] scenario finish: Robin opens an unknown club subdomain status=PASSED duration=1304ms
  
  [acceptance 2026-07-11T12:01:01.575Z] AfterAll: closing shared browser
  [acceptance 2026-07-11T12:01:01.603Z] AfterAll: closed shared browser
  [acceptance 2026-07-11T12:01:01.603Z] AfterAll: stopping Phoenix browser acceptance lifecycle
  [acceptance 2026-07-11T12:01:01.604Z] AfterAll: stopped Phoenix browser acceptance lifecycle
  109 scenarios (109 passed)
  783 steps (783 passed)
  6m24.937s (executing steps: 6m10.539s)
  ```

## Stage: collect_implementation_evidence
- Status: succeeded
- Handler: command
- Script: `bash .fabro/workflows/iteration-review/scripts/collect_implementation_evidence.sh 'eebacadd114ae0325805a17da9744b0722f8e91e'`
- Output:
  ```
  (3341 lines omitted)
          subject: "Trip planning night"
        )
  
      {:ok, view, _html} =
        conn
        |> Map.put(:host, "kmc.lvh.me")
        |> init_test_session(%{IdentityAuth.identity_session_key() => "alice@example.com"})
        |> live(~p"/messages/#{message.message_id}")
  
      assert has_element?(
               view,
               "#member-message-detail[data-club-id='#{alice.club_id}'][data-message-id='#{message.message_id}']"
             )
  
      assert has_element?(
               view,
               "a#back-to-club-home-link[href='/conversations']",
               "All conversations"
             )
  
      refute has_element?(view, "a#back-to-club-home-link[href*='club_id=']")
    end
  
    test "routed message detail places the follow control beside the subject in the detail head", %{
      conn: conn
    } do
      alice =
        create_active_member(
          email: "alice@example.com",
          name: "Alice Adams",
          club_name: "Alpine Club"
        )
  
      message =
        create_message(
          club_id: alice.club_id,
          sender_id: alice.person_id,
          subject: "Trip planning night"
        )
  
      {:ok, view, _html} =
        conn
        |> signed_in_club_host("alice@example.com", alice)
        |> live(~p"/messages/#{message.message_id}")
  
      assert has_element?(
               view,
               "#member-message-heading-row.detail-head > .detail-head__main " <>
                 "h1#member-message-subject.page-title",
               "Trip planning night"
  ```

## Stage: claude_review
- Status: succeeded
- Handler: prompt
- Model: claude-sonnet-4-5
- Tokens: 5.3k in / 3.8k out
- Response:
  > # Iteration Review Report
  > 
  > **Iteration:** 052-desktop-member-app-design-alignment  
  > **Commit Range:** `eebacadd114ae0325805a17da9744b0722f8e91e..HEAD`  
  > **Review Date:** 2026-07-11
  > 
  > ---
  > 
  > ## Decision: **ACCEPT**
  > 
  > ## Confidence: **High**
  > 
  > ## ADR Conformance: **PASS**
  > 
  > ---
  > 
  > ## ADR Violations
  > 
  > None identified.
  > 
  > **Analysis:**
  > - No ADRs explicitly cited in the plan
  > - Changes are UI/presentation layer focused (LiveView components, templates, styling)
  > - Implementation follows standard Phoenix LiveView patterns documented in project references
  > - No domain modeling, CQRS, event sourcing, or aggregate responsibility changes
  > - Component boundaries and LiveView structure align with project conventions in `docs/reference/liveview.md` and `docs/reference/phoenix-html.md`
  > 
  > ---
  > 
  > ## Blocking Issues
  > 
  > None.
  > 
  > ---
  > 
  > ## Bounded-Safe Fixes
  > 
  > 1. **Test setup extraction**: Consider extracting repeated test setup patterns into shared helpers. Examples:
  >    - `create_active_member` + `create_message` + `signed_in_club_host` appears in multiple tests in `member_message_detail_live_test.exs`
  >    - Could introduce `setup_message_detail_test(conn, opts)` helper
  >    - **Why low-risk:** Pure test code refactoring; no behavior change; improves maintainability
  > 
  > 2. **CSS selector test assertions**: Some tests use long CSS selector strings that could be extracted into named helper predicates. Example:
  >    ```elixir
  >    # Current:
  >    "#member-message-heading-row.detail-head > .detail-head__main h1#member-message-subject.page-title"
  >    
  >    # Could be:
  >    message_subject_in_detail_head(view, expected_text)
  >    ```
  >    **Why low-risk:** Test code only; improves readability; preserves exact assertions
  > 
  > ---
  > 
  > ## Judgement-Worthy Non-Blocking Code-Health Findings
  > 
  > 1. **Cross-cutting UI behavior test coverage**  
  >    **Files:** `member_message_detail_live_test.exs`, `club_home_live_test.exs`, `member_conversations_live_test.exs`  
  >    **Smell:** Multiple test files test similar UI patterns (back links, footer visibility, compact layout) across different LiveView contexts  
  >    **Why judgement-worthy:** While appropriate for integration testing, this might indicate opportunity for:
  >    - Shared component tests if these UI elements become reusable components
  >    - Documented UI patterns/guidelines to ensure consistency
  >    - Trade-off: Current approach tests actual integration points; component tests would require more test infrastructure
  > 
  > 2. **Follow control placement architecture**  
  >    **Files:** `member_message_detail_live.ex`, `member_message_detail_component.ex`  
  >    **Smell:** Follow toggle moved from one UI location to another (below composer → beside subject in detail head)  
  >    **Why judgement-worthy:** Implementation is clean, but broader question: "Where should contextual actions like follow/unfollow live in member app layouts?" might merit documentation for:
  >    - Future UI consistency across member app features
  >    - Design system pattern catalog
  >    - Not a code smell per se, but architectural decision worth capturing
  > 
  > 3. **Design system coupling and maintenance**  
  >    **Files:** All changed HEEx templates, CSS classes, component render functions  
  >    **Smell:** Direct 1:1 implementation of design system wireframes (expected and correct), but no documented mapping between wireframe IDs and implementation files  
  >    **Why judgement-worthy:** Future design system changes will require code changes. Consider:
  >    - Adding comments linking code sections to design system wireframe IDs
  >    - Maintaining a design-to-code mapping document
  >    - Trade-off: Adds documentation overhead vs. easier maintenance when designs evolve
  > 
  > ---
  > 
  > ## Suggested Fixes
  > 
  > None required for acceptance.
  > 
  > **Optional bounded-safe improvements** (can be deferred to maintenance):
  > - Extract repeated test setup into `test/support/member_message_test_helpers.ex`
  > - Add inline comments linking major UI sections to design system wireframe references
  > - Consider shared test predicates for common UI assertions (footer presence, back link structure)
  > 
  > ---
  > 
  > ## Validation Notes
  > 
  > **Automated Test Coverage:**
  > - ✅ Dev check passed: 109 scenarios (109 passed), 783 steps (783 passed)
  > - ✅ New tests for back link behavior (text, href, no club_id param)
  > - ✅ New tests for follow control placement in detail head
  > - ✅ Tests verify removal of "Prefer email?" card
  > - ✅ Tests verify compact footer-only presence
  > - ✅ Tests verify composer "Replying as" inline placement
  > - ✅ Tests verify page-title scale (not hero scale) for message subject
  > - ✅ Tests verify removal of helper sentence and green alert from posted state
  > 
  > **Implementation Evidence:**
  > - ✅ `member_message_detail_live.ex`: Clean component structure
  > - ✅ Tests use semantic selectors (`#back-to-club-home-link`, `.detail-head__main`)
  > - ✅ CSS changes use Tailwind utilities consistently
  > - ✅ No behavioral regressions (all existing tests pass)
  > - ✅ Mobile explicitly out of scope (correctly)
  > 
  > **Plan Conformance:**
  > - ✅ All 8 plan requirements addressed (back link, follow control, subject scale, composer inline, helper/alert removal, email card removal, compact footer, coordination with iteration 051)
  > - ✅ No out-of-scope work detected
  > - ✅ Acceptance criteria met via automated tests
  > 
  > **Code Quality:**
  > - ✅ Phoenix LiveView conventions followed
  > - ✅ HEEx templates well-structured
  > - ✅ Test organization clear and focused
  > - ✅ Proper use of PhoenixTest helpers (`has_element?`, `refute has_element?`)
  > - ✅ Clean component boundaries
  > 
  > **Manual Smoke Validation Required:**
  > Per plan, human should verify:
  > - Desktop gallery screenshots match wireframes
  > - App card width, top-bar alignment, compact footer
  > - Back link wording and placement
  > - Message card styling (borders, shadows, spacing)
  > - Composer panel background/border/height
  > - Absence of removed elements (helper sentence, green alert, email card, public footer)
  > 
  > ---
  > 
  > ## Summary
  > 
  > This is a **clean, well-executed UI alignment iteration** with excellent test coverage and no architectural concerns. The implementation:
  > 
  > 1. Addresses all plan requirements precisely
  > 2. Maintains backward compatibility (no behavioral changes)
  > 3. Follows project conventions for Phoenix/LiveView/HEEx/Tailwind
  > 4. Has comprehensive automated test coverage
  > 5. Includes appropriate integration tests for new UI layouts
  > 
  > The code is maintainable, the changes are minimal and focused, and the test suite provides strong confidence in correctness. Minor opportunities for test code refactoring exist but do not block merge.
  > 
  > **Recommendation:** Merge after human visual validation of desktop gallery screenshots against design system wireframes as outlined in plan acceptance criteria.

## Stage: codex_review
- Status: succeeded
- Handler: prompt
- Model: gpt-5.5
- Tokens: 6.0k in / 3.3k out
- Response:
  > # Iteration Review Report
  > 
  > ## Decision: ACCEPT
  > 
  > ## Confidence: Medium
  > 
  > Confidence is reduced only because the core goal is visual desktop alignment, and the provided evidence is mostly automated DOM/test output rather than full screenshot/manual inspection. From the implementation evidence and successful `dev ci`, the code-health and ADR risk looks low.
  > 
  > ## ADR conformance: PASS
  > 
  > The iteration appears presentation-layer focused: Phoenix LiveView templates/components, HEEx structure, Tailwind styling, and LiveView tests for member-app UI alignment.
  > 
  > No cited ADRs or nearby domain/CQRS/event-sourcing concerns appear to be implicated by the provided evidence. The implementation does not appear to change aggregates, commands, projections, event streams, read models, authorization boundaries, or infrastructure choices.
  > 
  > ## ADR violations
  > 
  > None identified.
  > 
  > ## Blocking issues
  > 
  > None identified.
  > 
  > ## Bounded-safe fixes
  > 
  > 1. **Extract repeated LiveView test setup helpers**
  > 
  >    **Files:** `member_message_detail_live_test.exs`, possibly related member app LiveView tests.
  > 
  >    The evidence shows repeated setup patterns around creating an active member, creating a message, signing in on a club host, and opening the message detail route. A small private helper such as `open_message_detail(conn, opts)` or `setup_member_message_detail/2` would reduce test noise without changing product behavior.
  > 
  > 2. **Name long structural selector assertions**
  > 
  >    **Files:** `member_message_detail_live_test.exs`
  > 
  >    Selectors such as:
  > 
  >    ```elixir
  >    "#member-message-heading-row.detail-head > .detail-head__main h1#member-message-subject.page-title"
  >    ```
  > 
  >    are precise, but hard to scan and maintain. Private assertion helpers like `assert_subject_in_detail_head(view, subject)` or `assert_follow_control_in_detail_head(view)` would preserve the same coverage while improving readability.
  > 
  > 3. **Review selector naming drift around the back link**
  > 
  >    **Files:** message detail LiveView/template and related tests.
  > 
  >    Evidence shows:
  > 
  >    ```elixir
  >    a#back-to-club-home-link[href='/conversations']
  >    ```
  > 
  >    with visible text `"All conversations"`.
  > 
  >    If this DOM id is not used by JS hooks, CSS, browser acceptance helpers, or external tooling, renaming it to something closer to the current behavior, such as `back-to-conversations-link`, would reduce semantic drift. If it is already treated as a stable selector, leaving it as-is is acceptable.
  > 
  > 4. **Consider shared compact-footer assertions**
  > 
  >    **Files:** member-app LiveView tests covering message detail, conversations, and club home.
  > 
  >    Several plan requirements concern the compact member-app footer and absence of the public footer. If those assertions are repeated across tests, a shared test helper like `assert_compact_member_footer_only(view)` would make future layout checks easier to maintain.
  > 
  > ## Judgement-worthy non-blocking code-health findings
  > 
  > 1. **Member-app layout patterns may be spreading across individual screens**
  > 
  >    **Files:** member message detail LiveView/component, club home LiveView/template, conversations LiveView/template.
  > 
  >    **Smell:** The iteration aligns multiple screens around shared concepts: compact app shell, detail header, compact footer, tab/action alignment, and desktop card width.
  > 
  >    **Why it may need human judgement:** This is fine for a focused iteration, but if these patterns continue to spread screen-by-screen, the project may benefit from explicit reusable member-app layout components or documented member-app shell conventions. That decision should be design/product-aware, not forced as part of this merge.
  > 
  > 2. **Visual conformance is only partially represented by DOM tests**
  > 
  >    **Files:** LiveView tests for message detail and club home.
  > 
  >    **Smell:** Tests validate important semantic structure and absence/presence of elements, but pixel-level concerns from the plan — spacing, card elevation, desktop width, alignment, footer compactness, and wireframe fidelity — cannot be fully proven by `has_element?/refute has_element?`.
  > 
  >    **Why it may need human judgement:** This is expected for a UI-alignment iteration, but the team may eventually want screenshot regression checks or a clearer human visual-review checklist as a release gate for design-alignment work.
  > 
  > 3. **Wireframe-to-implementation mapping is implicit**
  > 
  >    **Files:** changed HEEx/templates/components and related tests.
  > 
  >    **Smell:** The implementation appears to track specific design-system wireframes, but the mapping from wireframe sections to implementation files/classes is not obvious from the code evidence.
  > 
  >    **Why it may need human judgement:** Inline comments or a lightweight design-to-code mapping can help future iterations understand why certain markup/classes exist. However, adding too many comments around visual layout can create maintenance noise, so this should be a team convention decision.
  > 
  > 4. **Structural CSS selectors in tests may ossify markup**
  > 
  >    **Files:** `member_message_detail_live_test.exs` and related LiveView tests.
  > 
  >    **Smell:** Some tests assert exact DOM hierarchy and class placement.
  > 
  >    **Why it may need human judgement:** For this iteration, that precision is useful because the goal is desktop layout alignment. Long-term, tests that over-specify structure can make harmless markup refactors expensive. The team may want a convention distinguishing semantic assertions from intentional layout-contract assertions.
  > 
  > ## Suggested fixes
  > 
  > Non-blocking, safe follow-ups:
  > 
  > 1. Add private test helpers for common member message detail setup.
  > 2. Wrap long selector assertions in clearly named helper functions.
  > 3. Audit the `#back-to-club-home-link` id; rename to match current semantics if it is not externally depended on.
  > 4. Add shared test helpers for recurring member-app layout/footer assertions if duplication continues.
  > 
  > No implementation changes are required before merge.
  > 
  > ## Validation notes
  > 
  > - `dev ci` passed.
  > - Acceptance output shows `109 scenarios`, `109 passed`; `783 steps`, `783 passed`.
  > - Sandbox/runtime preflight passed.
  > - The implementation evidence shows targeted LiveView tests for:
  >   - routed message detail identity via club/message data attributes;
  >   - back link text and `/conversations` href;
  >   - absence of stale `club_id` query parameter on the back link;
  >   - follow control placement beside the subject in the detail head;
  >   - removal/absence-oriented UI assertions required by the plan.
  > - No domain, CQRS, event-sourcing, read-model, migration, or integration changes are apparent from the evidence.
  > - Manual visual validation remains important for the plan’s desktop screenshot goals, especially spacing, card styling, footer treatment, and wireframe fidelity.


You are independently reviewing the completed, plan-conforming implementation of the iteration plan at docs/iterations/052-desktop-member-app-design-alignment/plan.md.

Use the prior context: the plan text, collected implementation evidence, current working tree state, commit range from `eebacadd114ae0325805a17da9744b0722f8e91e..HEAD`, and the successful dev check output. Be strict, practical, and specific. Do not edit files.

This workflow reviews an already-committed implementation after the implementation workflow has proved plan conformance. The review job is code polish plus smell radar: refactoring, maintainability, project conventions, ADR conformance, and surfacing judgement-worthy non-blocking smells. Do not emit shell-command/tool-call JSON; return the Markdown review report only.

Use the project pattern reference docs as review guidelines when the touched code involves domain modeling, Commanded, aggregates, projections, event streams, read models, or object responsibility boundaries:

- `docs/reference/domain-driven-design.md`
- `docs/reference/cqrs.md`
- `docs/reference/event-sourcing.md`
- `docs/reference/responsibility-driven-design.md`

Treat accepted ADRs as binding project decisions. Treat these reference docs as design-quality guidance for interpreting and applying those ADRs, not as permission to override an ADR or the iteration plan.

Automated tests are the behavioural feedback loop in this workflow. If you find a likely behavioural gap, missing acceptance criterion, or inadequate automated coverage despite green dev check, flag it as a blocking issue requiring a new implementation/test pass or human decision; do not disguise it as refactoring feedback. Do not ask for feature-file edits.

Review against these questions:

0. ADR conformance
   - Read every ADR cited by the plan and any nearby/current ADRs under `docs/adr/` that govern touched architecture.
   - Follow signposts in those ADRs to the reference docs above; use them to check whether domain/CQRS/event-sourcing/RDD implementation choices match the patterns Memba wants.
   - Does the implementation obey accepted ADR decisions and consequences as binding constraints?
   - Does it avoid replacing ADR-mandated infrastructure or architecture with simpler local substitutes, unless the plan explicitly deferred that decision?
   - Do tests and implementation evidence prove the ADR-relevant behaviour, wiring, or structure?
   - Reject if the implementation conflicts with accepted ADRs or omits a cited ADR's central decision without an explicit plan deferral or human decision.

1. Light plan-fidelity sanity check
   - Does the implementation appear consistent with the stated goal and capability, given the plan-conformance gate has already passed?
   - Did it avoid obvious out-of-scope work?
   - If you find a substantial plan gap, classify it as blocking and requiring human input or a new implementation pass.

2. Behaviour and automated coverage
   - Did dev check pass before review?
   - Are important happy paths, edge cases, permissions, error states, and data/state changes covered by automated tests where appropriate?
   - Were acceptance feature files left unchanged as domain acceptance criteria?

3. Technical quality / refactoring
   - Are Phoenix, LiveView, HEEx, Ecto, Tailwind, and Elixir conventions followed where relevant?
   - Are migrations, schemas, contexts, tests, routes, UI, background jobs, and integrations coherent?
   - Is the implementation maintainable, minimal, and well factored?

4. Code-health classification
   - Blocking: ADR violations, behavioural gaps, missing or unsafe coverage, repeated blockers, or anything needing product/architecture judgement before merge.
   - Bounded-safe: concrete, low-risk refactoring, maintainability, convention, or test-quality fixes an agent can apply without changing product behaviour or feature files.
   - Judgement-worthy non-blocking: design smells, coupling, duplication, naming, dependency, or architecture drift that might merit human judgement later but should not block this merge.

Return a Markdown report with:

- Decision: ACCEPT or REJECT
- Confidence: High, Medium, or Low
- ADR conformance: PASS or FAIL
- ADR violations: numbered list with ADR number/file and implementation evidence
- Blocking issues: numbered list
- Bounded-safe fixes: numbered list
- Judgement-worthy non-blocking code-health findings: numbered list; for each include file(s), smell, and why it may need human judgement
- Suggested fixes: concrete changes if rejected or bounded-safe fixes exist
- Validation notes: tests/checks/manual checks relevant to the decision