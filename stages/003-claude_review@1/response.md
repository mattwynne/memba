## Review: Iteration 100 — "Populated clubs always have an Admin"

I read the full plan file (211 lines) directly and independently cross-checked its technical claims against the actual codebase (`lib/memba/membership/club.ex`, `lib/memba/membership/membership.ex`, `lib/memba/membership/router.ex`, `lib/memba/membership.ex`, `lib/memba/onboarding.ex`, and `acceptance-tests/features/club_membership_administration.feature`). Every specific technical claim in the plan matched the code: the Club/Membership aggregate split via `identify/dispatch` in the router, the projection-backed `ensure_membership_administrator_removal_keeps_an_administrator` guard with no equivalent for `remove_member`, onboarding's separate `AssignMemberRole` dispatch after `add_member`, and invitation acceptance's lack of that follow-up. The seven new Cucumber scenarios tagged `@iteration-100` already exist in the feature file exactly as the plan describes, tagged `@todo-domain`/`@todo-ui`/`@not-ui` as claimed.

### Decision: READY

### Confidence: High

### Blocking gaps
None found.

### Non-blocking improvements
1. The plan says "No captured problem note directly describes the production zero-Admin invariant failure" — consider filing a short problem note retroactively for traceability, even though it doesn't block this iteration.
2. Step 4 says the old `Membership` aggregate module may be kept as "inert compatibility code" — a one-line note on when/how it will eventually be removed (or an explicit "never remove" call) would tidy up an otherwise open thread, though it's correctly scoped as a non-blocking implementation-detail choice for the author.
3. The plan doesn't explicitly name which test files/modules house the new aggregate unit tests (e.g. `club_test.exs`) — naming them would slightly sharpen step 12, though the described test *content* is already specific enough to implement from.

### Smallest viable iteration
The plan is already close to minimal for a true invariant fix: it explicitly excludes archive/close, bulk import, saga/outbox machinery, and broader role redesign. It could not be meaningfully split further without leaving the invariant only partially enforced (e.g., fixing only the creation path but not the removal path would leave the "populated club always has an Admin" guarantee false on the removal side, which is exactly the same class of bug already found in production). The current scope — one consistency boundary, one atomic creation decision, two removal guards — is the smallest slice that closes the actual invariant gap.

### Required plan edits
None required for readiness. Optional (non-blocking): name specific test file paths in step 12; add a disposal/retention note for the inert legacy `Membership` aggregate module.

### Validation plan
- Confirm `dev check` passes on the delivered branch (plan already commits to this).
- Confirm the new Cucumber scenarios execute (not just parse) once runner-debt tags are removed, per the plan's own step 13.
- Independently re-run the aggregate-level unit tests for: first-vs-later `MemberAdded`+`MemberRoleAssigned` atomicity, concurrent-acceptance single-Admin outcome, sole-Admin-role removal block, sole-Admin whole-membership-removal block, final-member removal block, and permitted-removal-with-replacement-Admin — all named explicitly in step 12 of the plan.
- Verify the read-only deployment audit step actually runs and reports zero missing compatibility facts before sign-off, since the plan correctly treats that as a delivery-blocking gate rather than an assumption.
- Manually walk the demo script in the Validation Plan section (empty club → first invite accepted → blocked sole-Admin removal → replacement Admin → blocked final-member removal).

{"context_updates":{"claude_review_decision":"READY","claude_review_confidence":"High","claude_review_blocking_gap_count":0,"claude_review_blocking_gaps":"None","claude_review_required_edits":"None"}}