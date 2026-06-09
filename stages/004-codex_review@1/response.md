## Decision: READY

## Confidence: High

I read the complete plan file directly from `docs/iterations/031-brand-email-navigation-polish/plan.md`.

## Blocking gaps

1. None.

## Non-blocking improvements

1. Define the “standard Memba footer content/style” more explicitly, or point to the exact canonical helper/component once known, so implementation and review have a sharper reference.
2. Make the public club-page “clear link” criterion slightly more objective by naming expected link text or acceptable text, for example “Memba home”, “Back to Memba”, or equivalent.
3. Clarify where follow-ups should be recorded if an email template cannot safely adopt the standard footer in this slice.
4. The iteration bundles several small polish fixes. That is acceptable here because the plan frames them as one trust/first-impression polish slice, but each item could be split out if implementation starts to expand.

## Smallest viable iteration

The smallest useful slice is: restore the volunteering-first homepage hero, fix sign-in email branding/footer, update club rejection sender name/footer, and add the public club-page link back to the main Memba homepage. Avoid broad transactional email migration unless it is genuinely mechanical through the existing shared layout/helper.

## Required plan edits

1. None required before implementation.

## Validation plan

Success should be proven by:

1. Acceptance scenarios exist or are implemented for:
   - Homepage volunteering promise.
   - Public club page link back to Memba.
   - Branded sign-in email.
   - Club-aware rejection email sender name.
2. Focused automated tests verify:
   - Homepage hero includes the volunteering promise and remains aimed at volunteer-run clubs.
   - Sign-in email uses the Memba sprig icon and standard footer.
   - Inbound club-message rejection email sender/display name is `<club name> via Memba`.
   - Rejection email uses the standard footer.
   - Public club pages link to the root Memba site rather than the club subdomain root.
3. Existing sign-in, rejection email, and public club-page behaviours continue working.
4. Any `@todo-*` acceptance tags are removed or narrowed where runners can execute the scenarios meaningfully.
5. `dev check` passes.
6. Stop condition: all in-scope acceptance criteria are met, follow-ups are recorded for any non-mechanical email footer exceptions, and `dev check` is green.

{"context_updates":{"codex_review_decision":"READY","codex_review_confidence":"High","codex_review_blocking_gap_count":0,"codex_review_blocking_gaps":"None","codex_review_required_edits":"None"}}