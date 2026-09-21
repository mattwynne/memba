Goal: Review a completed plan-conforming iteration implementation for code polish, ADR conformance, and code-health signals
Run ID: 01M30SK3NT65YGJ6T9BGJ8TAKK
Pipeline progress: 6 of 29 stages completed

## Stage: read_plan
- Status: succeeded
- Handler: command
- Script: `PLAN_PATH='docs/iterations/063-add-custom-group-members/plan.md'
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
  (61 lines omitted)
  - `design-system/templates/club-group-members.html`: ordinary member rows, Add member action and picker.
  - `design-system/templates/club-group-non-member.html`: outside-admin Members view and Add yourself action.
  - `design-system/emails/group-welcome.html`: welcome email, with authenticated group link and no replay of old mail.
  - `design-system/explorations/custom-groups-prototype.html`: reviewed final interactions.
  
  Omit removal/leave controls until 064. Group Members shows Add member in the sole contextual tab action position. Outside admin sees no Conversations or New message until actually added; Add yourself is explained as opting into history and emails. Use normal member rows even for one member. No invented joined dates or group-admin badges. Keep club invitation flow separate; custom-group Add member does not create people. Local designs are sufficient; cloud sync remains pending.
  
  ## Acceptance Criteria
  
  - Every active group member can add another active member of that club, regardless of their club-admin role.
  - Any active club admin can manage additions in any custom group, including self-add, without reading conversations or joining as a side effect of adding someone else.
  - A regular club member outside the group cannot self-add, add another person or use a forged action to bypass the rule.
  - Pending invitees, former members and members of another club are not eligible. The action never creates or restores club membership.
  - New membership gives the whole history and write participation immediately; the welcome email links to the authenticated group page. Old conversation emails are not resent.
  - Repeating an already-applied addition does not create another membership transition or repeat its welcome. A genuine later re-add sends a new welcome but does not restore old follows cleared on departure.
  - Everyone and Admin retain automatic/role-based membership. The custom-group API cannot grant a club-admin role or bypass system-group rules.
  - Existing group recipients exclude nonmember admins; additions and permissions refresh in open views.
  
  ## Open Business Decisions
  
  None known. Deliver the welcome to the member's existing verified primary email; use the existing provider-neutral mailer/sender conventions and group-branded content. No new preferences or special delivery-status screen is introduced.
  
  ## Implementation Plan
  
  1. Add a public authenticated custom-group admission use case and actor-bearing command handled by `Membership.Club`. Evaluate actor active club membership, actor group membership or existing admin permission, target active membership and custom-group identity against current aggregate state. Preserve trusted system-group commands rather than exposing them directly to web callers.
  2. Reuse `GroupMemberAdded` and the existing projection. Make duplicate addition an idempotent no-op and carry sufficient actor/new-transition information for the welcome use case. Respect the departure/rejoin cleanup introduced in 062; no projection-only mutation or restoration shortcut.
  3. Extend `MemberDashboardPresentation`, shared member components and the group Members surface with the picker and admin self-add. Use explicit component attributes/slots, not a copied full-page template. Query candidates through Membership's public API, reauthorize on submit and render fresh membership after a successful transition.
  4. Add a small provider-neutral group-welcome composer using `Memba.EmailTemplates` and the existing `Memba.Mailer` handoff conventions. Send only after a confirmed new membership transition, not on projection replay, duplicate requests or ordinary group reads. Keep provider side effects out of aggregates/projectors; committed membership must not be represented as rolled back if delivery fails. Reuse default operational/error handling; do not build a notification framework, bespoke retry UI or delivery-status feature.
  5. Implement the tagged admission/history scenarios, including outside-admin self-add, duplicate additions, inactive/cross-club targets and system-group bypass attempts. Test replay does not resend welcomes, already-open views update, and existing invitation/role behaviour is unchanged. Run `dev check` on the exact delivery state.
  
  ## Open Technical Decisions
  
  No new aggregate is needed. Use explicit per-use-case command results or new-event metadata to distinguish a new addition from an idempotent no-op; never infer that distinction by racing a projection preflight. Use the existing mailer abstraction and primary-email API instead of a new provider dependency. The welcome route is a normal group URL requiring sign-in, not a token granting membership.
  
  ## New Capability
  
  A group can grow through its own members without involving a club admin; an admin can join or populate it explicitly without gaining hidden access beforehand.
  
  ## Validation Plan
  
  - Planning parser and runner-debt checks; stakeholder review completed during discovery and prototype review.
  - Aggregate tests for actor/target/club identity, current permission, duplicates and concurrent changes.
  - Membership/Messaging integration for history and normal email eligibility with no replay of historic conversation emails.
  - Mailer tests for content, recipient, group link, a new transition versus duplicate/replay, using the test adapter rather than real email.
  - Browser demo: Bob adds Carol; Dan adds Eve without joining; Dan adds himself; ordinary outsider cannot add anyone; role/system regressions.
  - Both Cucumber runners and full `dev check` on the final delivery state.
  
  ## Risks / Follow-ups
  
  The raw group commands currently serve trusted policies/backfills and are not a safe web authorization API. Do not expose them unchanged. Welcome delivery cannot undo membership: avoid conflating domain success and provider outcome. Leave/removal and their controls are intentionally deferred to 064; club-departure safety already exists from 062.
  ```

## Stage: preflight_sandbox
- Status: succeeded
- Handler: command
- Script: `bash .fabro/workflows/iteration-review/scripts/preflight_sandbox.sh`
- Output:
  ```
  (391 lines omitted)
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
  (3708 lines omitted)
  
    Rule: Staff-edited slugs must already be address-safe
  
      Scenario: Staff enter an invalid slug # features/staff_club_slugs.feature:17
  [acceptance 2026-09-21T02:01:41.949Z] scenario start: Staff enter an invalid slug
  [acceptance 2026-09-21T02:01:41.981Z] scenario reset app state: Staff enter an invalid slug
        Given Pat is signed in as Memba staff
  [acceptance 2026-09-21T02:01:43.196Z] slow step: Staff enter an invalid slug :: Pat is signed in as Memba staff :: 1141ms
        Given Kootenay Mountaineering Club is a club
        When Pat tries to change Kootenay Mountaineering Club's slug to "kmc club!"
        Then Memba should reject the club slug as invalid
        And Kootenay Mountaineering Club should keep its previous slug
  [acceptance 2026-09-21T02:01:44.553Z] scenario teardown start: Staff enter an invalid slug status=PASSED
  [acceptance 2026-09-21T02:01:44.558Z] scenario finish: Staff enter an invalid slug status=PASSED duration=2610ms
  
    Rule: A slug can belong to only one club
  
      Scenario: Staff enter a slug that another club already uses # features/staff_club_slugs.feature:25
  [acceptance 2026-09-21T02:01:44.559Z] scenario start: Staff enter a slug that another club already uses
  [acceptance 2026-09-21T02:01:44.595Z] scenario reset app state: Staff enter a slug that another club already uses
        Given Pat is signed in as Memba staff
  [acceptance 2026-09-21T02:01:45.800Z] slow step: Staff enter a slug that another club already uses :: Pat is signed in as Memba staff :: 1134ms
        Given Kootenay Mountaineering Club has the slug "kmc"
        And Nelson Paddling Club is a club
        When Pat tries to change Nelson Paddling Club's slug to "kmc"
        Then Memba should reject the club slug as already taken
        And Nelson Paddling Club should keep its previous slug
  [acceptance 2026-09-21T02:01:47.565Z] scenario teardown start: Staff enter a slug that another club already uses status=PASSED
  [acceptance 2026-09-21T02:01:47.569Z] scenario finish: Staff enter a slug that another club already uses status=PASSED duration=3010ms
  
    Rule: A club slug routes public visitors to that club's public page
  
      @not-domain
      Scenario: Robin opens an unknown club subdomain # features/staff_club_slugs.feature:35
  [acceptance 2026-09-21T02:01:47.570Z] scenario start: Robin opens an unknown club subdomain
  [acceptance 2026-09-21T02:01:47.602Z] scenario reset app state: Robin opens an unknown club subdomain
        Given Pat is signed in as Memba staff
  [acceptance 2026-09-21T02:01:48.784Z] slow step: Robin opens an unknown club subdomain :: Pat is signed in as Memba staff :: 1109ms
        When Robin opens "unknown.clubs.memba.io"
        Then Robin should see a not found page
  [acceptance 2026-09-21T02:01:48.843Z] scenario teardown start: Robin opens an unknown club subdomain status=PASSED
  [acceptance 2026-09-21T02:01:48.849Z] scenario finish: Robin opens an unknown club subdomain status=PASSED duration=1279ms
  
  [acceptance 2026-09-21T02:01:48.850Z] AfterAll: closing shared browser
  [acceptance 2026-09-21T02:01:48.876Z] AfterAll: closed shared browser
  [acceptance 2026-09-21T02:01:48.876Z] AfterAll: stopping Phoenix browser acceptance lifecycle
  [acceptance 2026-09-21T02:01:48.877Z] AfterAll: stopped Phoenix browser acceptance lifecycle
  189 scenarios (189 passed)
  1415 steps (1415 passed)
  19m20.007s (executing steps: 19m05.748s)
  ```

## Stage: collect_implementation_evidence
- Status: succeeded
- Handler: command
- Script: `bash .fabro/workflows/iteration-review/scripts/collect_implementation_evidence.sh '91edff41b9732c09f3d37ed00d8414696ddc5565'`
- Output:
  ```
  (6149 lines omitted)
               )
  
      assert Enum.map(assigns.messages, & &1.message_id) == [everyone_conversation.message_id]
      refute Enum.any?(assigns.messages, &(&1.message_id == admin_conversation.message_id))
    end
  
    test "authorizes and presents member and conversation rows for a selected group" do
      alice =
        create_active_member(
          email: "alice@example.com",
          name: "Alice Adams",
          club_name: "Alpine Club"
        )
  
      bob =
        create_active_member(
          email: "bob@example.com",
          name: "Bob Builder",
          club_name: "Alpine Club",
          club_id: alice.club_id
        )
  
  === web/test/memba_web/membership_command_boundary_test.exs ===
  defmodule MembaWeb.MembershipCommandBoundaryTest do
    use ExUnit.Case, async: true
  
    @web_source_root Path.expand("../../lib/memba_web", __DIR__)
  
    @internal_membership_references [
      "Memba.Membership.Commands.AddGroupMember",
      "Memba.Membership.Commands.CreateGroup",
      "Memba.Membership.Commands.RemoveGroupMember"
    ]
  
    test "web delivery does not bypass the public Membership command boundary" do
      @web_source_root
      |> Path.join("**/*.ex")
      |> Path.wildcard()
      |> Enum.each(fn path ->
        source = File.read!(path)
        relative_path = Path.relative_to(path, @web_source_root)
  
        Enum.each(@internal_membership_references, fn internal_reference ->
          refute source =~ internal_reference,
                 "#{relative_path} must use the public Memba.Membership API, " <>
                   "not #{internal_reference}"
        end)
      end)
    end
  end
  ```

## Stage: review_fork
- Status: partially_succeeded
- Handler: parallel
- Notes: Parallel node dispatched 3 branches (2 succeeded, 1 failed)

## Stage: review_merge
- Status: succeeded
- Handler: parallel.fan_in
- Notes: Joined 3 parallel branches

## Current context
| Key | Value |
|-----|-------|
| parallel.branch_count | 3 |
| parallel.results | [{"id":"claude_review","index":0,"status":"failed","context_updates":{}},{"id":"codex_review","index":1,"status":"succeeded","context_updates":{"last_response":"# Iteration Review\n\n- **Decision:** ACCEPT\n- **Confidence:** Medium\n- **ADR conformance:** PASS\n\n## ADR violations\n\nNone identified. The implementation evidence is consistent with the accepted archite","last_stage":"codex_review","response.codex_review":"# Iteration Review\n\n- **Decision:** ACCEPT\n- **Confidence:** Medium\n- **ADR conformance:** PASS\n\n## ADR violations\n\nNone identified. The implementation evidence is consistent with the accepted architectural direction for the touched area:\n\n- Membership changes remain command-driven rather than mutating projections directly.\n- The existing `GroupMemberAdded` event and projection path are reused.\n- Authorization is evaluated through the Membership domain boundary rather than in LiveView alone.\n- Email delivery is downstream of a confirmed new transition rather than aggregate or projector behavior.\n- Web code is explicitly prevented from referencing the trusted internal membership commands directly.\n\n## Blocking issues\n\nNone identified.\n\nThe successful `dev ci` run, including all 189 browser acceptance scenarios, provides substantial behavioral coverage. No evidence indicates an omitted acceptance criterion, unsafe authorization path, event-sourcing violation, or welcome-email replay issue requiring another implementation pass.\n\n## Bounded-safe fixes\n\n1. **Strengthen the web-to-domain boundary test**\n   - **File:** `web/test/memba_web/membership_command_boundary_test.exs`\n   - The test searches source text for three fully qualified command module names. It can be bypassed unintentionally through aliases, shortened module references, dynamic module construction, or a newly added internal command omitted from the hard-coded list.\n   - This does not show that the current implementation bypasses the boundary, but the guard provides less protection than its name suggests.\n\n## Judgement-worthy non-blocking code-health findings\n\n1. **Architecture enforcement is based on a command denylist**\n   - **File:** `web/test/memba_web/membership_command_boundary_test.exs`\n   - **Smell:** The test enumerates selected internal commands rather than expressing the broader rule that web delivery must not depend on `Memba.Membership.Commands`.\n   - **Why judgement may be needed:** A namespace-wide rule would be more durable, but the team may prefer narrow checks where trusted commands are intentionally used by other delivery mechanisms. This is architectural-test strategy rather than a product correctness problem.\n\n2. **Boundary enforcement uses raw source matching**\n   - **File:** `web/test/memba_web/membership_command_boundary_test.exs`\n   - **Smell:** Comments, strings, formatting, and alias choices can affect the result without changing actual module dependencies.\n   - **Why judgement may be needed:** Moving to AST-based inspection or a project-wide dependency checker adds complexity. The current lightweight check may be considered sufficient when paired with review discipline.\n\n## Suggested fixes\n\nFor the bounded-safe test improvement:\n\n1. Replace the three-command denylist with a check for dependencies on the internal `Memba.Membership.Commands` namespace from `lib/memba_web`.\n2. Prefer parsed Elixir AST over unrestricted source substring matching, so comments and string literals do not trigger the rule and aliased command references cannot evade it.\n3. If AST inspection is considered excessive, retain the lightweight test but:\n   - detect `alias Memba.Membership.Commands`;\n   - detect the namespace generally rather than individual commands; and\n   - document any intentional exceptions explicitly.\n\nThis can be handled as follow-up polish and does not need to block the iteration.\n\n## Validation notes\n\n- The sandbox runtime preflight passed.\n- `dev ci` completed successfully.\n- Browser acceptance suite result: **189 scenarios passed, 1415 steps passed**.\n- The reviewed evidence includes tests around the public Membership command boundary and integration/presentation behavior.\n- The implementation follows the plan’s key responsibility boundaries: commands and aggregates determine membership transitions, projections represent committed state, and welcome delivery is a post-transition integration concern.\n- No file changes were made during this review."}},{"id":"gemini_review","index":2,"status":"succeeded","context_updates":{"last_response":"# Implementation Review Report\n\n- **Decision**: ACCEPT\n- **Confidence**: Medium (Based on successful CI logs, full acceptance test pass, and limited/truncated implementation evidence).\n- **ADR conform","last_stage":"gemini_review","response.gemini_review":"# Implementation Review Report\n\n- **Decision**: ACCEPT\n- **Confidence**: Medium (Based on successful CI logs, full acceptance test pass, and limited/truncated implementation evidence).\n- **ADR conformance**: PASS\n\n### ADR violations\nNone observed. The implementation actively protects the command boundary as mandated by the architectural guidelines, ensuring the web layer does not directly dispatch internal commands.\n\n### Blocking issues\nNone.\n\n### Bounded-safe fixes\nNone required.\n\n### Judgement-worthy non-blocking code-health findings\n1. **Source-based architectural boundary checking (`web/test/memba_web/membership_command_boundary_test.exs`)**: \n   The test enforces the iteration plan's requirement (\"Preserve trusted system-group commands rather than exposing them directly to web callers\") by reading `**/*.ex` files and performing string matching (`=~`). While this is a practical and pragmatic way to prevent direct command usage in the web layer for this iteration, it is structurally brittle. It can be bypassed using module aliases (`alias Memba.Membership.Commands.AddGroupMember, as: AddMember`), and it risks false positives if the module names are merely mentioned in code comments. \n   *Why it may need human judgement*: In the future, as the application scales, relying on `mix xref graph` or custom Elixir compiler tracers is a much more robust, AST-aware method for enforcing contextual boundaries and preventing cross-domain coupling.\n\n### Suggested fixes\nNo fixes are strictly necessary for this merge since the existing boundary check accomplishes the immediate goal securely. \n\n### Validation notes\n- **CI / Pipeline**: `dev check` passed successfully. All 189 scenarios (1415 steps) executed and passed (duration: 19m20s), confirming that the club membership, system-group behaviour, and outside-admin custom group features maintain system integrity.\n- **Preflight Sandbox**: The sandbox runtime check compiled all expected apps (`commanded`, `bandit`, `phoenix_live_view`, etc.) cleanly without compilation warnings blocking the pipeline.\n- **Design Alignment**: The provided test snippet explicitly proves that the implementation fulfills the technical requirement to insulate raw aggregate commands from the web delivery mechanism, correctly routing requests through the `Memba.Membership` public API."}}] |


Synthesize the independent implementation reviews for docs/iterations/063-add-custom-group-members/plan.md.

This review runs after implementation has already merged to `main`. It is a smell radar and bounded polish loop, not a delivery gate. Decide whether there are bounded fixes the workflow should attempt now, or whether remaining findings should be logged for human judgement in `docs/code-health.md` while the run continues.

## Context

Use the prior context from this workflow run:

- The iteration plan text and its explicit requirements.
- Implementation evidence collected from `91edff41b9732c09f3d37ed00d8414696ddc5565` to `HEAD`.
- Successful `dev check` output.
- The merged parallel fan-in evidence in `parallel.results` from the Claude Review (`claude_review`), Sol Review (`codex_review`), and Gemini Review (`gemini_review`) branches.
- Previous synthesis decisions and repair summaries, if this is a repeated synthesis after repair.

The reviewer stages fan out independently and then fan in before this stage. In the merged context, inspect `parallel.results` explicitly. Each required branch must expose a completed outcome and the substantive Markdown response for that reviewer. Do not assume branch responses or routing fields are promoted to top-level context.

Fail closed if you cannot see usable, substantive reviewer evidence for all three required branches in `parallel.results`. Branch status metadata, head SHAs, empty strings, or tool-call-looking JSON without an actual review report are not usable reviewer evidence. Missing reviewer evidence is a workflow/tooling failure, not proof that the implementation is acceptable and not a product-code fix.

If any required reviewer evidence is missing or unusable, do not route **ACCEPTED** and do not route **FIX**. Return an infrastructure-failure synthesis that names the missing/unusable branch evidence and end with routing JSON that sets the stage outcome to failed, for example: `{"outcome":"failed","failure_reason":"parallel fan-in did not expose usable review evidence for every required reviewer"}`. This must route to the workflow's review-synthesis-unavailable failure path.

Do not emit shell-command/tool-call JSON; return the Markdown synthesis and final routing JSON only.

## Standards

- Treat accepted ADRs as binding. Use `docs/reference/domain-driven-design.md`, `docs/reference/cqrs.md`, `docs/reference/event-sourcing.md`, and `docs/reference/responsibility-driven-design.md` as the design-quality guidelines for domain modeling, Commanded/CQRS, event streams/projections, aggregates, and responsibility/collaboration boundaries. They guide interpretation of ADRs and code-health findings; they do not override an accepted ADR or iteration plan.
- Treat automated tests and implementation plan-conformance as already-owned by the implementation workflow.
- Prefer automatic improvement over deferral. Request automatic fixes for every concrete, bounded refactoring, maintainability, project-convention, documentation, security-hardening, data-integrity-hardening, or low-risk test-quality issue that can be resolved without changing acceptance feature files or making a new product decision.
- Verification findings are often auto-fixable: if reviewers are unsure whether an implemented rule is truly wired, reused, or protected, route **FIX** when the workflow can add/strengthen targeted automated tests, assertions, constraints, or code comments to prove the existing intended behaviour.
- Examples of normally bounded automatic fixes: normalizing inputs before duplicate checks, adding HTML form attributes that match existing validation, adding double-submit protection where the project has an established pattern, adding/strengthening domain/web tests for planned behaviour, adding database constraints that enforce an already-existing invariant, replacing duplicated implementation with an existing shared service, and documenting a non-obvious shared path in code.
- Do not request edits to acceptance feature files (`*.feature`).
- Do not introduce new product behaviour in review; hardening is allowed when it enforces or proves behaviour already required by the iteration plan.
- Mark a finding as code-health/manual only when it needs external/manual verification that cannot be represented by an automated test, requires a product/architecture/scope decision, is too large or risky for the review repair budget, or a prior automatic repair attempted the same issue and it still remains.
- If any reviewer lists judgement-worthy non-blocking code-health findings, preserve them in the `Code-health findings for human judgement` section even when the final decision is **ACCEPTED**.
- If any reviewer lists bounded-safe fixes or hardening ideas, either route **FIX** with exact bounded changes, or explicitly explain why each proposed fix is not auto-fixable under these rules. Do not silently defer useful hardening.
- If no bounded automatic fixes are worth attempting, accept the review and let the next step record any judgement-worthy findings in `docs/code-health.md`.

## Output format

Return a concise Markdown synthesis with these sections:

### Decision

One of: **ACCEPTED**, **FIX**, or **INFRASTRUCTURE FAILURE**. Use **INFRASTRUCTURE FAILURE** only when the required reviewer evidence in `parallel.results` is missing or unusable.

### Evidence preflight

List Claude Review, Sol Review, and Gemini Review. For each, state whether usable substantive evidence was present in `parallel.results`. If any are missing or unusable, stop the synthesis after this section and route the stage outcome to failed.

### Review synthesis

Summarize the important findings across reviewers.

### Finding disposition

Account for each substantive reviewer finding as one of: auto-fix now, record for human judgement, dismissed as unsupported, duplicate/already fixed.

### Bounded automatic fixes

If **FIX**, list exact bounded changes to make, with constraints and validation. Include test/constraint/documentation-only fixes when they are the safest way to make an uncertainty visible and enforceable.

### Code-health findings for human judgement

List findings that should be logged to `docs/code-health.md` because they are not safe bounded review fixes. If none, state "None."

### Fixed or dismissed findings

Note findings that were already fixed during this review run, duplicates, or findings you are dismissing as not supported by evidence.

## Routing JSON

End your response with exactly one JSON object that Fabro can use for routing. The JSON object must be the final text in the response and must not be wrapped in a Markdown code fence.

Use one of these shapes:

- Accepted / log-only findings:
  `{"context_updates":{"implementation_accepted":true,"review_fixes_available":false}}`
- Automatic fixes appropriate:
  `{"context_updates":{"implementation_accepted":false,"review_fixes_available":true,"review_blockers":[{"id":"fix-id-1","title":"Short fix title","source":"review_synthesis","first_seen_stage":"synthesize_review","status":"open"}]}}`
- Infrastructure/tooling failure because required merged review evidence is missing or unusable:
  `{"outcome":"failed","failure_reason":"parallel fan-in did not expose usable review evidence for every required reviewer"}`

Do not route to human input from this post-merge review. Human-judgement findings belong in the Markdown section above so the next step can record them in `docs/code-health.md`.