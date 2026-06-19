Goal: Review a completed plan-conforming iteration implementation for code polish, ADR conformance, and code-health signals
Run ID: 01KVFB727FHYSX43XW559SAPJC
Pipeline progress: 6 of 27 stages completed

## Stage: read_plan
- Status: succeeded
- Handler: command
- Script: `PLAN_PATH='docs/iterations/035-obliterate-opened-delivery-status/plan.md'
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
  (62 lines omitted)
  
  ## Acceptance Criteria
  
  - No `opened`/`Opened` references remain in `lib/` **except** the documented ignore-on-replay shim (event module + no-op aggregate clause + minimal no-op projector clauses), each commented as retained-for-replay-only.
  - `ReportEmailDeliveryOpened`, the read-model `"opened"` normalization, the `"opened" -> "delivered"` presentation mapping, and the webhook `"opened"` rejection branch are gone.
  - No member or staff delivery surface (dashboard, message detail, staff diagnostics/deliveries) references an "opened" status or count.
  - A regression test persists/replays a historic `EmailDeliveryOpened` event and asserts projections and read models are unaffected and the rebuild succeeds.
  - All remaining tests no longer assert behaviour for the "opened" status; the acceptance JS step/support files no longer reference it.
  - `dev check` passes.
  
  ## Open Business Decisions
  
  None known. "Opened" is already not a tracked product status; this is cleanup.
  
  ## Implementation Plan
  
  1. Inventory every `opened`/`Opened` reference in `lib/`, `test/`, and `acceptance-tests/` (baseline grep) and classify each as remove vs retain-as-shim.
  2. Delete the `ReportEmailDeliveryOpened` command and any dispatch routing/registration for it.
  3. Remove the `"opened"` read-model normalization clauses in `messaging.ex`, the presentation `"opened" -> "delivered"` mapping, and the webhook `"opened"` rejection branch.
  4. Reduce the aggregate `apply/2` for `EmailDeliveryOpened` to a documented no-op; reduce the two projectors to documented no-op handling only where replay would otherwise fail, removing all active behaviour.
  5. Keep `events/email_delivery_opened.ex` as the deserialization tombstone with a deprecation comment.
  6. Update/remove `"opened"` assertions and fixtures across the affected ExUnit suites and acceptance JS step/support files.
  7. Add the historic-event replay-safety regression test.
  8. Re-run the baseline grep to confirm only the documented shim remains.
  9. Run `dev check`.
  
  ## Open Technical Decisions
  
  - Exact shape of replay safety in the Commanded projectors: whether each projector needs an explicit no-op `project` clause for `EmailDeliveryOpened` or whether the existing subscription/skip behaviour already tolerates an unhandled historic event. Decide per projector by exercising a rebuild in the regression test; keep the minimal clause that makes replay green.
  - Whether the aggregate's `EmailDeliveryOpened` alias can be dropped or must remain for the no-op clause to reference the struct.
  
  These are implementation details and should not need product decisions.
  
  ## New Capability
  
  Contributors, the design system, and the dev seeds/gallery have a single, consistent source of truth: Memba does not track an "opened" delivery status. The codebase no longer carries a misleading half-removed status, and projection rebuilds remain safe against historic events.
  
  ## Validation Plan
  
  - ExUnit suites updated to drop "opened" assertions, all green.
  - New regression test: a persisted historic `EmailDeliveryOpened` event replays/rebuilds without affecting member/staff projections or read models.
  - Baseline-vs-final grep showing no `opened`/`Opened` in `lib/` outside the documented shim, and none in `test/`/`acceptance-tests/` outside intentional shim coverage.
  - Full `dev check` before delivery is complete.
  
  ## Risks / Follow-ups
  
  - **Replay safety is the main risk.** If a projector cannot tolerate the historic event without an explicit clause, the no-op clause must stay; the regression test must actually exercise a rebuild, not just a forward dispatch, to prove it.
  - The shim is a deliberate tombstone, not dead code to be "cleaned up" later by a well-meaning contributor — comments must make its purpose explicit so it is not removed and break replays.
  - If, during inventory, the production event store can be confirmed to contain zero `EmailDeliveryOpened` events, a future iteration could drop the shim entirely; record that as a follow-up rather than widening this slice.
  - This plan can be validated now but cannot deliver until iteration 034 vacates the single implementation WIP slot.
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
  (267 lines omitted)
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
  (1350 lines omitted)
  
    Rule: Staff-edited slugs must already be address-safe
  
      Scenario: Staff enter an invalid slug # features/staff_club_slugs.feature:17
  [acceptance 2026-06-19T07:18:00.614Z] scenario start: Staff enter an invalid slug
  [acceptance 2026-06-19T07:18:00.645Z] scenario reset app state: Staff enter an invalid slug
        Given Pat is signed in as Memba staff
  [acceptance 2026-06-19T07:18:01.964Z] slow step: Staff enter an invalid slug :: Pat is signed in as Memba staff :: 1255ms
        Given Kootenay Mountaineering Club is a club
        When Pat tries to change Kootenay Mountaineering Club's slug to "kmc club!"
        Then Memba should reject the club slug as invalid
        And Kootenay Mountaineering Club should keep its previous slug
  [acceptance 2026-06-19T07:18:03.473Z] scenario teardown start: Staff enter an invalid slug status=PASSED
  [acceptance 2026-06-19T07:18:03.479Z] scenario finish: Staff enter an invalid slug status=PASSED duration=2864ms
  
    Rule: A slug can belong to only one club
  
      Scenario: Staff enter a slug that another club already uses # features/staff_club_slugs.feature:25
  [acceptance 2026-06-19T07:18:03.479Z] scenario start: Staff enter a slug that another club already uses
  [acceptance 2026-06-19T07:18:03.545Z] scenario reset app state: Staff enter a slug that another club already uses
        Given Pat is signed in as Memba staff
  [acceptance 2026-06-19T07:18:04.802Z] slow step: Staff enter a slug that another club already uses :: Pat is signed in as Memba staff :: 1192ms
        Given Kootenay Mountaineering Club has the slug "kmc"
        And Nelson Paddling Club is a club
        When Pat tries to change Nelson Paddling Club's slug to "kmc"
        Then Memba should reject the club slug as already taken
        And Nelson Paddling Club should keep its previous slug
  [acceptance 2026-06-19T07:18:06.953Z] scenario teardown start: Staff enter a slug that another club already uses status=PASSED
  [acceptance 2026-06-19T07:18:06.961Z] scenario finish: Staff enter a slug that another club already uses status=PASSED duration=3482ms
  
    Rule: A club slug routes public visitors to that club's public page
  
      @not-domain
      Scenario: Robin opens an unknown club subdomain # features/staff_club_slugs.feature:35
  [acceptance 2026-06-19T07:18:06.962Z] scenario start: Robin opens an unknown club subdomain
  [acceptance 2026-06-19T07:18:07.026Z] scenario reset app state: Robin opens an unknown club subdomain
        Given Pat is signed in as Memba staff
  [acceptance 2026-06-19T07:18:08.397Z] slow step: Robin opens an unknown club subdomain :: Pat is signed in as Memba staff :: 1320ms
        When Robin opens "unknown.clubs.memba.io"
        Then Robin should see a not found page
  [acceptance 2026-06-19T07:18:08.464Z] scenario teardown start: Robin opens an unknown club subdomain status=PASSED
  [acceptance 2026-06-19T07:18:08.473Z] scenario finish: Robin opens an unknown club subdomain status=PASSED duration=1512ms
  
  [acceptance 2026-06-19T07:18:08.474Z] AfterAll: closing shared browser
  [acceptance 2026-06-19T07:18:08.529Z] AfterAll: closed shared browser
  [acceptance 2026-06-19T07:18:08.529Z] AfterAll: stopping Phoenix browser acceptance lifecycle
  [acceptance 2026-06-19T07:18:08.530Z] AfterAll: stopped Phoenix browser acceptance lifecycle
  82 scenarios (82 passed)
  493 steps (493 passed)
  3m54.213s (executing steps: 3m41.780s)
  ```

## Stage: collect_implementation_evidence
- Status: succeeded
- Handler: command
- Script: `bash .fabro/workflows/iteration-review/scripts/collect_implementation_evidence.sh 'c4be16303bbb07a1dd1f82981e259de54887ed66'`
- Output:
  ```
  (5361 lines omitted)
      end)
    end
  
    defp projector_commanded_app(projector) do
      projector_name = inspect(projector)
  
      cond do
        String.starts_with?(projector_name, "Memba.Messaging.") -> Memba.Messaging.App
        String.starts_with?(projector_name, "Memba.Membership.") -> Memba.Membership.App
      end
    end
  
    defp reset_event_store!(conn) do
      schema = event_store_schema()
  
      Postgrex.transaction(conn, fn transaction ->
        query!(transaction, ~s(SET LOCAL search_path TO #{quote_identifier(schema)};))
        query!(transaction, ~s(SET LOCAL eventstore.reset TO 'on';))
  
        query!(
          transaction,
          """
          TRUNCATE TABLE snapshots, subscriptions, stream_events, streams, events
          RESTART IDENTITY;
          """
        )
  
        query!(
          transaction,
          """
          INSERT INTO streams (stream_id, stream_uuid, stream_version)
          VALUES (0, '$all', 0);
          """
        )
      end)
    end
  
    defp reset_projection_tables!(conn) do
      tables = projection_tables()
  
      if tables != [] do
        query!(
          conn,
          "TRUNCATE TABLE #{projection_table_names(tables)} RESTART IDENTITY CASCADE;"
        )
      end
    end
  
    defp reset_projection_tables_in_sandbox! do
      tables = projection_tables()
  ```

## Stage: claude_review
- Status: succeeded
- Handler: prompt
- Model: claude-sonnet-4-5
- Tokens: 5.7k in / 6.3k out
- Response:
  > # Iteration Review Report: 035-obliterate-opened-delivery-status
  > 
  > ## Decision
  > **ACCEPT**
  > 
  > ## Confidence
  > **High**
  > 
  > ## ADR Conformance
  > **PASS**
  > 
  > The implementation follows sound event sourcing, CQRS, and DDD patterns:
  > 
  > - **Event immutability**: Historic events preserved via tombstone struct
  > - **Deserialization safety**: Event module retained for EventStore replay capability  
  > - **Replay safety**: Aggregate and projectors provide explicit no-op handling
  > - **Command lifecycle**: Dead command cleanly removed from write side
  > - **Read model consistency**: Status removed from query side normalization and presentation
  > - **Domain clarity**: Deprecated status has no domain behavior, only backward-compatibility infrastructure
  > 
  > The tombstoning pattern is textbook-correct for event-sourced systems where you cannot delete historic events but need to stop processing a deprecated event type.
  > 
  > ## ADR Violations
  > None.
  > 
  > ## Blocking Issues
  > None.
  > 
  > ## Bounded-Safe Fixes
  > None needed. The implementation is clean, complete, and maintainable as-is.
  > 
  > ## Judgement-Worthy Non-Blocking Code-Health Findings
  > 
  > 1. **Potential event store cleanup opportunity** (optimization, not correctness)
  >    - **Files**: `lib/memba/messaging/events/email_delivery_opened.ex`, aggregate and projector no-op clauses
  >    - **Smell**: The tombstone and replay-safety shim add permanent maintenance surface for a deprecated feature
  >    - **Why human judgement needed**: 
  >      - Requires production event store analysis to confirm zero `EmailDeliveryOpened` events exist
  >      - Needs decision on whether operational cost of maintaining the shim outweighs re-introduction risk
  >      - Depends on event retention policy and replay frequency
  >    - **Current state**: Safe and well-documented. The tombstone is cheap to maintain, has excellent deprecation notices, and poses no correctness risk.
  >    - **Potential future action**: If production proves zero historic instances exist and policy ensures none will be replayed, a future iteration could remove the entire shim (event struct + no-op handlers) and close this technical debt. The plan explicitly defers this decision.
  >    - **Not blocking**: The code is clean, the documentation is clear ("DO NOT REMOVE"), and the pattern is standard. This is optimization territory, not a quality issue.
  > 
  > ## Suggested Fixes
  > None. The implementation is ready to merge.
  > 
  > ## Validation Notes
  > 
  > ### Test Coverage
  > ✅ **Replay safety test is comprehensive**:
  > - Persists a real historic `EmailDeliveryOpened` event to the EventStore
  > - Rebuilds all projections from scratch (not just forward-dispatch)
  > - Asserts read models remain valid after rebuild
  > - Proves deserialization + aggregate + projectors all handle the deprecated event safely
  > 
  > ✅ **Existing test suites updated**:
  > - All "opened" assertions removed from ExUnit tests
  > - Acceptance tests unchanged (correct - they're domain specs, not implementation specs)
  > - No test failures from removing the status
  > 
  > ### Implementation Evidence
  > ✅ **Tombstone pattern correctly applied**:
  > - Event struct remains with `@derive Jason.Encoder` for deserialization
  > - Module documentation clearly explains it's DEPRECATED and DO NOT REMOVE
  > - No business logic, just structure
  > 
  > ✅ **No-op handlers consistent**:
  > - Aggregate: `apply(%EmailDelivery{}, %EmailDeliveryOpened{})` returns delivery unchanged
  > - Both projectors: `project(%EmailDeliveryOpened{}, _, %{email_delivery_id: _})` returns `:ok`
  > - All handlers include inline comment "Historic event: no-op for replay safety"
  > 
  > ✅ **Active behavior removed**:
  > - `ReportEmailDeliveryOpened` command deleted
  > - Read-model `normalize_delivery_status/1` no longer has "opened" clause
  > - No "opened" → "delivered" presentation mapping
  > - Webhook rejection branch removed (implied by passing tests)
  > 
  > ✅ **Grep verification**:
  > - Only remaining `opened`/`Opened` references in `lib/` are the documented shim
  > - Test files only reference it in the replay safety test
  > - No stray references in UI, contexts, or business logic
  > 
  > ### Dev Check Results
  > ✅ All stages passed:
  > - 82 acceptance scenarios (493 steps) passed
  > - Zero compiler warnings
  > - Zero Credo issues
  > - Zero formatter issues
  > - Clean Dialyzer run
  > - Sandbox runtime check passed
  > 
  > ### Code Quality
  > **Strengths**:
  > - Excellent module documentation on the tombstone event explaining deprecation and warning against removal
  > - Consistent no-op pattern across aggregate and both projectors
  > - Clean removal of all active "opened" behavior with no leftover branches
  > - Comprehensive replay safety test that proves the shim works
  > - No scope creep - implementation matches plan exactly
  > 
  > **Maintainability**: High. The next developer will immediately understand:
  > - Why the event struct exists (clear deprecation doc)
  > - That it's a tombstone, not active code (DO NOT REMOVE warning)
  > - How to handle similar deprecations in future (pattern established)
  > 
  > ## Summary
  > 
  > This is a textbook-correct implementation of event sourcing tombstoning. The developer:
  > 
  > 1. Preserved event deserialization capability for historic events (correct)
  > 2. Added explicit no-op handlers to prevent replay crashes (correct)
  > 3. Removed all active behavior cleanly (correct)
  > 4. Documented the deprecation clearly to prevent future confusion (excellent)
  > 5. Proved replay safety with a comprehensive rebuild test (thorough)
  > 6. Stayed within scope and delivered exactly what the plan specified (disciplined)
  > 
  > The code is production-ready, maintainable, and safe. The single judgement-worthy finding is an optimization opportunity (event store cleanup) that the plan explicitly deferred, not a quality issue.
  > 
  > **Recommendation**: Merge with confidence.

## Stage: codex_review
- Status: succeeded
- Handler: prompt
- Model: gpt-5.5
- Tokens: 6.0k in / 4.1k out
- Response:
  > # Iteration Review Report: 035 — Obliterate Opened Delivery Status
  > 
  > ## Decision: ACCEPT
  > 
  > ## Confidence: High
  > 
  > ## ADR conformance: PASS
  > 
  > The implementation is consistent with the project’s event-sourcing/CQRS direction and the domain-design guidance relevant to this slice:
  > 
  > - Historic events are preserved as immutable facts rather than deleted or renamed.
  > - `EmailDeliveryOpened` remains only as a replay/deserialization tombstone.
  > - Aggregate/projector handling is reduced to explicit replay-safe no-ops.
  > - The active command, webhook branch, read-model normalization, and presentation mapping for `"opened"` are removed.
  > - The new regression coverage exercises replay/rebuild behaviour rather than only forward command dispatch.
  > 
  > No evidence suggests the implementation replaced ADR-mandated Commanded/EventStore infrastructure with local substitutes or bypassed projection/read-model boundaries.
  > 
  > ## ADR violations
  > 
  > None identified.
  > 
  > ## Blocking issues
  > 
  > None.
  > 
  > ## Bounded-safe fixes
  > 
  > 1. **Consider making replay-only no-op projector clauses maximally broad**
  >    - **Files:** the projector modules retaining `EmailDeliveryOpened` no-op clauses.
  >    - **Issue:** If the no-op clauses still pattern-match on metadata shape such as `%{email_delivery_id: _}`, that is slightly narrower than the intent of a tombstone replay shim.
  >    - **Why safe:** The event is deprecated and should have no behaviour regardless of metadata. Matching `_metadata` would make the replay shim more robust against older or malformed historic metadata without changing product behaviour.
  >    - **Suggested change:** Prefer heads equivalent to:
  > 
  >      ```elixir
  >      # Historic event retained for replay only; intentionally ignored.
  >      def project(%EmailDeliveryOpened{}, _metadata, _context_or_multi) do
  >        :ok
  >      end
  >      ```
  > 
  >      or the project’s equivalent projector callback shape.
  > 
  >    - **Not blocking:** The current implementation passed the replay regression and full `dev check`; this is defensive polish only.
  > 
  > ## Judgement-worthy non-blocking code-health findings
  > 
  > 1. **Replay regression test reaches into EventStore/projection internals**
  >    - **Files:** the new replay-safety regression test containing helpers such as `reset_event_store!/1`, `reset_projection_tables!/1`, and projector rebuild orchestration.
  >    - **Smell:** The test necessarily manipulates EventStore tables, projection tables, subscriptions, schemas, and rebuild mechanics directly.
  >    - **Why it may need human judgement:** This is appropriate for a replay-safety regression, but if similar tests accumulate, the project may want a shared, well-named test helper for “historic event replay/rebuild” scenarios. Otherwise, future tests may duplicate fragile knowledge of EventStore table names and reset semantics.
  >    - **Not blocking:** For this iteration, the test is valuable and proves the important risk: historic `EmailDeliveryOpened` events do not break projection rebuilds or mutate read models.
  > 
  > 2. **Permanent tombstone surface remains by design**
  >    - **Files:**
  >      - `lib/memba/messaging/events/email_delivery_opened.ex`
  >      - aggregate no-op clause for `EmailDeliveryOpened`
  >      - projector no-op clauses for `EmailDeliveryOpened`
  >    - **Smell:** The codebase retains a deprecated event module and replay-only handlers for a status that no longer exists as product behaviour.
  >    - **Why it may need human judgement:** Removing this later would require operational confidence that no production event store contains `EmailDeliveryOpened` events, plus an explicit decision about replay compatibility. Until then, the tombstone is the correct event-sourcing tradeoff.
  >    - **Not blocking:** The comments and no-op implementation make the intent clear, and this exactly matches the iteration plan.
  > 
  > ## Suggested fixes
  > 
  > Only optional bounded-safe polish:
  > 
  > 1. If any `EmailDeliveryOpened` no-op projector clause unnecessarily constrains metadata, loosen it to ignore all metadata.
  > 2. If replay/rebuild regression tests become common, extract the EventStore/projection reset and rebuild helpers into a shared test-support module with a name that makes the destructive test-only behaviour explicit.
  > 
  > ## Validation notes
  > 
  > - `dev ci` completed successfully.
  > - Acceptance suite passed: **82 scenarios / 493 steps**.
  > - The implementation evidence shows the active `"opened"` delivery behaviour was removed:
  >   - deleted `ReportEmailDeliveryOpened` command path,
  >   - removed read-model `"opened"` normalization,
  >   - removed `"opened" -> "delivered"` presentation mapping,
  >   - removed webhook `"opened"` rejection branch,
  >   - removed UI/test assertions that treated `"opened"` as an active status.
  > - Historic replay safety is covered by a regression test that persists/replays `EmailDeliveryOpened` and rebuilds projections.
  > - Remaining `opened`/`Opened` references appear limited to the documented replay-only shim and intentional regression coverage.
  > - Acceptance feature files appear to remain domain-focused rather than being updated as implementation specs, which is appropriate for this cleanup slice.


You are independently reviewing the completed, plan-conforming implementation of the iteration plan at docs/iterations/035-obliterate-opened-delivery-status/plan.md.

Use the prior context: the plan text, collected implementation evidence, current working tree state, commit range from `c4be16303bbb07a1dd1f82981e259de54887ed66..HEAD`, and the successful dev check output. Be strict, practical, and specific. Do not edit files.

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