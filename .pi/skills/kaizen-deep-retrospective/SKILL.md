---
name: kaizen-deep-retrospective
description: Review Memba's software-delivery factory periodically or on demand, select its highest-value systemic problem from broad evidence, and propose one approval-gated improvement or experiment.
---

# Kaizen deep retrospective

Use this skill for periodic or requested reviews of the system that turns approved iterations into production changes. This is not an incident note, an ordinary product retrospective, or permission to change the factory immediately.

## Objective

Optimize, in order:

1. successful-change throughput;
2. idea-to-production lead time;
3. token cost per successful change.

A successful delivery starts when Matt approves and dispatches an iteration and ends when it reaches production hands-off: no intervention, restart, workaround, or failed Fabro-run nursing, with code quality preserved. Count failed and abandoned attempts in cost. Missing evidence is a named gap, never inferred success.

Default to the 90 days ending at review start; accept a different requested window. Weight recent evidence most heavily. Use older evidence for recurrence, controls, and disconfirmation, but do not let old fixed issues dominate.

## Control rules

- Read [the review protocol](references/review-protocol.md) before conducting a review.
- Inspect `docs/kaizen/README.md` first. If any row is `Experiment`, do not launch another; route the work to reviewing that experiment.
- Work largely autonomously. Ask only when evidence is unavailable or contradictory, or business context is necessary.
- Question assumptions and existing standard work. ADRs have a higher burden of proof, not immunity from review.
- Surface one top problem concisely with enough causal and impact context. Offer options only for a genuine tradeoff; otherwise recommend one improvement.
- Require Matt's approval before implementation or experiment launch.

## Durable outputs

Write the full retrospective to `docs/notes/YYYY-MM-DD-<title>.md`. Preserve:

- the source inventory and evidence window;
- candidate problems and ranking;
- evidence for the leader, including disconfirming evidence;
- runners-up and rejected ideas without needlessly deep investigation;
- evidence gaps and review usage when available.

Create or update exactly one selected note in `docs/kaizen/` and update its ledger row. Put experiment design in that kaizen note, not the retrospective. Do not discard useful runner-up evidence and do not create kaizen notes for every candidate.

An experiment note must record causal evidence and hypothesis, baseline, one primary outcome metric aligned to the objective order, quality guardrails, implementation, validation ladder, review date, and decision criteria.

## After approval

Use BB child threads to implement and independently validate the approved factory change. Test outside production delivery using an evidence-appropriate ladder: static/contracts, fixtures, isolated historical replay, then limited canary. Never make the next real delivery the first test. If no safe harness exists, recommend building one instead.

Keep `docs/kaizen/README.md` complete and preserve its exact columns and allowed statuses. Follow project instructions for validation; docs/skill-only changes do not require `dev check`.
