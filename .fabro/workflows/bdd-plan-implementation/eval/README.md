# Retained plan-workflow checks

This directory contains reusable checks from the plan-workflow experiments:

- `test_boundaries.py` tests the assembled native graph boundaries, canonical
  selector binding, failure routing and scratch preservation;
- `selection/` contains the commit-only selector prompt, host harness, fixed case
  records, and pure tests; and
- `cases/stock-fabro/` is a model-free capability graph for native import and
  shell writes without changing file ownership.

Raw results, source bundles, prepared fixture patches, and synthetic product
implementations remain in durable external evidence storage and Git objects.
They are intentionally ignored here. The failed historical controller, double,
grader, and batch runner are also excluded: they used a broken literal
`@double.sh` path and do not establish reusable workflow behavior.

These checks prove different things. Source-quality checks establish that a
source snapshot passed its quality gate. Selector batches establish decisions
for three fixed inputs. The stock capability case establishes only import and
shell-write mechanics. None establishes successful runtime coordination of the
assembled workflow.

Run the local pure checks with:

```bash
node --test dev-tools/bdd/test-workflow.cjs
python3 -B .fabro/workflows/bdd-plan-implementation/eval/test_boundaries.py
python3 -B -m unittest discover \
  -s .fabro/workflows/bdd-plan-implementation/eval/selection \
  -p 'test_*.py'
```
