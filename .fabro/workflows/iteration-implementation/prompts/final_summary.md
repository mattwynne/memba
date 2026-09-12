Prepare the final implementation summary for {{ inputs.plan_path }}.

Use the implementation context, passing dev check output, plan conformance evidence, final artifact gate evidence, and publish-to-main output. Do not edit files.

Critical requirements:

- Cite the final artifact gate output to confirm implementation evidence.
- Cite the publish-to-main output and the resulting main commit SHA.
- Do not claim files were changed unless they appear in the final artifact gate evidence or publish output.
- If the final artifact gate shows only working-tree evidence, list those files.
- If the final artifact gate shows base-head diff evidence, use those file names.
- Do not invent, assume, or hallucinate changed files that are not present in the evidence.

Return:

- Result: IMPLEMENTED_AND_PUBLISHED
- Plan path
- Summary of delivered capability
- Plan conformance summary
- Key files changed (must match final artifact gate evidence), grouped by area
- Published commit on main
- Commit trailer metadata present
- Tests and validation run
- Any manual demo/checks still recommended
- Any non-blocking follow-ups
