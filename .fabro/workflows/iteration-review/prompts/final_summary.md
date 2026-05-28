Prepare the final review summary for {{ inputs.plan_path }}.

Use the plan text, dev check output, plan conformance gate, ADR coherence gate, independent reviews, review synthesis, and final artifact gate evidence. Do not edit files.

Critical requirements:

- Cite the final artifact gate output to confirm the reviewed implementation evidence.
- Do not claim files were changed unless they appear in the final artifact gate evidence.
- If review repairs were applied, list only files shown in final artifact evidence.
- Do not invent, assume, or hallucinate changed files that are not present in the artifact evidence.

Return:

- Result: REVIEW_ACCEPTED
- Plan path
- Plan conformance summary
- ADR conformance summary
- Independent review outcome
- Any repairs applied during review
- Key files reviewed or repaired, matching final artifact gate evidence
- Tests and validation run
- Any manual demo/checks still recommended
- Any non-blocking follow-ups
