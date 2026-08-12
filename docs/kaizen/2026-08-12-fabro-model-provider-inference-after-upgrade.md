# Problem: Fabro workflow model routing inferred the wrong provider after upgrade

Date: 2026-08-12

## Context

After upgrading the remote Fabro server and local CLI from `0.243.0-nightly.1` to `0.316.0-nightly.0` (`0abf229`), we checked the project workflows in `.fabro/workflows/`.

The affected workflows were:

- `.fabro/workflows/plan-validation/workflow.fabro`
- `.fabro/workflows/iteration-review/workflow.fabro`

Both route their `claude_review` node to `claude-sonnet-4-5` while the general workflow default is OpenAI `gpt-5.5`.

## Expected standard

A workflow stylesheet that names a catalogued model should select that model's provider, or preflight should clearly identify any unsupported routing before a delivery run starts. Plan validation and iteration review need to probe Claude through Anthropic and GPT through OpenAI.

## What happened

`fabro validate` accepted both workflow graphs, but `fabro preflight` resolved the `claude-sonnet-4-5` review node as provider `openai` and failed its model probe:

```text
Invalid request to openai: The 'claude-sonnet-4-5' model is not supported when using Codex with a ChatGPT account.
```

The model itself was available when explicitly probed with its intended provider:

```text
fabro model test --model claude-sonnet-4-5 --provider anthropic
```

That probe succeeded. Adding `provider: anthropic` explicitly to each affected `#claude_review` stylesheet rule made both workflow preflights pass.

## Impact

This blocked plan-validation and iteration-review runs immediately after an otherwise successful Fabro upgrade. The error looked like an Anthropic-model availability problem even though the model and Anthropic credentials were usable, requiring manual diagnosis of model routing and a workflow patch.

## What allowed it to happen

The workflow relied on automatic provider inference from `model: claude-sonnet-4-5`, while the run's general default was OpenAI. The upgraded preflight selected OpenAI for that node instead of the model-catalog provider. Validation checked graph syntax but did not reveal the incorrect resolved provider.

## Observations

- Client and server version parity alone did not prove that the existing workflow configurations would execute with their intended providers.
- `fabro model test` without a provider inferred Anthropic correctly for this model; the incorrect provider appeared while resolving the workflow preflight.
- The problem affected the two multi-provider workflows; the OpenAI-only iteration-implementation workflow preflight passed.
- The immediate mitigation is committed workflow configuration, not a conclusion about whether the inference problem belongs in Fabro, its server configuration, or configuration migration.

## Why this matters

Multi-provider review is deliberate independent evidence. Silent provider misrouting can turn a valid workflow into an infrastructure failure, waste a run attempt, and obscure whether a plan or implementation is actually blocked.

## Open questions

- Why did workflow preflight resolve the named Claude model through OpenAI while direct model testing inferred Anthropic?
- Did the server upgrade or client configuration migration change provider-resolution precedence?
- Should `fabro validate` or `fabro preflight` reject a node whose named model belongs to a different provider than the resolved provider?

## Possible prevention ideas

- Make provider resolution from a named model deterministic and visible in validation/preflight output.
- Keep explicit provider declarations for deliberately multi-provider workflow nodes.
- Add a post-upgrade preflight of each project workflow with representative inputs.
