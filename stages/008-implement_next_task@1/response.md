1. **Selected todo line**
   - `- [ ] 001 Inspect the post-iteration-009 route structure and admin pipeline.`

2. **Changes made**
   - Added inspection notes at:
     - `docs/iterations/010-shared-magic-link-auth/route-inspection.md`
   - Findings recorded:
     - Current app still exposes harness routes at `/clubs`, `/clubs/:club_id`, `/deliveries`, and `/messages/:message_id`.
     - No `/admin` scope exists yet.
     - No `:staff_browser` pipeline exists yet.
     - No `MembaWeb.Admin.*` LiveView namespace exists yet.
     - `POST /webhooks/postmark` is still routed through the `:api` pipeline and remains unchanged.
   - Updated `todo.md` to check off task `001`.
   - Added a required follow-up todo before auth work:
     - `001a Reconcile the missing post-iteration-009 admin route structure...`
   - No application code or tests were changed because this task was inspection-only.

3. **Focused validation run**
   - `mix phx.routes`
     - Confirmed current route structure and absence of `/admin/*`.
   - `git diff --check`
     - Passed with no whitespace issues.
   - `PATH="$PWD/bin:$PATH" dev check`
     - Passed.
     - ExUnit result: `132 tests, 0 failures`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 001 Inspect the post-iteration-009 route structure and admin pipeline.`
   - To:
     - `- [x] 001 Inspect the post-iteration-009 route structure and admin pipeline.`

5. **Todo additions/reordering**
   - Added one new unchecked task immediately after `001`:
     - `001a Reconcile the missing post-iteration-009 admin route structure before auth gates: move the existing harness LiveViews under /admin/*, introduce a :staff_browser seam, update links/tests, and preserve POST /webhooks/postmark.`
   - Reason: iteration 010 assumes the iteration-009 admin route split exists, but the current branch does not have it. This prerequisite must be reconciled before implementing `/admin/*` auth gates.

6. **ADR conformance evidence**
   - No ADRs were explicitly referenced by the plan.
   - Relevant accepted ADRs inspected:
     - ADR 0001: Phoenix is the core application stack.
     - ADR 0013: Use PhoenixTest for feature-style web tests.
   - This task only documented Phoenix route inspection findings and did not introduce code, HTTP clients, feature file edits, or test style changes.