# Plan-level BDD workflow baseline

This directory collects reusable, separately tested parts for a future workflow
that implements a plan's domain scenarios one at a time. It is opt-in and does
not change `fabro deliver`.

## What is reusable now

- [`pending.cjs`](pending.cjs) deterministically reads an immutable commit,
  validates iteration ownership and status, and reports pending domain scenarios
  and journeys. Its ordinary tests are in [`eval/test_pending.cjs`](eval/test_pending.cjs).
  It is standalone and is not wired into the graph.
- [`eval/selection/`](eval/selection/README.md) contains the tested read-only
  commit-only selector prompt and harness. Three fixed host cases are retained
  separately; the synthetic fixture implementations are not copied here.
- [`eval/cases/stock-fabro/`](eval/cases/stock-fabro/) is a small model-free
  capability graph for shell writes around a native Fabro import.
- The single-scenario graph has the stock-import exit boundary and shell-write
  prompt guidance tested in source commit `e9fe14759093dcd87447bdc1e192174f68b2f5e5`.
- The imported implementation navigator uses one literal full-fidelity
  `bdd-navigator` thread across scenarios. Drivers remain truncate-fidelity and
  fresh for each assignment. The outer choice stage is a separate identity.
- Before the next scenario starts, the graph moves the complete prior
  `.fabro/tmp/bdd/` directory to the next numbered directory under
  `.fabro/tmp/bdd-plan/scenarios/`, then recreates empty scenario scratch. The
  last scenario remains in the active scratch directory when the plan finishes.
- The scenario's graph-owned full check has a native 1800-second timeout. A
  failed check returns to the continuing navigator; success still crosses the
  conditional `check -> checked` edge and unconditional imported exit boundary.

## What is still a draft

[`workflow.fabro`](workflow.fabro), [`workflow.toml`](workflow.toml), and
[`prompts/navigator.md`](prompts/navigator.md) are the historical stock-import
baseline. They are retained for the later assembly task, but they are **not a
working or proven controller**. In particular, this draft:

- does not call the deterministic pending checker;
- uses an old navigator prompt rather than the tested commit-only selector;
- lets that navigator edit tags instead of calling the agreed `dev bdd pick`
  command;
- has no complete loop, implementation, coordination, or all-done proof.

Do not run this parent graph as a supported workflow until those pieces are
assembled and validated. The pending helper is also expected to move into the
`dev bdd pending` toolkit command; avoid creating a second public interface here.

The eventual workflow remains limited to domain scenarios. Browser journeys,
refactoring, review, publication, and marking an iteration merged are outside it.
See [`eval/README.md`](eval/README.md) for the retained evidence boundaries.

## Boundary behavior and remaining integration decisions

The continuing implementation navigator must re-read the current commit,
selected declaration, code and setup for every scenario. Earlier work may inform
its reasoning, but old predictions and test output are not proof after the
source, scenario or setup changes. Each driver assignment is self-contained and
fresh.

This boundary delta deliberately does not wire the pending checker, tested
commit-only selector prompt or public `dev bdd pick` command into the graph. The
tested selector prompt remains byte-identical. Parent integration must connect
those pieces and preserve the graph variables they provide. The existing outer
`navigator` node and its `bdd-plan-navigator` thread are temporary historical
drafts. `bdd-connect` must replace that choice stage with the tested read-only
selector, give it only the current commit in a fresh session on every choice,
and never share the implementation navigator's `bdd-navigator` thread or history.

Two public-tooling decisions also remain outside this change:

- The current pending policy refuses inherited-only active TODO declarations.
  This workflow boundary does not change that policy flag.
- `test:wip` counts expanded example rows rather than selected declarations. For
  example, one tagged outline with two rows is currently counted as two WIP
  scenarios and rejected:

  ```gherkin
  @wip
  Scenario Outline: invite a <role>
    Given a <role> invite

  Examples:
    | role   |
    | owner  |
    | member |
  ```

  This workflow does not claim that Outline/Examples case is compatible or
  modify the public command.

The pure boundary tests in [`eval/test_boundaries.py`](eval/test_boundaries.py)
check source structure and prompt contracts only. They are not a Fabro execution,
model evaluation or source-quality/full-workflow proof.
