# Problem: Fabro read-guard can block routine todo.md check-off late in a task

Date: 2026-06-23

## Context

During Fabro implementation run `01KVSMA9D18M6V47C2ZPQ9S83N` for iteration 044, the implementation agent attempted to check off the selected task in `todo.md` after doing implementation and validation work.

Relevant path:

- `.fabro/workflows/iteration-implementation/prompts/implement_next_task.md`

## Expected standard

The implementation prompt should make Fabro read-guard expectations explicit for routine `todo.md` check-off. Agents should read the exact active todo file through the agent read tool immediately before editing it, so a routine check-off does not fail near the end of a long implementation node.

## What happened

Fabro blocked a `todo.md` write because the agent had not read that exact path through the agent read tool first:

```text
Write blocked: file not read by agent path=/repos/mattwynne/memba/docs/iterations/044-conversation-page-alignment/todo.md
```

The agent then read the exact file path and retried the one-line patch successfully. The recovery worked, but it consumed time near the node timeout boundary.

Follow-up investigation noted that earlier script-node reads, shell output, or `cat`-style inspection do not satisfy the agent tool read-guard. The guard requires a read by the active agent on the exact path it will edit.

## Impact

This is small but repeatable workflow friction. It can surprise agents at the end of a task, after implementation and validation have already consumed most of the node budget. In this run, the check-off friction happened shortly before the implementation node timed out.

## What allowed it to happen

- `implement_next_task.md` tells agents to read the plan and `todo.md` before editing, but it does not explicitly say to reread the exact todo path with the agent read tool immediately before check-off.
- The workflow prints `todo.md` in earlier shell/script nodes, which can give the appearance that the file has been “read,” but that does not satisfy Fabro’s agent read-guard.
- The read-guard error is protective and correct, but the prompt does not teach agents the safe pattern.

## Observations

- This is not a product bug and not a reason to remove the read-guard.
- The safe fix is likely prompt-level: make the expected read-before-patch sequence explicit.
- The check-off itself is routine and happens on every implementation task, so even small friction here can recur often.

## Why this matters

The end of an implementation node is the worst time to discover a process requirement. A late read-guard failure can turn otherwise complete work into timeout risk and add noise to run diagnosis.

## Open questions

- Does Fabro expose a clearer error/remediation message for read-guard failures?
- Should the workflow provide a deterministic helper for checking off a selected todo line, or is prompt guidance enough?
- Can validation verify that `implement_next_task.md` contains the read-guard-safe check-off instruction?

## Possible prevention ideas

- Update `implement_next_task.md` so the check-off instruction says: immediately before editing `todo.md`, read the exact todo path with the agent read tool, then patch only the selected line.
- Mention explicitly that shell `cat`, workflow pre-read nodes, and prior script output do not satisfy the active agent read-guard.
- Consider a small deterministic script/helper for todo check-off if prompt guidance does not prevent recurrence.

## Resolution

Date: 2026-06-23

Root cause: the `implement_next_task` prompt required reading `todo.md` before editing and checking off the implemented task, but it did not teach the timing-sensitive Fabro read-guard rule: the active agent must read the exact todo path with the agent read tool immediately before the final check-off edit. Earlier script output and shell reads can look sufficient while not satisfying the guard.

Fix applied:

- `.fabro/workflows/iteration-implementation/prompts/implement_next_task.md`: added an ownership-rule instruction to read the exact active `todo.md` path with the agent read tool immediately before check-off, then patch only the selected line, and explicitly noted that shell `cat`, earlier workflow/script output, and reads of other paths do not satisfy the active-agent read guard.

Validation:

- `rg -n 'Immediately before editing `todo\.md`|agent read tool|active-agent read guard|Shell `cat`' .fabro/workflows/iteration-implementation/prompts/implement_next_task.md` — confirmed the prompt contains the read-guard-safe check-off instruction.
- `fabro validate .fabro/workflows/iteration-implementation/workflow.toml` — passed (`Validation: OK`); existing goal-gate retry warnings were unchanged.

Remaining follow-up:

- None for this prompt-level fix. If this recurs despite the prompt, reconsider a deterministic todo check-off helper.
