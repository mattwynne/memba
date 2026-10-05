Goal: Rehearse an approved historical BDD scenario without publication
Run ID: 01M45EKSVMVZJF071CH3WCHVZV


Independently review the **single-scenario** historical candidate. Do not edit files. Inspect `docs/iterations/066-request-group-access/plan.md`, the active feature `acceptance-tests/features/custom_group_access_requests.feature`, `.delivery/goal-directed-bdd/{before,after}.json`, focused unit-test evidence and `git diff` since the gate baseline. Return structured decision `accept`, `revise` or `blocked`, with concrete reason. Verify the actual before observation failed for missing product behaviour, after passed exactly one `@wip` scenario, the scenario driver was not weakened, the production change is the narrowest coherent solution with required authorization/recipient privacy, relevant unit tests pass and other observable behaviour is preserved. A passing scenario alone is insufficient. Distinct bounded technical findings => `revise`; genuine new business/architecture decision or unsafe scope => `blocked`. An accepted checkpoint is **not publication**; the gate removes `@wip` only after it validates your verdict and evidence. Do not request Matt merely to authorize a specified technical repair.


Fabro final-output contract

The following contract is trusted workflow configuration. It applies only to your final response, not to intermediate tool calls.
Return a single JSON object that satisfies this JSON Schema:
<output_schema>
{"type":"object","additionalProperties":false,"required":["decision","reason"],"properties":{"decision":{"type":"string","enum":["accept","revise","blocked"]},"reason":{"type":"string","minLength":1}}}
</output_schema>
The contract is complete. Do not ask the user to provide or choose the output shape.