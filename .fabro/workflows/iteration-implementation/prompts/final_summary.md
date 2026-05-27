Prepare the final implementation summary for {{ inputs.plan_path }}.

Use the implementation context, review synthesis, passing dev check output, and final artifact gate evidence. Do not edit files.

**Critical requirements:**

- You must cite the final artifact gate output to confirm implementation evidence.
- You must not claim files were changed unless they appear in the final artifact gate evidence.
- If the final artifact gate shows only working-tree evidence, list those files.
- If the final artifact gate shows base-head diff evidence, use those file names.
- Do not invent, assume, or hallucinate changed files that are not present in the artifact evidence.

Return:

- Result: IMPLEMENTED
- Plan path
- Summary of delivered capability
- ADR conformance summary
- ADRs considered
- Evidence for each ADR-relevant implementation decision
- Any ADR deviations or human follow-ups
- Key files changed (must match final artifact gate evidence), grouped by area
- Tests and validation run
- Any manual demo/checks still recommended
- Any non-blocking follow-ups
