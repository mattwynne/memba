Both review repairs are complete and their focused regression tests plus the selected scenario pass. There is no further behavioral change assignment or known cleanup.

The prior `dev check` is stale because it predates both repairs. The repaired state must proceed through the refactoring/check path so a full `dev check` runs on the exact final code before completion or fresh review.

{"preferred_next_label":"refactor"}