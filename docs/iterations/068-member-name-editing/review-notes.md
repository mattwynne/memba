# 068 bounded specialist review and design verification

## Review

Read-only bounded domain/UX/formulation review: @thread:thr_en8aqpbjbq. One inherited model only,
not three independent families, not live Three Amigos, and not the parent's final whole-plan review.
The reviewer inspected current parent artifacts and immutable spike contents via git show.

Significant findings and routes:

1. **Temporal ambiguity (Matt/model):** expected-value comparison cannot detect Jones → Green →
   Jones between warning and confirmation, or Smith → Jones → Smith before the original save.
   A currently differing value is protected; every intervening rename needs a revision instead.
   Resolved by Matt in the parent conversation: use current normalized value comparison; no
   revisions. Same normalized target is a successful no-op. No re-opening this minority edge case.
2. **No-op discrepancy (model/tests):** the spike fake writer checks stale first while the proposed
   Person model accepts identical normalized targets as no-ops. Spike tests do not prove that policy.
   Dispose of the fake writer; real aggregate tests must prove chosen ordering, authorization and
   normalization. Authorize even no-op attempts.
3. **Raw/comparable data (form adapter):** preserve raw typed text separately from comparable values.
   For the name form, derive normalized requested values without rewriting the displayed draft;
   authoritative baseline names must match actual persisted aggregate data, including historical
   names. Do not retroactively validate old history. Aggregate remains the validation authority.
   Do not enforce a browser UTF-16 maxlength as a substitute for agreed character counting.
4. **Accessibility (UX/implementation proof):** warning must be announced on rejection and repeated
   conflicts; preserve descriptions for validation errors; manage focus when Save is replaced and
   return focus to Edit on Cancel. Enter must not accidentally activate overwrite confirmation.
   Draft changes invalidate confirmation. Static readonly mock-ups prove none of these transitions.
5. **Focused browser proof (validation):** retain one accepted journey, plus a focused browser
   interaction test (not another stakeholder acceptance scenario) for dirty draft/warning/explicit
   confirmation/cancellation. Test real DOM event order and focused input preservation.

Review supports a small pure coordinator and stateless warning component with domain-owned atomic
conditional writes; no app-wide migration, phone support or generic persistence framework.
No reviewer chose product policy or accepted a model/ADR.

## Local design render verification

Both local HTML mock-ups were opened in headless Chromium at 1320px and 390px. Checks found no
horizontal document overflow and correct Save anyway / Cancel my changes labels at both widths.
Screenshots retained locally under `.local/068-planning/`; the 390px name screenshot was visually
inspected: amber card/icon, neutral name input, actions wrapping, and red inline validation comparison.

The first launch attempt used a Playwright/browser-version mismatch; reran successfully with the
installed Chromium executable. No DesignSync was used or published. This verifies static layout,
not connected interaction, announcements/focus, or production component implementation.

## Gates

The first gate completed with six browser scenarios passing, but docs were edited while it ran;
it is not claimed as the exact published-state gate. The next exact-state run failed after Ecto
sandbox/projector shutdown caused cascading missing-Repo failures; no application fixes were made.
A retry on clean committed state `12d98f759b24ed6334e14cb71027b9303a8e6730` passed `dev check`
(exit 0, six browser scenarios/106 steps). Local logs: `.local/068-planning/final-dev-check.log`
(failed run), `.local/068-planning/retry-dev-check.log` (passing retry).

Parent final whole-plan review subsequently completed with two independent families. Its synthesis
is preserved verbatim in [final-ensemble-review.md](final-ensemble-review.md). Trusted actor/self-only
entry-point authorization and synchronized readback/delayed-projector proofs were clarified in the
plan and ADR record. These are docs-only corrections: `git diff --check` applies, with no new
`dev check` required and no attribution of the earlier gate to a later untested commit. Matt then
explicitly decided “No that does not merit an ADR.” The record requirement is removed, not the
agreed behaviour or corrections. Useful guidance is folded into the plan/design notes; the redundant
proposal is removed and no numbered ADR is created. No approval blocker or second ensemble remains.
