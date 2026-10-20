# Implement a plan's domain scenarios

**Draft; coordination is not yet validated.** The first eval stopped on file
ownership and child-output errors. This version uses stock Fabro imports and
shell writes instead; no new model batch has run. No fork or patched Fabro is used.

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

See [the parent eval](eval/README.md). Production child wiring is inspected;
the coordination eval substitutes a test-double workflow, not real implementation.
