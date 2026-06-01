Goal: Review a completed plan-conforming iteration implementation for code polish, ADR conformance, and code-health signals
Run ID: 01KT1A2TXBEJAVJTMWJVSCJ56S
Pipeline progress: 4 of 28 stages completed

## Stage: read_plan
- Status: succeeded
- Handler: command
- Script: `PLAN_PATH='docs/iterations/012-member-receipt-detail-liveview-polish/plan.md'
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
  (138 lines omitted)
     - all visible groups collapsed initially;
     - `handle_event("toggle_receipt_group", ...)` toggles a status key;
     - avoid custom JavaScript unless needed.
  8. Preserve the existing stable DOM/test attributes for recipient rows.
  9. Update browser acceptance support, if needed, so existing member-message scenarios can find addressed recipient rows by expanding the relevant visible group before asserting row content. Do not change the Gherkin feature text for this iteration.
  10. Add focused LiveView/ConnCase tests covering:
     - route and authorization behaviours preserved;
     - summary counts and percentages for mixed statuses;
     - all visible groups collapsed by default;
     - expand/collapse reveals and hides rows;
     - zero-count statuses appear in the summary only, not as empty expandable groups;
     - no operator-only fields appear on the member page.
  11. Run the existing member-message browser Cucumber scenarios and `dev check`.
  
  ## Open Technical Decisions
  
  - Exact LiveView module name and whether small helper functions live in the LiveView or a presentation module. Prefer simple module boundaries that keep receipt calculations testable without over-engineering.
  
  Resolved for this plan:
  
  - Zero-count statuses appear in the “Who got this” summary only, with count `0` and `0%`. They do not appear as empty collapsible group headers in the recipient list.
  - Existing Gherkin scenarios remain unchanged. Browser acceptance support may expand the relevant visible receipt group before asserting addressed recipient rows, while LiveView tests cover the collapse/expand UI behaviour directly.
  - Percentages are displayed as whole numbers by rounding each status independently from addressed-recipient totals; displayed status percentages are not force-adjusted to sum to exactly 100.
  
  ## New Capability
  
  Members can scan a message's reach using a summary bar with counts and percentages, then expand specific receipt groups to see which members are in each status without leaving the page.
  
  ## Validation Plan
  
  - Run `dev check`.
  - Run targeted LiveView/Phoenix tests for the new member message detail LiveView.
  - Confirm existing `acceptance-tests/features/member_message_deliverability.feature` passes unchanged through the browser runner; if row assertions fail because groups are collapsed, fix the browser support to expand the relevant group rather than changing the feature language.
  - Manual demo:
    - sign in as Alice;
    - open a message with mixed receipt statuses;
    - confirm the summary bar shows all four statuses, including any zero-count statuses;
    - confirm zero-count statuses do not appear as empty groups in the recipient list;
    - confirm non-empty group counts, percentages, descriptions, and default collapsed state;
    - expand and collapse each non-empty group;
    - confirm recipient rows appear only when their group is expanded;
    - confirm no operator-only details are visible;
    - confirm `/admin/*` diagnostics still show operator detail for staff.
  
  ## Risks / Follow-ups
  
  - LiveView conversion may require carefully preserving controller-era auth and error semantics.
  - Browser acceptance support may need a small update to expand the relevant group before asserting recipient rows; keep this in support code and leave the feature language unchanged.
  - Percent rounding can produce totals that do not add exactly to 100%; this plan uses deterministic independent status rounding and accepts non-100 displayed totals.
  - This does not address dashboard polish or separate compose screens; those remain good future iterations.
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
  (215 lines omitted)
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
  • Validating lock
  ✓ Validating lock in 20.6ms
  Manager did not shut down within 30 seconds, sending SIGKILL
  ```

## Stage: dev_check
- Status: succeeded
- Handler: command
- Script: `PATH="$PWD/bin:$PATH" dev ci`
- Output:
  ```
  (37 lines omitted)
  ✓ Running devenv:enterTest in 87.0µs (no command)
  ✓ Running tasks in 24.7ms
  ✨ devenv 2.1.0 is out of date. Please update to 2.1.2: https://devenv.sh/getting-started/#installation
  Memba dev environment
  Web app: web/
  Acceptance tests: acceptance-tests/
  Erlang/OTP 27 [erts-15.2.7.8] [source] [64-bit] [smp:8:1] [ds:8:1:10] [async-threads:1] [jit:ns]
  
  Elixir 1.18.4 (compiled with Erlang/OTP 27)
  • Validating lock
  ✓ Validating lock in 19.5ms
  • Configuring cachix
  ✓ Configuring cachix in 4.63ms
  • Configuring shell
  • Evaluating shell
  ✓ Evaluating shell in 3.14s
  ✓ Configuring shell in 3.58s
  • Evaluating Nix
  ✓ Evaluating Nix in 3.14ms
  • Loading tasks
  • Evaluating devenv.config.task.config
  ✓ Evaluating devenv.config.task.config in 1.92ms
  ✓ Loading tasks in 2.39ms
  • Running tasks
  • Running devenv:files:cleanup
  ✓ Running devenv:files:cleanup in 11.0ms
  • Running devenv:enterShell
  ✓ Running devenv:enterShell in 11.6ms
  • Running devenv:enterTest
  ✓ Running devenv:enterTest in 88.0µs (no command)
  ✓ Running tasks in 23.5ms
  • Running processes
  • Evaluating Nix
  ✓ Evaluating Nix in 1.56ms
  ✓ Running processes in 2.13s
  • Validating lock
  ✓ Validating lock in 20.4ms
  Compiling 94 files (.ex)
  Generated memba app
  Running ExUnit with seed: 898915, max_cases: 2
  
  .....................................................................................................................................................10:05:55.484 request_id=GLTtBE9NSzG5UXwAAh6B [warning] Rejected auth magic link callback: :expired
  .10:05:55.487 request_id=GLTtBE96M42tC_MAAh6h [warning] Rejected auth magic link callback: :consumed
  ..10:05:55.490 request_id=GLTtBE-hl6OCDMMAAh7h [warning] Rejected auth magic link callback: :not_found
  ..............................................................................
  Finished in 10.9 seconds (4.9s async, 6.0s sync)
  230 tests, 0 failures
  • Validating lock
  ✓ Validating lock in 19.5ms
  Manager did not shut down within 30 seconds, sending SIGKILL
  ```

## Stage: collect_implementation_evidence
- Status: succeeded
- Handler: command
- Script: `set -eu
base_sha='5d0a18418cf5735ed22d6037f504946a649be174'
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
  (2189 lines omitted)
                   "/webhooks/postmark",
                   "localhost"
                 )
      end
    end
  
    describe "member message routes" do
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


You are independently reviewing the completed, plan-conforming implementation of the iteration plan at docs/iterations/012-member-receipt-detail-liveview-polish/plan.md.

Use the prior context: the plan text, collected implementation evidence, current working tree state, commit range from `5d0a18418cf5735ed22d6037f504946a649be174..HEAD`, and the successful dev check output. Be strict, practical, and specific. Do not edit files.

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