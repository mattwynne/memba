Goal: Review a completed plan-conforming iteration implementation for code polish, ADR conformance, and code-health signals
Run ID: 01KTG0TGK3Y7P6AXHZ61K0Q2HV
Pipeline progress: 6 of 28 stages completed

## Stage: read_plan
- Status: succeeded
- Handler: command
- Script: `PLAN_PATH='docs/iterations/025-messaging-and-onboarding-quick-wins/plan.md'
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
  (123 lines omitted)
  6. Update local delivery facts to record the actual outbound email subject if local facts are used as mailbox evidence.
  7. Add tests proving stored message subject remains unprefixed while outbound emails are prefixed.
  8. Update `MembaWeb.MemberMessageLive.New` to validate blank/whitespace-only body before `send_current_member_message/2` dispatches.
  9. Add body-specific form error rendering while preserving the existing generic send-failure state for provider/infrastructure failures.
  10. Add LiveView tests for blank body and whitespace-only body, including no provider delivery requests and preserved subject.
  11. Add a request-specific route in the existing staff live session, likely mapping both routes to the same LiveView module:
      - `live "/requests", RequestsLive.Index, :index`
      - `live "/requests/:request_id", RequestsLive.Index, :convert`
  12. Refactor `RequestsLive.Index` to use `handle_params/3` for conversion route state:
      - `:index` clears conversion state;
      - `:convert` loads the active request and assigns the existing conversion panel/form;
      - invalid or inactive request assigns a no-longer-active state.
  13. Replace the list Convert button with a patch link to the request-specific route, using `<.link patch={...}>` or the current Phoenix 1.8 equivalent. Do not use deprecated `live_patch`.
  14. Make conversion cancel patch back to `/admin/requests`.
  15. After successful conversion, return staff to `/admin/requests` with the existing success flash and refreshed stream.
  16. Update `Memba.Onboarding.NewRequestEmail` to include an absolute request-specific staff URL. Reuse the app's existing URL generation/configuration approach for absolute links.
  17. Add tests for direct request URL, list Convert patch behaviour, inactive/missing request state, notification email link, and unchanged conversion outcomes.
  18. Update acceptance feature files with the planned `@wip` scenarios.
  19. Run targeted tests for messaging email providers, member compose LiveView, onboarding request LiveView, onboarding email, and acceptance feature parsing.
  20. Run `dev check`.
  
  ## Implementation Details to Confirm
  
  These are low-level implementation details, not blocking product or architecture decisions:
  
  - Exact helper/module name for prefixed member-message email subjects after iteration 024's email helper structure is known.
  - Whether the request route uses `RequestsLive.Index` with live action `:convert` or a similarly named module. Prefer the same LiveView and shared render path to avoid duplication.
  - Exact absolute URL source for staff notification email links in test/dev/prod configuration.
  
  ## New Capability
  
  Memba clears three small workflow and trust gaps: club-message emails are easier to recognize in inboxes, blank compose input is handled as a normal form validation problem, and staff can act on onboarding request notifications without manually finding the request.
  
  ## Validation Plan
  
  - Review the updated Gherkin scenarios with Matt as domain language before implementation if there are wording concerns.
  - Run focused tests for member-message email providers and local delivery facts proving prefixed outbound subjects.
  - Run member compose LiveView tests proving blank-body validation and no send side effect.
  - Run onboarding request LiveView tests proving patch navigation, direct route mounting, inactive/missing state, and unchanged conversion behaviour.
  - Run onboarding notification email tests proving the request-specific action link is present.
  - Run affected acceptance tests or at least feature parsing/tag checks while scenarios remain `@wip`.
  - Remove the `@wip` tags from the three new acceptance scenarios once implemented and run them green.
  - Run full `dev check` before delivery is considered complete.
  
  ## Risks / Follow-ups
  
  - Iteration 024 may change email rendering and tests; starting this iteration after 024 reduces merge conflicts.
  - Slugged subjects solve only one part of the broader email-context problem. Club/message links should remain a follow-up if not already handled by iteration 024.
  - Request-specific conversion state should not become a hidden second implementation of request conversion. Keep one conversion path and one set of tests for the business outcome.
  - Direct request links in email require correct external URL configuration in production; tests should make the expected base URL explicit.
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
  (193 lines omitted)
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
  (720 lines omitted)
  [acceptance 2026-06-07T03:24:33.760Z] scenario start: Pat rejects a request without notifying the requester
  [acceptance 2026-06-07T03:24:33.812Z] scenario reset app state: Pat rejects a request without notifying the requester
        Given Robin has requested Memba access for Suspicious Sender Club
        And Pat is signed in as Memba staff
  [acceptance 2026-06-07T03:24:35.452Z] slow step: Pat rejects a request without notifying the requester :: Pat is signed in as Memba staff :: 1170ms
        When Pat rejects Robin's Suspicious Sender Club request with the internal note "Looks like spam"
        Then Robin's request should leave the active requests inbox
        And Robin should not receive an email about the rejected request
  [acceptance 2026-06-07T03:24:37.015Z] slow step: Pat rejects a request without notifying the requester :: Robin should not receive an email about the rejected request :: 1045ms
        And Suspicious Sender Club should not exist as a club
        And Robin should not be able to sign in to Suspicious Sender Club
  [acceptance 2026-06-07T03:24:39.089Z] slow step: Pat rejects a request without notifying the requester :: Robin should not be able to sign in to Suspicious Sender Club :: 1674ms
  [acceptance 2026-06-07T03:24:39.089Z] scenario teardown start: Pat rejects a request without notifying the requester status=PASSED
  [acceptance 2026-06-07T03:24:39.118Z] scenario finish: Pat rejects a request without notifying the requester status=PASSED duration=5358ms
  
    Rule: Memba staff can act from request notification emails
  
      Scenario: Pat opens a request from the notification email # features/request_account.feature:56
  [acceptance 2026-06-07T03:24:39.130Z] scenario start: Pat opens a request from the notification email
  [acceptance 2026-06-07T03:24:39.211Z] scenario reset app state: Pat opens a request from the notification email
        Given Robin has requested Memba access for West Coast Paddlers
        And Pat is signed in as Memba staff
  [acceptance 2026-06-07T03:24:40.797Z] slow step: Pat opens a request from the notification email :: Pat is signed in as Memba staff :: 1136ms
        When Pat follows the staff notification link for Robin's request
        Then Pat should be preparing to convert Robin's West Coast Paddlers request
  [acceptance 2026-06-07T03:24:40.923Z] scenario teardown start: Pat opens a request from the notification email status=PASSED
  [acceptance 2026-06-07T03:24:40.932Z] scenario finish: Pat opens a request from the notification email status=PASSED duration=1802ms
  
    Rule: Converted requesters receive direct club access
  
      Scenario: Robin receives a welcome sign-in link for the new club # features/request_account.feature:64
  [acceptance 2026-06-07T03:24:40.933Z] scenario start: Robin receives a welcome sign-in link for the new club
  [acceptance 2026-06-07T03:24:40.990Z] scenario reset app state: Robin receives a welcome sign-in link for the new club
        Given Robin has requested Memba access for West Coast Paddlers
        And Pat is signed in as Memba staff
  [acceptance 2026-06-07T03:24:42.590Z] slow step: Robin receives a welcome sign-in link for the new club :: Pat is signed in as Memba staff :: 1152ms
        When Pat converts Robin's West Coast Paddlers request
        Then Robin should receive a welcome email for West Coast Paddlers
        When Robin follows the welcome sign-in link
        Then Robin should be signed in to West Coast Paddlers
  [acceptance 2026-06-07T03:24:43.579Z] scenario teardown start: Robin receives a welcome sign-in link for the new club status=PASSED
  [acceptance 2026-06-07T03:24:43.586Z] scenario finish: Robin receives a welcome sign-in link for the new club status=PASSED duration=2653ms
  
  [acceptance 2026-06-07T03:24:43.588Z] AfterAll: closing shared browser
  [acceptance 2026-06-07T03:24:43.631Z] AfterAll: closed shared browser
  [acceptance 2026-06-07T03:24:43.631Z] AfterAll: stopping Phoenix browser acceptance lifecycle
  [acceptance 2026-06-07T03:24:43.632Z] AfterAll: stopped Phoenix browser acceptance lifecycle
  47 scenarios (47 passed)
  314 steps (314 passed)
  2m04.388s (executing steps: 1m53.131s)
  ```

## Stage: fix_dev_check
- Status: succeeded
- Handler: agent
- Model: gpt-5.5
- Tokens: 182.3k in / 4.6k out
- Response:
  > Dev check is now passing.
  > 
  > ## 1. Preceding dev check failure
  > 
  > | Failure | Details |
  > |---|---|
  > | Acceptance test runner could not start | `npm test` in `acceptance-tests/` failed with `sh: line 1: cucumber-js: command not found` |
  > | ExUnit status before failure | Passed: `589 tests, 0 failures` |
  > 
  > Root cause: `acceptance-tests/node_modules` was missing, so the tracked `@cucumber/cucumber` dependency had not been installed locally. This was an environment/dependency-install gap, not an implementation defect.
  > 
  > ## 2. Changes made
  > 
  > No tracked code/config/test changes were needed.
  > 
  > I installed the existing acceptance-test dependencies from the tracked lockfile:
  > 
  > ```sh
  > PATH="$PWD/bin:$PATH" devenv shell -- bash -lc 'cd acceptance-tests && npm ci'
  > ```
  > 
  > This created ignored local dependency files under:
  > 
  > ```text
  > acceptance-tests/node_modules/
  > ```
  > 
  > ## 3. Files changed
  > 
  > No tracked files changed.
  > 
  > Current non-tracked/ignored state observed:
  > 
  > ```text
  > ?? .fabro/tmp/
  > !! acceptance-tests/node_modules/
  > ```
  > 
  > `acceptance-tests/node_modules/` is ignored local install output. `.fabro/tmp/` was already produced by the review/preflight process.
  > 
  > ## 4. Tests run
  > 
  > ```sh
  > PATH="$PWD/bin:$PATH" dev ci
  > ```
  > 
  > Result: passed.
  > 
  > Summary from the successful run:
  > 
  > - ExUnit: `589 tests, 0 failures`
  > - Cucumber acceptance: `47 scenarios (47 passed)`, `314 steps (314 passed)`
  > 
  > ## 5. Failure-to-fix mapping
  > 
  > | Dev check failure | Fix/action | Files/modules |
  > |---|---|---|
  > | `cucumber-js: command not found` during `acceptance-tests npm test` | Installed acceptance-test npm dependencies from existing `package-lock.json` inside the devenv shell | No tracked files changed; local ignored `acceptance-tests/node_modules/` created |
  > 
  > ## Remaining failures or questions
  > 
  > None. The full automated suite now passes without modifying product code, tests, config, or acceptance feature files.

## Stage: dev_check
- Status: succeeded
- Handler: command
- Script: `PATH="$PWD/bin:$PATH" dev ci`
- Output:
  ```
  (720 lines omitted)
  [acceptance 2026-06-07T03:24:33.760Z] scenario start: Pat rejects a request without notifying the requester
  [acceptance 2026-06-07T03:24:33.812Z] scenario reset app state: Pat rejects a request without notifying the requester
        Given Robin has requested Memba access for Suspicious Sender Club
        And Pat is signed in as Memba staff
  [acceptance 2026-06-07T03:24:35.452Z] slow step: Pat rejects a request without notifying the requester :: Pat is signed in as Memba staff :: 1170ms
        When Pat rejects Robin's Suspicious Sender Club request with the internal note "Looks like spam"
        Then Robin's request should leave the active requests inbox
        And Robin should not receive an email about the rejected request
  [acceptance 2026-06-07T03:24:37.015Z] slow step: Pat rejects a request without notifying the requester :: Robin should not receive an email about the rejected request :: 1045ms
        And Suspicious Sender Club should not exist as a club
        And Robin should not be able to sign in to Suspicious Sender Club
  [acceptance 2026-06-07T03:24:39.089Z] slow step: Pat rejects a request without notifying the requester :: Robin should not be able to sign in to Suspicious Sender Club :: 1674ms
  [acceptance 2026-06-07T03:24:39.089Z] scenario teardown start: Pat rejects a request without notifying the requester status=PASSED
  [acceptance 2026-06-07T03:24:39.118Z] scenario finish: Pat rejects a request without notifying the requester status=PASSED duration=5358ms
  
    Rule: Memba staff can act from request notification emails
  
      Scenario: Pat opens a request from the notification email # features/request_account.feature:56
  [acceptance 2026-06-07T03:24:39.130Z] scenario start: Pat opens a request from the notification email
  [acceptance 2026-06-07T03:24:39.211Z] scenario reset app state: Pat opens a request from the notification email
        Given Robin has requested Memba access for West Coast Paddlers
        And Pat is signed in as Memba staff
  [acceptance 2026-06-07T03:24:40.797Z] slow step: Pat opens a request from the notification email :: Pat is signed in as Memba staff :: 1136ms
        When Pat follows the staff notification link for Robin's request
        Then Pat should be preparing to convert Robin's West Coast Paddlers request
  [acceptance 2026-06-07T03:24:40.923Z] scenario teardown start: Pat opens a request from the notification email status=PASSED
  [acceptance 2026-06-07T03:24:40.932Z] scenario finish: Pat opens a request from the notification email status=PASSED duration=1802ms
  
    Rule: Converted requesters receive direct club access
  
      Scenario: Robin receives a welcome sign-in link for the new club # features/request_account.feature:64
  [acceptance 2026-06-07T03:24:40.933Z] scenario start: Robin receives a welcome sign-in link for the new club
  [acceptance 2026-06-07T03:24:40.990Z] scenario reset app state: Robin receives a welcome sign-in link for the new club
        Given Robin has requested Memba access for West Coast Paddlers
        And Pat is signed in as Memba staff
  [acceptance 2026-06-07T03:24:42.590Z] slow step: Robin receives a welcome sign-in link for the new club :: Pat is signed in as Memba staff :: 1152ms
        When Pat converts Robin's West Coast Paddlers request
        Then Robin should receive a welcome email for West Coast Paddlers
        When Robin follows the welcome sign-in link
        Then Robin should be signed in to West Coast Paddlers
  [acceptance 2026-06-07T03:24:43.579Z] scenario teardown start: Robin receives a welcome sign-in link for the new club status=PASSED
  [acceptance 2026-06-07T03:24:43.586Z] scenario finish: Robin receives a welcome sign-in link for the new club status=PASSED duration=2653ms
  
  [acceptance 2026-06-07T03:24:43.588Z] AfterAll: closing shared browser
  [acceptance 2026-06-07T03:24:43.631Z] AfterAll: closed shared browser
  [acceptance 2026-06-07T03:24:43.631Z] AfterAll: stopping Phoenix browser acceptance lifecycle
  [acceptance 2026-06-07T03:24:43.632Z] AfterAll: stopped Phoenix browser acceptance lifecycle
  47 scenarios (47 passed)
  314 steps (314 passed)
  2m04.388s (executing steps: 1m53.131s)
  ```

## Stage: collect_implementation_evidence
- Status: succeeded
- Handler: command
- Script: `set -eu
base_sha='e1279c7f239cfcb076fbd8965eca0008932e863a'
echo '=== Implementation Evidence Debug ==='
echo "PWD: $PWD"
echo "Branch: $(git branch --show-current || true)"
echo "HEAD: $(git rev-parse HEAD 2>/dev/null || echo unknown)"
echo "Base sha input: ${base_sha:-<empty>}"
echo ''
if [ -z "$base_sha" ]; then
  echo 'Missing required input: base_sha' >&2
  echo 'Run via: bin/dev fabro review <branch> <plan_path> [base_ref_or_base_sha]' >&2
  exit 1
fi
if ! git cat-file -e "$base_sha^{commit}" 2>/dev/null; then
  shallow=$(git rev-parse --is-shallow-repository 2>/dev/null || echo unknown)
  echo "Base sha is not present locally: $base_sha" >&2
  echo "Repository shallow: $shallow" >&2
  if [ "$shallow" = true ]; then
    echo 'Trying to unshallow repository before failing...' >&2
    git fetch --quiet --unshallow origin || true
  fi
fi
if ! git cat-file -e "$base_sha^{commit}" 2>/dev/null; then
  echo "Base sha still does not resolve after fallback: $base_sha" >&2
  echo '--- available refs ---' >&2
  git show-ref >&2 || true
  echo '--- recent commits ---' >&2
  git log --oneline --decorate --max-count=40 --all >&2 || true
  exit 1
fi
echo '=== Implementation Evidence ==='
echo "Branch: $(git branch --show-current || true)"
echo "HEAD: $(git rev-parse HEAD)"
echo "Base sha: $base_sha"
echo ''
echo '--- git status --short ---'
git status --short
echo ''
echo '--- git diff --stat ---'
if ! git diff --stat "$base_sha"..HEAD; then
  echo "Could not compute diff stat from $base_sha to HEAD." >&2
  exit 1
fi
echo ''
echo '--- git diff --name-status ---'
if ! git diff --name-status "$base_sha"..HEAD; then
  echo "Could not compute diff name-status from $base_sha to HEAD." >&2
  exit 1
fi
echo ''
echo '--- changed source/config/test file excerpts ---'
if ! changed_files=$(git diff --name-only "$base_sha"..HEAD); then
  echo "Could not compute changed files from $base_sha to HEAD." >&2
  exit 1
fi
if [ -z "$changed_files" ]; then
  echo 'No files differ between base sha and HEAD.'
else
  excerpt_files=$(printf '%s
' "$changed_files" | grep -E '^(web/(lib|config|test|priv/repo/migrations|mix\.exs|mix\.lock)|bin/|docs/iterations/|docs/adr/)' || true)
  if [ -z "$excerpt_files" ]; then
    echo 'No changed files matched the excerpt filter.'
  else
    printf '%s
' "$excerpt_files" | while IFS= read -r file; do
      if [ -f "$file" ]; then
        echo "=== $file ==="
        sed -n '1,220p' "$file"
        echo ''
      fi
    done
  fi
fi`
- Output:
  ```
  (2473 lines omitted)
                   MembaWeb.Router,
                   "GET",
                   "/messages/new",
                   "localhost"
                 )
      end
  
      test "routes /messages/:message_id through the required club member pipeline to the member message LiveView" do
        assert %{
                 path_params: %{"message_id" => "message-123"},
                 pipe_through: [:browser, :club_member_required],
                 phoenix_live_view: {MembaWeb.MemberMessageLive.Show, :show, _opts, _live_session},
                 plug: Phoenix.LiveView.Plug,
                 plug_opts: :show,
                 route: "/messages/:message_id"
               } =
                 Phoenix.Router.route_info(
                   MembaWeb.Router,
                   "GET",
                   "/messages/message-123",
                   "localhost"
                 )
      end
    end
  
    describe "removed public harness routes" do
      test "old harness paths return the normal 404 response without redirects", %{conn: conn} do
        Enum.each(@old_harness_paths, fn path ->
          conn =
            conn
            |> recycle()
            |> get(path)
  
          assert response(conn, 404) == "Not Found"
          assert get_resp_header(conn, "location") == []
        end)
      end
    end
  
    defp assert_live_route(path, route_pattern, live_view, path_params, live_action \\ nil) do
      assert %{
               pipe_through: [:staff_browser],
               phoenix_live_view: {^live_view, ^live_action, _opts, _live_session},
               plug: Phoenix.LiveView.Plug,
               plug_opts: ^live_action,
               path_params: ^path_params,
               route: ^route_pattern
             } = Phoenix.Router.route_info(MembaWeb.Router, "GET", path, "localhost")
    end
  end
  ```


You are independently reviewing the completed, plan-conforming implementation of the iteration plan at docs/iterations/025-messaging-and-onboarding-quick-wins/plan.md.

Use the prior context: the plan text, collected implementation evidence, current working tree state, commit range from `e1279c7f239cfcb076fbd8965eca0008932e863a..HEAD`, and the successful dev check output. Be strict, practical, and specific. Do not edit files.

This workflow reviews an already-committed implementation after the implementation workflow has proved plan conformance. The review job is code polish plus smell radar: refactoring, maintainability, project conventions, ADR conformance, and surfacing judgement-worthy non-blocking smells. Do not emit shell-command/tool-call JSON; return the Markdown review report only.

Automated tests are the behavioural feedback loop in this workflow. If you find a likely behavioural gap, missing acceptance criterion, or inadequate automated coverage despite green dev check, flag it as a blocking issue requiring a new implementation/test pass or human decision; do not disguise it as refactoring feedback. Do not ask for feature-file edits.

Review against these questions:

0. ADR conformance
   - Read every ADR cited by the plan and any nearby/current ADRs under `docs/adr/` that govern touched architecture.
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