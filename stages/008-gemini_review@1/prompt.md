Goal: Review a completed plan-conforming iteration implementation for code polish, ADR conformance, and code-health signals
Run ID: 01KWRVAABPA4ZM8HQBRW5WSJ7F
Pipeline progress: 6 of 27 stages completed

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
  [acceptance 2026-07-05T10:05:38.224Z] scenario start: Staff enter an invalid slug
  [acceptance 2026-07-05T10:05:38.295Z] scenario reset app state: Staff enter an invalid slug
        Given Pat is signed in as Memba staff
  [acceptance 2026-07-05T10:05:39.503Z] slow step: Staff enter an invalid slug :: Pat is signed in as Memba staff :: 1172ms
        Given Kootenay Mountaineering Club is a club
        When Pat tries to change Kootenay Mountaineering Club's slug to "kmc club!"
        Then Memba should reject the club slug as invalid
        And Kootenay Mountaineering Club should keep its previous slug
  [acceptance 2026-07-05T10:05:41.053Z] scenario teardown start: Staff enter an invalid slug status=PASSED
  [acceptance 2026-07-05T10:05:41.059Z] scenario finish: Staff enter an invalid slug status=PASSED duration=2835ms
  
    Rule: A slug can belong to only one club
  
      Scenario: Staff enter a slug that another club already uses # features/staff_club_slugs.feature:25
  [acceptance 2026-07-05T10:05:41.059Z] scenario start: Staff enter a slug that another club already uses
  [acceptance 2026-07-05T10:05:41.126Z] scenario reset app state: Staff enter a slug that another club already uses
        Given Pat is signed in as Memba staff
  [acceptance 2026-07-05T10:05:42.416Z] slow step: Staff enter a slug that another club already uses :: Pat is signed in as Memba staff :: 1223ms
        Given Kootenay Mountaineering Club has the slug "kmc"
        And Nelson Paddling Club is a club
        When Pat tries to change Nelson Paddling Club's slug to "kmc"
        Then Memba should reject the club slug as already taken
        And Nelson Paddling Club should keep its previous slug
  [acceptance 2026-07-05T10:05:44.438Z] scenario teardown start: Staff enter a slug that another club already uses status=PASSED
  [acceptance 2026-07-05T10:05:44.446Z] scenario finish: Staff enter a slug that another club already uses status=PASSED duration=3386ms
  
    Rule: A club slug routes public visitors to that club's public page
  
      @not-domain
      Scenario: Robin opens an unknown club subdomain # features/staff_club_slugs.feature:35
  [acceptance 2026-07-05T10:05:44.446Z] scenario start: Robin opens an unknown club subdomain
  [acceptance 2026-07-05T10:05:44.512Z] scenario reset app state: Robin opens an unknown club subdomain
        Given Pat is signed in as Memba staff
  [acceptance 2026-07-05T10:05:45.801Z] slow step: Robin opens an unknown club subdomain :: Pat is signed in as Memba staff :: 1243ms
        When Robin opens "unknown.clubs.memba.io"
        Then Robin should see a not found page
  [acceptance 2026-07-05T10:05:45.865Z] scenario teardown start: Robin opens an unknown club subdomain status=PASSED
  [acceptance 2026-07-05T10:05:45.871Z] scenario finish: Robin opens an unknown club subdomain status=PASSED duration=1425ms
  
  [acceptance 2026-07-05T10:05:45.872Z] AfterAll: closing shared browser
  [acceptance 2026-07-05T10:05:45.916Z] AfterAll: closed shared browser
  [acceptance 2026-07-05T10:05:45.916Z] AfterAll: stopping Phoenix browser acceptance lifecycle
  [acceptance 2026-07-05T10:05:45.917Z] AfterAll: stopped Phoenix browser acceptance lifecycle
  85 scenarios (85 passed)
  523 steps (523 passed)
  3m59.166s (executing steps: 3m46.666s)
  ```

## Stage: collect_implementation_evidence
- Status: succeeded
- Handler: command
- Script: `bash .fabro/workflows/iteration-review/scripts/collect_implementation_evidence.sh 'e0fb9401c0e88b3388bf1a2f847acdb7be0b7e55'`
- Output:
  ```
  (3800 lines omitted)
      for {label, source} <- member_page_sources() do
        refute source =~ @hardcoded_hex,
               "#{label} contains a hardcoded hex colour; use a Memba token or daisyUI class"
  
        refute source =~ "--club-site-",
               "#{label} contains legacy club-site theming; use the canonical Memba theme"
  
        refute source =~ @legacy_member_palette,
               "#{label} contains a legacy Tailwind colour-family utility; use a Memba token or daisyUI class"
      end
    end
  
    test "member page sources call shared design-system components and shell classes" do
      for {label, source_ref, required_components} <- @expected_component_usage do
        source = source_for(source_ref)
  
        for component_call <- required_components do
          assert source =~ component_call,
                 "#{label} should render #{component_call} from the shared design system"
        end
      end
    end
  
    defp member_page_sources do
      file_sources =
        Enum.map(@member_page_files, fn path ->
          {path, File.read!(web_path(path))}
        end)
  
      [{"MembaWeb.Layouts.club_site", club_site_source()} | file_sources]
    end
  
    defp source_for(:club_site), do: club_site_source()
    defp source_for(path), do: File.read!(web_path(path))
  
    defp club_site_source do
      source = File.read!(web_path("lib/memba_web/components/layouts.ex"))
  
      [template] =
        Regex.run(
          ~r/def club_site\(assigns\) do\s+~H"""\n(.*?)\n\s+"""\n\s+end/s,
          source,
          capture: :all_but_first
        )
  
      template
    end
  
    defp web_path(path), do: Path.expand("../../#{path}", __DIR__)
  end
  ```

## Stage: claude_review
- Status: succeeded
- Handler: prompt
- Model: claude-sonnet-4-5
- Tokens: 5.6k in / 7.5k out
- Response:
  > # Iteration 044 Implementation Review
  > 
  > **Decision:** ACCEPT  
  > **Confidence:** High  
  > **ADR Conformance:** PASS
  > 
  > ---
  > 
  > ## ADR Conformance: PASS
  > 
  > The implementation respects design-system authority as the binding architectural principle governing this work:
  > 
  > - **Design-system classes ported 1:1:** CSS classes (`.app-frame`, `.app-bar`, `.app-card`, `.app-menu`, `.app-foot`, identity-dropdown components) are ported verbatim from `design-system/memba.css` with explicit comments acknowledging the source and the 1:1 naming requirement.
  > - **No Tailwind re-expression:** The plan explicitly chose to port component classes rather than re-express the shell in Tailwind utilities. The implementation follows this decision.
  > - **Automated conformance checks:** The integration test enforces that member pages use shared design-system components, contain no hardcoded hex colors, no legacy club-site theming, and no legacy Tailwind color-family utilities.
  > 
  > No ADR violations detected. The implementation treats the design system as authoritative and implements the shell with pixel fidelity to the design mirror.
  > 
  > ---
  > 
  > ## ADR Violations
  > 
  > None.
  > 
  > ---
  > 
  > ## Blocking Issues
  > 
  > None.
  > 
  > The implementation:
  > - Delivers the stated goal (shared app-like shell across member surfaces).
  > - Passes dev check completely (85 scenarios, 523 steps, all green).
  > - Has comprehensive automated coverage (layout unit tests, integration tests for all six surfaces, design-system conformance tests).
  > - Includes no out-of-scope work.
  > - Respects the plan's technical decisions (CSS porting strategy, optional `member_name` assign, identity dropdown gating).
  > 
  > ---
  > 
  > ## Bounded-Safe Fixes
  > 
  > None identified.
  > 
  > The code is clean, follows conventions, and is well-factored. Variable names are clear, test descriptions are precise, and the separation of concerns is sound. No mechanical refactoring opportunities detected.
  > 
  > ---
  > 
  > ## Judgement-Worthy Non-Blocking Code-Health Findings
  > 
  > ### 1. Identity Dropdown: Accessibility Enhancement Opportunity
  > 
  > **Files:** `lib/memba_web/components/layouts.ex`
  > 
  > **Smell:** The identity dropdown has basic accessibility (semantic elements, `aria-label`), but could be enhanced with fuller ARIA menu semantics (`role="menu"`, `aria-expanded`, `aria-haspopup`) and keyboard focus management (Escape key handling, focus trapping).
  > 
  > **Why it may need human judgement:** This is a product/UX decision about how far to invest in accessibility patterns for a simple toggle dropdown. The current implementation works and has no accessibility violations per se, but a staff product decision might prioritize fuller ARIA support or keyboard navigation for compliance/usability goals. The technical lift is small (a few attributes and a JS hook), but the priority call is a human judgement.
  > 
  > **Current state:** The dropdown uses LiveView's `JS.toggle()` and `JS.hide()` commands, semantic `<button>` and `<form>` elements, an `aria-label` on the toggle button, and a CSRF token in the sign-out form. The inline `style="display: none;"` is standard LiveView initial-state practice.
  > 
  > ---
  > 
  > ## Validation Notes
  > 
  > ### Automated Coverage
  > 
  > - **Layout unit tests** (`test/memba_web/components/layouts_test.exs`): app-bar rendering, identity dropdown gating, sign-out link behaviour, app-card wrapping, `initials/1` helper (empty, single-word, multi-word cases).
  > - **Integration test** (`test/memba_web/club_site_shell_integration_test.exs`): all six club_site surfaces render (club home, conversation, compose, invitation, public club page); shared design-system components called; no hardcoded hex colors; no legacy club-site theming; no legacy Tailwind color utilities.
  > - **Dev check:** 85 scenarios passed, 523 steps passed, no failures.
  > - **Feature files:** unchanged (acceptance criteria unchanged).
  > 
  > ### Design-System Conformance
  > 
  > The integration test explicitly enforces that member pages render required design-system components:
  > 
  > ```elixir
  > @expected_component_usage [
  >   {"MembaWeb.Layouts.club_site", :club_site,
  >    ["app-frame", "app-bar", "app-bar-content", "app-bar-title", "app-card", "app-foot"]},
  >   # ... (club home, conversation, compose, invitation, public club)
  > ]
  > ```
  > 
  > And checks that member page sources contain no design-drift violations (hardcoded colors, legacy theming, legacy Tailwind palettes). This is a strong automated guard against future drift.
  > 
  > ### Security
  > 
  > - CSRF token present in the sign-out form.
  > - No user-controlled data rendered without escaping (`<%= %>` handles HEEx escaping).
  > - No obvious injection vectors.
  > 
  > ### Plan Fidelity
  > 
  > - **Goal:** shared app-like shell across member surfaces → **delivered** (app-bar + app-card wrapping all six surfaces).
  > - **CSS porting:** design-system component classes ported verbatim → **confirmed** (CSS comments acknowledge source; class names match 1:1).
  > - **Identity dropdown:** optional `member_name` assign, gated on presence → **confirmed** (layout uses `assigns[:member_name]` guard; LiveViews pass `member_name: member.name`; public page omits it).
  > - **Initials helper:** `Layouts.initials/1` extracts first letter(s) → **confirmed** (implementation splits on whitespace, uppercases, takes first two).
  > - **Validation:** `dev check` green + gallery-walk comparison → **dev check passed**; gallery-walk comparison not shown but plan step 13 is manual/human-validated.
  > 
  > ---
  > 
  > ## Summary
  > 
  > This is a high-quality, plan-conforming implementation. The code is clean, well-tested, respects design-system authority, and introduces a maintainable shell pattern. The single non-blocking code-health note (accessibility enhancement opportunity for the identity dropdown) is a product/UX judgement call, not a code defect.
  > 
  > **Recommendation:** Merge. The implementation delivers the stated capability with no blocking issues and strong automated guards against future drift.

## Stage: codex_review
- Status: succeeded
- Handler: prompt
- Model: gpt-5.5
- Tokens: 6.0k in / 2.5k out
- Response:
  > # Iteration 044 Review Report
  > 
  > - **Decision:** ACCEPT
  > - **Confidence:** High
  > - **ADR conformance:** PASS
  > 
  > ## ADR violations
  > 
  > None.
  > 
  > The touched implementation is in the Phoenix web/layout/CSS/test layer. No domain modeling, Commanded aggregate, projection, event stream, read-model, or CQRS infrastructure changes appear implicated. The implementation follows the governing design-system decision from the plan: port shared app-shell component classes from the design mirror rather than locally re-expressing the shell in Tailwind utilities.
  > 
  > ## Blocking issues
  > 
  > None.
  > 
  > The implementation appears plan-conforming, avoids obvious out-of-scope behaviour, and passed the automated feedback loop.
  > 
  > ## Bounded-safe fixes
  > 
  > None required before merge.
  > 
  > I did not identify a concrete low-risk refactor that is clearly worth applying immediately without product/design judgement.
  > 
  > ## Judgement-worthy non-blocking code-health findings
  > 
  > 1. **Identity dropdown accessibility could be strengthened**
  > 
  >    - **Files:** `lib/memba_web/components/layouts.ex`
  >    - **Smell:** The dropdown appears to use a normal button plus LiveView JS show/hide behaviour and has basic labelling, but fuller dropdown/menu accessibility patterns may not yet be present: e.g. `aria-expanded`, `aria-haspopup`, explicit menu/menuitem semantics where appropriate, Escape-key behaviour, and predictable focus handling.
  >    - **Why it may need human judgement:** This is not necessarily a blocker for this slice, especially if the UI is visually and behaviourally correct, but accessibility expectations for authenticated navigation controls should be decided deliberately. Adding richer ARIA/focus behaviour may be small technically, but the desired interaction model belongs with product/design standards.
  > 
  > 2. **Static source-scanning tests are useful but somewhat brittle**
  > 
  >    - **Files:** `test/memba_web/club_site_shell_integration_test.exs`
  >    - **Smell:** The design-conformance tests inspect source text for required class/component usage and forbidden legacy styling patterns. This is valuable as a drift guard, but source-text assertions can fail on harmless refactors, formatting changes, component extraction, or alternate-but-equivalent HEEx structure.
  >    - **Why it may need human judgement:** The brittleness may be acceptable here because the iteration explicitly wants to lock the shared shell to design-system classes. Longer term, the team may want to decide whether these checks should remain source-level, move toward rendered-DOM assertions, or be supplemented by a more direct design-system/CSS sync check.
  > 
  > 3. **Manual visual parity remains a human validation concern**
  > 
  >    - **Files:** `web/assets/css/app.css`, `lib/memba_web/components/layouts.ex`, affected LiveViews/templates using `club_site`
  >    - **Smell:** The plan’s design intent depends on visual fidelity to `design-system/wireframes/club-home.html` and `member-conversation.html`. Automated tests confirm rendering, class usage, and lack of legacy styling, but they do not fully prove pixel/layout parity.
  >    - **Why it may need human judgement:** This is inherent to a UI shell slice. If `gallery-walk` comparison was performed during implementation, this is satisfied. If not, product/design review should still spot-check the club home and conversation pages, but this does not block the code review given the green automated pass and plan-conformance gate.
  > 
  > ## Suggested fixes
  > 
  > None required for acceptance.
  > 
  > Optional follow-ups if the team chooses:
  > 
  > - Add richer ARIA/focus behaviour to the identity dropdown.
  > - Revisit whether source-scanning design-conformance tests should be complemented by rendered-DOM assertions.
  > - Continue using gallery screenshots as the visual parity feedback loop for app-shell changes.
  > 
  > ## Validation notes
  > 
  > - `dev ci` / dev check completed successfully.
  > - Acceptance suite passed: **85 scenarios, 523 steps**.
  > - Working tree was clean at review preflight.
  > - Feature files appear unchanged, preserving existing acceptance criteria.
  > - Automated coverage described in the implementation evidence includes:
  >   - shared `club_site` shell rendering,
  >   - app-bar/app-card/app-foot presence,
  >   - identity dropdown gating,
  >   - sign-out form behaviour,
  >   - `Layouts.initials/1` helper coverage,
  >   - all relevant `club_site` surfaces still rendering,
  >   - checks against hardcoded colours, legacy club-site theme variables, and legacy Tailwind palette utilities.
  > 
  > Overall, this is a clean, focused implementation of the shared app shell with strong automated coverage and no identified ADR or behavioural blockers.


You are independently reviewing the completed, plan-conforming implementation of the iteration plan at docs/iterations/044-shared-app-shell/plan.md.

Use the prior context: the plan text, collected implementation evidence, current working tree state, commit range from `e0fb9401c0e88b3388bf1a2f847acdb7be0b7e55..HEAD`, and the successful dev check output. Be strict, practical, and specific. Do not edit files.

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