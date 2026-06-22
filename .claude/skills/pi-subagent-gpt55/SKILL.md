---
name: pi-subagent-gpt55
description: Delegate self-contained research, review, planning, debugging, or implementation subtasks to a Pi subagent running the openai-codex/gpt-5.5 model. Use when the user asks for Pi, GPT-5.5, a subagent, independent analysis, parallel investigation, or a second coding-agent opinion.
user-invocable: true
---

# Pi Subagent GPT-5.5

Use this skill to delegate a bounded task to a separate Pi coding-agent process using Matt's `openai-codex/gpt-5.5` model.

## Command

From the repository root, run the helper script with a heredoc prompt:

```bash
.claude/skills/pi-subagent-gpt55/scripts/delegate-pi-gpt55.sh --research <<'PROMPT'
Your delegated task here.
PROMPT
```

For tasks that may edit files, use `--write`:

```bash
.claude/skills/pi-subagent-gpt55/scripts/delegate-pi-gpt55.sh --write <<'PROMPT'
Your delegated implementation task here.
PROMPT
```

The helper invokes:

```bash
pi --provider openai-codex --model gpt-5.5 --thinking high -p ...
```

## When to delegate

Delegate when a task is useful as an isolated branch of work:

- Independent code review or architecture critique.
- Focused investigation across unfamiliar files.
- Debugging a specific failure where a second hypothesis would help.
- Drafting a plan or alternatives before you decide.
- Implementing a small, clearly bounded change in disjoint files.

Do not delegate tiny lookups you can do faster yourself, ambiguous tasks that need user clarification first, or broad implementation work that would conflict with your own edits.

## Prompt checklist

Write the subagent prompt as a complete brief. Include:

1. The goal and expected output format.
2. The relevant files, commands, logs, or failing tests.
3. Whether the task is read-only or allowed to edit files.
4. Boundaries: files/directories in scope and explicitly out of scope.
5. Project rules that matter, especially whether to run `dev check`.
6. A request to report evidence: files read, commands run, tests/checks run, and any changed paths.

## Default modes

### Research mode (`--research`)

Use for investigation, review, planning, and second opinions. The helper restricts Pi to read/search tools so the subagent cannot edit files. Ask for concise findings with file references.

### Write mode (`--write`)

Use only when you want Pi to change files. Make the scope narrow and avoid editing the same files yourself while the subagent runs. Tell the subagent to run the smallest relevant checks; for Memba code/config/behaviour changes, tell it to run `dev check` before reporting back unless you deliberately want only a draft patch.

## Parallel delegation

You may run multiple Pi subagents in parallel only when their tasks are independent and either read-only or assigned non-overlapping write scopes. Use separate Bash tool calls in the same turn.

## After the subagent returns

- Treat the output as advice or a draft, not truth.
- Inspect any changed files yourself.
- Re-run or review important checks before telling the user the work is done.
- Summarize what the subagent contributed and what you verified.
