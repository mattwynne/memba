The intended WIP scenario was selected: “Alice's older edit requires confirmation of the newer name.” It ran as exactly one ExUnit test and failed at the predicted undefined first step:

> Given Alice began changing their name when it was "Alice Smith"

The initial shell lacked the repository’s `bin/` directory, so the first invocation exited 127 because `dev` was unavailable. That mismatch is preserved separately; after correcting only `PATH`, the baseline run exited 2 with the expected single scenario failure.

Artifacts:

- Assignment: [change.md](/workspace/memba/.fabro/tmp/bdd/change.md)
- Baseline output: [baseline.log](/workspace/memba/.fabro/tmp/bdd/baseline.log)
- Baseline status: [baseline.status](/workspace/memba/.fabro/tmp/bdd/baseline.status)
- Initial setup mismatch: [initial.log](/workspace/memba/.fabro/tmp/bdd/initial.log)
- Initial setup status: [initial.status](/workspace/memba/.fabro/tmp/bdd/initial.status)

The assignment covers one conditional Person-rename vertical slice through preparation, authorization, aggregate concurrency, event, projection, live-query classification, real query assertions, and native Cucumber steps. No agreed scenario or product code was changed.

{"preferred_next_label":"change"}