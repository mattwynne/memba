# Implement a plan's domain scenarios

**Draft; coordination is not yet validated.** The first eval stopped on file
ownership and child-output errors. This version uses stock Fabro imports and
shell writes instead. The commit-only selector has been tested separately;
full coordination is still unvalidated. No fork or patched Fabro is used.

Opt-in; this does not change `fabro deliver`.

```bash
fabro run .fabro/workflows/bdd-plan-implementation/workflow.toml \
  -I plan=docs/iterations/NNN-topic/plan.md
```

Start from a committed plan and its agreed domain scenarios tagged `@todo`.
The plan navigator reads the plan, linked decisions, guidance and current code.
It chooses a useful foundation before adding complexity, rather than following
file order. It activates one scenario, calls `bdd-scenario-implementation`,
keeps that child's work, then chooses again.

```text
start → setup → plan navigator → scenario child
                    ↑                 │
                    └─────────────────┘
                    ↓ all planned domain scenarios done
                   done
```

Fabro's built-in `import` reuses the scenario graph inside the same run. This is
not a `shape=house` child engine: imported stages use the run's normal durable
output storage, avoiding that version's child-output persistence problem. There
is no second clone, copy of the scenario logic or cherry-pick controller. The
same `plan` input is available to both workflows; standalone scenario runs still
work. Agents write files using shell commands to avoid native-upload ownership
changes. This uses existing capabilities of the unmodified Fabro release.

The child owns focused testing and `dev check`. The parent owns selection,
tag preparation and notes. Previous child notes are retained under
`.fabro/tmp/bdd-plan/`; Fabro retains stage output and checkpoints. A native
failure stops with the work preserved.

This does not implement browser journeys, refactor, review, publish, or mark an
iteration merged. Completion means the plan's agreed **domain scenarios** are
done, not that every other activity in the iteration has happened.

## Deterministic pending-work check

```bash
node .fabro/workflows/bdd-plan-implementation/pending.cjs COMMIT
```

This read-only helper finds the one active iteration using the index's documented
WIP statuses. It parses all committed feature files with the existing
`@cucumber/gherkin` dependency, including inherited feature/rule/scenario/Examples
tags. A `@todo` for a `merged` iteration is an error, including journeys. Future
iterations' TODOs are allowed. Unfinished examples with missing, unknown or
ambiguous iteration ownership error rather than being silently dropped; any WIP
also prevents completion. The lifecycle vocabulary is tested against the existing
Python status helper.

The JSON result gives `pending`, `pending_journeys`, `domain_complete` and Fabro's
`preferred_next_label`: `choose` if domain TODOs remain, otherwise `done`. Errors
exit nonzero with the file/scenario where possible and no success result.
`done` is only the domain loop: it does not mark an iteration merged, and pending
current journeys are explicitly reported. Nothing edits tags or metadata.

The helper is ready for an ordinary command node, but is **not wired into this
draft graph yet**; that belongs with connecting the tested selector. Its ordinary
tests live in [eval/test_pending.cjs](eval/test_pending.cjs). No model eval is
needed to determine whether the eligible set is empty.

See [the parent eval](eval/README.md). Production child wiring is inspected;
the coordination eval substitutes a test-double workflow, not real implementation.
