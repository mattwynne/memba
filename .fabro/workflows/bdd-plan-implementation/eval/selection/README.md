# Commit-only next-scenario decision

This tests one read-only prompt, not a parent implementation workflow. The only
task input is a Git commit. The agent discovers the single active plan and its
pending domain scenarios, reads relevant code and guidance at that commit, and
returns a plan path, feature path, exact scenario name, and short reason.

`prompt.md` and `eval.py` are unchanged across the three tested source snapshots.
The default `case.json` is the original preimplementation case used by source
commit `3f30c0adfc4f0862ba095f266093491c0a28e428`. Later host-only records are kept
without overwriting it:

| Record | Source | Fixture state | Accepted next work |
| --- | --- | --- | --- |
| `case.json` | `3f30c0adf` | Before implementation | Either successful rename foundation |
| `cases/foundation-done.json` | `4087367f5` | Synthetic foundation done | Either pending constraint |
| `cases/whitespace-done.json` | `4240e4c35` | Synthetic foundation and whitespace done | Stale-edit constraint |

Each case had 20/20 accepted decisions in fresh sessions with the same prompt.
That is fixed-case decision evidence, not a general reliability result. The two
later fixtures are synthetic and unsafe to deploy. Case two does not rank its two
constraints, and case three has only one eligible choice. No case proves
implementation, coordination, empty-set handling, or ambiguous-plan handling.

The case records are host grading data and must never be sent to the agent or
copied into a fixture checkout. The harness defaults to `case.json`; the later
records preserve provenance for review and future explicit fixtures rather than
silently changing that default.

The prompt's read-only rule is an instruction, not a tool interceptor. A real
batch must audit actual tools and Git state, retain every response and failure,
and stop rather than relaunch after an unknown acknowledgement. Do not run model
batches as part of ordinary source tests.

Run the pure tests with:

```bash
python3 -B -m unittest discover \
  -s .fabro/workflows/bdd-plan-implementation/eval/selection \
  -p 'test_*.py'
```

Executable source still needs the project quality gate on the exact assembled
state. That source-quality result is separate from selector decision evidence.
