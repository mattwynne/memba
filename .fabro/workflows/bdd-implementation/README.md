# BDD implementation — connected native draft, not an accepted implementation

Review [graph](workflow.fabro), [TOML](workflow.toml), the **five** prompts below
and [sandbox guard](runner/guard.py). No Pi SDK/ACP/host-hook/provider bridge.
Fabro's built-in API agents own inference, normal provider/auth, sessions and tools;
its managed clone/Docker/run branch/checkpoints/logs remain the execution path.
No publishing, iteration-status update, delivery helper or replacement runtime.

The initial review-only pause was superseded by Matt's overnight-run request,
relayed by the parent. **Parent owns integration, approved throwaway source branch,
push/launch and the maximum THREE normal-Fabro scenario attempts across repairs.**
Original overnight deadline: **2026-10-16T13:03:37Z**, never reset per visit/run.
This folder is not permission to launch. No historical branch/run is created here.

## Actual graph, role and guard connections

| Native role / exact prompt | Context and work |
| --- | --- |
| [BDD navigator](prompts/bdd-navigator.md) | `full`, `thread_id=bdd-navigator`; one change, initial/next predictions, or sequential review/full-check repairs |
| [BDD driver](prompts/bdd-driver.md) | `truncate`, NEW API session **every visit**; first/invalid baseline before edits, later matching actual reused; own unit red/green loop; immediate handback at predicted next/green/unexpected result |
| [Refactoring navigator](prompts/refactoring-navigator.md) | `full`, DISTINCT `thread_id=refactoring-navigator`; whole diff from immutable pre-scenario base, our CQRS/event-sourcing/RDD/Elixir guidance; one worthwhile smell or none |
| [Refactoring driver](prompts/refactoring-driver.md) | `truncate`, NEW session every visit including review repairs; always entire selected baseline green before editing; own regressions repaired within scope to green/blocker |
| [Review](prompts/review.md) | `truncate`, NEW read-only session every pass after full ordinary `bin/dev check`; all applicable architecture/ADRs, quality/Elixir, spec, UX and human-copy lenses in ONE list |

All use **normal OpenAI `gpt-5.6-sol`, high**, explicitly styled in the graph and
TOML with an explicitly empty model-keyed fallback chain (`"gpt-5.6-sol" = []`). Parent reported the normal server/client as
`0.316.0-nightly.0 git0abf229`, catalog `openai/gpt-5.6-sol` default/configured,
reasoning high, and no `gpt-6.1-sol` match. This is an explicit normal-config model
choice following the later instruction, not silent fallback or a provider invention.
This child has not made an auth/model smoke call. Its BB coding model is unrelated.

Graph: admission → normal `dev sandbox-check` AND `dev responsive-check --force`
(exit zero, forced marker, real positive viewport/page count, no skip) → BDD loop →
separate refactoring loop (optional) → full ordinary `dev check` → one fresh review.
One combined finding list or full-gate failure returns to the SAME BDD navigator;
it assigns fresh BDD/refactoring drivers sequentially. Then full gate/review again.
Routine fixes have no human gate. Real blockers fail without reaching `done`.
Native environment lifecycle preserves work and stops its own Docker on terminal;
actual stopped state still needs observation by the parent, not agent assertions.

Each role returns native custom-schema JSON through `output.<node>` → command
`stdin_source` → `guard.py accept` → native routing JSON. Agents cannot route to
success by prose. `stage_start` writes a small, current `task.json`; full-fidelity
navigators MUST reread it because `full` has no other-stage preamble. Fresh drivers
get only facts, their bounded assignment and results, NOT navigator conversations.
Review gets whole source/spec/results and the previous finding list, not histories.

Sandbox `pre_tool_use` enforces read-only navigator/review tools, blocks subagents,
unknown/web/MCP/run-management tools, and restricts shell to exact guarded
`inspect`/`observe` commands. Drivers cannot write before required baseline or
after recorded handback, outside assigned paths, or to workflows/.feature files.
Apply-patch paths (including moves) and native edit paths are checked. Native API
tools may run in parallel: a file lock serializes counters/observations, and
pre/post-tool reservations prevent overlapping shell/edit calls from crossing a
baseline/handback boundary. Missing completion stops rather than silently unlocks.
Do not batch change/test tools. No invented
`permissions`/`fresh_session` node attributes. Raw shell is not a read-only tool.

## Small job facts, not a new session/receipt platform

After approval, commit a JSON admission file on the **trial source branch** with:

```json
{
  "acceptance_kind": "domain",
  "feature": "acceptance-tests/features/member_profile.feature",
  "scenario": "Alice's older edit requires confirmation of the newer name",
  "spec": "docs/iterations/068-member-name-editing/plan.md",
  "setup_id": "REPLACE-with-reviewed-historical-source-and-pinned-runtime-identity",
  "deadline_utc": "2026-10-16T13:03:37Z",
  "aggregate_operations": 600,
  "operations_spent_before_run": 0,
  "allowed_paths": ["web/lib/memba", "web/lib/memba_web", "web/test"]
}
```

**Illustrative only**: parent must verify the actual historical spec path, approve
scope and choose the finite allowance; 600 is not an inherited admission. Operation
units are shared stage attempts + tool invocations + guarded command starts, not a
claim about dollar/token cost. Native usage/cost logs remain authoritative where
available. Native `max_node_visits=128` is an additional fixed safety ceiling, not a
renewable per-change allowance. The parent separately owns the three-run ceiling.
For any approved new attempt, keep the ORIGINAL total/deadline and carry actual
consumed operations from preceding native logs/artifacts into
`operations_spent_before_run`; never set it back to zero to buy another attempt.
There is intentionally no automatic cross-run recovery platform.

Pass `admission_path` (simple repo-relative path, no quotes/shell characters) and
`expected_source_head` (exact prepared 40-hex commit) as normal Fabro run inputs.
The SHA is passed separately to avoid a committed file containing its own SHA.
The facts file must already be in that managed clone; admission rejects dirty or
wrong source, missing spec/example and absent/expired/nonfinite original limits.
Normal launch is directly against this TOML, NOT `dev fabro deliver`, an eval
wrapper/private server/direct SDK or rollback of main. Parent must assemble the
reviewed workflow + agreed 068 example + genuine product source BEFORE that
example's implementation, preserving all other pending historical examples.

Only latest bounded task/results/limits live under `.fabro/tmp/bdd-implementation`,
excluded from checkpoint commits. Actual product bytes/modes (including nonignored
new files), selection, setup identity/available baked image metadata (not a verified
digest), prediction BEFORE execution, command/exit and raw ExUnit trace/log are
recorded. Checkpoint SHA alone is not test identity.
Artifacts are requested through native `[run.artifacts]`; no private receipt broker,
custom session persistence, cleanup controller or recovery platform is added.

This draft uses the EXISTING DOMAIN/Elixir runner, not JS browser step definitions:
`bin/dev test test/features/domain_cucumber_acceptance_test.exs --only
"scenario_name:EXACT NAME" --trace` (real argv, so apostrophes are not shell code).
The raw trace/tag must identify the exact feature basename/name; actual ExUnit
summary total minus intentionally excluded tests must equal ONE. Excluded tests
from a focused selector are not skipped executions; pending historical examples
remain visible/unmodified. Zero selected, skipped checks, setup errors and non-test
exits cannot pass. Existing `Cucumber.StepError` missing-step output is a legitimate
`undefined` observation, not an infrastructure failure. Actual failed-step text
and causal assertion details come from framework error output, not invented JSON.
Earlier selections use `domain:acceptance-tests/features/file.feature::Exact name`.
Green requires exit zero, exactly one executed test and zero failures/skips.
Failure matching uses step + status + stable causal error;
known-failure comparison ignores stack locations, not assertion values. Supporting
checks must be current/green before reached-prediction handback. Finish requires
current selected green, real full-check exit/test summaries and one complete clean
review on the SAME bytes. Agent declarations/zero/missing/skipped checks cannot
supply test green. Approved examples/assertions/authorisation remain unchanged.

## Source basis and honest limitations

Inspected vendored docs: [agents/backends](../../../docs/tools/fabro/public/core-concepts/agents.mdx),
[context/fidelity](../../../docs/tools/fabro/public/execution/context.mdx),
[run config](../../../docs/tools/fabro/public/execution/run-configuration.mdx),
[language](../../../docs/tools/fabro/public/reference/dot-language.mdx),
[transitions](../../../docs/tools/fabro/public/workflows/transitions.mdx),
[hooks](../../../docs/tools/fabro/public/agents/hooks.mdx). Local 0.316 source snapshot:
`/home/matt/projects/fabro-slack-0316/lib/components/fabro-workflow/src/`:
`handler/llm/api.rs` caches sessions ONLY with full fidelity, otherwise creates new
sessions; workflow tool permission is Full with hooks as the policy boundary.
`lifecycle/fidelity.rs` resolves thread IDs (including implicit previous-node IDs),
but non-full fidelity still disables API session caching. `handler/command.rs`
supports `stdin_source`/structured output; `lifecycle/hook.rs` runs sandbox guards.
For domain evidence, inspected the actual Cucumber `step_error.ex` message
contract and existing `DomainCucumberRunner`, the prototype's raw ExUnit
`selected_count(kind='domain')`, and its forced responsive preflight output check.
Only those boundary ideas are reused, NOT its controller/builder state machine.
These inspections are not a proof that every deployed behaviour matches the draft.

- Native conversation cache is memory-only; full fidelity degrades on resume.
  Do NOT claim durable navigator conversation on controller restart. The begin
  marker refuses reuse of an existing runtime directory; missing job state stops
  resumed later stages. No automatic resume/replacement run is supported. Preserve
  logs/checkpoints/work for a deliberate parent decision, retaining original limits.
  Restoring an empty sandbox/new run is NOT a proven aggregate-counter recovery.
- Deadline is checked before stages/tools/commands; command timeout is bounded by
  remaining time. This is NOT a hard controller-inference/process billing cap;
  parent must monitor/cancel at the original deadline. Remote resource caps and
  descendant-process cancellation are not newly established by this helper.
- Focused units currently support only `web/test/..._test.exs[:line]`. Other runners
  (including package units) need a small reviewed selector addition, NOT arbitrary
  shell. Full check uses ordinary `bin/dev check`, never quick/ci substitution.
- Domain ExUnit trace/error/full-check summary parsing, native hook payloads/output/
  artifact collection and actual session separation still need the real normal run.
  Unsupported/missing output is not passing. Browser/network proof is separately
  forced BEFORE implementation; the domain example is not a browser substitute.
  No fake fonts/network/browser success or JS step-definition transplant is added.
- Review completeness and semantic matching still require agent judgement. These
  guards validate evidence/protocol, not the truth of a design finding or a proof
  against malicious test code (tests execute in the same application sandbox).
  UX evidence gaps must block/report honestly; generic artifact export is unproved.
- No source clone disabling, local source injection, provider/auth changes, new
  image, dependency or global settings. No controller credentials are copied into
  Docker. Native clone/checkpoint transport remains Fabro's responsibility.

## Focused checks in this child

Python AST/TOML/five-role/native-configuration assertions passed. An initial
assertion incorrectly compared the model table without its nested `controls`;
inspection identified that test-harness mistake and the corrected assertion passed.
Initial isolated guard fixture runs passed (19 then 24 cases including serial
edit/test boundaries), but parent inspection correctly identified the JS acceptance
boundary as wrong for this DOMAIN example. That parser was removed, not accepted
on synthetic success. The replacement uses actual domain ExUnit evidence and
forced responsive preflight. **25 current domain/preflight/protocol checks passed**,
including read-only parsing of genuine old framework errors plus explicit synthetic
selection/handback/guard cases. No old result is treated as a new runtime result.
Synthetic decisions/old raw logs are NOT current product/model/runtime proof.
`fabro validate workflow.fabro` passed: 17 nodes/37 edges, with the expected
graph-only warning about unbound `admission_path` (normal TOML/launch supplies it).
Follow-up validation of the actual TOML reproduced the unsupported flat fallback
array; changing it to the native model-keyed map fixed parsing. Direct TOML
validation then passed with no warnings; see `runner/tests/toml-validate-01.log`
(failure) and `toml-validate-02.log` (pass). Existing hook command arrays were accepted
by that parser; actual hook execution remains for the parent's normal smoke.
No workflow execution, app test, model/eval call, container/probe, `dev check`,
compile/lint/format, commit or push was performed by this child.

This remains an unfinished, not runtime-tested draft. Stop at handoff for parent
inspection/integration; do not interpret these focused checks as a successful run.
