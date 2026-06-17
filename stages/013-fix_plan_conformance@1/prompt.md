Goal: Implement a validated iteration plan and leave the codebase passing dev check
Run ID: 01KVBSQVSDNZJ67FQQ3NCFSPAY
Pipeline progress: 11 of 32 stages completed

## Stage: read_plan
- Status: succeeded
- Handler: command
- Script: `PLAN_PATH='docs/iterations/033-homepage-staff-bar/plan.md'
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
  (77 lines omitted)
  
  - Placement: first child inside `#signed-in-home`, above `<header>`.
  - Copy (verbatim from the design):
    - Tag: "Memba staff"
    - Description: "You have operator access across every group on Memba."
    - Link: "Open the staff console"
  - Colours follow the design: sage-700 bar with cream text; translucent-white tag and link surfaces.
  - The descriptive text is hidden below the `sm` breakpoint so the bar stays tidy and does not overflow on phones; the tag and console link remain visible at all widths.
  - The console link carries a trailing external-link icon (`hero-arrow-top-right-on-square-mini`).
  
  ## Implementation Plan
  
  1. Inspect the current homepage template (`web/lib/memba_web/controllers/page_html/home.html.heex`) and the existing staff-access acceptance support (`acceptance-tests/features/support/homepage.js`).
  2. Update `assertHomepageStaffAccess` to assert the staff bar: `a#staff-console-link` visible and linking to `/admin/clubs`, plus the visible "Memba staff" tag. Watch the two `homepage.feature` staff scenarios fail against the current button.
  3. Add the staff bar markup to the signed-in branch of the homepage template, gated on `@current_identity_staff?`, above `<header>`.
  4. Remove the existing "Memba staff" nav button block (`#admin-home-link`) from the signed-in nav.
  5. Run the homepage Cucumber scenarios; confirm they pass.
  6. Run `dev check`; fix any issues.
  7. Visual check against the design (pull `wireframes/home.html` staff mode; confirm tag/text/link and narrow-screen behaviour).
  
  ## Technical Decisions
  
  Binding for this iteration:
  
  - Translate the design's `.m-staffbar` CSS to the app's existing Tailwind tokens rather than adding new CSS:
    - Bar: `bg-sage-700 text-cream`.
    - Inner: `mx-auto flex max-w-7xl items-center gap-3.5 px-6 py-2.5 lg:px-8`.
    - Tag: `rounded-full bg-white/10 px-2 py-0.5 font-mono text-[10px] font-semibold uppercase tracking-[0.06em]`.
    - Text: `hidden text-sm text-cream/80 sm:inline`.
    - Link (`id="staff-console-link"`, `href={~p"/admin/clubs"}`): `ml-auto inline-flex items-center gap-1.5 rounded-lg border border-white/20 bg-white/5 px-3.5 py-1.5 text-sm font-semibold transition hover:border-white/40 hover:bg-white/15`, trailing `<.icon name="hero-arrow-top-right-on-square-mini" class="size-3.5 bg-cream" />`.
  - Two deliberate adaptations from the wireframe (raw-CSS standalone → routed Tailwind app):
    1. The bar's inner uses the homepage's own container width (`max-w-7xl`, `px-6`/`lg:px-8`) instead of the wireframe's `max-w-[1000px]`, so the bar aligns with the header and content below it.
    2. The console link points to `/admin/clubs` (the app's staff area) rather than the wireframe's `staff-console.html`.
  - Keep the link id stable as `#staff-console-link` so the acceptance assertion has a durable selector.
  
  ## New Capability
  
  Memba staff get a clear, on-brand operator-access banner on the homepage that matches the design, replacing the easily-missed nav button and giving a prominent path to the staff console.
  
  ## Validation Plan
  
  - Update and run the `homepage.feature` staff scenarios (red before implementation, green after).
  - Run `dev check` before completion.
  - Visual check against the design's staff mode (`wireframes/home.html`), including a narrow-screen pass to confirm no horizontal overflow.
  
  ## Risks / Follow-ups
  
  - The design's "Staff" role chip is deferred; a later iteration should add the avatar/name nav (inconsistency #1) and then the chip.
  - The other homepage inconsistencies remain as future iterations: richer signed-in club cards (latest-message preview, stats, per-group branding) and the inline request-access modal vs. the separate `/get-started` page.
  - If staff mode is later wanted across the whole app, the bar should move into a shared layout rather than the homepage template.
  ```

## Stage: wip_gate
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/033-homepage-staff-bar/plan.md'
PATH="$PWD/bin:$PATH" dev iteration check-predecessors "$PLAN_PATH"
PATH="$PWD/bin:$PATH" dev iteration check-clear "$PLAN_PATH" --allow-same-iteration`
- Output:
  ```
  (6 lines omitted)
  ✓ Evaluating shell in 1.38ms (cached)
  ✓ Configuring shell in 7.56ms
  • Loading tasks
  • Evaluating devenv.config.task.config
  ✓ Evaluating devenv.config.task.config in 85.1µs (cached)
  ✓ Loading tasks in 1.35ms
  • Running tasks
  • Running devenv:files:cleanup
  ✓ Running devenv:files:cleanup in 12.5ms
  • Running devenv:enterShell
  ✓ Running devenv:enterShell in 11.5ms
  • Running devenv:enterTest
  ✓ Running devenv:enterTest in 87.3µs (no command)
  ✓ Running tasks in 24.9ms
  ✨ devenv 2.1.0 is out of date. Please update to 2.1.2: https://devenv.sh/getting-started/#installation
  Memba dev environment
  Web app: web/
  Acceptance tests: acceptance-tests/
  Erlang/OTP 27 [erts-15.2.7.8] [source] [64-bit] [smp:8:1] [ds:8:1:10] [async-threads:1] [jit:ns]
  
  Elixir 1.18.4 (compiled with Erlang/OTP 27)
  Earlier iterations are merged.
  • Validating lock
  ✓ Validating lock in 23.6ms
  • Configuring shell
  • Configuring cachix
  ✓ Configuring cachix in 1.95ms
  • Evaluating shell
  ✓ Evaluating shell in 1.06ms (cached)
  ✓ Configuring shell in 4.97ms
  • Loading tasks
  • Evaluating devenv.config.task.config
  ✓ Evaluating devenv.config.task.config in 92.1µs (cached)
  ✓ Loading tasks in 3.09ms
  • Running tasks
  • Running devenv:files:cleanup
  ✓ Running devenv:files:cleanup in 10.8ms
  • Running devenv:enterShell
  ✓ Running devenv:enterShell in 14.3ms
  • Running devenv:enterTest
  ✓ Running devenv:enterTest in 66.0µs (no command)
  ✓ Running tasks in 25.8ms
  ✨ devenv 2.1.0 is out of date. Please update to 2.1.2: https://devenv.sh/getting-started/#installation
  Memba dev environment
  Web app: web/
  Acceptance tests: acceptance-tests/
  Erlang/OTP 27 [erts-15.2.7.8] [source] [64-bit] [smp:8:1] [ds:8:1:10] [async-threads:1] [jit:ns]
  
  Elixir 1.18.4 (compiled with Erlang/OTP 27)
  Implementation WIP slot is clear.
  ```

## Stage: preflight_sandbox
- Status: succeeded
- Handler: command
- Script: `set -eu
for tool in nix python3; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "Missing required bare sandbox tool: $tool" >&2
    echo "The iteration workflow uses $tool before or outside bin/dev's devenv shell. Rebuild the Fabro sandbox image with this tool on the default PATH." >&2
    exit 1
  fi
done
if [ ! -x bin/dev ]; then
  echo "Missing or non-executable bin/dev" >&2
  exit 1
fi
rm -rf .fabro/tmp
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

## Stage: resume_gate
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/033-homepage-staff-bar/plan.md'
case "$PLAN_PATH" in
  */plan.md) ITERATION_DIR=${PLAN_PATH%/plan.md} ;;
  *) echo "plan_path must end with /plan.md: $PLAN_PATH" >&2; exit 1 ;;
esac
TODO_PATH="$ITERATION_DIR/todo.md"
echo '=== Iteration resume gate ==='
if git rev-parse --verify HEAD >/dev/null 2>&1; then
  printf 'HEAD: ' && git log -1 --format='%h %s'
else
  echo 'HEAD: unavailable'
fi
if [ -f "$TODO_PATH" ]; then
  checked=$(grep -E '^[[:space:]]*- \[x\] ' "$TODO_PATH" | wc -l | tr -d ' ')
  unchecked=$(grep -E '^[[:space:]]*- \[ \] ' "$TODO_PATH" | wc -l | tr -d ' ')
  printf 'Todo: %s (%s checked, %s unchecked)\n' "$TODO_PATH" "${checked:-0}" "${unchecked:-0}"
else
  printf 'Todo: %s is absent; sync_task_list will create it from plan.md.\n' "$TODO_PATH"
fi
status=$(git status --short)
if [ -n "$status" ]; then
  echo 'Uncommitted changes present:'
  printf '%s\n' "$status"
  echo 'Refusing to resume with a dirty working tree. Commit, stash, or run git reset --hard HEAD (and clean untracked files if appropriate), then rerun iteration-implementation.' >&2
  exit 1
fi
echo 'Working tree clean; safe to resume from durable Fabro checkpoint commits.'`
- Output:
  ```
  === Iteration resume gate ===
  HEAD: 09a91d6 fabro(01KVBSQVSDNZJ67FQQ3NCFSPAY): preflight_sandbox (succeeded)
  Todo: docs/iterations/033-homepage-staff-bar/todo.md (7 checked, 0 unchecked)
  Working tree clean; safe to resume from durable Fabro checkpoint commits.
  ```

## Stage: sync_task_list
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/033-homepage-staff-bar/plan.md'
case "$PLAN_PATH" in
  */plan.md) ITERATION_DIR=${PLAN_PATH%/plan.md} ;;
  *) echo "plan_path must end with /plan.md: $PLAN_PATH" >&2; exit 1 ;;
esac
TODO_PATH="$ITERATION_DIR/todo.md"
mkdir -p .fabro/tmp
# Resume contract: once todo.md exists, it is the execution-state source of truth.
# Preserve existing check-offs, splits, and reorderings across runs. Regenerate
# from plan.md only when todo.md is absent.
if [ ! -f "$TODO_PATH" ]; then
  tmp=.fabro/tmp/generated-todo.md
  {
    printf '# Implementation TODO\n\n'
    in_plan=0
    count=0
    while IFS= read -r line; do
      case "$line" in
        '## Implementation Plan') in_plan=1; continue ;;
        '## '*) if [ "$in_plan" -eq 1 ]; then break; fi ;;
      esac
      if [ "$in_plan" -eq 1 ]; then
        case "$line" in
          [0-9]*'. '*)
            count=$((count + 1))
            task=${line#*. }
            printf -- '- [ ] %03d %s\n' "$count" "$task"
            ;;
        esac
      fi
    done < "$PLAN_PATH"
    if [ "${count:-0}" -eq 0 ]; then
      echo "No numbered tasks found under ## Implementation Plan in $PLAN_PATH" >&2
      exit 1
    fi
  } > "$tmp"
  mkdir -p "$ITERATION_DIR"
  mv "$tmp" "$TODO_PATH"
  echo "Created $TODO_PATH from $PLAN_PATH"
else
  echo "Using existing $TODO_PATH; preserving existing check-offs, splits, and ordering."
fi
printf 'PLAN_PATH=%s\nTODO_PATH=%s\n' "$PLAN_PATH" "$TODO_PATH"
sed -n '1,120p' "$TODO_PATH"`
- Output:
  ```
  Using existing docs/iterations/033-homepage-staff-bar/todo.md; preserving existing check-offs, splits, and ordering.
  PLAN_PATH=docs/iterations/033-homepage-staff-bar/plan.md
  TODO_PATH=docs/iterations/033-homepage-staff-bar/todo.md
  # Implementation TODO
  
  - [x] 001 Inspect the current homepage template (`web/lib/memba_web/controllers/page_html/home.html.heex`) and the staff-access acceptance support (`acceptance-tests/features/support/homepage.js`).
  - [x] 002 Update `assertHomepageStaffAccess` to assert the staff bar (`a#staff-console-link` visible and linking to `/admin/clubs`, plus the visible "Memba staff" tag). Note: the planned red-run check was skipped during local implementation; existing support still asserted `a#admin-home-link` before the implementation change.
  - [x] 003 Add the staff bar markup to the signed-in branch of the homepage template, gated on `@current_identity_staff?`, above `<header>`.
  - [x] 004 Remove the existing "Memba staff" nav button block (`#admin-home-link`) from the signed-in nav.
  - [x] 005 Run the homepage Cucumber scenarios and confirm they pass.
  - [x] 006 Run `dev check` and fix any issues. Fixed the dev-seed/test email delivery configuration leak and event-sourced reset cache issue uncovered by the gate, then confirmed `./bin/dev check --quick` and full `./bin/dev check` pass.
  - [x] 007 Visual check against the design's staff mode (`wireframes/home.html`), including a narrow-screen pass for overflow. Verified the signed-in staff homepage at 390×844: staff bar and console link remain visible and the page fits the viewport.
  ```

## Stage: all_tasks_done
- Status: succeeded
- Handler: prompt
- Model: gpt-5.5
- Tokens: 4.6k in / 188 out
- Response:
  > {"context_updates":{"task_list_complete":true,"task_list_needs_human":false}}

## Stage: dev_check
- Status: succeeded
- Handler: command
- Script: `PATH="$PWD/bin:$PATH" dev ci`
- Output:
  ```
  (1349 lines omitted)
  
    Rule: Staff-edited slugs must already be address-safe
  
      Scenario: Staff enter an invalid slug # features/staff_club_slugs.feature:17
  [acceptance 2026-06-17T22:12:20.020Z] scenario start: Staff enter an invalid slug
  [acceptance 2026-06-17T22:12:20.067Z] scenario reset app state: Staff enter an invalid slug
        Given Pat is signed in as Memba staff
  [acceptance 2026-06-17T22:12:21.274Z] slow step: Staff enter an invalid slug :: Pat is signed in as Memba staff :: 1167ms
        Given Kootenay Mountaineering Club is a club
        When Pat tries to change Kootenay Mountaineering Club's slug to "kmc club!"
        Then Memba should reject the club slug as invalid
        And Kootenay Mountaineering Club should keep its previous slug
  [acceptance 2026-06-17T22:12:22.653Z] scenario teardown start: Staff enter an invalid slug status=PASSED
  [acceptance 2026-06-17T22:12:22.661Z] scenario finish: Staff enter an invalid slug status=PASSED duration=2641ms
  
    Rule: A slug can belong to only one club
  
      Scenario: Staff enter a slug that another club already uses # features/staff_club_slugs.feature:25
  [acceptance 2026-06-17T22:12:22.664Z] scenario start: Staff enter a slug that another club already uses
  [acceptance 2026-06-17T22:12:22.722Z] scenario reset app state: Staff enter a slug that another club already uses
        Given Pat is signed in as Memba staff
  [acceptance 2026-06-17T22:12:23.915Z] slow step: Staff enter a slug that another club already uses :: Pat is signed in as Memba staff :: 1157ms
        Given Kootenay Mountaineering Club has the slug "kmc"
        And Nelson Paddling Club is a club
        When Pat tries to change Nelson Paddling Club's slug to "kmc"
        Then Memba should reject the club slug as already taken
        And Nelson Paddling Club should keep its previous slug
  [acceptance 2026-06-17T22:12:25.687Z] scenario teardown start: Staff enter a slug that another club already uses status=PASSED
  [acceptance 2026-06-17T22:12:25.698Z] scenario finish: Staff enter a slug that another club already uses status=PASSED duration=3034ms
  
    Rule: A club slug routes public visitors to that club's public page
  
      @not-domain
      Scenario: Robin opens an unknown club subdomain # features/staff_club_slugs.feature:35
  [acceptance 2026-06-17T22:12:25.700Z] scenario start: Robin opens an unknown club subdomain
  [acceptance 2026-06-17T22:12:25.750Z] scenario reset app state: Robin opens an unknown club subdomain
        Given Pat is signed in as Memba staff
  [acceptance 2026-06-17T22:12:26.953Z] slow step: Robin opens an unknown club subdomain :: Pat is signed in as Memba staff :: 1156ms
        When Robin opens "unknown.clubs.memba.io"
        Then Robin should see a not found page
  [acceptance 2026-06-17T22:12:27.051Z] scenario teardown start: Robin opens an unknown club subdomain status=PASSED
  [acceptance 2026-06-17T22:12:27.057Z] scenario finish: Robin opens an unknown club subdomain status=PASSED duration=1358ms
  
  [acceptance 2026-06-17T22:12:27.058Z] AfterAll: closing shared browser
  [acceptance 2026-06-17T22:12:27.099Z] AfterAll: closed shared browser
  [acceptance 2026-06-17T22:12:27.099Z] AfterAll: stopping Phoenix browser acceptance lifecycle
  [acceptance 2026-06-17T22:12:27.100Z] AfterAll: stopped Phoenix browser acceptance lifecycle
  82 scenarios (82 passed)
  493 steps (493 passed)
  3m45.242s (executing steps: 3m32.735s)
  ```

## Stage: collect_implementation_evidence
- Status: succeeded
- Handler: command
- Script: `set -eu
PLAN_PATH='docs/iterations/033-homepage-staff-bar/plan.md'
case "$PLAN_PATH" in
  */plan.md) ITERATION_DIR=${PLAN_PATH%/plan.md} ;;
  *) echo "plan_path must end with /plan.md: $PLAN_PATH" >&2; exit 1 ;;
esac
TODO_PATH="$ITERATION_DIR/todo.md"
base_ref=''
git fetch --quiet origin main:refs/remotes/origin/main || true
for ref in origin/main main; do
  if git rev-parse --verify "$ref" >/dev/null 2>&1; then
    base_ref=$ref
    break
  fi
done
if [ -z "$base_ref" ]; then
  echo 'Could not determine implementation base. Tried origin/main and main.' >&2
  git branch -a -vv >&2 || true
  git show-ref >&2 || true
  exit 1
fi
merge_base_err="${TMPDIR:-/tmp}/memba-implementation-merge-base-$$.err"
if ! merge_base=$(git merge-base HEAD "$base_ref" 2>"$merge_base_err"); then
  echo "Could not compute merge base between HEAD and $base_ref." >&2
  cat "$merge_base_err" >&2 || true
  shallow=$(git rev-parse --is-shallow-repository 2>/dev/null || echo unknown)
  echo "Repository shallow: $shallow" >&2
  if [ "$shallow" = true ]; then
    echo 'Trying to unshallow repository before failing...' >&2
    git fetch --quiet --unshallow origin || true
  fi
  if ! merge_base=$(git merge-base HEAD "$base_ref" 2>"$merge_base_err"); then
    echo "Still could not compute merge base between HEAD and $base_ref." >&2
    cat "$merge_base_err" >&2 || true
    git log --oneline --decorate --max-count=20 --all >&2 || true
    git branch -a -vv >&2 || true
    git show-ref >&2 || true
    exit 1
  fi
fi
echo '=== Plan Conformance Evidence ==='
echo "Plan path: $PLAN_PATH"
echo "Todo path: $TODO_PATH"
echo "Branch: $(git branch --show-current || true)"
echo "HEAD: $(git rev-parse HEAD)"
echo "Base ref: $base_ref"
echo "Merge base: $merge_base"
echo ''
echo '--- todo.md ---'
if [ -f "$TODO_PATH" ]; then
  sed -n '1,220p' "$TODO_PATH"
else
  echo "Todo file missing: $TODO_PATH" >&2
  exit 1
fi
echo ''
echo '--- git status --short ---'
git status --short
echo ''
echo '--- git diff --stat ---'
if ! git diff --stat "$merge_base"..HEAD; then
  echo "Could not compute diff stat from $merge_base to HEAD." >&2
  exit 1
fi
echo ''
echo '--- git diff --name-status ---'
if ! git diff --name-status "$merge_base"..HEAD; then
  echo "Could not compute diff name-status from $merge_base to HEAD." >&2
  exit 1
fi
echo ''
echo '--- changed source/config/test/iteration file excerpts ---'
if ! changed_files=$(git diff --name-only "$merge_base"..HEAD); then
  echo "Could not compute changed files from $merge_base to HEAD." >&2
  exit 1
fi
if [ -z "$changed_files" ]; then
  echo 'No files differ between merge base and HEAD.'
else
  excerpt_files=$(printf '%s\n' "$changed_files" | grep -E '^(web/(lib|config|test|priv/repo/migrations|mix\.exs|mix\.lock)|bin/|docs/iterations/)' || true)
  if [ -z "$excerpt_files" ]; then
    echo 'No changed files matched the excerpt filter.'
  else
    printf '%s\n' "$excerpt_files" | while IFS= read -r file; do
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
  === Plan Conformance Evidence ===
  Plan path: docs/iterations/033-homepage-staff-bar/plan.md
  Todo path: docs/iterations/033-homepage-staff-bar/todo.md
  Branch: fabro/run/01KVBSQVSDNZJ67FQQ3NCFSPAY
  HEAD: 8ea554f8e6bc18b03d74191d4e2e49e082973613
  Base ref: origin/main
  Merge base: 7821062c78b28bc3a998c1b778ff37a00a81c40e
  
  --- todo.md ---
  # Implementation TODO
  
  - [x] 001 Inspect the current homepage template (`web/lib/memba_web/controllers/page_html/home.html.heex`) and the staff-access acceptance support (`acceptance-tests/features/support/homepage.js`).
  - [x] 002 Update `assertHomepageStaffAccess` to assert the staff bar (`a#staff-console-link` visible and linking to `/admin/clubs`, plus the visible "Memba staff" tag). Note: the planned red-run check was skipped during local implementation; existing support still asserted `a#admin-home-link` before the implementation change.
  - [x] 003 Add the staff bar markup to the signed-in branch of the homepage template, gated on `@current_identity_staff?`, above `<header>`.
  - [x] 004 Remove the existing "Memba staff" nav button block (`#admin-home-link`) from the signed-in nav.
  - [x] 005 Run the homepage Cucumber scenarios and confirm they pass.
  - [x] 006 Run `dev check` and fix any issues. Fixed the dev-seed/test email delivery configuration leak and event-sourced reset cache issue uncovered by the gate, then confirmed `./bin/dev check --quick` and full `./bin/dev check` pass.
  - [x] 007 Visual check against the design's staff mode (`wireframes/home.html`), including a narrow-screen pass for overflow. Verified the signed-in staff homepage at 390×844: staff bar and console link remain visible and the page fits the viewport.
  
  --- git status --short ---
  
  --- git diff --stat ---
  
  --- git diff --name-status ---
  
  --- changed source/config/test/iteration file excerpts ---
  No files differ between merge base and HEAD.
  ```

## Stage: plan_conformance_gate
- Status: succeeded
- Handler: prompt
- Model: gpt-5.5
- Tokens: 7.7k in / 2.5k out
- Response:
  > {"context_updates":{"plan_conformant":false,"plan_rework_available":true}}

## Stage: plan_gate
- Status: succeeded
- Handler: conditional
- Notes: Conditional node evaluated: plan_gate

## Stage: snapshot_before_plan_repair
- Status: succeeded
- Handler: command
- Script: `set -eu
mkdir -p .fabro/tmp
kind='plan'
git rev-parse HEAD > ".fabro/tmp/${kind}-repair-before-head.txt"
git diff --binary > ".fabro/tmp/${kind}-repair-before.patch"
git diff --name-only > ".fabro/tmp/${kind}-repair-before-files.txt"
git diff --stat > ".fabro/tmp/${kind}-repair-before-stat.txt" || true
printf 'Repair baseline (%s) captured at HEAD %s.
' "$kind" "$(cat .fabro/tmp/${kind}-repair-before-head.txt)"`
- Output:
  ```
  Repair baseline (plan) captured at HEAD d95a826f97be58be666c2e9285f014ee27608dfc.
  ```

## Current context
| Key | Value |
|-----|-------|
| plan_conformant | false |
| plan_rework_available | true |
| task_list_complete | true |
| task_list_needs_human | false |


Fix the plan conformance violations identified by the preceding Plan Conformance Gate for docs/iterations/033-homepage-staff-bar/plan.md.

Use only the gate's repair brief, the plan text, the implementation todo list, and current repository state. Stay within the approved iteration scope.

Rules:

- Fix only the explicit plan-conformance gaps identified by the gate.
- Do not reinterpret explicit requirements as optional or implementation strategy.
- Do not omit, weaken, or substitute plan-mandated architecture, tests, configurations, migrations, commands, or deliverables.
- Add or update automated tests proving each repaired plan requirement is satisfied.
- Add code, configuration, migrations, scripts, or modules needed to satisfy each explicit plan requirement.
- Acceptance feature files (`*.feature`, including files under `acceptance-tests/`) are locked unless the plan has a `## Allowed acceptance feature changes` section naming the exact file and allowed kind of change. If the plan permits a feature edit, make only that explicit edit and preserve/validate the coverage promised by the plan.
- If a fix requires changing feature files beyond explicit plan permission, changing the plan, or making a product/architecture decision, stop and request human input.
- If the repair brief is too large, ambiguous, conflicting, or requires a decision beyond the plan scope, stop and request human input.
- Do not add unrelated cleanup or new product behaviour beyond the plan requirements.
- Do not skip or weaken existing validation.
- Do not commit changes.
- **Sandbox/runtime boundary**: If the plan violation or failure appears caused by sandbox/toolchain/runtime incoherence (stale `/env` paths, unwritable caches, missing tools, broken services, stale process-compose state), stop and report a sandbox blocker. Do not patch `bin/dev`, application scripts, product code, dependencies, or tests merely to compensate for sandbox runtime defects.
- **If no changes were needed**: If after reviewing the gaps you determine that no code/config/test changes are required, state that explicitly and provide clear justification for why the plan conformance gaps do not require changes.

When finished, summarize:

1. Each plan requirement gap from the gate.
2. The concrete code/config/test/migration changes made for each requirement, or an explicit statement that no changes were needed with justification.
3. Files changed, grouped by requirement addressed.
4. The automated tests added or updated to prove plan conformance.
5. Tests run and their results.
6. Any remaining plan gaps or human questions.

Include a requirement-to-fix mapping showing which files/modules/tests address each explicit plan requirement.