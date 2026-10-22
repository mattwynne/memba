# Plan-level BDD workflow

This opt-in native Fabro workflow implements an active plan's domain scenarios
one at a time. The delivery skill recommends it for suitable small, agreed
domain-focused work through `bin/dev fabro deliver <plan> --domain-only`.
Ordinary delivery without that flag is unchanged.

On stock Fabro `0.389.0-nightly.0`, one historical rehearsal completed all three
domain scenarios with graph-owned full checks and no manual repair. The
rebased source and historical fixture passed their managed Docker gates.
However, the first selector also read Git history, so the strict HEAD-tree-only
constraint was not met. See the [result and limits](REHEARSAL.md).
This is not a reliability estimate or approval to deploy the historical result.

## Assembled loop

- Setup rejects any run-input override whose value is not exactly `HEAD`, then
  the graph runs the repository's ordinary `npm ci --prefix acceptance-tests
  --no-audit` once before inspection. This supplies the Gherkin parser in a
  fresh managed clone without starting the app or running tests.
- `node dev-tools/bdd/workflow.cjs inspect` calls the public
  `bin/dev bdd pending HEAD --json` command, records the resolved full SHA and
  complete root-tree OID, and routes either to a fresh selector or domain-loop
  completion. Journeys remain in the saved report and never mark an iteration
  merged.
- [`eval/selection/`](eval/selection/README.md) contains the retained canonical
  commit-only selector prompt and fixed cases. Every loop visit uses
  `fidelity="truncate"`, no thread ID and no output schema. Stock Fabro adds its
  minimal goal/run-ID preamble; the canonical task body remains unchanged and
  receives only the literal run input `HEAD`. Pinned stock Fabro shell-quotes
  the unquoted command-script substitution as one argument, allowing setup to
  reject a CLI override before the selector runs.
- Native `response.selector` is passed by `stdin_source` to deterministic
  validation. A valid selector `error` response stops with its reason. A choice
  command captures the current full SHA, requires a clean
  worktree and the same complete tree, reruns public `pending` at that SHA,
  resolves exactly one eligible declaration, then calls public
  `bin/dev bdd pick REF --from CURRENT_SHA` in the same command node. Empty
  checkpoint commits are tolerated only because the tree is unchanged; the
  tree never replaces the exact `--from` SHA guard.
- The parent DOT graph is [workflow.fabro](workflow.fabro), beside its public
  `workflow.toml`. The reusable scenario package is nested under
  [`scenario/`](scenario/README.md), so every imported graph and prompt remains
  below the parent graph's directory. This satisfies stock 0.389's package
  collector while keeping one canonical copy of each graph and prompt.
- The real single-scenario graph is imported with stock Fabro. Its implementation
  navigator uses the one literal full-fidelity `bdd-navigator` thread across the
  whole plan. Each driver remains truncate-fidelity and fresh. The selector is
  separate and receives no pending report, plan path, scenario list or
  implementation conversation.
- Before another scenario starts, the graph moves the complete prior
  `.fabro/tmp/bdd/` directory to the next numbered directory under
  `.fabro/tmp/bdd-plan/scenarios/`, then creates fresh scratch. Partial and
  complete notes, bases, results, check logs and arbitrary logs are retained.
  A symlinked scratch path fails clearly rather than reusing old evidence. The
  final scenario remains in active scratch when the domain loop finishes.
- The tracked root `.gitignore` narrowly owns `/.fabro/tmp/` and
  `/.fabro/blobs/`. Setup verifies those exact declarations and never changes
  `.git/info/exclude`, so public clean-state checks do not hide other files.
- The imported graph owns the 1800-second full `bin/dev check`. Failure returns
  to the continuing navigator. Success crosses its conditional `check ->
  checked` edge and unconditional imported exit boundary before outer inspection
  repeats on the new commit.

## Evidence boundary

For a real ready/validated iteration, use `bin/dev fabro deliver <plan>
--domain-only` after explicit approval. The helper owns validation, predecessor
and WIP checks, source/plan admission and lifecycle reservation; the graph
leaves the product candidate for review and separate merge approval. It does
not complete pending journeys or other plan obligations.

For an explicitly approved fixture or split-phase operation that already meets
those prerequisites, launch the public entry with the environment selected:

```bash
fabro run .fabro/workflows/bdd-plan-implementation/workflow.toml --environment memba-dev
```

The graph owns inspect/select/pick/import/repeat routing and uses stock command
outputs, routing output schemas, raw response stdin and imports. Ordinary tests
cover two loop visits, updated HEAD binding, tree staleness, strict choice
validation, clean guards, completion/errors/journeys, failed-node routing,
scratch preservation and symlink rejection. The retained stock capability case
only proves import and shell-write mechanics.

The retained stock 0.389 rehearsal demonstrates one complete functional
HEAD/truncate loop, including one navigator conversation across all three
scenarios, fresh selectors/drivers and graph-directed check repair. It does not
prove strict snapshot-only selector compliance or general reliability. The
earlier 20/20 fixed selector cases used isolated full-fidelity calls with literal
SHAs and remain a different experiment.

The loop is limited to domain scenarios. Browser journeys, refactoring, review,
publication and marking an iteration merged are outside it. See
[`eval/README.md`](eval/README.md) for retained evidence boundaries and
[`OPERATIONS.md`](OPERATIONS.md) for the guarded operating procedure.

## Known limits

- The first selector in the successful functional rehearsal made read-only Git
  history queries outside the current HEAD tree. Strict snapshot-only selection
  remains an unmet constraint; the canonical prompt was not changed to hide it.
- Active inherited-only TODO work without a locally pickable declaration fails
  closed. This workflow does not add policy for it.
- The updated `test:wip` runner treats one declaration as one selection and
  generates separate tests for all its eligible rows. The rebased source passed
  its exact managed gate on stock 0.389; earlier standalone row-selection CLI
  proof belongs to 0.316 and is not relabelled as a new-runtime experiment.
- Fabro 0.389 reports a built-in maximum of 500 firings for otherwise unlimited
  loop nodes. This workflow adds no arbitrary cost, duration or visit cap.
  Native warnings and any automatic context compaction must remain in evidence.
- Selector JSON has only plan, feature, scenario and reason. Multiple eligible
  Examples groups with the same names fail as ambiguous; the workflow does not
  guess or add hidden selector fields.

The pure boundary tests are in [`eval/test_boundaries.py`](eval/test_boundaries.py).
The deterministic mechanics tests are in
[`dev-tools/bdd/test-workflow.cjs`](../../../dev-tools/bdd/test-workflow.cjs).
They are not a Fabro execution, model evaluation or managed source-quality gate.
