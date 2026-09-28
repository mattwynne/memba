# Problem: Validator escalated a stale preview into an immediate-consistency requirement

Date: 2026-09-28

## Context

Iteration [066](../iterations/066-request-group-access/plan.md) adds a read-only targeted Members page and a separate explicit Add action. [ADR 0024](../adr/0024-use-club-as-membership-admin-consistency-boundary.md) puts club membership and Admin-role write decisions at the Club consistency boundary. The page's ordinary display gate reads projections, which can briefly lag a role revocation or club departure.

The failed implementation run was `01M3HSZ69HTJN82FD03JR94BVV`; the recovery run was `01M3JPCGJBCG3NVGR5FTBK3MMG`.

## Expected standard

Review the approved plan and ADRs while distinguishing a read-only display from the command that changes membership. Raise a timing risk in terms of how likely it is and what harm it can actually cause in this product, rather than assuming every projected view needs immediate consistency.

## What happened

The first run's task-006 validator required an aggregate-backed authority check on GET so a recently revoked admin could not briefly see the targeted page while display projections lagged. It cited the plan and ADR 0024, although that ADR specifies the Club boundary for membership and role *write decisions*. The validator separately found that the targeted panel used a projected group name instead of the resolver-returned group name; that was a valid, bounded finding.

Clarifying the display-versus-command distinction took an extended Slack discussion and interrupted delivery. Matt accepted a brief stale preview in this volunteer-club context, provided the explicit Add checks current authority and target membership and refuses an invalid change. The iteration plan and domain model now record that decision. In the recovery run, the task-006 validator accepted the targeted group-name correction while retaining the projection-backed display gate. That acceptance was for task 006, not evidence that the whole iteration had passed final validation.

## Impact

The validator's proposed GET check expanded the task beyond the agreed boundary and created avoidable clarification and recovery work. The relevant residual risk is brief visibility of member details, including changes made since revocation, not successful addition by a revoked actor. Projection-lag duration and encounter frequency were not measured here.

## What allowed it to happen

Accepted ADR 0024 protects write invariants but does not itself provide a proportionate way to assess stale-read risks. Review guidance did not prompt the validator to separate the incremental harm of a temporary view from the authority required for a consequential command. That is a suspected guidance gap, not proof that every validator will make the same inference.

## Fix agreed in this conversation

Add [a design heuristic](../design-heuristics/tolerate-eventual-consistency.md) that asks about likelihood and worst realistic incremental harm before escalating projection lag. It permits a briefly stale option followed by a clear refusal or error when the command checks current authority, while calling for specific review when the stale view itself could cause meaningful harm. Add a [design-heuristics index](../design-heuristics/README.md) and signpost it from `AGENTS.md` so future agents can find it. This is guidance, not a new privacy policy or a change to Fabro's workflow prompts.

## Open questions

- Whether future Fabro validators reliably follow the `AGENTS.md` signpost and use the heuristic in similar reviews has not yet been observed.
