Goal: Prove that a Fabro parallel fan-in exposes every branch response to the downstream synthesis prompt
Run ID: 01M1PCVZT131EPRN993ARQ42AH
Pipeline progress: 2 of 6 stages completed

## Stage: fork
- Status: succeeded
- Handler: parallel
- Notes: Parallel node dispatched 3 branches (3 succeeded, 0 failed)

## Stage: merge
- Status: succeeded
- Handler: parallel.fan_in
- Notes: Joined 3 parallel branches

## Current context
| Key | Value |
|-----|-------|
| parallel.branch_count | 3 |
| parallel.results | [{"id":"alpha","index":0,"status":"succeeded","context_updates":{"last_response":"FANOUT-EVIDENCE-ALPHA-71C3","last_stage":"alpha","response.alpha":"FANOUT-EVIDENCE-ALPHA-71C3"}},{"id":"bravo","index":1,"status":"succeeded","context_updates":{"last_response":"FANOUT-EVIDENCE-BRAVO-4A9E","last_stage":"bravo","response.bravo":"FANOUT-EVIDENCE-BRAVO-4A9E"}},{"id":"charlie","index":2,"status":"succeeded","context_updates":{"last_response":"FANOUT-EVIDENCE-CHARLIE-8F2B","last_stage":"charlie","response.charlie":"FANOUT-EVIDENCE-CHARLIE-8F2B"}}] |


Inspect the completed review-stage responses in your context. If and only if you can see all three distinct response tokens, return one line beginning `FANIN-EVIDENCE-PRESENT:` followed by the three exact tokens, separated by ` | `. Otherwise return exactly `FANIN-EVIDENCE-MISSING`.