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

## What is still a draft

[`workflow.fabro`](workflow.fabro), [`workflow.toml`](workflow.toml), and
[`prompts/navigator.md`](prompts/navigator.md) are the historical stock-import
baseline. They are retained for the later assembly task, but they are **not a
working or proven controller**. In particular, this draft:

- does not call the deterministic pending checker;
- uses an old navigator prompt rather than the tested commit-only selector;
- lets that navigator edit tags instead of calling the agreed `dev bdd pick`
  command;
- has not yet received the separate conversation/result isolation and full-check
  timeout work; and
- has no complete loop, implementation, coordination, or all-done proof.

Do not run this parent graph as a supported workflow until those pieces are
assembled and validated. The pending helper is also expected to move into the
`dev bdd pending` toolkit command; avoid creating a second public interface here.

The eventual workflow remains limited to domain scenarios. Browser journeys,
refactoring, review, publication, and marking an iteration merged are outside it.
See [`eval/README.md`](eval/README.md) for the retained evidence boundaries.
