# Iteration 036 Review Report

## Decision: REJECT

This is a release-boundary / plan-fidelity rejection, not a judgement that the in-range app code is poorly written.

The reviewed commit range `9d699054c173f9dc30454056a03230357a6a1d38..HEAD` appears to include substantial club slug / public subdomain application work in addition to the design-system preview files. The iteration plan is explicit that this slice should only add/update static DS preview files and should not change app code, routes, LiveViews, templates, or `.feature` files.

If the slug/subdomain work belongs to a prior iteration, the review base is wrong and this review should be rerun against the correct DS-only range. If it is intentionally part of this merge artifact, it needs explicit human approval or a different/updated plan before acceptance.

## Confidence: Medium

Confidence is medium because the provided implementation evidence is truncated and the workflow says plan conformance was already proven, but the visible evidence from the reviewed commit range conflicts materially with the plan’s stated scope.

## ADR conformance: PASS

No ADR violation is visible from the provided evidence.

For the apparent in-range domain/CQRS/event-sourcing work around club slugs, the visible implementation appears to use the project’s established aggregate/command/event/projection/read-model patterns rather than bypassing them with local substitutes. However, that work appears out of scope for this DS iteration.

## ADR violations

None found.

## Blocking issues

1. **Reviewed commit range contains substantial out-of-scope application/domain work**

   - **Plan requirement:** The iteration plan says:
     - new DS previews for member invitations, profile completion, and check-email/delivery-progress;
     - badges component card update;
     - no app code, routes, LiveViews, templates, or `.feature` files changed.
   - **Evidence from review context:** The collected implementation evidence and successful acceptance run include club slug / public subdomain work, including references to:
     - `features/staff_club_slugs.feature`
     - `lib/memba/clubs/aggregates/club.ex`
     - public club subdomain routing/controller behaviour
     - `test/memba_web/controllers/club_site_controller_test.exs`
     - smoke-test club slug handling
   - **Why this blocks:** The merge artifact under review is not limited to the DS preview slice described in `docs/iterations/036-ds-catchup-member-management-and-auth/plan.md`. Even if the slug work is correct, it changes acceptance coverage and application behaviour that this plan explicitly excluded.
   - **Required resolution:** Either:
     - correct the review/merge base so this iteration contains only the DS preview files, then rerun review; or
     - get explicit human approval that the broader slug/subdomain work is intentionally part of this merge and should be reviewed under an appropriate plan/scope.

## Bounded-safe fixes

1. **Replace Tailwind-utility-shaped layout classes in static DS previews with local CSS**

   - **Files:** likely DS preview files such as:
     - `design-system/wireframes/auth/check-email.html`
     - `design-system/wireframes/member-invitations/invite-a-member-admin.html`
     - `design-system/wireframes/member-invitations/invite-a-member-staff.html`
     - `design-system/wireframes/member-invitations/profile-completion.html`
   - **Issue:** The earlier review evidence mentioned markup like:

     ```html
     <div style="max-width: 480px" class="mx-auto">
     ```

     `mx-auto` is a Tailwind utility class. These previews are supposed to be self-contained static HTML using daisyUI prebuilt CSS plus plain CSS, not Tailwind utilities.
   - **Safe fix:** Define a local class, for example:

     ```css
     .preview-container {
       max-width: 480px;
       margin: 0 auto;
     }
     ```

     Then use:

     ```html
     <div class="preview-container">
     ```

2. **Move repeated inline preview layout styles into local CSS classes**

   - **Files:** same DS preview files as above.
   - **Issue:** Inline layout styles make the previews harder to scan and easier to drift between cards.
   - **Safe fix:** Replace one-off inline layout declarations with named local classes in each file’s `<style>` block. This preserves the plan’s self-contained-file requirement while improving maintainability.

3. **If the slug/subdomain work remains in the final reviewed scope, extract reserved slugs to a named module attribute**

   - **File:** `lib/memba/clubs/aggregates/club.ex`
   - **Issue:** Evidence suggests validation similar to:

     ```elixir
     validate_exclusion(:slug, ["test"], message: "is reserved")
     ```

   - **Safe fix:**

     ```elixir
     @reserved_slugs ~w(test)

     # ...

     |> validate_exclusion(:slug, @reserved_slugs, message: "is reserved")
     ```

   - **Note:** This is only relevant if that app/domain work is intentionally included after the scope issue is resolved.

## Judgement-worthy non-blocking code-health findings

1. **Theme variable duplication across static DS preview files**

   - **Files:**
     - `design-system/wireframes/auth/check-email.html`
     - `design-system/wireframes/member-invitations/*.html`
     - `design-system/components/badges/badges.card.html`
   - **Smell:** Each self-contained preview appears to duplicate the app theme variables and supporting preview CSS.
   - **Why it may need human judgement:** The duplication is partly intentional: the plan requires previews to be self-contained and not rely on bespoke shared component CSS. Long term, though, this may drift from the app theme unless there is a generation/copying convention. A future decision may be needed between portability and maintainability.

2. **Reserved smoke-test slug behaviour may be split across validation and runtime lookup**

   - **Files:** visible/referenced evidence includes:
     - `lib/memba/clubs/aggregates/club.ex`
     - public club subdomain lookup/routing helpers
     - `test/memba_web/controllers/club_site_controller_test.exs`
   - **Smell:** The system appears to both reserve `"test"` at the aggregate validation layer and ensure `test.lvh.me` does not expose a public club site. If those rules live in separate places, they can drift.
   - **Why it may need human judgement:** Centralising reserved-subdomain knowledge may be desirable, but the right boundary depends on project architecture: aggregate validation, read-model lookup, routing, and smoke-test infrastructure each have plausible responsibility claims.

3. **Iteration/review base ambiguity**

   - **Files:** whole reviewed range `9d699054c173f9dc30454056a03230357a6a1d38..HEAD`.
   - **Smell:** The plan is DS-only, but the reviewed range appears to include a separate club slug/subdomain feature.
   - **Why it may need human judgement:** This may be a tooling/base-SHA issue rather than an implementation mistake. Either way, future reviews need a crisp boundary so design-only iterations are not evaluated together with unrelated domain/application changes.

## Suggested fixes

1. **Resolve the scope mismatch before merge**
   - If slug/subdomain work belongs to another already-approved iteration, rerun this review with the correct base SHA so the range only includes the DS preview files.
   - If the work is not intended for this iteration, split/revert it from the iteration branch.
   - If the work is intentionally included, obtain explicit human approval or update/create the appropriate plan and rerun review for that broader scope.

2. **Clean up DS preview layout classes**
   - Replace any Tailwind utilities such as `mx-auto` with locally defined plain CSS classes.
   - Prefer classes such as `.preview-container`, `.preview-stack`, or `.preview-section` over repeated inline layout styles.

3. **Keep DS previews self-contained while reducing drift**
   - Add clear CSS section comments inside each preview file, for example:
     - theme variables;
     - base/layout styles;
     - component-specific preview styles.
   - Do not introduce shared CSS imports unless the plan is changed, because the current plan explicitly requires self-contained previews.

4. **If slug/subdomain work is approved into scope**
   - Extract reserved slugs to a named attribute or helper.
   - Consider whether aggregate validation and runtime subdomain exclusion should share the same reserved-slug source of truth.

## Validation notes

- `dev ci` / dev check passed before review.
- Acceptance output showed `82 scenarios`, `493 steps`, all passing.
- Sandbox runtime check passed.
- Working tree was clean at review preflight.
- The green test suite is good evidence that the apparent slug/subdomain work behaves as tested, but it does not resolve the scope conflict with this DS-only iteration plan.
- I did not see direct screenshot artifacts in the provided context for the required headless-Chrome visual verification of the DS previews; the plan-conformance workflow may have checked that separately.