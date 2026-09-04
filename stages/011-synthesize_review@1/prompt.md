Goal: Review a completed plan-conforming iteration implementation for code polish, ADR conformance, and code-health signals
Run ID: 01M1PX1E133CXVRQEZGW0AWA8S
Pipeline progress: 6 of 29 stages completed

## Stage: read_plan
- Status: succeeded
- Handler: command
- Script: `PLAN_PATH='docs/iterations/056-group-audience-foundation/plan.md'
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
  
  - **System-group policy:** `Memba.Membership.Policies.SystemGroupMembership` is a
    stateless Commanded event handler with a stable name. It starts from `:origin`,
    uses strong consistency, and handles each membership/Admin-role lifecycle event
    independently. Starting from origin lets a first subscription replay history
    instead of skipping events written during subscriber startup. The Club aggregate
    owns group-membership state; idempotent commands make first-subscription replay
    and at-least-once handler redelivery safe. Release backfill remains required for
    clubs whose historic streams predate the new system-group facts, and future
    role/removal events for memberships seeded by backfill work normally because the
    handler holds no process state.
  - **Membership projection:** `membership_group_memberships` is a current-state
    projection keyed by `(group_id, membership_id)` with `active`; remove/re-add
    toggles that row. The event stream is the membership history. Index current rows
    for group-to-members and person-to-groups access queries.
  - **Backfill:** `Memba.Membership.SystemGroups.Backfill` runs automatically from the
    existing release migration flow, after schema migration and app startup. It is a
    paginated, idempotent command dispatcher that logs counts, aborts safely on
    unrecoverable failure, and resumes on the next release. It never runs at normal
    boot and requires no manual operator command.
  - **Replay proof:** reuse `Memba.EventSourcedCase.rebuild_event_sourced_projections!/0`
    and `Memba.ProjectionBarrier` in an asynchronous-false ExUnit test after adding
    the new projectors/tables to its reset/restart lists. The test compares query
    results before and after rebuild from retained events.
  
  ## New Capability
  
  Memba has explicit, rebuildable Group identities and memberships for its two
  existing conversation cohorts, plus a conversation-to-group write-access model.
  Current club-wide messages are no longer a hidden special case: they are Everyone
  conversations. The next iteration can build a usable Admin-group email route on
  this foundation without introducing a second audience model.
  
  ## Validation Plan
  
  - Run focused Membership and Messaging ExUnit tests while implementing the aggregate,
    policy, projections, and access change.
  - Test a club creation path produces Everyone and Admin facts; member and Admin-role
    lifecycle changes produce the intended group-membership facts once and only once.
  - Test that the existing acceptance examples still have the same recipients,
    authorisation results, reply followers, and email threading after the new policy
    is in place.
  - Exercise the automatic `Memba.Release.migrate/0` backfill path against
    representative existing clubs, memberships, Admin-role assignments, root messages,
    and replies; interrupt/retry it in tests and assert no duplicate facts or current
    rows.
  - Use `Memba.EventSourcedCase.rebuild_event_sourced_projections!/0` and a projection
    barrier to rebuild the relevant Membership and Messaging projections from retained
    events, then compare their group/membership/access query results to the
    post-backfill state.
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
  (385 lines omitted)
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
  (6605 lines omitted)
  
    Rule: Staff-edited slugs must already be address-safe
  
      Scenario: Staff enter an invalid slug # features/staff_club_slugs.feature:17
  [acceptance 2026-09-04T19:18:09.742Z] scenario start: Staff enter an invalid slug
  [acceptance 2026-09-04T19:18:09.775Z] scenario reset app state: Staff enter an invalid slug
        Given Pat is signed in as Memba staff
  [acceptance 2026-09-04T19:18:10.963Z] slow step: Staff enter an invalid slug :: Pat is signed in as Memba staff :: 1112ms
        Given Kootenay Mountaineering Club is a club
        When Pat tries to change Kootenay Mountaineering Club's slug to "kmc club!"
        Then Memba should reject the club slug as invalid
        And Kootenay Mountaineering Club should keep its previous slug
  [acceptance 2026-09-04T19:18:12.242Z] scenario teardown start: Staff enter an invalid slug status=PASSED
  [acceptance 2026-09-04T19:18:12.250Z] scenario finish: Staff enter an invalid slug status=PASSED duration=2508ms
  
    Rule: A slug can belong to only one club
  
      Scenario: Staff enter a slug that another club already uses # features/staff_club_slugs.feature:25
  [acceptance 2026-09-04T19:18:12.251Z] scenario start: Staff enter a slug that another club already uses
  [acceptance 2026-09-04T19:18:12.285Z] scenario reset app state: Staff enter a slug that another club already uses
        Given Pat is signed in as Memba staff
  [acceptance 2026-09-04T19:18:13.491Z] slow step: Staff enter a slug that another club already uses :: Pat is signed in as Memba staff :: 1135ms
        Given Kootenay Mountaineering Club has the slug "kmc"
        And Nelson Paddling Club is a club
        When Pat tries to change Nelson Paddling Club's slug to "kmc"
        Then Memba should reject the club slug as already taken
        And Nelson Paddling Club should keep its previous slug
  [acceptance 2026-09-04T19:18:15.160Z] scenario teardown start: Staff enter a slug that another club already uses status=PASSED
  [acceptance 2026-09-04T19:18:15.166Z] scenario finish: Staff enter a slug that another club already uses status=PASSED duration=2915ms
  
    Rule: A club slug routes public visitors to that club's public page
  
      @not-domain
      Scenario: Robin opens an unknown club subdomain # features/staff_club_slugs.feature:35
  [acceptance 2026-09-04T19:18:15.166Z] scenario start: Robin opens an unknown club subdomain
  [acceptance 2026-09-04T19:18:15.228Z] scenario reset app state: Robin opens an unknown club subdomain
        Given Pat is signed in as Memba staff
  [acceptance 2026-09-04T19:18:16.400Z] slow step: Robin opens an unknown club subdomain :: Pat is signed in as Memba staff :: 1134ms
        When Robin opens "unknown.clubs.memba.io"
        Then Robin should see a not found page
  [acceptance 2026-09-04T19:18:16.459Z] scenario teardown start: Robin opens an unknown club subdomain status=PASSED
  [acceptance 2026-09-04T19:18:16.464Z] scenario finish: Robin opens an unknown club subdomain status=PASSED duration=1298ms
  
  [acceptance 2026-09-04T19:18:16.466Z] AfterAll: closing shared browser
  [acceptance 2026-09-04T19:18:16.497Z] AfterAll: closed shared browser
  [acceptance 2026-09-04T19:18:16.497Z] AfterAll: stopping Phoenix browser acceptance lifecycle
  [acceptance 2026-09-04T19:18:16.498Z] AfterAll: stopped Phoenix browser acceptance lifecycle
  118 scenarios (118 passed)
  833 steps (833 passed)
  6m26.157s (executing steps: 6m14.624s)
  ```

## Stage: collect_implementation_evidence
- Status: succeeded
- Handler: command
- Script: `bash .fabro/workflows/iteration-review/scripts/collect_implementation_evidence.sh '1d11137ca64b0b9dda2a71ff920a2d10b6c81581'`
- Output:
  ```
  (9912 lines omitted)
        reset_projection_tables!(conn)
      end)
    end
  
    defp stop_event_sourced_subscribers! do
      for {child_id, pid, :worker, [module]} <- Supervisor.which_children(Memba.Supervisor),
          module in event_sourced_subscribers() do
        if is_pid(pid) do
          :ok = Supervisor.terminate_child(Memba.Supervisor, child_id)
        end
  
        child_id
      end
    end
  
    defp start_event_sourced_subscribers!(child_ids) do
      Enum.each(child_ids, fn child_id ->
        case Supervisor.restart_child(Memba.Supervisor, child_id) do
          {:ok, _pid} -> :ok
          {:ok, _pid, _info} -> :ok
          {:error, :running} -> :ok
        end
      end)
    end
  
    defp stop_commanded_aggregate_instances! do
      Enum.each(@commanded_apps, fn app ->
        supervisor_name = Module.concat([app, Commanded.Aggregates.Supervisor])
  
        if supervisor_pid = Process.whereis(supervisor_name) do
          supervisor_pid
          |> DynamicSupervisor.which_children()
          |> Enum.each(fn {_child_id, aggregate_pid, _type, _modules} ->
            if is_pid(aggregate_pid) do
              DynamicSupervisor.terminate_child(supervisor_pid, aggregate_pid)
            end
          end)
        end
      end)
    end
  
    defp reset_commanded_subscription_acks! do
      Enum.each(@commanded_apps, &Commanded.Subscriptions.reset/1)
    end
  
    defp reset_event_store_subscription_checkpoints! do
      Enum.each(event_sourced_subscribers(), fn subscriber ->
        :ok =
          Commanded.EventStore.delete_subscription(
            subscriber_commanded_app(subscriber),
  ```

## Stage: review_fork
- Status: succeeded
- Handler: parallel
- Notes: Parallel node dispatched 3 branches (3 succeeded, 0 failed)

## Stage: review_merge
- Status: succeeded
- Handler: parallel.fan_in
- Notes: Joined 3 parallel branches

## Current context
| Key | Value |
|-----|-------|
| parallel.branch_count | 3 |
| parallel.results | [{"id":"claude_review","index":0,"status":"succeeded","context_updates":{"last_response":"# Iteration Review: 056-group-audience-foundation\n\n## Decision: ACCEPT\n\n## Confidence: Medium\n\n## ADR conformance: PASS (based on available evidence)\n\n## ADR violations\nNone identified from the availa","last_stage":"claude_review","response.claude_review":"# Iteration Review: 056-group-audience-foundation\n\n## Decision: ACCEPT\n\n## Confidence: Medium\n\n## ADR conformance: PASS (based on available evidence)\n\n## ADR violations\nNone identified from the available evidence. The plan's stated design explicitly follows the patterns Memba's ADRs and reference docs require for this stack:\n\n- Group-membership facts are produced by commands against the Club aggregate (aggregate remains the single writer of membership state), not inferred ad hoc in a projector — consistent with `docs/reference/event-sourcing.md` / `docs/reference/cqrs.md` guidance that write-side invariants live in the aggregate, not in read-side handlers.\n- `Memba.Membership.Policies.SystemGroupMembership` is described as a stateless, idempotent, at-least-once-safe Commanded event handler starting from `:origin` with strong consistency — this matches the standard Commanded event-handler idempotency/replay-safety pattern this project relies on elsewhere (confirmed indirectly by the `EventSourcedCase` reset/restart machinery shown in the evidence, which exists specifically to prove replay safety for this class of subscriber).\n- The projection (`membership_group_memberships`) is explicitly a current-state table keyed by `(group_id, membership_id)`, keeping the event stream as the source of history rather than duplicating it — matches the CQRS read-model guidance (derive, don't duplicate, history).\n- Backfill runs through the existing `Memba.Release.migrate/0` flow rather than a bespoke boot-time job or a manual mix task, respecting the project's existing release/migration architecture rather than substituting a simpler local mechanism.\n- The plan requires the replay-proof test to reuse `Memba.EventSourcedCase.rebuild_event_sourced_projections!/0` and `Memba.ProjectionBarrier` rather than hand-rolling a new rebuild/verification harness — the collected evidence shows this shared harness (subscriber stop/restart, subscription-ack reset, checkpoint deletion) is exactly the mechanism actually exercised, which is the correct reuse rather than a parallel one-off.\n\nI could not directly inspect the full moduel-by-module diff (the evidence stream was almost entirely elided in what was surfaced to this review), so this PASS is based on the plan's architecture description cross-checked against the one concrete artifact shown (the shared `EventSourcedCase` reset/restart support code) and the fully green `dev ci` run. No behaviour in the evidence contradicts the ADR-mandated patterns.\n\n## Blocking issues\nNone found. `dev ci` passed end-to-end, including 118/118 acceptance scenarios (833/833 steps), which cover the existing club-messaging/authorisation/reply-following/threading behaviours the plan promised to preserve, plus (per the plan) new membership/Admin-role lifecycle and backfill idempotency tests folded into the same suite.\n\n## Bounded-safe fixes\nNone identified from the available evidence. (No specific file/line-level smell was visible in what was surfaced to this review; nothing to prescribe without risking a speculative/unfounded change.)\n\n## Judgement-worthy non-blocking code-health findings\n\n1. **Review-evidence visibility gap (process note, not a code finding).** The `collect_implementation_evidence` output available for this pass surfaced almost no lines from the actual new modules (`Group` aggregate, `SystemGroupMembership` policy, `membership_group_memberships` projection, `SystemGroups.Backfill`) — only tail output of the pre-existing `EventSourcedCase` support helpers was visible. This review could not perform a line-level polish pass (naming, function size, duplication, pattern-matching style) on the new aggregate/policy/backfill code itself. Recommend a follow-up pass (or re-running evidence collection without truncation) if a deeper polish/refactor review of those specific new modules is wanted; nothing here should be read as those modules being clean or dirty — it's simply unverified in this pass.\n2. **Backfill/handler overlap risk (design smell to watch, not confirmed).** The plan pairs an at-least-once, from-`:origin` event handler with a separate paginated command-dispatching backfill process, both able to produce group-membership facts for the same historic clubs. The plan states commands are idempotent so this is safe by design, but this dual-path fact production (live handler + backfill) is exactly the kind of area where a future person changing either path independently could reintroduce duplicate-fact risk. Worth a comment/doc pointer at the backfill call site and at the policy module noting the invariant they jointly rely on (idempotent Club aggregate commands), if not already present — human judgement on whether existing comments are sufficient.\n3. **Two-audience-model transition surface.** The plan explicitly frames this iteration as removing \"hidden special case\" club-wide messaging in favor of an explicit Everyone group. Any remaining code paths that special-cased \"everyone\" messaging directly (rather than going through the new Group/membership model) should be confirmed fully migrated rather than left as a parallel legacy path; this is worth a targeted grep/audit in a follow-up if not already exhaustively covered by the \"existing acceptance examples still have same recipients\" validation step (which did pass in full per the `dev ci` acceptance run).\n\n## Suggested fixes\nNo mandatory fixes — nothing here rises to blocking or concretely bounded-safe given the evidence available. If the team wants a deeper polish pass, re-run evidence collection to expose the actual diffs for `Memba.Membership.Group` (or equivalent aggregate module), `Memba.Membership.Policies.SystemGroupMembership`, the `membership_group_memberships` projection, and `Memba.Membership.SystemGroups.Backfill`, and re-review those specifically against `docs/reference/domain-driven-design.md`, `docs/reference/cqrs.md`, and `docs/reference/event-sourcing.md` line-by-line.\n\n## Validation notes\n- `dev ci` (full pipeline: compile, format/credo/dialyzer as configured, unit/integration tests, acceptance suite) ran clean on the reviewed state: 118 acceptance scenarios / 833 steps, all passed, ~6m26s.\n- Sandbox preflight passed cleanly on a clean working tree at the recorded start SHA.\n- The plan's own validation plan (Membership/Messaging focused tests, club-creation fact generation, lifecycle-change idempotency, pre/post-backfill acceptance parity, and projection-rebuild-vs-live-state comparison via `EventSourcedCase`/`ProjectionBarrier`) is architecturally sound and, per the green CI run, appears to have been executed — but this review could not independently inspect the specific new test files asserting each of those properties beyond the aggregate acceptance-suite pass/fail signal. Recommend spot-checking (in a future pass, if deeper assurance is wanted) that a dedicated test explicitly demonstrates \"no duplicate facts\" under interrupted/retried backfill, since that's the single highest-risk correctness property in this iteration and is easy to assert weakly (e.g., only checking row counts rather than exact idempotency under interruption)."}},{"id":"codex_review","index":1,"status":"succeeded","context_updates":{"last_response":"# Iteration Review\n\n- **Decision:** ACCEPT\n- **Confidence:** Medium\n- **ADR conformance:** PASS\n\n## ADR violations\n\n1. None identified. The implementation evidence is consistent with the project’s a","last_stage":"codex_review","response.codex_review":"# Iteration Review\n\n- **Decision:** ACCEPT\n- **Confidence:** Medium\n- **ADR conformance:** PASS\n\n## ADR violations\n\n1. None identified. The implementation evidence is consistent with the project’s accepted event-sourcing and CQRS direction: Commanded remains the write-side infrastructure, the Club aggregate owns group-membership state, lifecycle automation is implemented as a stateless event handler, current-state queries use rebuildable Ecto projections, and retained events remain the source for replay.\n\n## Blocking issues\n\n1. None identified.\n\n## Bounded-safe fixes\n\n1. None required before merge.\n\n## Judgement-worthy non-blocking code-health findings\n\n1. **Files:** `test/support/event_sourced_case.ex` and the event-sourced subscriber modules it enumerates  \n   **Smell:** Projection rebuilding depends on explicit subscriber lists, direct supervision-tree inspection, aggregate-process termination, Commanded subscription resets, and EventStore checkpoint deletion.  \n   **Why it may need human judgement:** This is appropriate test infrastructure for proving full replay, and the plan explicitly requires extending this helper. However, it is coupled to Commanded and supervisor internals. Future subscribers can be omitted silently unless every addition updates the helper. A later architectural decision could introduce a central subscriber registry or projection reset contract, but that would be broader than a safe polish change for this iteration.\n\n2. **Files:** `Memba.Membership.Policies.SystemGroupMembership` and the Club aggregate command handlers used by it  \n   **Smell:** Correctness spans an at-least-once event handler and idempotency implemented by the receiving aggregate rather than a transaction local to one process.  \n   **Why it may need human judgement:** This is intentional and consistent with the plan’s event-sourced design, including replay from `:origin`. It does make aggregate idempotency a durable contract: future edits to the relevant commands must preserve duplicate-delivery safety. The invariant would benefit from continued explicit documentation and tests whenever these commands evolve.\n\n3. **Files:** `Memba.Membership.SystemGroups.Backfill` and the release migration flow  \n   **Smell:** Application-level event-sourced backfill is coupled to release migration ordering, application startup, read-model pagination, and command dispatch.  \n   **Why it may need human judgement:** The coupling is mandated by the iteration plan and is preferable to manufacturing event-sourced state through SQL. It nevertheless increases operational complexity compared with ordinary schema migrations. Future backfills should reuse a clearly defined pattern rather than adding independently shaped release-time workflows.\n\n## Suggested fixes\n\nNo changes are required for this iteration.\n\nFor future maintenance:\n\n- Consider making the complete set of replayable subscribers discoverable through one registry or callback rather than duplicating it in replay-test infrastructure.\n- Preserve focused duplicate-delivery tests whenever system-group commands or lifecycle policy subscriptions change.\n- Keep release-backfill progress, failure, and retry behavior observable; avoid bypassing aggregates with direct projection writes.\n\n## Validation notes\n\n- The review started from a clean working tree.\n- Sandbox/runtime validation passed.\n- `dev ci` completed successfully on the reviewed committed state.\n- The complete acceptance suite passed: **118 scenarios and 833 steps**.\n- The implementation evidence includes the required projection-reset and subscriber-restart support for retained-event replay.\n- The design retains the central architectural boundaries described by the plan:\n  - Commanded aggregates and events remain authoritative.\n  - The system-group policy is stateless and replayable from `:origin`.\n  - Aggregate commands provide idempotency for replay and redelivery.\n  - Group membership and conversation access are rebuildable current-state projections.\n  - Existing installations are handled through the automatic release backfill rather than direct event-history fabrication.\n- No evidence indicates that acceptance feature files were changed to weaken existing behavior.\n"}},{"id":"gemini_review","index":2,"status":"succeeded","context_updates":{"last_response":"# Iteration Review Report: 056-group-audience-foundation\n\n**Decision:** ACCEPT\n**Confidence:** High\n**ADR conformance:** PASS\n\n## ADR Violations\n*None detected.* The implementation aligns with establi","last_stage":"gemini_review","response.gemini_review":"# Iteration Review Report: 056-group-audience-foundation\n\n**Decision:** ACCEPT\n**Confidence:** High\n**ADR conformance:** PASS\n\n## ADR Violations\n*None detected.* The implementation aligns with established CQRS and Event Sourcing guidelines, particularly regarding stateless event handlers starting from `:origin`, projection separation, and aggregate boundary definitions.\n\n## Blocking Issues\n*None.* \n\n## Bounded-Safe Fixes\n*None.*\n\n## Judgement-Worthy Non-Blocking Code-Health Findings\n1. **EventSourcedCase / Projection Reset Complexity (`Memba.EventSourcedCase`)**\n   - *Smell:* The logic for stopping and restarting Commanded subscriptions, aggregates, and resetting checkpoints (e.g., `stop_event_sourced_subscribers!`, `reset_commanded_subscription_acks!`, `reset_event_store_subscription_checkpoints!`) introduces significant manual supervisor manipulation into the test suite helpers.\n   - *Why it needs human judgement:* While perfectly suited for the required asynchronous-false replay proof test in this iteration, directly manipulating supervisor children and dynamic supervisors makes the test harness tightly coupled to the internal supervision tree of the Commanded applications. As the application grows, consider extracting this lifecycle management into a dedicated `Memba.ProjectionTesting` support module or leveraging Commanded's testing supervision tools to avoid fragile test setups.\n\n## Suggested Fixes\n*No immediate fixes required.*\n\n## Validation Notes\n- **Dev Check Pass:** Confirmed. `dev ci` completed successfully, executing 118 scenarios and 833 steps in ~6.5 minutes.\n- **Acceptance Criteria Integrity:** Domain acceptance feature files were preserved and executed cleanly, verifying that the new group-audience foundation does not negatively impact existing public club subdomains, staff slug validations, or general message visibility.\n- **Replay Proof Validation:** The collected implementation evidence confirms that `Memba.EventSourcedCase` was successfully modified to support stopping subscribers, clearing checkpoints, and rebuilding event-sourced projections from retained events, as explicitly required by the validation plan."}}] |


Synthesize the independent implementation reviews for docs/iterations/056-group-audience-foundation/plan.md.

This review runs after implementation has already merged to `main`. It is a smell radar and bounded polish loop, not a delivery gate. Decide whether there are bounded fixes the workflow should attempt now, or whether remaining findings should be logged for human judgement in `docs/code-health.md` while the run continues.

## Context

Use the prior context from this workflow run:

- The iteration plan text and its explicit requirements.
- Implementation evidence collected from `1d11137ca64b0b9dda2a71ff920a2d10b6c81581` to `HEAD`.
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