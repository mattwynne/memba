# Problem: Fabro model routing lacked an explicit cost and independence policy

Date: 2026-09-04

## Context

Memba's plan-validation and iteration-review workflows deliberately use multiple models for independent review. Their model stylesheets evolved through availability incidents and provider-routing upgrades, but did not state which roles should use Memba's OpenAI subscription or when token-billed providers were justified.

Before this observation, plan validation used GPT-5.6 Sol for the GPT review, synthesis, plan repair, and recheck. The same model family could therefore review, coordinate repair, make the repair, and certify the result. Claude Sonnet 5 and Gemini 3.1 Pro Preview were each called through OpenRouter for an independent review, but the workflow did not describe their limited, paid role.

Matt clarified the operating constraint: use the GPT/OpenAI subscription as the daily driver. Claude, Gemini, and other providers incur API-token billing and should be used sparingly.

## Expected standard

Workflow model routing should make both responsibilities explicit:

- OpenAI/GPT models are the default for routine workflow work and repair loops.
- Token-billed non-OpenAI models are used only where an independent review materially improves confidence.
- A repair should not be certified by the same model assignment that made it.
- Prompts and workflow labels identify the model actually assigned to the node.

## What happened

A web-backed review of the available models found that GPT-5.6 Terra is a suitable lower-cost/independent GPT-family recheck model, while GPT-5.6 Sol remains suitable for evidence synthesis and bounded repair. The review also found that model diversity has its greatest value in the first independent review pass; it is less valuable than evidence discipline in synthesis.

The prior workflow had no written policy to express that conclusion. It also retained stale prompt identities referring to Claude Opus and Codex after the nodes had been routed to Sol.

## Impact

Without an explicit policy, workflow edits can accidentally:

- spend token-billed Claude or Gemini capacity in routine repair loops;
- make a model certify its own repair;
- obscure the real provider/model in operator-facing prompts; or
- choose a more expensive model by habit rather than for an evidence-sensitive role.

## Resolution applied

- Plan-validation keeps one Claude and one Gemini independent review per validation pass, rather than using either provider for synthesis, repair, or recheck loops.
- GPT-5.6 Sol remains the OpenAI daily driver for synthesis and bounded plan repair.
- The post-repair plan recheck now uses GPT-5.6 Terra, separating repair from recheck without adding a token-billed provider call.
- Plan-validation prompts and terminal failure copy now use the assigned model name or model-neutral wording.
- The model-routing decision was informed by official OpenAI, Anthropic, and Google model documentation plus an independent comparative source; project-specific evaluation remains the stronger future evidence.

## Observations

- Fabro's catalog price display is API-equivalent reference information; it does not describe Matt's OpenAI subscription economics. Model selection must follow the configured account and billing arrangement, not only those displayed prices.
- The external Claude and Gemini calls remain valuable as independent challenges, but are intentionally confined to one review each per plan validation or post-merge review.
- The policy has not yet been measured against Memba's historical plans or review diffs.

## Possible prevention ideas

- Keep this policy visible beside the workflow model stylesheets or in the workflow reference documentation.
- Periodically evaluate a small set of historical plan/review cases for evidence-backed findings, missed defects, repair success, wall time, and external token spend.
- Revisit the external-review frequency if it does not produce findings that change synthesis or repair decisions.
