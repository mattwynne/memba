# 068 final whole-plan review — checkpoint 12d98f759

## Panel and limits

- OpenAI GPT-6 Astra via Pi/openai-codex: completed domain/concurrency review.
- Google Gemini 3.1 Pro Preview via Pi/OpenRouter: completed proof/delivery review.
- Anthropic Claude Opus 5 via Pi/OpenRouter: incomplete. Continued investigating after the other reports finished; parent requested an immediate bounded final report, waited 60 seconds, then stopped it. No final Claude verdict is counted.

This is a two-family completed review, not three-family consensus. All reviewed the same detached snapshot at /tmp/memba-068-review-12d98f759 independently. No second ensemble round is requested.

## Agreements

The three domain examples plus browser journey cover the four agreed subjects without duplicating browser proof. Current normalized-value comparison, identical-target eventless success, conditional Save anyway, no revision tracking, shared bounded conflict handling, historical names and staff/photo exclusions remain coherent. No new product mechanism decision was identified by the completed reviewers. The spike proves feasibility, not production integration. Written ADR acceptance remains outstanding.

## Corrections to incorporate

### 1. Align authorization responsibility across plan and ADR

Evidence: plan.md:195–197 derives Person identity and authorizes at the web boundary; plan.md:208–212 requires authorization even before no-op success; form-conflict-adr-proposal.md:30–31 assigns authorization to the owning domain. Existing Person aggregate identity matching is not actor authorization. Proof matrix currently only calls for spoofed-target rejection at the web boundary.

Correction: explicitly define the trusted actor/target contract and the owner of self-only authorization, consistently with Memba's existing command preparation/dispatch architecture. Do not trust a posted Person ID or let identical-target no-op bypass authorization. Make the domain/application entry-point responsibility and direct unauthorized-attempt proof explicit; retain fresh settings authorization. Do not introduce a general authorization framework or cross-aggregate locking. This clarifies approved self-service scope rather than adding policy.

### 2. Prove current readback when projections lag, including no-op success

Evidence: plan.md promises current data after Save and cancellation, but an identical-target command can succeed without emitting an event while the Person projection still shows an older name. The aggregate can safely reject a conflict without an ordinary projection query yet containing the value it compared.

Correction: obtain conflict values from authoritative comparison results or a synchronized authorized read, and define how successful/no-op/cancel readback observes the appropriate committed state using existing ADR 0022/barrier conventions. Add deterministic delayed-projector proof for conflict values, identical-target success and cancellation after conflict. Bounded readback failure must not discard a dirty draft or present stale data as confirmed current state. Do not invent a new synchronization framework or interaction pattern when existing handling suffices.

## Disagreement / synthesis

Gemini called conflict/readback coherence guaranteed by aggregate comparison. That supports write safety, but does not answer GPT's distinct eventless-success/stale-display example. Parent retains the readback finding on its concrete evidence rather than treating the reports as a vote. These are planning/proof gaps, not claims of an implemented security bug.

## Optional, not a new requirement

A legacy over-length current-name example could clarify validation/no-op ordering, but it is not a blocker and must not introduce retroactive history validation or reopen Matt's simplicity decision.

## Ownership / next step

Parent owns this synthesis and final workflow contract. Planner applies the two scope-preserving clarifications to plan, ADR proposal and proof matrix, checks consistency, preserves/publishes the correction commit and presents the remaining written ADR acceptance briefly. No new product scope interview, second ensemble, old Fabro launch or application implementation. No reviewer advice grants ADR acceptance or production authority.
