Goal: Review a completed plan-conforming iteration implementation for code polish, ADR conformance, and code-health signals
Run ID: 01KTFXCWNP930EVDCXG5AB5H5X
Pipeline progress: 6 of 28 stages completed

## Stage: read_plan
- Status: succeeded
- Handler: command
- Script: `PLAN_PATH='docs/iterations/024-email-template-designs/plan.md'
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
  (139 lines omitted)
     - converting plaintext message bodies to email-safe HTML;
     - rendering a primary button plus fallback URL;
     - rendering group-led and Memba-led headers;
     - rendering the Memba footer/trust footer without hard-coded unconfirmed support addresses.
  4. Update `web/lib/memba/accounts/auth_email.ex` to render the new sign-in template while preserving provider options and error handling. Keep `deliver_sign_in_link/2`; add an optional context/options variant for group-led sign-in where callers can provide group name/context.
  5. Update sign-in call sites only where group context is already available or cheaply derivable, such as club-subdomain sign-in. When no group context is available, keep the Memba-led sign-in subject/heading.
  6. Update `web/lib/memba/onboarding/welcome_email.ex` to use the compatible group-led welcome/sign-in variant and pass the converted club as context.
  7. Update member-message delivery HTML in `web/lib/memba/messaging/email_delivery_providers/postmark.ex` and `web/lib/memba/messaging/email_delivery_providers/local.ex`, extracting shared rendering so both paths stay aligned. Keep plain-text member-message bodies exactly as the sender wrote them.
  8. Update `web/lib/memba/messaging/inbound_club_rejection_email.ex` to use the new delivery-notice template, subject rules, reason copy, next-step copy, threading headers, and metadata.
  9. Update tests, especially:
     - `web/test/memba/accounts/auth_email_test.exs` for auth email Postmark/Resend/local provider options, HTML/text content, fallback URL, escaping, and context/no-context variants;
     - `web/test/memba/onboarding_conversion_test.exs` or a focused onboarding email test for welcome email link and group-led content;
     - existing member-message provider tests, or add focused tests near `web/test/memba/messaging/email_delivery_providers/`, for member-message HTML, unchanged text body, From/Reply-To, subject, metadata, and local delivery facts;
     - existing inbound email/rejection tests, or add `web/test/memba/messaging/inbound_club_rejection_email_test.exs`, for reason text, HTML, subject fallback, threading, and metadata/tags;
     - escaping/header-safety tests for group names, sender names, subjects, and message bodies with HTML/script-like text or newlines.
  10. Run targeted email-related tests while developing.
  11. Run any affected acceptance tests if mailbox text parsing changes.
  12. Run `dev check`.
  13. Record implementation notes and any deliberate deviations from the supplied designs in this iteration folder.
  
  ## Open Technical Decisions
  
  None known.
  
  ## New Capability
  
  Memba transactional emails will look and read like a coherent product system: group-led where members are interacting with their group, Memba-led where Memba is the carrier or account/trust actor, and consistently readable on iPads and common email clients.
  
  ## Validation Plan
  
  - Compare generated emails against the v2 source artifacts for semantic structure and copy hierarchy, not pixel-perfect browser-prototype fidelity.
  - Confirm sign-in email HTML includes a primary button with `href`, a printed fallback URL, expiry/one-use reassurance, and the Memba trust mark.
  - Confirm member-message HTML includes group-led header, sender-to-members line, escaped message body, reply guidance, and Memba carrier footer, while the text body remains exactly the sender's body.
  - Confirm inbound rejection HTML includes Memba-led header, group name if known, one reason line, next steps, and reassurance that nothing was posted.
  - Unit-test email fields, provider options, text bodies, key HTML content, escaping, header sanitization, fallback links, and reason mappings.
  - Use local Swoosh mailbox previews during implementation to manually inspect:
    - sign-in link;
    - onboarding welcome link;
    - member message;
    - inbound rejection notice.
  - If practical, inspect at desktop and mobile/iPad-like widths in the browser mailbox.
  - Run `dev check` before completion.
  
  ## Risks / Follow-ups
  
  - Email-client compatibility is easy to regress if templates use modern web CSS too literally. Implementation should translate the design into conservative email HTML rather than copy every browser-only style from the prototypes.
  - Exact design fidelity may need a follow-up after real mailbox screenshots from Gmail, Apple Mail, Outlook, and Fastmail.
  - Some ordinary sign-in requests may remain Memba-led when the current flow has no reliable group context; this is acceptable for this iteration and is covered by the no-context fallback acceptance criteria.
  - If Matt later wants to publish a support mailbox in email templates, confirm the mailbox/support process first and add it in a small follow-up.
  - A later i18n iteration can move copy strings behind locale-aware rendering.
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
  (200 lines omitted)
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
  Compiling lib/phoenix_live_view/test/live_view_test.ex (it's taking more than 10s)
  Compiling lib/phoenix_live_view/test/client_proxy.ex (it's taking more than 10s)
  Compiling lib/phoenix_component.ex (it's taking more than 10s)
  Compiling lib/phoenix_live_view/channel.ex (it's taking more than 10s)
  Generated phoenix_live_view app
  ==> phoenix_live_dashboard
  Compiling 36 files (.ex)
  Compiling lib/phoenix/live_dashboard/components/table_component.ex (it's taking more than 10s)
  Compiling lib/phoenix/live_dashboard/components/layered_graph_component.ex (it's taking more than 10s)
  Generated phoenix_live_dashboard app
  ==> phoenix_test
  Compiling 31 files (.ex)
  Compiling lib/phoenix_test/live.ex (it's taking more than 10s)
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
  (670 lines omitted)
  [acceptance 2026-06-07T02:44:19.655Z] scenario reset app state: Pat converts a request from an existing person
        Given Alice is a person in Memba
        And Alice has requested Memba access for Nelson Trail Society
        And Pat is signed in as Memba staff
  [acceptance 2026-06-07T02:44:21.738Z] slow step: Pat converts a request from an existing person :: Pat is signed in as Memba staff :: 1178ms
        When Pat converts Alice's Nelson Trail Society request
        Then Nelson Trail Society should exist as a club
        And Alice should be an active member of Nelson Trail Society
        And Memba should not create a duplicate person for Alice
  [acceptance 2026-06-07T02:44:23.799Z] scenario teardown start: Pat converts a request from an existing person status=PASSED
  [acceptance 2026-06-07T02:44:23.808Z] scenario finish: Pat converts a request from an existing person status=PASSED duration=4209ms
  
      Scenario: Pat rejects a request without notifying the requester # features/request_account.feature:45
  [acceptance 2026-06-07T02:44:23.808Z] scenario start: Pat rejects a request without notifying the requester
  [acceptance 2026-06-07T02:44:23.868Z] scenario reset app state: Pat rejects a request without notifying the requester
        Given Robin has requested Memba access for Suspicious Sender Club
        And Pat is signed in as Memba staff
  [acceptance 2026-06-07T02:44:25.506Z] slow step: Pat rejects a request without notifying the requester :: Pat is signed in as Memba staff :: 1177ms
        When Pat rejects Robin's Suspicious Sender Club request with the internal note "Looks like spam"
        Then Robin's request should leave the active requests inbox
        And Robin should not receive an email about the rejected request
  [acceptance 2026-06-07T02:44:27.034Z] slow step: Pat rejects a request without notifying the requester :: Robin should not receive an email about the rejected request :: 1020ms
        And Suspicious Sender Club should not exist as a club
        And Robin should not be able to sign in to Suspicious Sender Club
  [acceptance 2026-06-07T02:44:29.162Z] slow step: Pat rejects a request without notifying the requester :: Robin should not be able to sign in to Suspicious Sender Club :: 1721ms
  [acceptance 2026-06-07T02:44:29.162Z] scenario teardown start: Pat rejects a request without notifying the requester status=PASSED
  [acceptance 2026-06-07T02:44:29.172Z] scenario finish: Pat rejects a request without notifying the requester status=PASSED duration=5364ms
  
    Rule: Converted requesters receive direct club access
  
      Scenario: Robin receives a welcome sign-in link for the new club # features/request_account.feature:65
  [acceptance 2026-06-07T02:44:29.175Z] scenario start: Robin receives a welcome sign-in link for the new club
  [acceptance 2026-06-07T02:44:29.227Z] scenario reset app state: Robin receives a welcome sign-in link for the new club
        Given Robin has requested Memba access for West Coast Paddlers
        And Pat is signed in as Memba staff
  [acceptance 2026-06-07T02:44:30.881Z] slow step: Robin receives a welcome sign-in link for the new club :: Pat is signed in as Memba staff :: 1190ms
        When Pat converts Robin's West Coast Paddlers request
        Then Robin should receive a welcome email for West Coast Paddlers
        When Robin follows the welcome sign-in link
        Then Robin should be signed in to West Coast Paddlers
  [acceptance 2026-06-07T02:44:31.970Z] scenario teardown start: Robin receives a welcome sign-in link for the new club status=PASSED
  [acceptance 2026-06-07T02:44:31.979Z] scenario finish: Robin receives a welcome sign-in link for the new club status=PASSED duration=2804ms
  
  [acceptance 2026-06-07T02:44:31.980Z] AfterAll: closing shared browser
  [acceptance 2026-06-07T02:44:32.025Z] AfterAll: closed shared browser
  [acceptance 2026-06-07T02:44:32.025Z] AfterAll: stopping Phoenix browser acceptance lifecycle
  [acceptance 2026-06-07T02:44:32.026Z] AfterAll: stopped Phoenix browser acceptance lifecycle
  44 scenarios (44 passed)
  291 steps (291 passed)
  1m54.381s (executing steps: 1m42.925s)
  ```

## Stage: fix_dev_check
- Status: succeeded
- Handler: agent
- Model: gpt-5.5
- Tokens: 421.0k in / 6.5k out
- Response:
  > Full automated suite is passing now. No tracked code/config/test changes were needed.
  > 
  > ## Failure-to-fix mapping
  > 
  > | Preceding dev check failure | What I found / did | Files/modules involved |
  > |---|---|---|
  > | 52 ExUnit failures in `Memba.Membership.QueryTest`, all failing in `Memba.EventSourcedCase.stop_event_sourced_projectors!/0` because `Memba.Supervisor` was not alive | Could not reproduce. Re-ran Mix quality gate and the full ExUnit suite passed repeatedly with 585 tests / 0 failures. No product-code or test change was needed. | Inspected `web/test/support/event_sourced_case.ex`, `web/lib/memba/application.ex`, `web/test/memba/membership/query_test.exs` |
  > | Acceptance failure: `sh: line 1: cucumber-js: command not found` | Acceptance npm dependencies were not installed. Installed them inside the devenv shell with `devenv shell -- bash -lc 'cd acceptance-tests && npm ci'`. This creates ignored `acceptance-tests/node_modules/`; no tracked files changed. | `acceptance-tests/package.json`, `acceptance-tests/package-lock.json` define the dependency; ignored runtime artifact `acceptance-tests/node_modules/` installed |
  > 
  > ## Files changed
  > 
  > No tracked files changed.
  > 
  > Current tracked working tree remains clean except for the existing workflow temp dir:
  > 
  > ```text
  > ?? .fabro/tmp/
  > ```
  > 
  > ## Validation run
  > 
  > - `PATH="$PWD/bin:$PATH" dev check --quick`
  >   - Passed: `585 tests, 0 failures`
  > 
  > - `PATH="$PWD/bin:$PATH" dev ci` before installing npm deps
  >   - ExUnit passed: `585 tests, 0 failures`
  >   - Acceptance failed: `cucumber-js: command not found`
  > 
  > - `devenv shell -- bash -lc 'cd acceptance-tests && npm ci'`
  >   - Passed: installed 119 npm packages, 0 vulnerabilities
  > 
  > - `PATH="$PWD/bin:$PATH" dev ci`
  >   - Passed ExUnit: `585 tests, 0 failures`
  >   - Passed acceptance: `44 scenarios (44 passed)`, `291 steps (291 passed)`
  > 
  > ## Remaining failures / questions
  > 
  > None. The full `dev ci` quality gate now passes.

## Stage: dev_check
- Status: succeeded
- Handler: command
- Script: `PATH="$PWD/bin:$PATH" dev ci`
- Output:
  ```
  (670 lines omitted)
  [acceptance 2026-06-07T02:44:19.655Z] scenario reset app state: Pat converts a request from an existing person
        Given Alice is a person in Memba
        And Alice has requested Memba access for Nelson Trail Society
        And Pat is signed in as Memba staff
  [acceptance 2026-06-07T02:44:21.738Z] slow step: Pat converts a request from an existing person :: Pat is signed in as Memba staff :: 1178ms
        When Pat converts Alice's Nelson Trail Society request
        Then Nelson Trail Society should exist as a club
        And Alice should be an active member of Nelson Trail Society
        And Memba should not create a duplicate person for Alice
  [acceptance 2026-06-07T02:44:23.799Z] scenario teardown start: Pat converts a request from an existing person status=PASSED
  [acceptance 2026-06-07T02:44:23.808Z] scenario finish: Pat converts a request from an existing person status=PASSED duration=4209ms
  
      Scenario: Pat rejects a request without notifying the requester # features/request_account.feature:45
  [acceptance 2026-06-07T02:44:23.808Z] scenario start: Pat rejects a request without notifying the requester
  [acceptance 2026-06-07T02:44:23.868Z] scenario reset app state: Pat rejects a request without notifying the requester
        Given Robin has requested Memba access for Suspicious Sender Club
        And Pat is signed in as Memba staff
  [acceptance 2026-06-07T02:44:25.506Z] slow step: Pat rejects a request without notifying the requester :: Pat is signed in as Memba staff :: 1177ms
        When Pat rejects Robin's Suspicious Sender Club request with the internal note "Looks like spam"
        Then Robin's request should leave the active requests inbox
        And Robin should not receive an email about the rejected request
  [acceptance 2026-06-07T02:44:27.034Z] slow step: Pat rejects a request without notifying the requester :: Robin should not receive an email about the rejected request :: 1020ms
        And Suspicious Sender Club should not exist as a club
        And Robin should not be able to sign in to Suspicious Sender Club
  [acceptance 2026-06-07T02:44:29.162Z] slow step: Pat rejects a request without notifying the requester :: Robin should not be able to sign in to Suspicious Sender Club :: 1721ms
  [acceptance 2026-06-07T02:44:29.162Z] scenario teardown start: Pat rejects a request without notifying the requester status=PASSED
  [acceptance 2026-06-07T02:44:29.172Z] scenario finish: Pat rejects a request without notifying the requester status=PASSED duration=5364ms
  
    Rule: Converted requesters receive direct club access
  
      Scenario: Robin receives a welcome sign-in link for the new club # features/request_account.feature:65
  [acceptance 2026-06-07T02:44:29.175Z] scenario start: Robin receives a welcome sign-in link for the new club
  [acceptance 2026-06-07T02:44:29.227Z] scenario reset app state: Robin receives a welcome sign-in link for the new club
        Given Robin has requested Memba access for West Coast Paddlers
        And Pat is signed in as Memba staff
  [acceptance 2026-06-07T02:44:30.881Z] slow step: Robin receives a welcome sign-in link for the new club :: Pat is signed in as Memba staff :: 1190ms
        When Pat converts Robin's West Coast Paddlers request
        Then Robin should receive a welcome email for West Coast Paddlers
        When Robin follows the welcome sign-in link
        Then Robin should be signed in to West Coast Paddlers
  [acceptance 2026-06-07T02:44:31.970Z] scenario teardown start: Robin receives a welcome sign-in link for the new club status=PASSED
  [acceptance 2026-06-07T02:44:31.979Z] scenario finish: Robin receives a welcome sign-in link for the new club status=PASSED duration=2804ms
  
  [acceptance 2026-06-07T02:44:31.980Z] AfterAll: closing shared browser
  [acceptance 2026-06-07T02:44:32.025Z] AfterAll: closed shared browser
  [acceptance 2026-06-07T02:44:32.025Z] AfterAll: stopping Phoenix browser acceptance lifecycle
  [acceptance 2026-06-07T02:44:32.026Z] AfterAll: stopped Phoenix browser acceptance lifecycle
  44 scenarios (44 passed)
  291 steps (291 passed)
  1m54.381s (executing steps: 1m42.925s)
  ```

## Stage: collect_implementation_evidence
- Status: succeeded
- Handler: command
- Script: `set -eu
base_sha='8dc16d48dcc10f31c6d75519205652da56d1419c'
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
  (4389 lines omitted)
               provider_message_id: "email_controller_duplicate",
               provider_event_id: "evt_controller_duplicate_first",
               status: "accepted"
             } = Messaging.get_inbound_email_source("resend", "email_controller_duplicate")
    end
  
    test "records rejection paths and does not send duplicate rejection emails on provider retries",
         %{
           conn: conn
         } do
      kmc = create_club!(name: "Kootenay Mountaineering Club", slug: "kmc")
      alice = create_person!(name: "Alice Example", email: "alice@example.com")
  
      add_member!(kmc.club_id, alice.person_id)
  
      payload =
        valid_payload(%{
          "id" => "evt_controller_attachment_rejected",
          "data" => %{
            "email_id" => "email_controller_attachment_rejected",
            "from" => "Alice Example <alice@example.com>",
            "to" => ["KMC <kmc@clubs.memba.io>"],
            "subject" => "Trip planning night",
            "text" => "See the attached route.",
            "attachments" => [
              %{
                "filename" => "route.gpx",
                "content_type" => "application/gpx+xml",
                "size" => "1234"
              }
            ]
          }
        })
  
      conn = post_resend_inbound_event(conn, payload)
  
      assert %{"status" => "accepted"} = json_response(conn, 202)
      assert [] = Messaging.list_messages_for_club(kmc.club_id)
      assert [] = Fake.deliveries()
  
      assert %{
               provider: "resend",
               provider_message_id: "email_controller_attachment_rejected",
               provider_event_id: "evt_controller_attachment_rejected",
               from_address: "alice@example.com",
               to_address: "kmc@clubs.memba.io",
               status: "rejected",
               message_id: nil,
               rejection_reason: "attachments_not_supported",
               rejection_email_delivery_reference: rejection_email_delivery_reference
  ```


You are independently reviewing the completed, plan-conforming implementation of the iteration plan at docs/iterations/024-email-template-designs/plan.md.

Use the prior context: the plan text, collected implementation evidence, current working tree state, commit range from `8dc16d48dcc10f31c6d75519205652da56d1419c..HEAD`, and the successful dev check output. Be strict, practical, and specific. Do not edit files.

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