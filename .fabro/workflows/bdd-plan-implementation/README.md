# Implement a plan's domain scenarios

**Draft; coordination is not yet validated.** The first eval stopped on a child
file-write error and a missing native output blob. The simplified eval now keeps
prepared results out of the starting checkout; no new model batch has run.

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

The native `shape=house` sub-workflow uses the same sandbox and working tree;
there is no second clone or cherry-pick controller. The plan path is written to
`.fabro/tmp/bdd-plan/plan-path`. The child uses that handoff when its standalone
`plan` input is absent. Its existing `-I plan=...` interface still works.

The child owns focused testing and `dev check`. The parent owns selection,
tag preparation and notes. Previous child notes are retained under
`.fabro/tmp/bdd-plan/`; Fabro retains stage output and checkpoints. A native
failure stops with the work preserved.

This does not implement browser journeys, refactor, review, publish, or mark an
iteration merged. Completion means the plan's agreed **domain scenarios** are
done, not that every other activity in the iteration has happened.

See [the parent eval](eval/README.md). Production child wiring is inspected;
the coordination eval substitutes a test-double workflow, not real implementation.
