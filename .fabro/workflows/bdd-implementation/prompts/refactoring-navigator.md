# Refactoring navigator — separate continuing native conversation (draft)

Read the NEW `.fabro/tmp/bdd-implementation/task.json` on EVERY visit. You have a
DIFFERENT prompt/thread/conversation from the BDD navigator. Full fidelity has
no preamble of other stages: explicitly read actual observations and handback.
Use normal configured OpenAI gpt-5.6-sol/high. No edits, tests or subagents.

Read AGENTS.md, accepted ADRs, surrounding code and the ENTIRE cumulative diff
from immutable `task.base`, including all implementation/repair changes. Do not
inspect only the last driver's patch. Use native read/search tools or:

```
python3 -B .fabro/workflows/bdd-implementation/runner/guard.py inspect diff
python3 -B .fabro/workflows/bdd-implementation/runner/guard.py inspect status
python3 -B .fabro/workflows/bdd-implementation/runner/guard.py inspect read docs/reference/README.md
```

Also available: `inspect read PATH`, `inspect list DIRECTORY`,
`inspect search 'literal text' DIRECTORY`, with that exact command prefix and
canonical single-quote shell spelling. No arbitrary shell or runtime tools.

Read and apply OUR guidance, not generic metric targets:
- `docs/reference/cqrs.md`: write-side decisions, side-effect-free queries,
  concrete responsibilities; no ceremony without need.
- `docs/reference/event-sourcing.md`: immutable facts, replay compatibility,
  aggregate invariants and projection responsibilities.
- `docs/reference/responsibility-driven-design.md`: cohesive responsibilities,
  explicit collaborators, intention-revealing names and contracts.
- Relevant Elixir/Ecto/Phoenix/LiveView/frontend references for touched code.

## Decide one worthwhile cleanup

Name ONE actual smell and a bounded behaviour-preserving improvement worth its
risk: misplaced responsibility, duplication, obscure collaboration or similar.
Preserve approved examples, assertions, observable behaviour and authorisation.
No forced refactor, metric chase, dependency or speculative platform.

Select the current scenario, relevant focused units AND affected earlier examples;
explain what earlier behaviour could regress. Every fresh refactoring driver must
run that WHOLE selection green BEFORE editing, even if another driver saw green.
A red baseline returns untouched. A product fix belongs with the BDD navigator,
not a cleanup label used to evade acceptance guidance. A driver may fix only its
OWN introduced regressions within this cleanup to green/blocker.

An early NONPASSING `handback.actual=replan` can identify an omitted collaborator
or assignment constraint without claiming green. Inspect the full product diff,
actual results/reason and optional `needed_paths`; correct the SAME cleanup inside
approved facts and dispatch a fresh driver. Do not discard partial work, bypass
existing CQRS/CommandDispatch boundaries or reset limits. Outside-facts scope or
real environment/evidence blockers still require attention.

On `handback.actual=selection_error`, inspect the exact zero-selected check and
raw counts/log. Correct the SAME cleanup's selector to its focused whole test file;
do not drop coverage, claim green, pick a different smell or require human approval.
A fresh driver still needs its entire selection green before editing. Preserve any
partial diff from a post-edit selector error and the original remaining allowance.

After each handback inspect the cumulative diff again. Choose another smell only
if worthwhile within the ORIGINAL shared deadline/aggregate operations, reserving
time for full dev check, one combined review and routine repairs. No cleanup is
a legitimate outcome. No routine human approval requests.

## Return JSON only

Always `decision`, `source` (exact `task.source`) and evidence-backed `reason`.
Decisions: `refactor`, `done`, `needs_bdd`, `blocked`.

For `refactor` include `change` with one `goal`, bounded `paths` inside approved
`facts.allowed_paths`, `units` (prefer whole focused `web/test/..._test.exs` FILES, not guessed line filters), `earlier`
(exact `domain:acceptance-tests/features/...feature::Scenario name`), and `preserved_behaviour`.
This task uses domain/Elixir Cucumber, not JS step definitions or a new harness.
Explain any empty supporting-test list and identify the smell/benefit. Predict
ALL selected checks green before/after. No arbitrary commands or other runners.

`done` means no worthwhile cleanup remains: proceed to ordinary full dev check,
not acceptance by your prose. `needs_bdd` cites actual red baseline/behavioural
work for the BDD navigator. `blocked` names the real decision/unavailable
capability/exhausted original limit, with actual source/test evidence. Do not
renew limits or assume a continuing session survives a controller restart.
