# Plan: harden iteration implementation workflow beyond ADR gate

Date: 2026-05-27

## Goal

Implement the remaining harness improvements discovered from the last `iteration-implementation` run, beyond the ADR gate work.

The workflow should fail early for sandbox/environment incoherence, reject contradictory review synthesis, prove repair stages actually repaired something, require explicit plan-conformance evidence, and refuse to declare success without captured code changes / PR evidence.

## Background

The prior run exposed several non-ADR harness weaknesses:

1. Sandbox/environment bugs leaked into product implementation.
2. Review synthesis contradicted itself and accepted unresolved blockers.
3. Repair stages could succeed without proving repair.
4. `dev check` was too weak as a product/plan gate.
5. Final success had no PR/diff artifact despite claiming changed files.
6. Preflight checked tools and Postgres, but not the full runtime contract.

The ADR gate plan now lives at:

- `docs/kaizen/2026-05-27-iteration-implementation-adr-gate-plan.md`

This plan complements it.

## Principles

- Shift quality left where possible.
- Make hidden assumptions observable.
- Treat environment failures as harness failures, not product work.
- Treat plan requirements as binding unless explicitly deferred or routed to human input.
- A repair stage must leave evidence of repair.
- Gates should compare new evidence with prior evidence, not rely on cumulative state that may already be dirty.
- A successful implementation run must produce meaningful diff / PR / checkpoint evidence.

## Scope

### In scope

- Strengthen sandbox preflight/runtime contract checks.
- Strengthen dev-check-fix, ADR-fix, and review-fix prompts to avoid patching product code for harness failures.
- Strengthen synthesis rules for repeated blockers and explicit plan requirements.
- Add repair-evidence gates after automatic repair stages.
- Add plan-conformance gate/checks after `dev_check` and before ADR/review gates.
- Add final artifact/diff sanity gate before final summary or before workflow success.
- Validate the Fabro workflow locally.
- Exercise the key harness regressions with a dry-run, fixture workflow, or documented manual Fabro graph check.

### Out of scope

- Running this workflow change through Fabro as an implementation iteration.
- Rewriting Fabro internals.
- Building a complete general-purpose static analyzer.
- Changing product code except where needed to reverse accidental harness-leakage patches, if Matt asks.

## Workstream 0: answer Fabro capability questions first

Several gates depend on what Fabro exposes to script nodes and when it checkpoints working-tree changes. Resolve these before implementing the affected gates.

### Questions to answer

1. Can a script node access prior node responses/context values, especially an agent's repair summary?
2. Does Fabro preserve all prior node outputs in later prompt context after repeated node visits?
3. At finalization time, is the sandbox working tree still dirty, or has Fabro already checkpointed/committed changes?
4. Does Fabro expose PR URL/number, base/head commit, run diff, checkpoint diff, or pull-request metadata to script/prompt nodes?
5. Can script nodes write small state files in the sandbox for later script nodes to read?

### Discovery approach

Create a temporary/debug workflow or use `--dry-run`/`--preserve-sandbox` to inspect:

- environment variables available to script nodes;
- current working tree state after implementation, after repair, and before final summary;
- `fabro dump` output for node context, diff, checkpoint, and PR metadata;
- whether a state file written by one script node is visible to a later script node.

### Output

Record the findings as a short note or addendum before implementing Workstreams 3 and 5.

### Discovery results (2026-05-27)

A temporary Fabro debug workflow was validated and run locally. `fabro run --dry-run --preserve-sandbox` works for graph validation, but dry-run skips script execution, so a normal temporary workflow is needed to inspect real script-node behavior.

Findings:

- Script nodes run with a sparse environment. In the debug run, variables such as `FABRO*`, `GITHUB*`, `PR*`, `BASE*`, `HEAD*`, `BRANCH*`, and `GIT*` were not exposed to scripts. Script gates should not rely on Fabro metadata being present as environment variables.
- Script nodes can share state files across nodes. Both `/tmp` and repository-local `.fabro/tmp` files written by one script node were visible to a later script node in the same run.
- Fabro persists prior node outputs in run metadata available through `fabro dump`, including checkpoint `node_outcomes`, command output, `diff`, `diff_summary`, `git_commit_sha`, run `base_sha`, `run_branch`, and `final_git_commit_sha`. However, scripts do not receive prior node responses/context values automatically via environment variables, and attempted template interpolation for prior context failed validation.
- Fabro checkpoints/commits working-tree changes between nodes. A later script node saw a clean `git status --short` after an earlier script wrote a repository-local file that appeared in checkpoint diff metadata. Final artifact gates should therefore prefer Fabro checkpoint/dump metadata or base/head commit comparison over working-tree dirtiness alone.
- No PR URL/number was present in the local debug run; `pull_request` metadata was `null`.

Conservative implementation guidance: use `.fabro/tmp` for before/after repair snapshots, but implement final artifact evidence using checkpoint/dump metadata or git base/head comparison where possible; do not rely only on `git status --short` at finalization.

## Workstream 1: stop sandbox/environment bugs leaking into product implementation

### Problem

The previous run hit sandbox/runtime environment failures such as stale `/env` cache paths and unwritable cache directories. The fix loop patched `bin/dev`, which blurred the boundary between harness infrastructure and product/dev scripts.

### Changes

#### 1.1 Strengthen `preflight_sandbox` script

Update `.fabro/workflows/iteration-implementation/workflow.fabro` preflight to validate the runtime contract, not just tool presence.

The check should run in three layers:

1. Bare container shell, before `devenv shell`.
2. Inside `devenv shell`.
3. Through the project command boundary: `PATH="$PWD/bin:$PATH" dev ...`.

Concrete script outline:

```sh
set -eu

fail=0
report_env() {
  label="$1"
  echo "== $label =="
  for name in HOME MIX_HOME HEX_HOME XDG_CACHE_HOME DEVENV_ROOT DEVENV_STATE DEVENV_PROFILE DEVENV_DOTFILE PGHOST PGPORT PGDATA; do
    eval "value=\${$name-}"
    printf '%s=%s\n' "$name" "$value"
  done
}

check_writable_dir() {
  name="$1"
  eval "dir=\${$name-}"
  if [ -z "$dir" ]; then
    echo "Missing runtime path: $name" >&2
    fail=1
    return
  fi
  case "$dir" in
    /env|/env/*)
      echo "Runtime path $name points into stale/non-writable /env: $dir" >&2
      fail=1
      ;;
  esac
  mkdir -p "$dir" 2>/dev/null || { echo "Could not create $name=$dir" >&2; fail=1; return; }
  test -w "$dir" || { echo "Runtime path is not writable: $name=$dir" >&2; fail=1; return; }
  probe="$dir/.fabro-write-probe-$$"
  : > "$probe" 2>/dev/null || { echo "Could not write probe in $name=$dir" >&2; fail=1; return; }
  rm -f "$probe"
}

report_env "bare container"

devenv shell -- bash -lc '
  set -eu
  echo "== inside devenv shell =="
  for name in HOME MIX_HOME HEX_HOME XDG_CACHE_HOME DEVENV_ROOT DEVENV_STATE DEVENV_PROFILE DEVENV_DOTFILE PGHOST PGPORT PGDATA; do
    eval "value=\${$name-}"
    printf "%s=%s\n" "$name" "$value"
  done
  for name in HOME MIX_HOME HEX_HOME XDG_CACHE_HOME; do
    eval "dir=\${$name-}"
    case "$dir" in /env|/env/*) echo "stale /env path: $name=$dir" >&2; exit 1;; esac
    mkdir -p "$dir"
    test -w "$dir"
    probe="$dir/.fabro-write-probe-$$"
    : > "$probe"
    rm -f "$probe"
  done
'

PATH="$PWD/bin:$PATH" dev --help >/dev/null
trap 'PATH="$PWD/bin:$PATH" dev down >/dev/null 2>&1 || true' EXIT
PATH="$PWD/bin:$PATH" dev up >/dev/null

# Native-dependency smoke test. Prefer a cheap elixir_make-dependent compile if available.
# For Memba today, lazy_html exercises the failure mode that previously leaked into implementation.
(cd web && mix deps.compile lazy_html --force)

if [ "$fail" -ne 0 ]; then
  echo 'Sandbox runtime preflight failed before implementation. Fix the Fabro image/workflow/runtime environment rather than patching application code.' >&2
  exit 1
fi
```

Adjust the final native dependency check if it proves too costly, but keep an explicit writable-cache probe and stale `/env` rejection.

#### 1.2 Update repair prompts with sandbox-boundary rules

Update:

- `.fabro/workflows/iteration-implementation/prompts/fix_dev_check.md`
- `.fabro/workflows/iteration-implementation/prompts/apply_review_fixes.md`
- `.fabro/workflows/iteration-implementation/prompts/fix_adr_coherence.md`
- `.fabro/workflows/iteration-implementation/prompts/fix_plan_conformance.md` once added

Add rules:

- If the failure appears caused by sandbox/toolchain/runtime incoherence (`/env` paths, unwritable caches, missing tools, broken services, stale process-compose state), stop and report a sandbox blocker.
- Do not patch `bin/dev`, application scripts, product code, dependencies, or tests merely to compensate for sandbox runtime defects.
- Only fix product/test failures that are plausibly caused by the implementation or by the concrete review/plan/ADR repair brief.

## Workstream 2: prevent contradictory review synthesis

### Problem

First synthesis correctly identified missing Commanded/EventStore/projections/Cucumber/migrations as blockers. A later synthesis accepted the same unresolved gaps by reframing them as optional implementation strategy.

### Changes

Strengthen `.fabro/workflows/iteration-implementation/prompts/synthesize_review.md` further.

Add hard rules:

- If the plan explicitly says “Implement X”, synthesis may not downgrade X to optional unless routing to `HUMAN_INPUT` with a clear question.
- If a blocker appeared in a previous synthesis/review cycle and remains unresolved after automatic repair, route to `HUMAN_INPUT`, not `ACCEPTED`.
- If multiple reviewers identify the same architectural or plan-fidelity gap, require human confirmation before accepting unless the gap was demonstrably fixed.
- Passing `dev check` is necessary but not sufficient for plan acceptance.
- A green suite with insufficient or irrelevant tests must not be used to accept missing explicit plan requirements.

### Repeated-blocker persistence

Do not rely on model memory alone. Add structured blocker state.

Require `synthesize_review.md` to end with routing JSON plus a `review_blockers` context update when blockers exist. Use stable blocker IDs when possible:

```json
{
  "context_updates": {
    "implementation_accepted": false,
    "review_fixes_available": true,
    "review_blockers": [
      {
        "id": "missing-commanded-eventstore",
        "title": "Commanded/EventStore architecture missing",
        "source": "review_synthesis",
        "first_seen_stage": "synthesize_review",
        "status": "open"
      }
    ]
  }
}
```

If Fabro's context schema cannot preserve arrays/objects reliably, use a Markdown block in the synthesis response with stable IDs and require later synthesis passes to copy forward unresolved IDs.

Add required synthesis output section:

- Repeated blockers from prior cycles:
  - blocker ID;
  - blocker title;
  - previous decision;
  - current evidence;
  - fixed? yes/no;
  - routing consequence.

## Workstream 3: repair stages must prove repair

### Problem

`apply_review_fixes` completed successfully with a response that only said it would implement the repair brief. The workflow treated that as a successful repair.

### Changes

#### 3.1 Strengthen repair prompts

Update:

- `.fabro/workflows/iteration-implementation/prompts/apply_review_fixes.md`
- `.fabro/workflows/iteration-implementation/prompts/fix_adr_coherence.md`
- `.fabro/workflows/iteration-implementation/prompts/fix_plan_conformance.md`
- optionally `.fabro/workflows/iteration-implementation/prompts/fix_dev_check.md`

Require final responses to include:

- files changed;
- each review/ADR/plan/dev-check issue mapped to a concrete fix;
- tests/checks run;
- remaining gaps or blockers;
- explicit statement if no code/config/test changes were needed, with justification.

#### 3.2 Add before/after repair evidence gates

A gate that checks only cumulative `git diff` is insufficient because implementation changes already exist before repair. The gate must compare repair-start and repair-end evidence.

Add a pair of script nodes around each non-dev-check repair agent:

```text
snapshot_before_review_repair -> apply_review_fixes -> verify_review_repair -> dev_check
snapshot_before_adr_repair    -> fix_adr_coherence  -> verify_adr_repair    -> dev_check
snapshot_before_plan_repair   -> fix_plan_conformance -> verify_plan_repair -> dev_check
```

For `fix_dev_check`, `dev_check` itself is usually the evidence gate. Add snapshots only if no-op fix-dev-check responses become a problem.

Snapshot script:

```sh
set -eu
mkdir -p .fabro/tmp
kind='review' # or adr / plan, baked into the node script
sha=$(git diff --binary | shasum -a 256 | awk '{print $1}')
git diff --name-only > ".fabro/tmp/${kind}-repair-before-files.txt"
git diff --stat > ".fabro/tmp/${kind}-repair-before-stat.txt" || true
printf '%s\n' "$sha" > ".fabro/tmp/${kind}-repair-before-sha.txt"
printf 'Repair baseline (%s): %s\n' "$kind" "$sha"
```

Verify script:

```sh
set -eu
kind='review' # or adr / plan, baked into the node script
before=$(cat ".fabro/tmp/${kind}-repair-before-sha.txt")
after=$(git diff --binary | shasum -a 256 | awk '{print $1}')
git diff --name-only > ".fabro/tmp/${kind}-repair-after-files.txt"
git diff --stat > ".fabro/tmp/${kind}-repair-after-stat.txt" || true
printf 'Repair baseline (%s): %s\n' "$kind" "$before"
printf 'Repair after    (%s): %s\n' "$kind" "$after"
printf 'Changed files after repair:\n'
git diff --name-only
if [ "$before" = "$after" ]; then
  echo "${kind} repair produced no working-tree diff change since repair started." >&2
  echo "If no code/config/test changes were required, route to human input or make the repair prompt explicitly justify that case." >&2
  exit 1
fi
if git diff --name-only | grep -E '\.feature$'; then
  echo "Repair modified locked acceptance feature files." >&2
  exit 1
fi
```

If Workstream 0 discovers script nodes cannot share files, use another durable location available inside the sandbox or fall back to a single verify node plus structured agent summary, but prefer before/after snapshots.

## Workstream 4: add explicit plan-conformance gate

### Problem

`dev check` passed with only 5 tests while the plan expected Commanded/EventStore/Cucumber/projections/migrations. The harness lacked a gate that checks explicit plan requirements independently of test count.

### Decision

Use a separate plan-conformance gate. ADR coherence is about accepted architectural decisions. Plan conformance is broader: scope, acceptance criteria, implementation plan steps, and validation plan.

### Proposed graph

```text
dev_check -> plan_conformance_gate -> plan_gate -> adr_coherence_gate -> adr_gate -> review_fork
```

Plan rework loop:

```text
plan_gate -> fix_plan_conformance -> snapshot/verify plan repair -> dev_check
plan_gate -> plan_not_ready -> exit
```

### Nodes

Add to `.fabro/workflows/iteration-implementation/workflow.fabro`:

- `plan_conformance_gate`
  - shape: `tab`
  - output_schema: `routing`
  - prompt: `@prompts/plan_conformance_gate.md`
  - model: strong reviewer model, e.g. `claude-opus-4-6`
- `plan_gate`
  - shape: `diamond`
  - label: `Plan conformant?`
- `fix_plan_conformance`
  - prompt: `@prompts/fix_plan_conformance.md`
  - timeout: `2400s`
  - max_visits: `2`
- `plan_not_ready`
  - fail/human-input script node

Routing:

```text
plan_conformance_gate -> plan_gate
plan_gate -> adr_coherence_gate [condition="context.plan_conformant=true"]
plan_gate -> snapshot_before_plan_repair [condition="context.plan_rework_available=true"]
plan_gate -> plan_not_ready
snapshot_before_plan_repair -> fix_plan_conformance
fix_plan_conformance -> verify_plan_repair
verify_plan_repair -> dev_check
plan_not_ready -> exit
```

Routing JSON from `plan_conformance_gate.md`:

```json
{"context_updates":{"plan_conformant":true,"plan_rework_available":false}}
```

```json
{"context_updates":{"plan_conformant":false,"plan_rework_available":true}}
```

```json
{"context_updates":{"plan_conformant":false,"plan_rework_available":false}}
```

### Plan-conformance prompt responsibilities

Create `.fabro/workflows/iteration-implementation/prompts/plan_conformance_gate.md`.

It must:

- read the plan acceptance criteria, implementation plan, and validation plan;
- identify explicit “Add”, “Implement”, “Configure”, “Run”, “Use”, “Provide”, and “Execute” requirements;
- compare each explicit requirement with repository evidence and test evidence;
- treat passing `dev check` as necessary but not sufficient;
- reject green tests that do not cover or prove explicit plan requirements;
- route explicit missing requirements to rework or human input;
- never downgrade explicit plan requirements to optional implementation strategy unless routing to human input.

Required report sections:

- Decision: `PLAN_CONFORMANT`, `PLAN_REWORK`, or `HUMAN_INPUT`;
- requirements checked;
- missing/weak requirements with evidence;
- exact rework brief if bounded;
- human question if not safely repairable;
- final routing JSON.

### Plan rework prompt

Create `.fabro/workflows/iteration-implementation/prompts/fix_plan_conformance.md`.

Rules:

- fix only explicit plan-conformance gaps identified by the gate;
- do not reinterpret explicit requirements as optional;
- if too large, ambiguous, conflicting, or requiring a product/architecture decision, stop and request human input;
- add tests/evidence for each plan item fixed;
- do not patch product code for sandbox/runtime defects;
- final response must include files changed, requirement-to-fix mapping, tests run, and remaining gaps.

### Static evidence collector

Add a lightweight script node before `plan_conformance_gate` only if useful. It should emit evidence for the LLM gate and hard-fail only on obvious locked-file violations or unreadable repository state.

For Memba-specific architecture-heavy plans, emit markers such as:

- whether `web/mix.exs` includes `:commanded`, `:eventstore`, `:commanded_ecto_projections`, `:cucumber`;
- whether Commanded app/router modules exist;
- whether command/event/aggregate/projector modules exist;
- whether migrations exist for EventStore/projections;
- whether Cucumber step definitions/config reference `acceptance-tests/features`.

Start project-specific; extract reusable patterns later if useful.

## Workstream 5: final diff / PR artifact sanity gate

### Problem

The run concluded with `diff: {}` and no PR info while final summary listed changed files. A successful implementation run with no captured diff/PR is suspicious.

### Changes

Add a final script gate before `final_summary`:

```text
review_gate -> final_artifact_gate -> final_summary -> exit
```

### Evidence priority

After Workstream 0 discovery, implement `final_artifact_gate` using the best available evidence, in this order:

1. Fabro PR metadata: PR URL/number, base/head branch or commit.
2. Fabro run/checkpoint diff metadata.
3. Git base/head comparison inside sandbox.
4. Working-tree/staged diff inside sandbox.

If none are available, fail with a clear harness error instead of declaring success.

### First-pass repository-local script

Use this only if Workstream 0 confirms final nodes still see the working-tree diff:

```sh
set -eu
status=$(git status --short)
printf 'Final working tree status:\n%s\n' "$status"
if [ -z "$status" ]; then
  echo 'Implementation workflow reached finalization with no working tree changes or artifact evidence. Refusing to report success without a captured diff/PR/checkpoint.' >&2
  exit 1
fi
if printf '%s\n' "$status" | grep -E '\.feature$'; then
  echo 'Final working tree includes locked acceptance feature changes.' >&2
  exit 1
fi
git diff --stat
```

### Prompt update

Update `final_summary.md`:

- final summary must cite final artifact gate output;
- it must not claim changed files that are absent from diff/status/PR/checkpoint evidence.

## Workstream 6: workflow routing and visit budgets

Need to keep loops bounded and meaningful.

Proposed high-level graph:

```text
implement
  -> dev_check
  -> plan_conformance_gate
  -> plan_gate
  -> adr_coherence_gate
  -> adr_gate
  -> review_fork
  -> synthesize_review
  -> review_gate
  -> final_artifact_gate
  -> final_summary
```

Repair loops:

```text
dev_check fail -> fix_dev_check -> dev_check
plan gap       -> snapshot_before_plan_repair -> fix_plan_conformance -> verify_plan_repair -> dev_check
ADR gap        -> snapshot_before_adr_repair  -> fix_adr_coherence    -> verify_adr_repair  -> dev_check
review fix     -> snapshot_before_review_repair -> apply_review_fixes -> verify_review_repair -> dev_check
```

Budget suggestions:

- `fix_dev_check`: max 3
- `fix_plan_conformance`: max 2
- `fix_adr_coherence`: max 2
- `apply_review_fixes`: max 2 or 3
- if same blocker survives a repair pass, synthesis/gates should prefer human input.

## Acceptance criteria

- Prior ADR gate plan remains in `docs/kaizen/`.
- This plan exists in `docs/kaizen/`.
- Fabro capability questions in Workstream 0 are answered or explicitly deferred with safe conservative behavior.
- Preflight validates writable caches and stale `/env` leakage before implementation.
- Prompts instruct agents not to patch product code for sandbox/runtime defects.
- Synthesis cannot accept explicit unresolved plan requirements or repeated blockers.
- Repeated blockers are persisted with stable IDs or copied forward explicitly.
- Repair prompts require concrete evidence: changed files, issue-to-fix mapping, tests, gaps.
- Repair evidence gates compare before/after repair snapshots and reject no-op repair when changes are expected.
- Separate plan-conformance gate exists with routing JSON, repair prompt, repair loop, and human-input failure path.
- Final artifact gate rejects success with no diff/PR/checkpoint evidence, using confirmed Fabro evidence sources.
- `fabro validate .fabro/workflows/iteration-implementation/workflow.toml` passes.
- `dev check` passes locally after changes.
- The four regression scenarios below are exercised with a dry-run, fixture workflow, or documented manual Fabro graph check.

## Regression tests

### Regression 1: plain-module implementation of Commanded plan

Given:

- plan explicitly requires Commanded/EventStore/projections/Cucumber;
- implementation uses only plain modules;
- `dev check` passes.

Expected:

- plan conformance and/or ADR gate rejects;
- synthesis cannot accept;
- route to rework or human input.

### Regression 2: repair stage says “I will fix it” but changes nothing

Given:

- review gate routes to `apply_review_fixes`;
- agent response contains no concrete files/tests/fixes;
- working tree diff is unchanged since repair-start snapshot.

Expected:

- repair evidence gate fails or routes to human input;
- workflow does not proceed as if repair happened.

### Regression 3: sandbox `/env` cache failure

Given:

- `MIX_HOME`/`XDG_CACHE_HOME` points to unwritable `/env`;
- native dep compilation or write-probe fails before implementation.

Expected:

- preflight fails before implementor starts;
- failure message says to fix Fabro image/workflow/runtime environment;
- no product repair agent is invoked.

### Regression 4: final success with no diff

Given:

- workflow reaches finalization;
- no changed files, PR metadata, run diff, checkpoint diff, or base/head artifact exists.

Expected:

- final artifact gate fails;
- final summary is not allowed to claim implementation success.

### Regression 5: repeated blocker after repair

Given:

- synthesis identifies blocker `missing-commanded-eventstore` and routes to repair;
- repair completes;
- subsequent review/synthesis still finds `missing-commanded-eventstore`.

Expected:

- synthesis routes to `HUMAN_INPUT`, not `ACCEPTED` and not another indefinite repair loop.

## Task checklist, in order

### Phase 0: housekeeping and discovery

- [x] Confirm `docs/kaizen/2026-05-27-iteration-implementation-adr-gate-plan.md` and this plan are in `docs/kaizen/`.
- [x] Run `git status --short` and note unrelated changes before editing. Result: clean working tree; no unrelated changes detected.
- [x] Create a tiny temporary/debug Fabro workflow or use an existing safe workflow to inspect script-node environment/context.
- [x] Determine whether script nodes can share sandbox state files across nodes. Result: yes; `/tmp` and `.fabro/tmp` persisted across script nodes in the same run.
- [x] Determine whether script nodes can read prior node responses/context values. Result: not directly via environment or prompt-style interpolation; prior outputs are visible through `fabro dump` metadata.
- [x] Determine whether final nodes see dirty working-tree changes or Fabro checkpoint/PR metadata instead. Result: later nodes may see a clean working tree because Fabro checkpoints changes between nodes; checkpoint/diff metadata is available via dump/inspect.
- [x] Document those discovery results in this plan or a small addendum.

### Phase 1: sandbox/runtime boundary

- [x] Expand `preflight_sandbox` in `.fabro/workflows/iteration-implementation/workflow.fabro` with env reporting, stale `/env` checks, writable cache probes, `dev up`, and native-dep smoke test or justified cheaper equivalent.
- [x] Update `fix_dev_check.md` with sandbox-boundary blocker rules.
- [x] Update `apply_review_fixes.md` with sandbox-boundary blocker rules.
- [x] Update `fix_adr_coherence.md` with sandbox-boundary blocker rules.
- [x] If added later, include the same rule in `fix_plan_conformance.md`.

### Phase 2: plan conformance gate

- [x] Create `prompts/plan_conformance_gate.md` with decision rules, report format, and routing JSON.
- [x] Create `prompts/fix_plan_conformance.md` with bounded repair rules and required evidence summary.
- [x] Add `plan_conformance_gate`, `plan_gate`, `fix_plan_conformance`, and `plan_not_ready` nodes to `workflow.fabro`.
- [x] Add model stylesheet entries and max visit budget for `fix_plan_conformance`.
- [x] Wire `dev_check -> plan_conformance_gate -> plan_gate -> adr_coherence_gate`.
- [x] Wire plan rework through snapshot/verify repair gates back to `dev_check`.
- [ ] Optionally add a Memba-specific static evidence collector before `plan_conformance_gate`.

### Phase 3: repair evidence gates

- [x] Add snapshot-before and verify-after script nodes for plan repair.
- [x] Add snapshot-before and verify-after script nodes for ADR repair.
- [x] Add snapshot-before and verify-after script nodes for review repair.
- [x] Change `fix_adr_coherence -> dev_check` to `fix_adr_coherence -> verify_adr_repair -> dev_check` with snapshot before the fix.
- [x] Change `apply_review_fixes -> dev_check` to `apply_review_fixes -> verify_review_repair -> dev_check` with snapshot before the fix.
- [x] Ensure verify gates reject locked `*.feature` changes.
- [x] Update repair prompts to require files changed, issue-to-fix mapping, tests/checks run, remaining gaps, and explicit justification if no changes were needed.

### Phase 4: synthesis hardening

- [x] Update `synthesize_review.md` with explicit-plan-requirement rules.
- [x] Add repeated-blocker output section with stable blocker IDs.
- [x] Add routing rule: repeated unresolved blocker after repair routes to `HUMAN_INPUT`.
- [x] Verify later synthesis prompt context includes previous synthesis/blocker state; if not, add an explicit mechanism.

**Phase 4 completion notes (2026-05-27)**:

All four items completed. The updated `synthesize_review.md` prompt now includes:

1. **Explicit plan requirements section**: Rules that prevent downgrading explicit plan requirements ("Implement X", "Add Y", etc.) to optional implementation strategy. Synthesis must route to FIX or HUMAN_INPUT for missing explicit requirements, not accept by reframing.

2. **Repeated-blocker detection and output**: 
   - Instructions to check prior context for previous synthesis attempts.
   - "Repeated blockers from prior cycles" section requiring blocker ID, title, previous decision, current evidence, fix status, and routing consequence.
   - Structured "Blocker registry" output with stable IDs in a parseable format.
   - Context updates JSON now includes `review_blockers` array and `repeated_blockers` array.

3. **Repeated-blocker routing rule**: Explicit logic that if a blocker with matching ID or substantially similar description remains unresolved after repair attempts, synthesis must route to HUMAN_INPUT, not another FIX loop.

4. **Context verification and explicit mechanism**:
   - Phase 0 showed prior node outputs are preserved in Fabro run metadata, but not exposed to script-node environment variables.
   - Prompt explicitly instructs synthesis to extract and compare blocker IDs from prior context.
   - Structured BLOCKER_REGISTRY output plus `review_blockers` / `repeated_blockers` context updates provide the explicit persistence mechanism for repeated synthesis cycles.
   - Regression 5 remains the runtime check that repeated blocker persistence works end-to-end.


### Phase 5: final artifact gate

- [x] Implement `final_artifact_gate` using the confirmed evidence source from Phase 0.
- [x] Wire `review_gate -> final_artifact_gate -> final_summary` for accepted implementations.
- [x] Ensure final gate fails if locked feature files changed.
- [x] Update `final_summary.md` so it cites final artifact evidence and cannot claim absent changed files.

### Phase 6: validation

- [x] Run `fabro validate .fabro/workflows/iteration-implementation/workflow.toml` and fix errors. Result: Validation OK; existing goal-gate retry warnings only.
- [x] Run `PATH="$PWD/bin:$PATH" dev check` locally. Result: PASS; 5 tests, 0 failures.
- [x] Exercise Regression 1 with a dry-run, fixture, or documented manual graph check.
  - Validation note (2026-05-27): Manual Fabro graph/prompt check completed. The graph runs `dev_check -> plan_conformance_gate -> plan_gate` before ADR/review acceptance. `plan_conformance_gate.md` treats Commanded/EventStore/projections/Cucumber requirements as binding, rejects plain-module substitutions, and says a green 5-test suite is insufficient. `adr_coherence_gate.md` rejects omitted cited ADR central decisions, and `synthesize_review.md` forbids accepting unresolved explicit plan requirements or repeated `missing-commanded-eventstore` blockers. This scenario should route to bounded rework or human input, not acceptance.
- [x] Exercise Regression 2 with a dry-run, fixture, or documented manual graph check.
  - Validation note (2026-05-27): Manual Fabro graph/script check completed. The workflow routes plan, ADR, and review repairs through `snapshot_before_*_repair -> fix_* -> verify_*_repair -> dev_check`. Each verify gate hashes `git diff --binary` before and after repair and exits non-zero when unchanged. A temp git fixture with an existing implementation diff and no repair changes caused plan, ADR, and review verify scripts to fail as expected, so a repair response that only says “I will fix it” cannot proceed as successful repair.
- [x] Exercise Regression 3 with a dry-run, fixture, or documented manual graph check.
  - Validation note (2026-05-27): Manual preflight logic check completed. Running the `devenv shell` cache-probe path with `MIX_HOME=/env XDG_CACHE_HOME=/env` failed before implementation: `XDG_CACHE_HOME` remained `/env` and the script exited with `stale /env path: XDG_CACHE_HOME=/env`. The workflow routes failed `preflight_sandbox` to `preflight_failed`, whose message tells the operator to fix the Fabro environment/image before coding. No product repair agent is invoked.
- [ ] Exercise Regression 4 with a dry-run, fixture, or documented manual graph check.
- [ ] Exercise Regression 5 with a dry-run, fixture, or documented manual graph check.
- [ ] Review final diff to ensure only harness/docs files changed unless Matt approved product-script changes.
