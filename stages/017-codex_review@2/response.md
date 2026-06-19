# Iteration 036 Review Report

## Decision: REJECT

## Confidence: High

The rejection is procedural/scope-related, not a finding that the visible implementation is low quality. The commit range under review does not match the iteration plan’s explicit DS-only scope.

## ADR conformance: PASS

No ADR violation is visible in the provided evidence. The out-of-scope club slug/subdomain work appears to follow the project’s domain/CQRS/event-sourcing patterns rather than bypassing them with local substitutes.

## ADR violations

None found.

## Blocking issues

1. **Reviewed commit range includes substantial out-of-scope application work**

   The plan for `docs/iterations/036-ds-catchup-member-management-and-auth/plan.md` is explicit that this iteration should add/update static design-system preview files only:

   - New DS previews for invite-a-member, profile completion, and check-email/delivery-progress.
   - Badges component card update.
   - “No app code, routes, LiveViews, templates, or `.feature` files are changed.”

   However, the reviewed range `9d699054c173f9dc30454056a03230357a6a1d38..HEAD` visibly includes club slug / public subdomain application work, including evidence of:

   - `features/staff_club_slugs.feature`
   - `lib/memba/clubs/aggregates/club.ex`
   - Public club subdomain routing/controller behaviour.
   - `test/memba_web/controllers/club_site_controller_test.exs`
   - Smoke-test club slug handling and public-club subdomain tests.

   This directly conflicts with the plan’s scope boundary.

   This needs human/process resolution before merge:

   - If the club slug/subdomain work belongs to a previous iteration, the review base SHA is wrong and this review should be rerun against the DS-only diff.
   - If the work is intentionally included in this merge artifact, the plan is outdated or incomplete and needs explicit human approval / revised scope before acceptance.
   - If the work was accidentally included, it should be split out before this iteration is reviewed again.

## Bounded-safe fixes

None recommended at this point.

The synthesized `ds-preview-static-css-cleanup` issue does not appear to be supported by the later repair investigation. The inspected DS files reportedly already avoid inline `style="..."`, `mx-auto`, and common Tailwind utility-class patterns, so making cosmetic churn there would not be a bounded-safe improvement.

## Judgement-worthy non-blocking code-health findings

1. **Review/iteration boundary ambiguity**

   - **Files:** Whole reviewed range `9d699054c173f9dc30454056a03230357a6a1d38..HEAD`.
   - **Smell:** The iteration plan is DS-only, but the reviewed diff includes a separate application feature around club slugs and public subdomains.
   - **Why it may need human judgement:** This may be a tooling/base-SHA issue rather than an implementation mistake. Either way, future reviews need crisp boundaries so unrelated feature work is not evaluated against a design-system-only plan.

2. **Reserved slug knowledge may be split across layers**

   - **Files:** Visible/referenced evidence includes `lib/memba/clubs/aggregates/club.ex`, public club subdomain lookup/routing code, and `test/memba_web/controllers/club_site_controller_test.exs`.
   - **Smell:** The `"test"` slug appears to be reserved/handled both at aggregate validation time and in runtime public-subdomain behaviour.
   - **Why it may need human judgement:** If the slug/subdomain work is confirmed in scope elsewhere, it may be worth centralising reserved-subdomain knowledge to avoid drift between domain validation and web-tier routing constraints. This should not block this DS iteration review, but it is worth tracking for the slug feature.

3. **Duplicated DS preview theme variables**

   - **Files:** New/changed static design-system preview files under `design-system/`.
   - **Smell:** Self-contained previews necessarily duplicate theme variables and local CSS.
   - **Why it may need human judgement:** This duplication appears intentional per the plan, but it creates future drift risk if app theme tokens change. A future DS maintenance convention or generation step may be useful, while still preserving the plan’s “self-contained preview” requirement.

## Suggested fixes

1. **Resolve the scope mismatch first**

   Choose one of:

   - Rerun the review using the correct base SHA that isolates only Iteration 036’s DS preview changes.
   - Split/revert the club slug/subdomain application work from this iteration branch.
   - Update/replace the plan and obtain human approval if the broader application work is intentionally part of this merge.

2. **Do not apply the stale CSS cleanup unless a concrete violation is found**

   The repair pass found no Tailwind utility or inline-style issue in the inspected DS preview files. Avoid unnecessary churn.

3. **If the club slug/subdomain work is reviewed separately**

   Consider extracting reserved slugs to a named source of truth, for example a module attribute or helper, if there is more than one layer that needs to know about reserved subdomains.

## Validation notes

- `dev ci` / dev check passed.
- Acceptance output showed `82 scenarios`, `493 steps`, all passing.
- Sandbox runtime check passed.
- Working tree was clean at review preflight.
- The green test suite is good evidence that the visible application work behaves as tested, but it does not resolve the scope conflict with the DS-only iteration plan.
- No ADR violations were visible in the provided evidence.
- The review cannot accept the implementation while the reviewed commit range materially conflicts with the plan’s explicit “no app code / no `.feature` changes” constraint.