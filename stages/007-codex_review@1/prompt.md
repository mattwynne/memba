Goal: Review a completed plan-conforming iteration implementation for code polish, ADR conformance, and code-health signals
Run ID: 01KTNHT1MC8VYH0EKM85ZCGE19
Pipeline progress: 5 of 26 stages completed

## Stage: read_plan
- Status: succeeded
- Handler: command
- Script: `PLAN_PATH='docs/iterations/030-verified-onboarding-requests/plan.md'
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
  (120 lines omitted)
  - Verification creates a signed-in identity/account session but not a Membership Person.
  - Name, club name, and note are collected after email verification for identities without a Person.
  - Staff only see and receive notifications for verified submitted requests.
  
  ## Implementation Plan
  
  1. Inspect the current `/get-started` controller/templates or LiveView, auth sign-in token creation, return-to handling, Staff request inbox, and onboarding request creation/notification code.
  2. Split the public Get Started experience into two states:
     - signed-out: email-only verification request;
     - signed-in: verified request form.
  3. Reuse the existing magic-link sign-in flow for the signed-out email-only step, setting return-to back to the Get Started request form.
  4. Ensure following the magic link returns the requester to Get Started and assigns `current_identity` for the verified email.
  5. Update request form rendering:
     - if signed in and the email belongs to an existing Person, show known name/email read-only and collect club name/note;
     - if signed in and no Person exists, collect name, club name, and note while using the signed-in email as read-only verified identity.
  6. Update request submission so it requires a signed-in identity email and never trusts a typed requester email for Staff-visible requests.
  7. Ensure email-only verification requests do not create onboarding request records or Staff notifications.
  8. Ensure verified request submission does not create Person, club, membership, or club access.
  9. Preserve Staff request inbox and notification behaviour for verified submitted requests.
  10. Preserve Staff conversion/rejection semantics for verified submitted requests, including creating/reusing the Person during conversion.
  11. Add or update controller/LiveView tests for signed-out email-only step, magic-link return-to, verified identity with no Person, verified identity with existing Person, and no Staff visibility before verification.
  12. Add or update domain/context tests proving request creation requires a verified identity email and does not create membership-domain records.
  13. Update Cucumber step definitions only as needed during delivery to exercise the `@iteration-030` scenarios.
  14. Remove or narrow `@todo-domain`/`@todo-ui` from the new/updated scenarios only when they pass in the relevant runner.
  15. Run `dev check`.
  
  ## Open Technical Decisions
  
  - Exact function/module names for the email-only Get Started verification step.
  - Whether the existing auth sign-in UI/service can be reused directly with a `return_to`, or whether Get Started needs a thin wrapper around the token/email creation call.
  - Whether to persist any short-lived pre-verification UI state. The preferred slice avoids this by collecting name/club/note only after magic-link verification.
  
  ## New Capability
  
  Memba Staff only triage onboarding requests from people who have proved control of the requester email address. Public visitors can create a verified identity/account session before requesting a club, without creating a Membership Person or gaining club access until Staff approve the request.
  
  ## Validation Plan
  
  - Review `acceptance-tests/features/request_account.feature` language for the new verified-request examples before delivery.
  - During implementation, add web tests for the signed-out email-only Get Started step, magic-link return-to, verified request form, and signed-in existing-person form.
  - Add tests proving Staff do not see or receive notification for an abandoned email-only verification.
  - Add tests proving verified request submission creates no Person, club, membership, or club access.
  - Run the updated Cucumber scenarios after implementation with appropriate todo tags removed or narrowed.
  - Run `dev check`.
  
  ## Risks / Follow-ups
  
  - This iteration changes a currently working public request flow; preserve the low-friction feel by making the email-first step clear and the post-link form obvious.
  - Staff notifications will move later in the flow, so abandoned email-only attempts become invisible by design. If Matt later wants visibility into abandoned attempts, capture that as a separate operational analytics problem rather than making them Staff-actionable requests.
  - This does not add CAPTCHA/rate limiting. If abuse continues through verified emails, a future anti-abuse iteration may be needed.
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
  (266 lines omitted)
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
  (1159 lines omitted)
      When Pat starts creating the club "Kootenay Mountaineering Club"
      Then Memba should suggest the slug "kootenay-mountaineering-club"
      When Pat saves the club
      Then Kootenay Mountaineering Club should have the slug "kootenay-mountaineering-club"
  [acceptance 2026-06-09T06:49:48.330Z] scenario teardown start: Staff create a club with the suggested slug status=PASSED
  [acceptance 2026-06-09T06:49:48.338Z] scenario finish: Staff create a club with the suggested slug status=PASSED duration=2400ms
  
    Scenario: Staff enter an invalid slug # features/staff_club_slugs.feature:17
  [acceptance 2026-06-09T06:49:48.339Z] scenario start: Staff enter an invalid slug
  [acceptance 2026-06-09T06:49:48.390Z] scenario reset app state: Staff enter an invalid slug
      Given Pat is signed in as Memba staff
  [acceptance 2026-06-09T06:49:49.556Z] slow step: Staff enter an invalid slug :: Pat is signed in as Memba staff :: 1125ms
      Given Kootenay Mountaineering Club is a club
      When Pat tries to change Kootenay Mountaineering Club's slug to "kmc club!"
      Then Memba should reject the club slug as invalid
      And Kootenay Mountaineering Club should keep its previous slug
  [acceptance 2026-06-09T06:49:50.926Z] scenario teardown start: Staff enter an invalid slug status=PASSED
  [acceptance 2026-06-09T06:49:50.934Z] scenario finish: Staff enter an invalid slug status=PASSED duration=2594ms
  
    Scenario: Staff enter a slug that another club already uses # features/staff_club_slugs.feature:25
  [acceptance 2026-06-09T06:49:50.937Z] scenario start: Staff enter a slug that another club already uses
  [acceptance 2026-06-09T06:49:50.987Z] scenario reset app state: Staff enter a slug that another club already uses
      Given Pat is signed in as Memba staff
  [acceptance 2026-06-09T06:49:52.161Z] slow step: Staff enter a slug that another club already uses :: Pat is signed in as Memba staff :: 1130ms
      Given Kootenay Mountaineering Club has the slug "kmc"
      And Nelson Paddling Club is a club
      When Pat tries to change Nelson Paddling Club's slug to "kmc"
      Then Memba should reject the club slug as already taken
      And Nelson Paddling Club should keep its previous slug
  [acceptance 2026-06-09T06:49:53.911Z] scenario teardown start: Staff enter a slug that another club already uses status=PASSED
  [acceptance 2026-06-09T06:49:53.920Z] scenario finish: Staff enter a slug that another club already uses status=PASSED duration=2983ms
  
    @not-domain
    Scenario: Robin opens an unknown club subdomain # features/staff_club_slugs.feature:35
  [acceptance 2026-06-09T06:49:53.925Z] scenario start: Robin opens an unknown club subdomain
  [acceptance 2026-06-09T06:49:53.974Z] scenario reset app state: Robin opens an unknown club subdomain
      Given Pat is signed in as Memba staff
  [acceptance 2026-06-09T06:49:55.150Z] slow step: Robin opens an unknown club subdomain :: Pat is signed in as Memba staff :: 1134ms
      When Robin opens "unknown.clubs.memba.io"
      Then Robin should see a not found page
  [acceptance 2026-06-09T06:49:55.251Z] scenario teardown start: Robin opens an unknown club subdomain status=PASSED
  [acceptance 2026-06-09T06:49:55.256Z] scenario finish: Robin opens an unknown club subdomain status=PASSED duration=1331ms
  
  [acceptance 2026-06-09T06:49:55.258Z] AfterAll: closing shared browser
  [acceptance 2026-06-09T06:49:55.297Z] AfterAll: closed shared browser
  [acceptance 2026-06-09T06:49:55.297Z] AfterAll: stopping Phoenix browser acceptance lifecycle
  [acceptance 2026-06-09T06:49:55.298Z] AfterAll: stopped Phoenix browser acceptance lifecycle
  73 scenarios (73 passed)
  489 steps (489 passed)
  3m32.121s (executing steps: 3m19.970s)
  ```

## Stage: collect_implementation_evidence
- Status: succeeded
- Handler: command
- Script: `set -eu
base_sha='4bbaa97b6cdd8bd810bcf1ffefff58f6f42c4bc1'
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
  (2294 lines omitted)
      assert text_for(html, "#request-row-#{request.request_id}") =~ "robin@example.com"
  
      assert text_for(html, "#request-row-#{request.request_id} [data-testid='admin-request-club']") =~
               "Verified Paddlers"
  
      assert text_for(html, "#request-row-#{request.request_id} [data-testid='admin-request-note']") =~
               "We need a safer way to message members."
  
      assert_selector_exists(
        html,
        "#reject-request-#{request.request_id}[data-admin-request-action='reject']"
      )
  
      assert_selector_exists(
        html,
        "#convert-request-#{request.request_id}[data-admin-request-action='convert']"
      )
    end
  
    test "staff requests index stays empty after an email-only Get Started verification", %{
      conn: conn
    } do
      configure_auth_email()
  
      verification_conn =
        post(conn, ~p"/get-started",
          verification: %{
            email: " Robin@Example.COM "
          }
        )
  
      assert redirected_to(verification_conn) == ~p"/auth/check-email"
      assert Onboarding.list_active_requests() == []
  
      assert [%SignInToken{email: "robin@example.com", consumed_at: nil}] = Repo.all(SignInToken)
  
      assert_email_sent(fn email ->
        assert email.to == [{"", "robin@example.com"}]
        assert email.subject == "Sign in to Memba"
        assert email.text_body =~ "/auth/sign-in/"
        assert email.text_body =~ "return_to=%2Fget-started"
        true
      end)
  
      refute_email_sent(to: [{"", "hello@memba.io"}])
  
      {:ok, view, _initial_html} =
        conn
        |> sign_in_staff()
        |> live(~p"/admin/requests")
  ```

## Stage: claude_review
- Status: succeeded
- Handler: prompt
- Model: claude-sonnet-4-5
- Tokens: 6.1k in / 8.5k out
- Response:
  > # Implementation Review Report: Iteration 030 - Verified Onboarding Requests
  > 
  > ## Decision: **ACCEPT**
  > 
  > ## Confidence: **High**
  > 
  > ## ADR Conformance: **PASS**
  > 
  > No ADRs were explicitly cited in the iteration plan. No ADR files appear in the changed file list. The implementation builds on existing infrastructure patterns visible in the codebase:
  > - Reuses `Auth.create_sign_in_token/2` for magic-link email verification
  > - Follows established Phoenix controller/template conventions
  > - Uses existing `Onboarding` context functions
  > - Maintains Staff notification patterns for verified requests only
  > 
  > The implementation introduces no new architectural decisions and follows Phoenix/Elixir/Ecto standard practices throughout.
  > 
  > ## ADR Violations
  > 
  > None identified.
  > 
  > ## Blocking Issues
  > 
  > None identified.
  > 
  > ## Bounded-Safe Fixes
  > 
  > 1. **Clearer conditional name assignment in request creation** (web/lib/memba_web/controllers/get_started_controller.ex:35-45)
  >    
  >    Current pattern builds `attrs` map with form `requester_name`, then conditionally overwrites it:
  >    ```elixir
  >    attrs = %{
  >      requester_email: identity.email,
  >      requester_name: request_params["requester_name"],
  >      club_name: String.trim(request_params["club_name"]),
  >      note: String.trim(request_params["note"] || "")
  >    }
  >    
  >    attrs =
  >      if person do
  >        Map.put(attrs, :requester_name, person.name)
  >      else
  >        attrs
  >      end
  >    ```
  >    
  >    Clearer intent with conditional in initial assignment:
  >    ```elixir
  >    attrs = %{
  >      requester_email: identity.email,
  >      requester_name: if(person, do: person.name, else: request_params["requester_name"]),
  >      club_name: String.trim(request_params["club_name"]),
  >      note: String.trim(request_params["note"] || "")
  >    }
  >    ```
  >    
  >    **Rationale**: Eliminates wasteful map construction and makes the "use person name when available" logic clearer at first read. Tests already verify this behaviour correctly.
  > 
  > 2. **Move string trimming to changeset validation** (web/lib/memba_web/controllers/get_started_controller.ex:37-38)
  >    
  >    Manual `String.trim()` calls in controller for `club_name` and `note` could move to `Onboarding.change_onboarding_request/1` changeset validation for consistency with Ecto conventions.
  >    
  >    **Rationale**: Controllers should delegate data transformation to contexts/changesets. This keeps controller focused on request flow and makes trimming behaviour testable at the domain layer.
  > 
  > ## Judgement-Worthy Non-Blocking Code-Health Findings
  > 
  > 1. **Email normalization duplication** (web/lib/memba_web/controllers/get_started_controller.ex:21)
  >    
  >    The pattern `String.trim(email) |> String.downcase()` appears in the controller. If this email normalization pattern is used elsewhere in the codebase (e.g., in `Auth` or `Identity` contexts), consider extracting to a shared helper like `Email.normalize/1`.
  >    
  >    **Why it may need judgement**: Current approach is clear and localized. Extraction only adds value if the pattern repeats across multiple contexts. Requires codebase-wide search to determine if centralization improves or complicates maintenance.
  > 
  > 2. **Two-form conditional rendering coupling** (web/lib/memba_web/controllers/get_started_html/show.html.heex)
  >    
  >    Single template with `if @current_identity` controlling two distinct forms creates coupling between signed-out verification flow and signed-in request flow.
  >    
  >    **Why it may need judgement**: Current approach is readable and keeps related flows together. Alternative of separate templates/views would increase file count but improve separation. Trade-off between cohesion (current) vs separation (alternative) depends on future evolution - if these flows diverge significantly, splitting becomes clearer; if they remain parallel, current approach is simpler.
  > 
  > 3. **Controller pattern-match clause ordering** (web/lib/memba_web/controllers/get_started_controller.ex:11-23)
  >    
  >    Using pattern-matching on `%{assigns: %{current_identity: %Identity{}}}` vs `current_identity: nil` in separate function clauses is idiomatic Elixir but creates implicit ordering dependency. Function clauses must remain in current order (specific patterns before general) or behaviour changes.
  >    
  >    **Why it may need judgement**: This is standard Elixir convention and tests verify both paths. However, as the controller grows, clause ordering becomes a maintenance consideration. Alternative guard clauses or explicit condition checks trade Elixir idioms for explicitness. Current approach is more functional/Elixir-native; alternatives would be more defensive but less idiomatic.
  > 
  > ## Suggested Fixes
  > 
  > If bounded-safe fixes are applied:
  > 
  > **Fix 1**: Simplify attrs construction in `create/2` request path:
  > ```elixir
  > def create(%{assigns: %{current_identity: identity}} = conn, %{"request" => request_params}) do
  >   person = Membership.get_person_by_email(identity.email)
  > 
  >   attrs = %{
  >     requester_email: identity.email,
  >     requester_name: if(person, do: person.name, else: request_params["requester_name"]),
  >     club_name: String.trim(request_params["club_name"]),
  >     note: String.trim(request_params["note"] || "")
  >   }
  > 
  >   case Onboarding.create_onboarding_request(attrs) do
  >     # ... rest unchanged
  >   end
  > end
  > ```
  > 
  > **Fix 2**: Move trimming to `Onboarding` context changesets. Update `Onboarding.change_onboarding_request/1` and related functions to trim `club_name` and `note` fields in changeset validation. Remove manual trimming from controller.
  > 
  > ## Validation Notes
  > 
  > **Tests/Checks Validating This Decision:**
  > 
  > 1. ✅ **Dev check passed completely** - No compilation warnings, Dialyzer clean, Credo clean, all tests green
  > 2. ✅ **Comprehensive controller test coverage** (web/test/memba_web/controllers/get_started_controller_test.exs):
  >    - Signed-out email verification flow
  >    - Magic-link token creation with return_to parameter
  >    - Email normalization (trim + downcase)
  >    - Signed-in request form for new identity
  >    - Signed-in request form for existing person
  >    - Person name override behaviour
  >    - Request creation with verified email only
  >    - No request/notification for email-only verification
  > 3. ✅ **Staff request visibility verification** (web/test/memba_web/live/admin_requests_live_test.exs):
  >    - Staff can see verified submitted requests
  >    - Staff request inbox stays empty after email-only verification
  >    - No staff notification email sent for verification-only flow
  > 4. ✅ **73 passing acceptance scenarios** including iteration-030 scenarios
  > 5. ✅ **Plan conformance validated** in prior workflow stage
  > 
  > **Manual/Runtime Checks Recommended:**
  > 
  > None required - automated test coverage and dev check success provide sufficient confidence.
  > 
  > **Acceptance Behaviour Verified:**
  > 
  > - Email verification creates sign-in token, sends magic link, sets return_to=/get-started
  > - Following magic link signs in identity and redirects to Get Started request form
  > - Request form pre-fills verified email (readonly)
  > - Request form uses existing person name when available (readonly)
  > - Request form collects new name when no person exists
  > - Request submission requires signed-in identity
  > - Staff only see and receive notifications for verified submitted requests
  > - No Person/club/membership created until Staff conversion


You are independently reviewing the completed, plan-conforming implementation of the iteration plan at docs/iterations/030-verified-onboarding-requests/plan.md.

Use the prior context: the plan text, collected implementation evidence, current working tree state, commit range from `4bbaa97b6cdd8bd810bcf1ffefff58f6f42c4bc1..HEAD`, and the successful dev check output. Be strict, practical, and specific. Do not edit files.

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