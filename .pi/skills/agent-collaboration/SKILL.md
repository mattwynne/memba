---
name: agent-collaboration
description: Maintain a small team of persistent agent perspectives alongside an evolving human conversation, using BB threads when available and Pi subagents as a fallback.
---

# Agent Collaboration

Use this skill when several agent perspectives should contribute during an evolving conversation rather than review a finished artifact. The caller owns the subject matter, roles, decision boundaries, and how observations affect its work. This skill owns collaborator lifecycle and communication.

## Collaboration Brief

Require the caller to provide:

- the purpose of the collaboration;
- up to three distinct roles and the question each role should keep asking;
- the facilitator conversation and evolving artifacts they may inspect;
- agreed facts, current scope, and explicit deferrals;
- prohibited actions and human decision owners;
- what makes an observation significant enough to interrupt the facilitator;
- when the collaboration ends.

Collaborators advise. They do not edit product artifacts, decide policy or architecture, expand scope, or require consensus. The facilitator filters their observations and remains responsible for the conversation with the human domain expert.

## Choose the Available Transport

BB coordinates threads and may itself be running Pi agents. Prefer BB coordination when the current session exposes `BB_THREAD_ID` and the `bb` CLI; otherwise use Pi's available subagent tools. This is capability detection, not a choice between BB and Pi as agent runtimes.

State the transport and any degraded capability. Never imply that a collaborator saw conversation it could not access.

### BB transport

Create one persistent child thread per role, normally hidden, attached to the facilitator's environment, and parented to the facilitator. Resolve the current project, environment, and thread with `bb status --json`, then use `bb thread spawn --parent-self --environment <environment-id> --visibility hidden ...`. Give each child:

- its role brief and significance threshold;
- the facilitator thread ID;
- the IDs of peers only when direct clarification between roles would be useful;
- instructions to remain read-only;
- an event cursor from which to read the facilitator conversation.

A BB collaborator reads the actual facilitator timeline incrementally with:

```bash
bb thread log <facilitator-thread-id> --json --after-seq <cursor>
```

At natural pauses, wake or queue each collaborator with `bb thread tell <collaborator-id> ... --mode auto`, naming the latest event boundary and any artifact paths that changed. Collaborators send concise, evidence-linked questions or counterexamples back with `bb thread tell <facilitator-id> ... --mode queue`; reserve steering for a genuinely urgent correction. They may message a peer to clarify evidence, but must not run open-ended debates or seek unanimity.

Do not make collaborators poll continuously. BB currently provides durable threads, logs, messaging, queues, and child completion/blocker notices—not a documented automatic subscription that wakes a collaborator on every parent event. The facilitator therefore owns wake-up points.

### Standalone Pi fallback

Start one background subagent per role. Supply the collaboration brief and the available conversation context. At the same natural pauses, send verbatim new conversation turns and changed artifact paths, then resume the same collaborator when the harness supports it. Do not replace the human conversation with a facilitator-authored summary when verbatim turns fit; summaries can conceal the ambiguity collaborators are meant to detect.

If persistent resumption or direct parent-context access is unavailable, disclose that limitation and use bounded fresh passes rather than pretending the collaboration is continuous.

## Cadence

Use a small number of meaningful wake-up points, such as when:

- a rule, example, model distinction, or option becomes concrete;
- the human makes or revises a consequential decision;
- an artifact changes enough to test the collaborator's perspective;
- the caller is about to leave the activity the collaborators are supporting.

Do not notify on every chat message. Do not wait for all collaborators before continuing a useful human conversation. At an activity boundary, give each available collaborator one final catch-up through the latest event and process any already-returned significant observations; this is completion of the live collaboration, not a new post-hoc review panel.

## Observation Contract

Ask collaborators to return only:

- a concrete question, counterexample, contradiction, or simpler alternative;
- the conversation turn or artifact evidence that prompted it;
- why it could materially change shared understanding;
- uncertainty, when relevant.

`No significant observation` is a valid response. Optional preferences, repeated settled questions, and out-of-scope ideas should stay quiet.

The facilitator:

1. deduplicates observations;
2. corrects factual misunderstandings from already-settled context;
3. brings the human only observations that need domain knowledge or a consequential decision;
4. sends the resulting decision or deferral back to collaborators at the next wake-up;
5. records important outcomes in the caller-owned artifact.

## Completion

When the caller's end condition is met:

- process outstanding significant observations without demanding consensus;
- record unresolved questions and explicit deferrals;
- report which collaborators and transport actually participated and any degraded coverage;
- archive or stop BB child threads when they are done, or allow Pi subagents to finish and retain their handles only if a later caller will continue the same collaboration.

A collaboration is successful when it improves the human conversation while it is still cheap to change understanding—not when agents agree with one another.
