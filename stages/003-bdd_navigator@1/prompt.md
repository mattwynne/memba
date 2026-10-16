Native hook/tool smoke only. Do not implement or test anything. Make exactly one read-only shell tool call using this exact command from checkout root: python3 -B .fabro/workflows/bdd-implementation/runner/guard.py inspect read .fabro/tmp/bdd-implementation/task.json . Do not include the final sentence period in the command. Read its source field and return JSON only: decision=smoke_complete, source=the supplied source field, reason=task inspected. No other commands, edits, subagents, network or tests.

Fabro final-output contract

The following contract is trusted workflow configuration. It applies only to your final response, not to intermediate tool calls.
Return a single JSON object that satisfies this JSON Schema:
<output_schema>
{"type":"object","required":["decision","source","reason"]}
</output_schema>
The contract is complete. Do not ask the user to provide or choose the output shape.