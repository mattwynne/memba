# Problems

## Onboarding request notification email lacks an action link

Observed: 2026-06-05

Status: Resolved in code after [iteration 022: Request-to-club onboarding](../iterations/022-request-to-club-onboarding/plan.md). `Memba.Onboarding.NewRequestEmail` now includes an `Open this request:` deep link to `/admin/requests/:request_id` in both text and HTML bodies. Evidence: `web/test/memba/onboarding/new_request_email_test.exs` and `web/test/memba_web/live/admin/requests_live/index_test.exs`.

The staff notification email for a new onboarding request does not include a link to open the request in a browser. Staff must navigate to the requests area themselves before they can review the request.

Expected:

- The email should include a direct link to open the onboarding request in Memba.
- Ideally, staff should be able to approve or reject the request from clear action links.
- Staff should be able to move from notification to triage without manual navigation or searching.
