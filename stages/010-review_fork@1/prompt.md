Goal: Review a completed plan-conforming iteration implementation for code polish, ADR conformance, and code-health signals
Run ID: 01KT7JTDGDNHCJYCMPJ28VWD0S
Pipeline progress: 8 of 28 stages completed

## Stage: read_plan
- Status: succeeded
- Handler: command
- Script: `PLAN_PATH='docs/iterations/020-migrate-production-email-to-postmark/plan.md'
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
  (99 lines omitted)
  6. Reuse iteration 019's provider-neutral command/API for all accepted/rejected behaviour rather than duplicating business rules in Postmark-specific code.
  7. Add Postmark inbound idempotency support using the stable provider message id or equivalent payload field.
  8. Add tests for Postmark inbound payload parsing and controller/dispatcher behaviour, including accepted primary-address sender, alternate-address sender where practical, rejection cases, attachments, HTML-only/missing plain text, and duplicate retry handling.
  9. Verify or add tests proving Postmark outbound member-message payloads still include sender/reply-to, text/HTML bodies, and correlation metadata expected by the Postmark delivery-status webhook handler.
  10. Verify or add tests proving Postmark auth email configuration uses `MEMBA_AUTH_EMAIL_PROVIDER=postmark`, `MEMBA_POSTMARK_SERVER_TOKEN`, `MEMBA_AUTH_EMAIL_FROM_ADDRESS`, and `MEMBA_AUTH_EMAIL_MESSAGE_STREAM`, and fails clearly when incomplete.
  11. Verify rejection-email delivery follows the configured mailer/provider path and works when Postmark is selected.
  12. Update `docs/postmark-email.md` to describe the full Postmark production setup: outbound member-message stream, auth stream, inbound club-message routing for `clubs.memba.io`, delivery-status webhook URL, inbound webhook URL, environment variables, and local smoke-test guidance.
  13. Update `docs/human-todo.md` or add a runbook under this iteration folder with Matt's manual cutover steps, smoke tests, monitoring checks, and rollback steps to Resend.
  14. Update ADR/documentation as needed to reflect that Postmark is the intended primary production provider after approval, while Resend remains a first-class fallback.
  15. Run targeted tests for Postmark inbound, Resend inbound regression, Postmark outbound delivery, auth email configuration, and provider selection.
  16. Run `dev check`.
  
  ## Open Technical Decisions
  
  Implementation should investigate and decide:
  
  - The exact Postmark inbound webhook payload shape and which field is the best stable provider message id for idempotency.
  - Whether Postmark inbound email and delivery-status events should use two separate routes or one dispatching route, based on Postmark configuration capabilities and the existing `/webhooks/postmark` controller.
  - The exact Postmark inbound domain/MX setup needed to preserve `<club-slug>@clubs.memba.io`.
  - Whether Postmark inbound webhooks provide attachment metadata without downloading attachments, and how to detect attachments early enough to preserve the iteration 019 rejection rule.
  - Whether any provider-specific inbound authentication is available and already configured; do not expand into a security iteration unless small and non-disruptive.
  
  ## New Capability
  
  Memba can receive, send, and operationally validate all production email paths through Postmark while preserving Resend as a fallback. Matt has a concrete runbook for a manual production cutover and rollback.
  
  ## Validation Plan
  
  - Run focused tests for Postmark inbound payload parsing/translation.
  - Run focused tests for provider-neutral inbound command/API regressions from iteration 019.
  - Run focused tests for Resend inbound parsing to confirm fallback support still works.
  - Run focused tests for Postmark outbound member-message payload metadata and delivery-status webhook correlation.
  - Run focused tests for Postmark auth email configuration and missing-config errors.
  - Run `dev check`.
  - Manual cutover smoke test from the runbook after Matt changes production configuration:
    1. Confirm Postmark outbound member-message stream, auth stream, inbound routing for `clubs.memba.io`, and webhooks are configured.
    2. Set production secrets to select Postmark for member-message delivery and auth email.
    3. Send a magic link to a controlled inbox, confirm receipt from the Postmark auth sender, and sign in successfully.
    4. Send a member message from the web UI, confirm Postmark accepts and delivers it, and confirm delivery-status webhook updates Memba.
    5. Email `kmc@clubs.memba.io` from an active member address, confirm Memba creates and distributes the club message.
    6. Email `kmc@clubs.memba.io` from an unsupported sender or with an unsupported attachment, confirm no club message is created and the rejection email is delivered through Postmark.
    7. Confirm Resend rollback instructions are complete and the required Resend secrets/webhooks are still available.
  
  ## Risks / Follow-ups
  
  - Postmark inbound payloads may differ enough from Resend that the provider-neutral API needs small adjustments. Keep changes provider-neutral and preserve Resend tests.
  - Inbound domain/MX setup for `clubs.memba.io` may require DNS/provider dashboard work that cannot be completed by code delivery alone; document it clearly for Matt's manual cutover.
  - Production cutover risk includes missed MX propagation, webhook misconfiguration, missing secrets, or sender-domain reputation issues. The runbook and rollback path mitigate this.
  - Webhook authentication remains a known follow-up security concern from ADR 0016 and the provider webhook authentication kaizen note.
  - Keeping both providers increases maintenance cost, but it is valuable while Memba is still proving deliverability and provider fit.
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
  (2 lines omitted)
  • Configuring shell
  • Configuring cachix
  ✓ Configuring cachix in 3.53ms
  • Evaluating shell
  ✓ Evaluating shell in 1.99ms (cached)
  ✓ Configuring shell in 12.0ms
  • Loading tasks
  • Evaluating devenv.config.task.config
  ✓ Evaluating devenv.config.task.config in 93.2µs (cached)
  ✓ Loading tasks in 3.09ms
  • Running tasks
  • Running devenv:files:cleanup
  ✓ Running devenv:files:cleanup in 14.0ms
  • Running devenv:enterShell
  ✓ Running devenv:enterShell in 11.5ms
  • Running devenv:enterTest
  ✓ Running devenv:enterTest in 83.1µs (no command)
  ✓ Running tasks in 26.4ms
  ✨ devenv 2.1.0 is out of date. Please update to 2.1.2: https://devenv.sh/getting-started/#installation
  Memba dev environment
  Web app: web/
  Acceptance tests: acceptance-tests/
  Erlang/OTP 27 [erts-15.2.7.8] [source] [64-bit] [smp:8:1] [ds:8:1:10] [async-threads:1] [jit:ns]
  
  Elixir 1.18.4 (compiled with Erlang/OTP 27)
  • Validating lock
  ✓ Validating lock in 20.0ms
  Running ExUnit with seed: 780967, max_cases: 2
  
  ..........................................................................................................................................................................................................................................................................................................................................................................Seeded representative Memba data.
  Member sign-in emails: alice@example.com, bob@example.com, carol@example.com
  Alice alternate sign-in email: alice@work.example
  Memba staff sign-in email: pat@memba.io
  Smoke-test member sign-in email: test@memba.io
  Smoke-test inbound email address: test@clubs.memba.io
  ..............................................20:44:38.609 request_id=GLWtCD4jT2sxzCEABUQB [warning] Rejected auth sign-in link callback: :consumed
  .........20:44:38.651 request_id=GLWtCECm0IUouiEABUYh [warning] Rejected auth sign-in link callback: :expired
  ...20:44:38.669 request_id=GLWtCEG_5_zma5UABUdh [warning] Rejected auth sign-in link callback: :not_found
  ...........................................................................
  Finished in 26.1 seconds (10.6s async, 15.4s sync)
  495 tests, 0 failures
  
  > memba-acceptance-tests@0.1.0 test
  > cucumber-js
  
  ...........................................................................................................................................................................................................................................................................................
  
  34 scenarios (34 passed)
  215 steps (215 passed)
  3m12.777s (executing steps: 3m00.992s)
  ```

## Stage: fix_dev_check
- Status: succeeded
- Handler: agent
- Model: gpt-5.5
- Tokens: 78.1k in / 2.7k out
- Response:
  > ## Summary
  > 
  > The dev check failure did **not** require code/config/test changes.
  > 
  > The preceding failure was caused by missing local acceptance-test dependencies (`cucumber-js` binary absent because `acceptance-tests/node_modules` was not installed), not by the Postmark iteration implementation.
  > 
  > ## 1. Dev check failures reviewed
  > 
  > | Failure | Evidence | Diagnosis |
  > |---|---|---|
  > | Acceptance tests failed with `cucumber-js: command not found` | `npm test` in `acceptance-tests` could not find `cucumber-js` | `@cucumber/cucumber` is already declared and locked; `acceptance-tests/node_modules` was absent locally |
  > | Subsequent retry failed dropping `memba_test` | `database "memba_test" is being accessed by other users` with 10 sessions | Stale acceptance-test/server/browser processes remained from a timed-out `dev ci` run |
  > 
  > ## 2. Changes made
  > 
  > No tracked repository files were changed.
  > 
  > Actions taken:
  > 
  > - Installed the already-locked acceptance-test dependencies locally:
  > 
  >   ```sh
  >   cd acceptance-tests && NPM_CONFIG_CACHE="$PWD/../.fabro/tmp/npm-cache" npm ci
  >   ```
  > 
  >   This avoided the sandbox’s unwritable default npm cache path at `/env/.npm`.
  > 
  > - Cleaned up stale local test processes left by the timed-out run:
  >   - `cucumber-js` / `node`
  >   - Phoenix test server / BEAM
  >   - Playwright Chromium processes
  > 
  > No source code, tests, package manifests, lockfiles, `bin/dev`, or acceptance feature files were modified.
  > 
  > ## 3. Files changed
  > 
  > None.
  > 
  > Current tracked working tree remains unchanged. `git status --short` shows only:
  > 
  > ```text
  > ?? .fabro/tmp/
  > ```
  > 
  > `acceptance-tests/node_modules` now exists locally as an ignored/generated dependency artifact.
  > 
  > ## 4. Tests run
  > 
  > | Command | Result |
  > |---|---|
  > | `cd acceptance-tests && NPM_CONFIG_CACHE="$PWD/../.fabro/tmp/npm-cache" npm ci` | Passed |
  > | `PATH="$PWD/bin:$PATH" dev ci` | Timed out once, leaving stale test processes |
  > | `PATH="$PWD/bin:$PATH" dev ci` after timeout | Failed due stale DB sessions |
  > | Cleaned stale local test processes | Succeeded |
  > | `PATH="$PWD/bin:$PATH" dev ci` | Passed |
  > 
  > Final successful result:
  > 
  > ```text
  > 495 tests, 0 failures
  > 
  > 34 scenarios (34 passed)
  > 215 steps (215 passed)
  > ```
  > 
  > ## 5. Remaining failures / human questions
  > 
  > None.
  > 
  > ## Failure-to-fix mapping
  > 
  > | Dev check failure | Fix / status | Files/modules |
  > |---|---|---|
  > | `cucumber-js: command not found` | Installed locked acceptance dependencies locally using a writable temporary npm cache. No repo change needed. | None |
  > | `memba_test` database in use | Terminated stale local acceptance/server/browser processes from timed-out check. No repo change needed. | None |

## Stage: dev_check
- Status: succeeded
- Handler: command
- Script: `PATH="$PWD/bin:$PATH" dev ci`
- Output:
  ```
  (2 lines omitted)
  • Configuring shell
  • Configuring cachix
  ✓ Configuring cachix in 3.53ms
  • Evaluating shell
  ✓ Evaluating shell in 1.99ms (cached)
  ✓ Configuring shell in 12.0ms
  • Loading tasks
  • Evaluating devenv.config.task.config
  ✓ Evaluating devenv.config.task.config in 93.2µs (cached)
  ✓ Loading tasks in 3.09ms
  • Running tasks
  • Running devenv:files:cleanup
  ✓ Running devenv:files:cleanup in 14.0ms
  • Running devenv:enterShell
  ✓ Running devenv:enterShell in 11.5ms
  • Running devenv:enterTest
  ✓ Running devenv:enterTest in 83.1µs (no command)
  ✓ Running tasks in 26.4ms
  ✨ devenv 2.1.0 is out of date. Please update to 2.1.2: https://devenv.sh/getting-started/#installation
  Memba dev environment
  Web app: web/
  Acceptance tests: acceptance-tests/
  Erlang/OTP 27 [erts-15.2.7.8] [source] [64-bit] [smp:8:1] [ds:8:1:10] [async-threads:1] [jit:ns]
  
  Elixir 1.18.4 (compiled with Erlang/OTP 27)
  • Validating lock
  ✓ Validating lock in 20.0ms
  Running ExUnit with seed: 780967, max_cases: 2
  
  ..........................................................................................................................................................................................................................................................................................................................................................................Seeded representative Memba data.
  Member sign-in emails: alice@example.com, bob@example.com, carol@example.com
  Alice alternate sign-in email: alice@work.example
  Memba staff sign-in email: pat@memba.io
  Smoke-test member sign-in email: test@memba.io
  Smoke-test inbound email address: test@clubs.memba.io
  ..............................................20:44:38.609 request_id=GLWtCD4jT2sxzCEABUQB [warning] Rejected auth sign-in link callback: :consumed
  .........20:44:38.651 request_id=GLWtCECm0IUouiEABUYh [warning] Rejected auth sign-in link callback: :expired
  ...20:44:38.669 request_id=GLWtCEG_5_zma5UABUdh [warning] Rejected auth sign-in link callback: :not_found
  ...........................................................................
  Finished in 26.1 seconds (10.6s async, 15.4s sync)
  495 tests, 0 failures
  
  > memba-acceptance-tests@0.1.0 test
  > cucumber-js
  
  ...........................................................................................................................................................................................................................................................................................
  
  34 scenarios (34 passed)
  215 steps (215 passed)
  3m12.777s (executing steps: 3m00.992s)
  ```

## Stage: fix_dev_check
- Status: succeeded
- Handler: agent
- Model: gpt-5.5
- Tokens: 78.1k in / 2.7k out
- Response:
  > ## Summary
  > 
  > The dev check failure did **not** require code/config/test changes.
  > 
  > The preceding failure was caused by missing local acceptance-test dependencies (`cucumber-js` binary absent because `acceptance-tests/node_modules` was not installed), not by the Postmark iteration implementation.
  > 
  > ## 1. Dev check failures reviewed
  > 
  > | Failure | Evidence | Diagnosis |
  > |---|---|---|
  > | Acceptance tests failed with `cucumber-js: command not found` | `npm test` in `acceptance-tests` could not find `cucumber-js` | `@cucumber/cucumber` is already declared and locked; `acceptance-tests/node_modules` was absent locally |
  > | Subsequent retry failed dropping `memba_test` | `database "memba_test" is being accessed by other users` with 10 sessions | Stale acceptance-test/server/browser processes remained from a timed-out `dev ci` run |
  > 
  > ## 2. Changes made
  > 
  > No tracked repository files were changed.
  > 
  > Actions taken:
  > 
  > - Installed the already-locked acceptance-test dependencies locally:
  > 
  >   ```sh
  >   cd acceptance-tests && NPM_CONFIG_CACHE="$PWD/../.fabro/tmp/npm-cache" npm ci
  >   ```
  > 
  >   This avoided the sandbox’s unwritable default npm cache path at `/env/.npm`.
  > 
  > - Cleaned up stale local test processes left by the timed-out run:
  >   - `cucumber-js` / `node`
  >   - Phoenix test server / BEAM
  >   - Playwright Chromium processes
  > 
  > No source code, tests, package manifests, lockfiles, `bin/dev`, or acceptance feature files were modified.
  > 
  > ## 3. Files changed
  > 
  > None.
  > 
  > Current tracked working tree remains unchanged. `git status --short` shows only:
  > 
  > ```text
  > ?? .fabro/tmp/
  > ```
  > 
  > `acceptance-tests/node_modules` now exists locally as an ignored/generated dependency artifact.
  > 
  > ## 4. Tests run
  > 
  > | Command | Result |
  > |---|---|
  > | `cd acceptance-tests && NPM_CONFIG_CACHE="$PWD/../.fabro/tmp/npm-cache" npm ci` | Passed |
  > | `PATH="$PWD/bin:$PATH" dev ci` | Timed out once, leaving stale test processes |
  > | `PATH="$PWD/bin:$PATH" dev ci` after timeout | Failed due stale DB sessions |
  > | Cleaned stale local test processes | Succeeded |
  > | `PATH="$PWD/bin:$PATH" dev ci` | Passed |
  > 
  > Final successful result:
  > 
  > ```text
  > 495 tests, 0 failures
  > 
  > 34 scenarios (34 passed)
  > 215 steps (215 passed)
  > ```
  > 
  > ## 5. Remaining failures / human questions
  > 
  > None.
  > 
  > ## Failure-to-fix mapping
  > 
  > | Dev check failure | Fix / status | Files/modules |
  > |---|---|---|
  > | `cucumber-js: command not found` | Installed locked acceptance dependencies locally using a writable temporary npm cache. No repo change needed. | None |
  > | `memba_test` database in use | Terminated stale local acceptance/server/browser processes from timed-out check. No repo change needed. | None |

## Stage: dev_check
- Status: succeeded
- Handler: command
- Script: `PATH="$PWD/bin:$PATH" dev ci`
- Output:
  ```
  (2 lines omitted)
  • Configuring shell
  • Configuring cachix
  ✓ Configuring cachix in 3.53ms
  • Evaluating shell
  ✓ Evaluating shell in 1.99ms (cached)
  ✓ Configuring shell in 12.0ms
  • Loading tasks
  • Evaluating devenv.config.task.config
  ✓ Evaluating devenv.config.task.config in 93.2µs (cached)
  ✓ Loading tasks in 3.09ms
  • Running tasks
  • Running devenv:files:cleanup
  ✓ Running devenv:files:cleanup in 14.0ms
  • Running devenv:enterShell
  ✓ Running devenv:enterShell in 11.5ms
  • Running devenv:enterTest
  ✓ Running devenv:enterTest in 83.1µs (no command)
  ✓ Running tasks in 26.4ms
  ✨ devenv 2.1.0 is out of date. Please update to 2.1.2: https://devenv.sh/getting-started/#installation
  Memba dev environment
  Web app: web/
  Acceptance tests: acceptance-tests/
  Erlang/OTP 27 [erts-15.2.7.8] [source] [64-bit] [smp:8:1] [ds:8:1:10] [async-threads:1] [jit:ns]
  
  Elixir 1.18.4 (compiled with Erlang/OTP 27)
  • Validating lock
  ✓ Validating lock in 20.0ms
  Running ExUnit with seed: 780967, max_cases: 2
  
  ..........................................................................................................................................................................................................................................................................................................................................................................Seeded representative Memba data.
  Member sign-in emails: alice@example.com, bob@example.com, carol@example.com
  Alice alternate sign-in email: alice@work.example
  Memba staff sign-in email: pat@memba.io
  Smoke-test member sign-in email: test@memba.io
  Smoke-test inbound email address: test@clubs.memba.io
  ..............................................20:44:38.609 request_id=GLWtCD4jT2sxzCEABUQB [warning] Rejected auth sign-in link callback: :consumed
  .........20:44:38.651 request_id=GLWtCECm0IUouiEABUYh [warning] Rejected auth sign-in link callback: :expired
  ...20:44:38.669 request_id=GLWtCEG_5_zma5UABUdh [warning] Rejected auth sign-in link callback: :not_found
  ...........................................................................
  Finished in 26.1 seconds (10.6s async, 15.4s sync)
  495 tests, 0 failures
  
  > memba-acceptance-tests@0.1.0 test
  > cucumber-js
  
  ...........................................................................................................................................................................................................................................................................................
  
  34 scenarios (34 passed)
  215 steps (215 passed)
  3m12.777s (executing steps: 3m00.992s)
  ```

## Stage: collect_implementation_evidence
- Status: succeeded
- Handler: command
- Script: `set -eu
base_sha='1b8421e20e936bf2de0df8ff4f3aa64e1931e112'
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
  (3233 lines omitted)
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
  
    defp assert_live_route(path, route_pattern, live_view, path_params) do
      assert %{
               pipe_through: [:staff_browser],
               phoenix_live_view: {^live_view, nil, _opts, _live_session},
               plug: Phoenix.LiveView.Plug,
               plug_opts: nil,
               path_params: ^path_params,
               route: ^route_pattern
             } = Phoenix.Router.route_info(MembaWeb.Router, "GET", path, "localhost")
    end
  end
  ```


You are independently reviewing the completed, plan-conforming implementation of the iteration plan at docs/iterations/020-migrate-production-email-to-postmark/plan.md.

Use the prior context: the plan text, collected implementation evidence, current working tree state, commit range from `1b8421e20e936bf2de0df8ff4f3aa64e1931e112..HEAD`, and the successful dev check output. Be strict, practical, and specific. Do not edit files.

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