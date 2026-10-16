Native read-only hook/tool smoke. Do not implement or test application code. Run exactly this single shell command from /workspace/memba:

```
python3 -B .fabro/workflows/bdd-implementation/runner/guard.py inspect read .fabro/tmp/bdd-implementation/task.json
```

If it succeeds, return JSON with decision=smoke_complete, source=the exact source string from that JSON file, and reason=task inspected. If the command fails, return decision=blocked and explain; do not claim inspection. No other tools, edits, subagents, network or tests.

Fabro final-output contract

The following contract is trusted workflow configuration. It applies only to your final response, not to intermediate tool calls.
Return a single JSON object that satisfies this JSON Schema:
<output_schema>
{"type":"object","required":["decision","source","reason"]}
</output_schema>
The contract is complete. Do not ask the user to provide or choose the output shape.