Goal: Review a completed plan-conforming iteration implementation for code polish, ADR conformance, and code-health signals
Run ID: 01KWS01J00N4Z7JM5CXD1JBK19
Pipeline progress: 10 of 27 stages completed

## Stage: read_plan
- Status: succeeded
- Handler: command
- Script: `PLAN_PATH='docs/iterations/044-shared-app-shell/plan.md'
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
  (144 lines omitted)
  12. Add/adjust a test that every `club_site` surface still renders under the new shell (club home,
      conversation, compose, invitation, public club page).
  13. Run `./bin/dev gallery-walk` and compare the club-home and conversation screenshots to
      `design-system/wireframes/club-home.html` / `member-conversation.html`.
  14. Run `dev check` and confirm it is green (no feature-file changes).
  
  ## Open Technical Decisions
  
  None open — both prior technical questions are decided in the Implementation Plan:
  
  - **CSS source: decided — port the DS component classes** (`app-frame`, `app-card`, `app-bar` &
    children, `app-menu`, `app-foot`, identity-dropdown pieces) verbatim from `design-system/`
    (`memba.css` / `styles.css`) into `web/assets/css/app.css`, keeping class names 1:1 with the
    design mirror rather than re-expressing the shell in Tailwind utilities. This keeps the design
    mirror authoritative and the app pixel-faithful.
  - **Identity name/initials plumbing: decided — a new optional `member_name` assign** on
    `club_site`, passed by the four signed-in member surfaces, with an email-local-part fallback and
    a `Layouts.initials/1` helper for the avatar. The signed-out public page supplies neither
    identity nor name (dropdown gated off).
  
  ## New Capability
  
  A shared, app-like **shell** (app-bar + app-card) across every member surface — built once in the
  shared layout — so the club-home tabs and the aligned conversation page can be built inside a
  consistent frame instead of each screen re-inventing its own header.
  
  ## Validation Plan
  
  - **Automated:** LiveView/layout tests (app-bar renders the club name; identity dropdown gated on
    identity; Sign out posts to `DELETE /auth`; app-card wraps content; every `club_site` surface
    renders). `dev check` green (no feature-file changes).
  - **Visual:** `./bin/dev gallery-walk`, then compare the club-home and conversation screenshots to
    `design-system/wireframes/club-home.html` / `member-conversation.html` (app-bar + app-card + the
    "Powered by Memba" foot).
  - **Manual:** signed-in club home + conversation show the app-bar; the identity dropdown opens and
    Sign out works; the public club page shows the app-bar with no identity dropdown.
  
  ## Risks / Follow-ups
  
  - **Shared-layout blast radius:** changing `club_site` touches all six surfaces — verify the public
    club page (signed out), compose, invitation, and message detail all still render.
  - **CSS porting:** the app-shell component classes must be added to the app stylesheet; keep them
    named 1:1 with the design mirror.
  - **Follow-on slices (my own sequencing, not bound to the old 044/045/046 drafts):** (1) club-home
    Conversations / Members / **About** tabs inside this shell; (2) conversation-page content
    alignment (compact delivery, follow toggle, replies-first + "Replies · N", message timestamps);
    (3) member names + role badges (needs role data in the read model). Each is its own later slice.
  - **Numbering:** delivered as iteration 044 so Fabro's "earlier iterations merged first" rule is
    satisfied (001–043 are merged). The unmerged 045/046 drafts are left untouched and will be
    re-decided when their turn comes.
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
  (301 lines omitted)
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
  (1459 lines omitted)
  
    Rule: Staff-edited slugs must already be address-safe
  
      Scenario: Staff enter an invalid slug # features/staff_club_slugs.feature:17
  [acceptance 2026-07-05T11:28:07.709Z] scenario start: Staff enter an invalid slug
  [acceptance 2026-07-05T11:28:07.766Z] scenario reset app state: Staff enter an invalid slug
        Given Pat is signed in as Memba staff
  [acceptance 2026-07-05T11:28:08.961Z] slow step: Staff enter an invalid slug :: Pat is signed in as Memba staff :: 1150ms
        Given Kootenay Mountaineering Club is a club
        When Pat tries to change Kootenay Mountaineering Club's slug to "kmc club!"
        Then Memba should reject the club slug as invalid
        And Kootenay Mountaineering Club should keep its previous slug
  [acceptance 2026-07-05T11:28:10.356Z] scenario teardown start: Staff enter an invalid slug status=PASSED
  [acceptance 2026-07-05T11:28:10.363Z] scenario finish: Staff enter an invalid slug status=PASSED duration=2655ms
  
    Rule: A slug can belong to only one club
  
      Scenario: Staff enter a slug that another club already uses # features/staff_club_slugs.feature:25
  [acceptance 2026-07-05T11:28:10.367Z] scenario start: Staff enter a slug that another club already uses
  [acceptance 2026-07-05T11:28:10.410Z] scenario reset app state: Staff enter a slug that another club already uses
        Given Pat is signed in as Memba staff
  [acceptance 2026-07-05T11:28:11.838Z] slow step: Staff enter a slug that another club already uses :: Pat is signed in as Memba staff :: 1331ms
        Given Kootenay Mountaineering Club has the slug "kmc"
        And Nelson Paddling Club is a club
        When Pat tries to change Nelson Paddling Club's slug to "kmc"
        Then Memba should reject the club slug as already taken
        And Nelson Paddling Club should keep its previous slug
  [acceptance 2026-07-05T11:28:13.568Z] scenario teardown start: Staff enter a slug that another club already uses status=PASSED
  [acceptance 2026-07-05T11:28:13.571Z] scenario finish: Staff enter a slug that another club already uses status=PASSED duration=3204ms
  
    Rule: A club slug routes public visitors to that club's public page
  
      @not-domain
      Scenario: Robin opens an unknown club subdomain # features/staff_club_slugs.feature:35
  [acceptance 2026-07-05T11:28:13.571Z] scenario start: Robin opens an unknown club subdomain
  [acceptance 2026-07-05T11:28:13.606Z] scenario reset app state: Robin opens an unknown club subdomain
        Given Pat is signed in as Memba staff
  [acceptance 2026-07-05T11:28:14.792Z] slow step: Robin opens an unknown club subdomain :: Pat is signed in as Memba staff :: 1120ms
        When Robin opens "unknown.clubs.memba.io"
        Then Robin should see a not found page
  [acceptance 2026-07-05T11:28:14.856Z] scenario teardown start: Robin opens an unknown club subdomain status=PASSED
  [acceptance 2026-07-05T11:28:14.860Z] scenario finish: Robin opens an unknown club subdomain status=PASSED duration=1289ms
  
  [acceptance 2026-07-05T11:28:14.862Z] AfterAll: closing shared browser
  [acceptance 2026-07-05T11:28:14.885Z] AfterAll: closed shared browser
  [acceptance 2026-07-05T11:28:14.885Z] AfterAll: stopping Phoenix browser acceptance lifecycle
  [acceptance 2026-07-05T11:28:14.886Z] AfterAll: stopped Phoenix browser acceptance lifecycle
  85 scenarios (85 passed)
  523 steps (523 passed)
  3m57.695s (executing steps: 3m45.689s)
  ```

## Stage: collect_implementation_evidence
- Status: succeeded
- Handler: command
- Script: `bash .fabro/workflows/iteration-review/scripts/collect_implementation_evidence.sh 'c8b1a4e95361504e41a1984cfacef631a1b56784'`
- Output:
  ```
  (1201 lines omitted)
      )
  
      assert_selector(
        html,
        "#club-site-layout header .app-bar__id .dropdown-content.app-menu.app-menu--id form#club-site-sign-out-form[action='/auth'][method='post']"
      )
  
      assert_selector(
        html,
        "#club-site-layout header .app-bar__id .dropdown-content.app-menu.app-menu--id form#club-site-sign-out-form input[name='_method'][value='delete']"
      )
  
      assert_selector(
        html,
        "#club-site-layout header .app-bar__id .dropdown-content.app-menu.app-menu--id button#club-site-sign-out-button.app-menu__signout[type='submit'][role='menuitem']"
      )
  
      assert_text(html, "#club-site-sign-out-button", "Sign out")
  
      refute_text(html, "#club-site-footer", "Commit")
  
      assert only_attribute(html, "#club-site-layout", "class") == "app-frame"
      refute html =~ "--club-site-"
      assert [] = attributes(html, "#club-site-layout", "style")
    end
  
    test "club-site layout gates the member identity dropdown when signed out" do
      assigns = %{flash: %{}}
  
      html =
        rendered_to_string(~H"""
        <Layouts.club_site flash={@flash} club_name="Riverside Tennis Club">
          <section id="public-club-site-layout-slot">Public club page content</section>
        </Layouts.club_site>
        """)
  
      assert_selector(html, "#club-site-layout header .app-bar")
  
      assert_text(
        html,
        "#club-site-layout header .app-bar__brand .app-bar__club",
        "Riverside Tennis Club"
      )
  
      refute_selector(html, "#club-site-layout header .app-bar .app-bar__id")
      refute_selector(html, "#club-site-layout header #club-site-identity-menu-button")
      refute_selector(html, "#club-site-layout header .app-bar__avatar")
      refute_selector(html, "#club-site-layout header .app-bar__who")
      refute_selector(html, "#club-site-layout header .app-menu")
      refute_selector(html, "#club-site-layout header #club-site-sign-out-form")
  ```

## Stage: claude_review
- Status: succeeded
- Handler: prompt
- Model: claude-sonnet-4-5
- Tokens: 5.7k in / 7.7k out
- Response:
  > # Iteration 044 Review Report: Shared App Shell
  > 
  > ## Decision: ACCEPT
  > 
  > ## Confidence: Medium
  > 
  > Would be High with direct access to ADR files governing UI/layout/CSS decisions and full JavaScript implementation evidence for dropdown behaviour.
  > 
  > ## ADR Conformance: PASS
  > 
  > No ADR violations detected in the implementation. The CSS porting approach (component classes from design-system rather than Tailwind utilities) is explicitly decided in the plan's "Open Technical Decisions" section and aligns with the README guidance that the design system is the source of truth. However, could not verify against all potentially relevant ADRs since none were explicitly cited in the plan.
  > 
  > ## ADR Violations
  > 
  > None found.
  > 
  > ## Blocking Issues
  > 
  > None found.
  > 
  > The implementation:
  > - Follows the plan's stated goal and capability (shared app-shell layout for club-site surfaces)
  > - Passes `dev check` with full test suite green
  > - Implements all planned components (app-bar, app-card, identity dropdown, footer)
  > - Provides comprehensive test coverage for layout structure, conditional rendering, and the initials helper
  > - Leaves feature files unchanged (domain acceptance criteria preserved)
  > 
  > ## Bounded-Safe Fixes
  > 
  > None identified. The potential improvements below require human judgement about product intent or architectural direction.
  > 
  > ## Judgement-Worthy Non-Blocking Code-Health Findings
  > 
  > 1. **Unused `@flash` assign** (files: `lib/memba_web/components/layouts.ex`, `test/memba_web/components/layouts_test.exs`)
  >    - **Smell:** The layout tests pass `flash={@flash}` but the implementation doesn't render flash messages anywhere in the component.
  >    - **Why it needs judgement:** This could indicate (a) incomplete implementation if flash should be rendered in the app-shell, (b) intentional deferral if flash rendering is planned for a later iteration, or (c) vestigial code if flash is handled by a parent layout. Typical Phoenix root layouts render flash, and this appears to be a root layout for club sites (has full page structure from header to footer). However, the plan makes no mention of flash rendering, and the tests don't verify it, suggesting it's out of scope. A human should decide whether to remove the unused assign, add flash rendering, or document the deferral.
  > 
  > 2. **Member name/initials fallback duplication** (file: `lib/memba_web/components/layouts.ex`)
  >    - **Smell:** The expression `assigns[:member_name] || String.split(@member_identity, "@") |> hd()` appears twice (once for initials, once for display name).
  >    - **Why it needs judgement:** Extracting this to a private helper like `member_display_name/1` would reduce duplication and make the fallback logic more explicit. However, with only two call sites and clear inline logic, the marginal benefit might not justify the abstraction. A human should weigh maintainability vs simplicity.
  > 
  > 3. **Dropdown JavaScript dependency** (file: `lib/memba_web/components/layouts.ex`)
  >    - **Smell:** The identity dropdown relies on `MembaWeb.CoreComponents.show("#club-site-identity-menu")` for click handling, but the implementation evidence doesn't show the JavaScript side or tests verifying dynamic ARIA attribute updates (e.g., `aria-expanded` toggling when menu opens/closes).
  >    - **Why it needs judgement:** Phoenix CoreComponents typically provide dropdown/modal functions, so this is likely correct. However, without seeing the JS implementation or tests, can't verify full accessibility compliance (dynamic ARIA updates) or that the dropdown interaction works as expected. If CoreComponents doesn't provide `show/1`, or if ARIA states aren't updated, this could be a usability/a11y gap. A human should verify the JS side exists and handles ARIA correctly, or flag for manual accessibility testing.
  > 
  > ## Suggested Fixes
  > 
  > None blocking. The implementation is solid as-is. The judgement-worthy items above are for potential future polish:
  > 
  > - **If flash should be rendered:** Add `<.flash_group flash={@flash} />` in the layout and verify with tests.
  > - **If flash is intentionally deferred:** Remove the unused `flash` assign from tests or add a comment documenting the deferral.
  > - **If duplication bothers future maintainers:** Extract `member_display_name/1` helper for the name/identity fallback logic.
  > - **For accessibility verification:** Manually test or add JavaScript tests confirming aria-expanded updates when dropdown toggles.
  > 
  > ## Validation Notes
  > 
  > ### Automated Coverage (Green)
  > - **Layout structure tests:** App-bar, app-card, app-foot, club name, identity dropdown, Sign out form all verified via DOM selectors.
  > - **Conditional rendering:** Identity dropdown correctly gated when signed out (no `member_identity` assign).
  > - **Initials helper edge cases:** Full name, email, empty string, nil, whitespace, single word all covered.
  > - **Sign-out form structure:** POST to `/auth` with `_method=delete` verified.
  > - **CSS class naming:** Tests confirm app-frame, app-bar, app-card, app-menu, app-foot classes present; legacy `--club-site-` variables absent.
  > 
  > ### Dev Check (Passed)
  > - Full test suite green (85 scenarios, 523 steps, 3m57s).
  > - No feature file changes (domain acceptance criteria unchanged).
  > - Elixir compilation clean.
  > 
  > ### Plan Fidelity
  > - All 14 implementation steps addressed in the evidence.
  > - CSS classes ported from design-system as decided (app-frame, app-bar, app-card, app-menu, app-foot, identity-dropdown pieces).
  > - Identity dropdown with member name/initials implemented.
  > - Signed-out public page correctly omits identity UI.
  > - Tests added for all club-site surfaces rendering under new shell (per step 12).
  > 
  > ### Manual Validation Deferred
  > The plan calls for `./bin/dev gallery-walk` and screenshot comparison to design-system wireframes. This is manual validation outside the review scope, but the automated tests provide strong structural confidence.
  > 
  > ---
  > 
  > **Summary:** This is a clean, plan-conforming implementation with solid test coverage and no blocking issues. The three non-blocking findings are minor code-health observations that may merit future attention but should not delay merge. The unused `@flash` assign is the only item worth brief human confirmation (intentional deferral vs oversight), but given the plan silence on flash rendering, it's likely out of scope. Recommend **accept and merge**.

## Stage: codex_review
- Status: succeeded
- Handler: prompt
- Model: gpt-5.5
- Tokens: 6.1k in / 3.0k out
- Response:
  > # Iteration 044 Review: Shared App Shell
  > 
  > ## Decision: ACCEPT
  > 
  > ## Confidence: Medium
  > 
  > Confidence is limited mainly by the truncated implementation evidence and lack of direct ADR contents in the provided context. The available evidence, plan excerpt, and green `dev check` are strong enough to accept.
  > 
  > ## ADR conformance: PASS
  > 
  > No ADR violations were identified from the provided plan/evidence. The plan excerpt cites no specific ADRs, and the implementation appears limited to Phoenix layout/CSS/test work rather than domain modeling, Commanded, CQRS, event sourcing, projections, or read-model boundaries.
  > 
  > The implementation also appears to follow the plan’s explicit technical decision to port the design-system shell classes directly into the application stylesheet instead of re-expressing the shell with Tailwind utilities.
  > 
  > ## ADR violations
  > 
  > None.
  > 
  > ## Blocking issues
  > 
  > None.
  > 
  > ## Bounded-safe fixes
  > 
  > None required before merge.
  > 
  > ## Judgement-worthy non-blocking code-health findings
  > 
  > 1. **Unused `flash` assign in the shared layout**
  >    - **Files:** `lib/memba_web/components/layouts.ex`, `test/memba_web/components/layouts_test.exs`
  >    - **Smell:** The layout accepts/passes `flash`, but the evidence does not show flash rendering inside the new `club_site` shell.
  >    - **Why judgement is needed:** This may be intentional because flash handling is out of scope for this iteration, or because flash is rendered by another/root layout. If `club_site` is now the effective application shell for these pages, a future pass should decide whether flashes belong inside it.
  > 
  > 2. **Identity display-name fallback appears duplicated**
  >    - **File:** `lib/memba_web/components/layouts.ex`
  >    - **Smell:** The member-name fallback logic appears to be repeated for display text and initials derivation.
  >    - **Why judgement is needed:** Extracting a helper such as `member_display_name/1` would reduce duplication, but the current duplication is small and may not justify extra abstraction yet.
  > 
  > 3. **Dropdown behaviour/a11y may deserve a follow-up check**
  >    - **File:** `lib/memba_web/components/layouts.ex`
  >    - **Smell:** The identity menu evidence verifies static DOM shape and the sign-out form, but does not demonstrate dynamic behaviour such as closing the menu, escape/click-away handling, focus management, or `aria-expanded` updates.
  >    - **Why judgement is needed:** The current implementation likely satisfies the iteration’s structural shell goal, and Phoenix/JS helpers may already provide enough behaviour. However, if the identity dropdown becomes a reusable interaction pattern, it should eventually get explicit accessibility/interaction coverage.
  > 
  > 4. **Sign-out form coverage is structural rather than behavioural**
  >    - **Files:** `lib/memba_web/components/layouts.ex`, layout/component tests
  >    - **Smell:** Tests assert the form posts to `/auth` with `_method=delete`, but the evidence does not show a test submitting the new dropdown sign-out form from a club-site page.
  >    - **Why judgement is needed:** Existing auth tests may already cover the controller route. Still, because this is a new sign-out entry point, a future test could assert the rendered form includes all required fields, especially CSRF protection if a raw `<form>` is used.
  > 
  > ## Suggested fixes
  > 
  > No merge-blocking fixes are recommended.
  > 
  > Potential future polish:
  > 
  > - If `club_site` should own flash rendering, add the project-standard flash component to the shell and test it.
  > - If the identity label logic grows, extract a small helper for member display-name fallback.
  > - Consider adding an interaction-level test or manual accessibility checklist for the identity dropdown.
  > - If not already covered elsewhere, add a small assertion that the sign-out form includes CSRF protection or use the project-standard form helper.
  > 
  > ## Validation notes
  > 
  > - `dev check` / `dev ci` passed successfully.
  > - Acceptance suite passed: **85 scenarios, 523 steps**.
  > - No feature-file changes were indicated.
  > - Evidence shows tests for:
  >   - shared `club_site` app frame;
  >   - app bar rendering the club name;
  >   - app card/content wrapping;
  >   - identity dropdown gated by signed-in identity;
  >   - signed-out public page omitting identity UI;
  >   - sign-out form shape using `POST /auth` plus `_method=delete`;
  >   - app-shell CSS class structure;
  >   - all relevant `club_site` surfaces rendering under the new shell.
  > - Plan fidelity appears good: the implementation delivers the shared app-like shell and avoids obvious out-of-scope domain or architecture changes.

## Stage: gemini_review
- Status: succeeded
- Handler: prompt
- Model: gpt-5.5
- Tokens: 7.3k in / 2.5k out
- Response:
  > # Iteration 044 Review: Shared App Shell
  > 
  > ## Decision: ACCEPT
  > 
  > ## Confidence: Medium
  > 
  > The plan-conformance gate, implementation evidence, and green `dev check` are strong. Confidence is not “High” only because the evidence shown here is partially truncated and no specific ADR files were cited in the plan excerpt.
  > 
  > ## ADR conformance: PASS
  > 
  > No ADR violations found.
  > 
  > The implementation appears to touch Phoenix layout/components, HEEx, CSS, routing/form structure, and tests. It does not appear to alter domain modeling, Commanded boundaries, aggregates, projections, event streams, read models, or CQRS/event-sourcing infrastructure.
  > 
  > The plan’s explicit technical decision to port the design-system app-shell classes 1:1 into `web/assets/css/app.css` appears to have been followed.
  > 
  > ## ADR violations
  > 
  > None.
  > 
  > ## Blocking issues
  > 
  > None.
  > 
  > ## Bounded-safe fixes
  > 
  > None required before merge.
  > 
  > ## Judgement-worthy non-blocking code-health findings
  > 
  > 1. **`flash` is accepted/passed but not visibly rendered in the new shell**
  >    - **Files:** `lib/memba_web/components/layouts.ex`, `test/memba_web/components/layouts_test.exs`
  >    - **Smell:** The layout tests pass `flash={@flash}`, but the evidence does not show the `club_site` shell rendering a flash group.
  >    - **Why it may need human judgement:** This may be intentional if flash rendering is handled by an outer/root layout or deferred out of scope. If `club_site` is now the primary shell for these member/public club pages, missing flash rendering could eventually hide redirect or action feedback. The plan did not require flash work, so this should not block the iteration.
  > 
  > 2. **Member display-name fallback logic appears duplicated**
  >    - **File:** `lib/memba_web/components/layouts.ex`
  >    - **Smell:** The fallback from optional `member_name` to the email local-part appears to be used both for displayed identity text and avatar initials.
  >    - **Why it may need human judgement:** The duplication is small and readable today. Extracting a helper such as `member_display_name/1` would reduce repeated logic, but may be unnecessary abstraction until this identity presentation grows.
  > 
  > 3. **Identity dropdown behaviour is mostly structurally tested**
  >    - **Files:** `lib/memba_web/components/layouts.ex`, layout/component tests
  >    - **Smell:** The evidence shows strong DOM-shape tests for the dropdown and sign-out form, but does not show interaction-level coverage for opening/closing, escape/click-away handling, focus behaviour, or `aria-expanded` state changes.
  >    - **Why it may need human judgement:** The iteration goal was a shared shell and identity dropdown presence, and the automated structural checks are appropriate for that scope. If this dropdown becomes a reusable app interaction pattern, it should receive explicit accessibility/interaction validation later.
  > 
  > 4. **Sign-out form is covered structurally, not end-to-end from the new menu**
  >    - **Files:** `lib/memba_web/components/layouts.ex`, layout/component tests
  >    - **Smell:** Tests assert the form posts to `/auth` with `_method=delete`, but the evidence does not show submitting the new dropdown sign-out form from a rendered club-site page.
  >    - **Why it may need human judgement:** Existing auth/controller coverage likely verifies the route itself. Still, because this is a new sign-out entry point, a future test could assert the full rendered form includes the expected CSRF token and successfully signs out when submitted.
  > 
  > ## Suggested fixes
  > 
  > No required fixes.
  > 
  > Optional future polish:
  > 
  > - If `club_site` owns user-facing flash display, render the project-standard flash component inside the shell and add a focused layout test.
  > - If the identity fallback logic grows, extract a small helper for display-name derivation.
  > - Add a lightweight interaction/manual-a11y check for the identity dropdown.
  > - If not already covered elsewhere, add an assertion that the sign-out form generated in the shell includes CSRF protection.
  > 
  > ## Validation notes
  > 
  > - `dev check` / `dev ci` passed before review.
  > - Acceptance suite passed: **85 scenarios, 523 steps**.
  > - No feature-file changes were indicated.
  > - Evidence shows coverage for:
  >   - shared `club_site` app frame;
  >   - app bar rendering club name;
  >   - app-card wrapping inner content;
  >   - identity dropdown gated by signed-in identity;
  >   - signed-out public page omitting identity controls;
  >   - sign-out form shape targeting `DELETE /auth` through POST + `_method=delete`;
  >   - app-shell CSS class structure;
  >   - all relevant `club_site` surfaces rendering under the new shell.
  > - Plan fidelity appears good: the implementation delivers the shared app-like shell without obvious out-of-scope domain or architecture changes.

## Stage: synthesize_review
- Status: succeeded
- Handler: prompt
- Model: gpt-5.5
- Tokens: 8.7k in / 2.8k out
- Response:
  > {
  >   "context_updates": {
  >     "implementation_accepted": false,
  >     "review_fixes_available": true,
  >     "review_blockers": [
  >       {
  >         "id": "csrf-protect-club-site-sign-out",
  >         "title": "Verify or add CSRF protection for club-site sign-out form",
  >         "source": "review_synthesis",
  >         "first_seen_stage": "synthesize_review",
  >         "status": "open"
  >       },
  >       {
  >         "id": "dedupe-member-display-name-fallback",
  >         "title": "Extract duplicated club-site member display-name fallback",
  >         "source": "review_synthesis",
  >         "first_seen_stage": "synthesize_review",
  >         "status": "open"
  >       }
  >     ]
  >   }
  > }

## Stage: review_gate
- Status: succeeded
- Handler: conditional
- Notes: Conditional node evaluated: review_gate

## Stage: snapshot_before_review_repair
- Status: succeeded
- Handler: command
- Script: `set -eu
mkdir -p .fabro/tmp
kind='review'
git diff --binary > ".fabro/tmp/${kind}-repair-before.patch"
git diff --name-only > ".fabro/tmp/${kind}-repair-before-files.txt"
git diff --stat > ".fabro/tmp/${kind}-repair-before-stat.txt" || true
printf 'Repair baseline (%s) captured.\n' "$kind"`
- Output:
  ```
  Repair baseline (review) captured.
  ```

## Current context
| Key | Value |
|-----|-------|
| implementation_accepted | false |
| review_blockers | [{"id":"csrf-protect-club-site-sign-out","title":"Verify or add CSRF protection for club-site sign-out form","source":"review_synthesis","first_seen_stage":"synthesize_review","status":"open"},{"id":"dedupe-member-display-name-fallback","title":"Extract duplicated club-site member display-name fallback","source":"review_synthesis","first_seen_stage":"synthesize_review","status":"open"}] |
| review_fixes_available | true |


Apply the automatic repair brief from the preceding Synthesize Review stage for docs/iterations/044-shared-app-shell/plan.md.

Rules:

- Fix only the concrete bounded issues selected by the review synthesis.
- Treat this as a post-green refactoring, maintainability, verification, and hardening pass. Do not add new product behaviour here.
- Stay within the iteration plan and do not introduce new product decisions.
- Enforce or prove existing intended behaviour when safe: add/strengthen automated tests, validation attributes, input normalization, constraints, comments, or small shared-service refactors when the synthesis selected them.
- Never edit acceptance feature files (`*.feature`, including files under `acceptance-tests/`). If a requested fix requires changing one, leave it unchanged and report it as a code-health/manual follow-up.
- Add or update automated tests whenever they are the safest bounded way to prove a reviewer concern about lifecycle reuse, authorization, duplicate handling, state transitions, or other already-planned behaviour.
- Do not skip or weaken existing validation.
- Do not commit changes.
- Review must never push red. If a fix proves unsafe, too large, judgement-heavy, or likely to regress behaviour, discard that fix, leave the code unchanged for that issue, and report it as a code-health/manual follow-up instead of forcing a change.
- Do not abandon a selected fix merely because it is a hardening or verification change. First try the smallest safe test/config/code change that addresses the concern within the existing design.
- **Sandbox/runtime boundary**: If the requested fix or failure appears caused by sandbox/toolchain/runtime incoherence (stale `/env` paths, unwritable caches, missing tools, broken services, stale process-compose state), stop and report a sandbox blocker. Do not patch `bin/dev`, application scripts, product code, dependencies, or tests merely to compensate for sandbox runtime defects.
- **If no changes were needed**: If after reviewing the issues you determine that no code/config/test changes are required, state that explicitly and provide clear justification for why the review issues do not require changes.

When finished, summarize:

1. Each review issue from the gate.
2. The concrete code/config/test changes made for each issue (or an explicit statement that no changes were needed with justification).
3. Files changed (grouped by issue addressed).
4. Tests run and their results.
5. Any remaining gaps or human questions.

Include an issue-to-fix mapping showing which files/modules/tests address each review issue.