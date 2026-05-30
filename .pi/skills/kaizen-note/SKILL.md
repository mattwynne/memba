---
name: kaizen-note
description: Offer to capture and, when accepted, write a docs/kaizen observation when we notice friction, imperfections, waste, opacity, brittleness, or failure in the pipeline/factory/workflows/tooling used to create the product. Use for workflow/tooling problems, not ordinary product bugs.
---

# Kaizen Note

Use this skill when a conversation or run reveals an imperfection in the machinery we use to create the product: Fabro workflows, Pi skills/prompts, planning/review/implementation handoffs, sandboxing, checkpoints, CI/dev scripts, model routing, observability, recovery, or other delivery pipeline/factory friction.

The purpose is to preserve factual observations for later improvement. Do not turn the note into a speculative solution plan unless Matt asks.

## Trigger Habit

When you notice relevant friction, pause and offer to record it:

> This looks like pipeline/workflow friction. Would you like me to write a kaizen note in `docs/kaizen/` capturing the context and observations?

If Matt declines, acknowledge and continue. Do not write the note.

If Matt explicitly invokes `/kaizen-note`, `/skill:kaizen-note`, says to record a kaizen note, or otherwise clearly asks for one, treat that as consent and write it unless important facts are missing.

## What Qualifies

Good candidates:

- A workflow failed before or around product work because tooling, sandbox, checkpointing, branching, PR creation, model routing, or handoff machinery behaved badly.
- A process was ambiguous, brittle, hard to resume, or required manual archaeology.
- A prompt, skill, workflow, script, validation gate, or review loop created avoidable waste or confusion.
- We had to use an operator workaround that should be remembered.
- The system hid the real cause, reported an unhelpful status, or lacked enough evidence to debug quickly.

Usually not candidates:

- An ordinary application bug or failing product test with clear product-code ownership.
- A feature request for user-facing behaviour.
- A personal preference with no observed delivery friction.

## Writing Checklist

1. Confirm consent unless the user explicitly requested the note.
2. Inspect enough local context to write accurately. Useful sources include:
   - recent conversation details supplied by Matt;
   - `git status --short --branch`;
   - relevant workflow, skill, prompt, script, or docs paths;
   - Fabro run IDs, events, logs, URLs, commands, or failure text when available.
3. Choose a concise slug and create:
   - `docs/kaizen/YYYY-MM-DD-short-observation-slug.md`
4. Keep the note factual and diagnostic.
5. Commit the note once written. Do not include unrelated working-tree changes.

## Note Template

```markdown
# Problem: <short description>

Date: YYYY-MM-DD

## Context

What were we trying to do? Include the workflow/skill/script/iteration/plan path/run ID/URL when relevant.

## What happened

What friction, failure, ambiguity, or waste did we observe? Include exact commands, statuses, and failure text when useful.

## Observations

- Factual observations that distinguish this from ordinary product work.
- Evidence about where the machinery made the work slower, more brittle, less observable, or harder to resume.
- Workarounds used or safe retry/resume commands, if known.

## Why this matters

What risk or waste does this create for future delivery?

## Open questions

- Unknowns to investigate later.
```

Use additional headings when the evidence calls for them, but prefer a short useful note over a comprehensive report.

## Style

- Write in plain language.
- Be specific about file paths, commands, run IDs, branches, statuses, and exact errors.
- Separate observed facts from hypotheses.
- If you include possible improvements, put them under a clearly labelled heading such as `## Possible improvement`, and keep them secondary to the observation.
- Do not edit application code while recording the note.
