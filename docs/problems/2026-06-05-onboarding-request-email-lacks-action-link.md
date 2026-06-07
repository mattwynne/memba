# Problems

## Onboarding request notification email lacks an action link

Observed: 2026-06-05

Status: Unresolved. [Iteration 022](../iterations/022-request-to-club-onboarding/plan.md) added staff-approved request onboarding and staff request review screens, but the current `Memba.Onboarding.NewRequestEmail` still sends only request details and no direct browser action link.

The staff notification email for a new onboarding request does not include a link to open the request in a browser. Staff must navigate to the requests area themselves before they can review the request.

Expected:

- The email should include a direct link to open the onboarding request in Memba.
- Ideally, staff should be able to approve or reject the request from clear action links.
- Staff should be able to move from notification to triage without manual navigation or searching.
