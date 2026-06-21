Goal: Review a completed plan-conforming iteration implementation for code polish, ADR conformance, and code-health signals
Run ID: 01KVMJ25ZA75KV5A0DPJ4A6X2D
Pipeline progress: 4 of 27 stages completed

## Stage: read_plan
- Status: succeeded
- Handler: command
- Script: `PLAN_PATH='docs/iterations/038-email-delivery-handoff-boundary/plan.md'
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
  (107 lines omitted)
  
  1. Inspect current outbound send paths and tests:
     - `Memba.Messaging.send_club_message/2`, `deliver_to_provider/1`, and `email_delivery_request/3`.
     - browser compose and inbound club-message acceptance callers.
     - `Memba.Messaging.Projectors.EmailDelivery` and related member/staff delivery projections.
     - fake/local/Postmark/Resend provider test seams.
  2. Update the `EmailDelivery` projection/read model so newly created records start with status `pending` and can store dispatch diagnostics such as attempt count, latest error/detail, and useful timestamps.
  3. Add database constraints or schema validation for the expanded status vocabulary where practical, preserving existing webhook statuses.
  4. Introduce a named dispatch module/process, probably `Memba.Messaging.EmailDeliveryDispatcher`, under the application supervision tree.
  5. Make the dispatcher subscribe to `Memba.ReadModelChanges.topic()` and treat relevant `EmailDeliveryCreated`/EmailDelivery projection changes as a nudge to dispatch pending email deliveries.
  6. Implement claiming logic that moves a pending delivery to `dispatching` before provider delivery, avoiding two dispatcher invocations claiming the same pending delivery concurrently.
  7. Move request-building/provider-call logic out of `Memba.Messaging` into the dispatcher or a focused collaborator used by the dispatcher.
  8. On provider success, update the delivery to `sent`; on provider error, update it to `failed`, increment attempt count, and persist the latest error/detail.
  9. Remove the synchronous provider call from `send_club_message/2`; keep its success contract tied to command acceptance/recording, not provider availability.
  10. Add an internal/manual retry API for failed deliveries. Do not add automatic retries, startup sweeps, periodic sweeps, or staff retry UI in this slice.
  11. Adapt accepted inbound club-message flow so it relies on the same pending-delivery projection and dispatcher path.
  12. Adjust member-facing and staff/operator delivery presentation only as needed for the new statuses: hide or soften infrastructure detail on member-facing screens, while allowing staff/operator diagnostics to show exact status/error.
  13. Add/update focused tests for the acceptance criteria above.
  14. Run `dev check` and fix any regressions.
  
  ## Open Technical Decisions
  
  None known.
  
  The plan intentionally decides the previously-open design choices:
  
  - Use existing `EmailDelivery` records rather than a separate handoff/outbox table.
  - Use `pending`, `dispatching`, `sent`, and `failed` as the pre/post-provider dispatch lifecycle.
  - Use a supervised OTP dispatcher and Phoenix PubSub read-model-change nudges.
  - Provide manual/internal retry only; automatic retry is a follow-up.
  - Do not rename `MessageSent` in this slice.
  
  ## New Capability
  
  Developers/operators can reason about outbound provider dispatch as an explicit, asynchronous lifecycle on each `EmailDelivery`. Provider outages or misconfiguration become observable failed delivery dispatches with retry diagnostics instead of misleading `send_club_message/2` failures after message events have already committed.
  
  ## Validation Plan
  
  - Run targeted tests around messaging send, `EmailDelivery` projection/status transitions, dispatcher behaviour, provider adapters/fakes, manual retry, and inbound club-message acceptance during implementation.
  - Run `dev check` before declaring the iteration complete.
  - Manually inspect a local/dev send flow with the fake provider to confirm message acceptance creates pending deliveries, the dispatcher sends them, and existing message/delivery views still populate.
  - Manually or through tests simulate provider failure and confirm the message remains accepted, the affected delivery becomes `failed`, attempt count/latest error are persisted, and manual retry can move it to `sent`.
  
  ## Risks / Follow-ups
  
  - There is deliberately no automatic retry, startup sweep, or periodic sweep in this iteration. If the PubSub nudge is missed or the app is down when deliveries are created, an operator/developer must use the internal retry/dispatch API. Automatic retry/sweeping should be a follow-up problem/iteration.
  - Best-effort duplicate prevention is acceptable for this slice: retry must not create duplicate domain events or duplicate local delivery records, but a crash after provider acceptance and before marking `sent` can still leave an ambiguous delivery. Strong provider-level idempotency using `delivery_id` may be a later hardening iteration.
  - Staff/operator diagnostics may need a later UI polish iteration if raw provider errors are too technical or if retry should become a Staff-facing action.
  - Existing callers/tests may assume email deliveries are immediately `sent`; updating them to understand `pending`/async dispatch may touch several tests and projections.
  - Other design-review findings remain: large application-service modules, Membership projection-backed policy preflights, onboarding conversion orchestration, and deprecated `opened` compatibility cleanup.
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
  (1355 lines omitted)
  
    Rule: Staff-edited slugs must already be address-safe
  
      Scenario: Staff enter an invalid slug # features/staff_club_slugs.feature:17
  [acceptance 2026-06-21T07:51:25.636Z] scenario start: Staff enter an invalid slug
  [acceptance 2026-06-21T07:51:25.700Z] scenario reset app state: Staff enter an invalid slug
        Given Pat is signed in as Memba staff
  [acceptance 2026-06-21T07:51:27.027Z] slow step: Staff enter an invalid slug :: Pat is signed in as Memba staff :: 1259ms
        Given Kootenay Mountaineering Club is a club
        When Pat tries to change Kootenay Mountaineering Club's slug to "kmc club!"
        Then Memba should reject the club slug as invalid
        And Kootenay Mountaineering Club should keep its previous slug
  [acceptance 2026-06-21T07:51:28.766Z] scenario teardown start: Staff enter an invalid slug status=PASSED
  [acceptance 2026-06-21T07:51:28.777Z] scenario finish: Staff enter an invalid slug status=PASSED duration=3141ms
  
    Rule: A slug can belong to only one club
  
      Scenario: Staff enter a slug that another club already uses # features/staff_club_slugs.feature:25
  [acceptance 2026-06-21T07:51:28.781Z] scenario start: Staff enter a slug that another club already uses
  [acceptance 2026-06-21T07:51:28.845Z] scenario reset app state: Staff enter a slug that another club already uses
        Given Pat is signed in as Memba staff
  [acceptance 2026-06-21T07:51:30.152Z] slow step: Staff enter a slug that another club already uses :: Pat is signed in as Memba staff :: 1262ms
        Given Kootenay Mountaineering Club has the slug "kmc"
        And Nelson Paddling Club is a club
        When Pat tries to change Nelson Paddling Club's slug to "kmc"
        Then Memba should reject the club slug as already taken
        And Nelson Paddling Club should keep its previous slug
  [acceptance 2026-06-21T07:51:32.261Z] scenario teardown start: Staff enter a slug that another club already uses status=PASSED
  [acceptance 2026-06-21T07:51:32.269Z] scenario finish: Staff enter a slug that another club already uses status=PASSED duration=3489ms
  
    Rule: A club slug routes public visitors to that club's public page
  
      @not-domain
      Scenario: Robin opens an unknown club subdomain # features/staff_club_slugs.feature:35
  [acceptance 2026-06-21T07:51:32.276Z] scenario start: Robin opens an unknown club subdomain
  [acceptance 2026-06-21T07:51:32.334Z] scenario reset app state: Robin opens an unknown club subdomain
        Given Pat is signed in as Memba staff
  [acceptance 2026-06-21T07:51:33.637Z] slow step: Robin opens an unknown club subdomain :: Pat is signed in as Memba staff :: 1245ms
        When Robin opens "unknown.clubs.memba.io"
        Then Robin should see a not found page
  [acceptance 2026-06-21T07:51:33.707Z] scenario teardown start: Robin opens an unknown club subdomain status=PASSED
  [acceptance 2026-06-21T07:51:33.714Z] scenario finish: Robin opens an unknown club subdomain status=PASSED duration=1438ms
  
  [acceptance 2026-06-21T07:51:33.714Z] AfterAll: closing shared browser
  [acceptance 2026-06-21T07:51:33.766Z] AfterAll: closed shared browser
  [acceptance 2026-06-21T07:51:33.766Z] AfterAll: stopping Phoenix browser acceptance lifecycle
  [acceptance 2026-06-21T07:51:33.769Z] AfterAll: stopped Phoenix browser acceptance lifecycle
  82 scenarios (82 passed)
  493 steps (493 passed)
  4m29.731s (executing steps: 4m14.191s)
  ```

## Stage: collect_implementation_evidence
- Status: succeeded
- Handler: command
- Script: `bash .fabro/workflows/iteration-review/scripts/collect_implementation_evidence.sh '90134f8ebf5b313e76e43e912c50800ab2687545'`
- Output:
  ```
  (5053 lines omitted)
    end
  end
  
  === web/test/support/messaging/email_delivery_providers/selective_failure.ex ===
  defmodule Memba.Messaging.EmailDeliveryProviders.SelectiveFailure do
    @moduledoc """
    Test email delivery provider that records every request and fails configured recipients.
    """
  
    use Agent
  
    alias Memba.Messaging.EmailDeliveryProvider
    alias Memba.Messaging.EmailDeliveryRequest
  
    @behaviour EmailDeliveryProvider
  
    def start_link(_opts \\ []) do
      Agent.start_link(fn -> %{requests: [], failing_addresses: MapSet.new()} end, name: __MODULE__)
    end
  
    @impl EmailDeliveryProvider
    def deliver(%EmailDeliveryRequest{} = request) do
      Agent.get_and_update(__MODULE__, fn state ->
        state = update_in(state.requests, &[request | &1])
  
        result =
          if MapSet.member?(state.failing_addresses, request.recipient_address) do
            {:error, {:selective_failure, request.recipient_address}}
          else
            :ok
          end
  
        {result, state}
      end)
    end
  
    def fail_addresses(addresses) when is_list(addresses) do
      Agent.update(__MODULE__, fn state ->
        %{state | failing_addresses: MapSet.new(addresses)}
      end)
    end
  
    def deliveries do
      Agent.get(__MODULE__, fn state -> Enum.reverse(state.requests) end)
    end
  
    def reset do
      Agent.update(__MODULE__, fn _state -> %{requests: [], failing_addresses: MapSet.new()} end)
    end
  end
  ```


You are independently reviewing the completed, plan-conforming implementation of the iteration plan at docs/iterations/038-email-delivery-handoff-boundary/plan.md.

Use the prior context: the plan text, collected implementation evidence, current working tree state, commit range from `90134f8ebf5b313e76e43e912c50800ab2687545..HEAD`, and the successful dev check output. Be strict, practical, and specific. Do not edit files.

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