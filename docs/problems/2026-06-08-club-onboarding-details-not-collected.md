# Problems

## Club onboarding does not collect required member details beyond name

Observed: 2026-06-08

Status: Unresolved. [Iteration 028](../iterations/028-staff-member-invitations/plan.md) plans a profile-completion gate that asks invited unknown members for their name only. Details such as date of birth, emergency contact, household details, or club-specific required fields are deliberately deferred.

Many clubs need more than a name and email address before someone can fully participate as a member. Memba does not yet have a general way to ask for those required details during onboarding or when new required fields are added later.

Why it matters:

- Clubs may need date of birth, emergency contact, consent, or other details for safety, compliance, or membership administration.
- If Memba later adds required person fields, existing signed-in people need a clear prompt to complete missing details.
- Without a reusable profile-completion mechanism, each invitation or onboarding path may collect details differently.

Expected:

- Memba should have a reusable way to define required profile details.
- Signed-in people with incomplete required details should be asked to complete them before continuing.
- Club-specific required details should be collected in a club-aware onboarding step when needed.
