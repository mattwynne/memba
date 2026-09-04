# Improvement: iteration-review can safely fan out and fan in reviewer evidence again

Date: 2026-09-04

## Context

Iteration review is supposed to run independent Claude, Sol, and Gemini reviews, then synthesize all reviewer findings before deciding whether to accept, apply bounded polish, or record code-health findings.

The workflow previously used Fabro's parallel fan-out/fan-in shape, but older Fabro runs exposed only branch metadata to the synthesis stage. The synthesis step could see that reviewer branches had completed, but it did not reliably see the full reviewer reports. That caused false-clean review results: individual reviewers raised bounded fixes or judgement-worthy code-health findings, while synthesis accepted as if there were no findings.

Because of that historical evidence loss, iteration review was changed to a safe sequential topology. The sequential chain was slower, but it preserved reviewer Markdown in ordinary prior-stage context and failed before synthesis when a required reviewer could not complete.

## Current change

Fabro 0.316.0-nightly.0 has now been proven to preserve completed branch responses under `parallel.results`. The repository also contains the small `fan-in-evidence-spike` workflow that verifies a downstream synthesis prompt can see distinct branch response tokens after a component fork and tripleoctagon merge.

With that proof in place, iteration review can regain parallelism while keeping the safety invariant explicit.

The iteration-review workflow now uses:

- a `review_fork` node with `shape=component` and `max_parallel=3`;
- independent `claude_review`, `codex_review`, and `gemini_review` branches;
- a `review_merge` node with `shape=tripleoctagon`;
- a merge-to-synthesis route that continues only on a successful fan-in outcome;
- an infrastructure-failure route when reviewer evidence cannot be collected and synthesized.

The synthesis prompt now tells the model to inspect `parallel.results` directly. It must confirm that Claude Review, Sol Review, and Gemini Review each supplied usable substantive evidence before it can accept or request bounded product-code fixes.

## Safeguards

- Missing, empty, metadata-only, or tool-call-looking reviewer evidence is treated as a workflow/tooling failure, not as acceptance.
- If synthesis cannot see usable evidence for all three required reviewers in `parallel.results`, it must set its stage outcome to failed so the workflow routes to `synthesis_unavailable`.
- The graph-level regression test now fails if the review topology reverts to the old sequential reviewer chain.
- The same regression test checks that the synthesis prompt still names `parallel.results`, all three required reviewer node IDs, and the failed-outcome routing shape for missing merged evidence.

## Remaining limits

- The guard relies on Fabro's prompt context exposing `parallel.results` as proven by the current engine spike; it is not a product-code invariant.
- The shell regression test validates graph and prompt structure, not live LLM judgment.
- A live review can still fail because a provider outage or unusable branch response prevents complete evidence collection. That is intentional: incomplete reviewer evidence must not produce acceptance.
- If Fabro changes the `parallel.results` shape again, the synthesis prompt may need another update and the fan-in evidence spike should be rerun.
