---
name: incident-review
description: Record and investigate production incidents using a blameless timeline, evidence-backed Five Whys, and corrective, detection, and prevention actions. Use when a production failure, outage, data incident, serious customer-facing degradation, or request for an incident review, postmortem, or retrospective is discussed.
---

# Incident Review

Use this skill to preserve what happened in production, understand why it happened and escaped, and agree on actions that restore service and reduce recurrence.

An incident review is neither a search for an individual to blame nor a demand for certainty. Explain how the system, safeguards, information, and conditions shaped the outcome. Separate confirmed facts, hypotheses, and unknowns.

## Scope

Use this skill for:

- production failures or outages;
- serious customer-facing degradation;
- incorrect, lost, exposed, or endangered production data;
- production security or privacy concerns; and
- explicit requests for an incident review, postmortem, or production retrospective.

An ordinary product bug found before production is not usually an incident. Delivery-workflow friction belongs in `docs/kaizen/`; use `kaizen-note` with the user's consent if an incident exposes a separate delivery-system problem. Link related records instead of duplicating them.

## Safety and Response First

If the incident may still be active:

1. Establish the current impact and whether it is spreading.
2. Protect people and data before pursuing a complete explanation.
3. Preserve relevant logs, timestamps, release identifiers, commands, and query results.
4. Prefer reversible containment.
5. Treat production inspection as read-only by default.
6. Obtain explicit user approval before any production mutation.
7. Follow the project's deployment and operations rules. Never bypass required CI/CD or operator controls.

Do not delay urgent containment merely to complete the incident document. Record what is known, mark unknowns, and update the review as evidence arrives.

## Incident Selection

The user may provide an incident path, title, symptom, or no existing record.

1. Search `docs/incidents/` for the same event or failure mode.
2. Update a matching incident rather than creating a duplicate.
3. If several records might match, show them and ask which one to use.
4. If none matches, create `docs/incidents/YYYY-MM-DD-short-slug.md`.
5. Create `docs/incidents/README.md` if needed and maintain its incident index.

When updating an existing incident, preserve the historical account. Add dated timeline or follow-up entries rather than silently rewriting earlier knowledge. Correct factual errors explicitly when necessary.

## Investigation Workflow

### 1. Establish the facts

Inspect enough evidence to answer:

- What failed?
- Who or what was affected?
- When did it begin, when was it detected, and what is its current state?
- What release, commit, configuration, data, or external dependency was involved?
- Was anything partially written, lost, exposed, duplicated, or left inconsistent?
- What is confirmed, what is inferred, and what remains unknown?

Useful evidence can include logs, traces, event history, database queries, release metadata, source code, tests, deployment records, prior sessions, and user observations. Record commands or durable evidence pointers when they will help later verification. Redact secrets and unnecessary personal data.

### 2. Find the causal mechanism

For failures, surprising behaviour, or unclear causes, load and follow the `systematic-debugging` skill before proposing fixes.

Reconstruct the smallest evidence-backed mechanism that explains the incident. Distinguish:

- **root cause** — the mechanism that produced the failure;
- **contributing conditions** — factors that made the failure more likely or harmful;
- **escape causes** — why tests, review, release checks, or safeguards did not catch it; and
- **detection causes** — why the incident was not noticed sooner.

Do not call temporal proximity causation. Test plausible counter-hypotheses when it is cheap and safe.

### 3. Use Five Whys

Start from the observed impact and ask why each answer was possible. Use evidence for every step.

- Do not force exactly five answers.
- Do not force one linear chain when occurrence, escape, and detection have different causes.
- Stop when another “why” would become speculation or leave the team's sphere of influence.
- Do not use “human error” as a root cause. Ask what information, default, guardrail, interface, workload, or workflow made that action reasonable or easy.
- Prefer a specific causal statement over labels such as “process failure” or “insufficient testing.”

### 4. Develop actions

Separate proposed actions by purpose:

- **Correct** — contain the incident, restore service, and repair affected state.
- **Detect** — expose recurrence quickly and provide useful diagnostic evidence.
- **Prevent** — remove the cause or strengthen the guardrail that should stop recurrence.

Each action should have an owner, status, and observable verification condition. Prefer a small number of strong actions tied directly to a demonstrated cause over a long wishlist. Do not default to documentation or “be more careful” when an executable guardrail is practical.

Before implementing follow-up work:

1. Brief the user on the impact, causal mechanism, evidence, uncertainties, and immediate risk.
2. Present viable actions with their benefits, costs, and risks.
3. Recommend an order and explain why.
4. Ask one focused decision question at a time when trade-offs matter.
5. Record the decision and rationale.

Writing the review does not authorize product changes, deployments, or production mutations. Do not launch an ensemble or independent reviewers unless the user explicitly requests that review method.

### 5. Resolve and follow up

Use these status meanings:

- **Investigating** — impact or cause is still being established.
- **Mitigated** — customer impact has stopped, but recovery verification or causal work remains.
- **Resolved** — service and affected production state have been restored and verified.

Prevention actions may remain open after resolution, but they must stay visible in the action table or a linked work item. Add a dated follow-up when evidence shows whether a prevention measure worked.

## Incident Template

```markdown
# Incident: <short description>

Date: YYYY-MM-DD
Status: Investigating | Mitigated | Resolved

## Summary

What happened, who or what was affected, and the current state.

## Impact

- Affected users or systems
- Duration and scope
- Data, privacy, or security impact
- What was not affected

## Timeline

All times UTC.

| Time | Event |
| --- | --- |
| HH:MM | What happened or what responders did |

## What happened

The confirmed technical explanation.

Evidence:

- Relevant errors, logs, commands, releases, commits, or queries
- Links to related iterations, incidents, or documentation

Unknowns:

- Facts that remain unconfirmed

## Five Whys

### Why it happened

1. ...
2. ...
3. ...

### Why it escaped or was detected late

1. ...
2. ...
3. ...

Do not force exactly five answers or a single causal chain. Branch when the evidence points to separate occurrence, escape, or detection causes.

## Contributing conditions

- System and process conditions that made the incident possible or harder to detect
- No individual blame

## Actions

| Type | Action | Owner | Status | Verification |
| --- | --- | --- | --- | --- |
| Correct | Restore service or repair affected state | | Proposed | |
| Detect | Make recurrence quickly visible | | Proposed | |
| Prevent | Remove or guard against the cause | | Proposed | |

## Resolution

How service was restored and how production recovery was verified.

## Follow-up

Dated updates, remaining actions, and evidence that prevention measures worked.
```

Optional headings for a large or instructive incident:

- `## What helped`
- `## What made the response harder`
- `## Where we were fortunate`
- `## Actions not recommended`

Prefer the simple template unless these sections add useful evidence or learning.

## Writing and Repository Rules

- Use plain, direct, blameless language.
- Use UTC in timelines.
- Include exact paths, commands, errors, releases, and commits when useful.
- Avoid secrets and unnecessary personal information.
- State the current production condition near the top.
- Keep the summary understandable without requiring the technical analysis.
- Do not claim resolution until production recovery has been verified.
- For documentation-only incident work, follow the project's documentation validation rules; do not run an application-wide check unless project guidance or the user requires it.
- Commit the incident record and index once written. Include no unrelated changes and do not push unless the user asks.

## Reporting Format

When the review reaches a natural stopping point, report:

- incident path and current status;
- impact and causal mechanism in a few sentences;
- whether production was changed;
- proposed or agreed Correct, Detect, and Prevent actions;
- unresolved questions or decisions;
- validation performed; and
- commit SHA and message, or why no commit was made.
