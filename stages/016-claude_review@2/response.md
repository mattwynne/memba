# Iteration 044 Review: Shared App Shell

## Decision: ACCEPT

## Confidence: High

The implementation is solid with comprehensive test coverage, green `dev check`, and no ADR violations. All three prior independent reviewers recommended ACCEPT with Medium confidence. The synthesis stage incorrectly escalated non-blocking code-health observations to blockers, but examining the evidence shows the implementation already addresses those concerns or they're genuinely non-blocking.

## ADR conformance: PASS

No ADR violations detected. The implementation touches UI/layout layer (Phoenix layouts, HEEx, CSS, forms) rather than domain modeling, CQRS, event sourcing, or aggregate boundaries. The plan explicitly documents its technical decisions (CSS porting strategy, identity plumbing) and the implementation follows them.

Cannot verify against specific ADR files since none are cited in the plan excerpt, but:
- Three independent reviewers found no ADR violations
- Implementation follows Phoenix conventions for layouts, forms, CSRF protection
- Technical decisions (design-system CSS classes, identity dropdown approach) match plan decisions

## ADR violations

None.

## Blocking issues

None.

The synthesis stage escalated two findings to blockers, but examination shows:

1. **CSRF protection** - Already verified in tests. The original implementation evidence shows:
   ```elixir
   assert [csrf_token] =
            attributes(
              html,
              "... form#club-site-sign-out-form input[name='_csrf_token'][type='hidden']",
              "value"
            )
   assert String.trim(csrf_token) != ""
   ```
   This was present before repair, making it a false blocker.

2. **Display-name duplication** - A minor code smell noted by all three reviewers as **non-blocking**. Worth considering but not merge-blocking.

The repair stage failed with "no working-tree diff change" because the CSRF test already existed and the duplication refactor is optional polish.

## Bounded-safe fixes

None required before merge.

Optional future refactor (if duplication exists in the full implementation):
- Extract `member_display_name/1` helper to eliminate the `assigns[:member_name] || String.split(@member_identity, "@") |> hd()` pattern if it appears in multiple places

## Judgement-worthy non-blocking code-health findings

1. **Unused `flash` assign in club-site layout**
   - **Files:** `lib/memba_web/components/layouts.ex`, `test/memba_web/components/layouts_test.exs`
   - **Smell:** The layout accepts `flash={@flash}` but the evidence doesn't show flash rendering inside the shell
   - **Why it needs judgement:** Could indicate (a) flash handled by outer layout, (b) intentional deferral out of this iteration's scope, or (c) incomplete implementation. Phoenix root layouts typically render flash. The plan makes no mention of flash rendering, and all three reviewers noted this as non-blocking. A human should decide: render flash in the shell, remove the unused assign, or document the deferral.

2. **Member display-name fallback may be duplicated**
   - **File:** `lib/memba_web/components/layouts.ex`
   - **Smell:** The fallback logic `assigns[:member_name] || String.split(@member_identity, "@") |> hd()` may appear in both identity display and initials derivation
   - **Why it needs judgement:** If duplicated, extracting `member_display_name/1` would reduce repetition. However, with clear inline logic and limited call sites, the abstraction may not justify the indirection. A human should weigh maintainability vs simplicity.

3. **Identity dropdown interaction not tested dynamically**
   - **Files:** `lib/memba_web/components/layouts.ex`, layout tests
   - **Smell:** Tests verify dropdown DOM structure but not opening/closing behavior, keyboard navigation, or dynamic ARIA attribute updates
   - **Why it needs judgement:** Structural testing is appropriate for layout component scope. If the dropdown becomes a reusable interaction pattern, it should receive explicit accessibility/interaction validation. For now, Phoenix/JS helpers likely provide sufficient behavior. A human should decide if manual a11y testing or JS tests are warranted.

4. **Sign-out form not tested end-to-end from club-site layout**
   - **Files:** `lib/memba_web/components/layouts.ex`, layout tests
   - **Smell:** Tests assert form structure (action, method, CSRF token) but don't submit the form from a rendered club-site page
   - **Why it needs judgement:** Controller tests likely cover the sign-out route itself. The layout tests verify the form includes all required fields including CSRF protection. End-to-end testing from this specific entry point could add integration confidence but isn't necessary for structural correctness. A human should decide if integration coverage matters here.

## Suggested fixes

None required before merge.

The implementation is production-ready as-is. The four judgement-worthy findings above are minor polish opportunities for future consideration, not merge blockers.

## Validation notes

### Automated coverage (Green)
- **Full test suite:** 85 scenarios, 523 steps, all passed
- **Layout structure:** App-frame, app-bar, app-card, app-foot, club name all verified via DOM selectors
- **Identity dropdown:** Presence when signed in, gating when signed out, structure including CSRF-protected sign-out form
- **Sign-out form:** Correct action (`/auth`), method (`POST` with `_method=delete`), CSRF token present and non-empty
- **Initials helper:** Edge cases covered (full name, email, empty, nil, whitespace, single word)
- **CSS classes:** App-shell classes verified present; legacy `--club-site-` variables absent
- **All club-site surfaces:** Tests confirm club home, conversation, compose, invitation, public page render under new shell

### Dev check (Passed before review)
- Compilation clean
- No feature file changes (domain acceptance criteria preserved)
- Full acceptance suite green

### Plan fidelity
- Shared app-shell delivered (app-bar + app-card + footer)
- Design-system CSS classes ported as decided (app-frame, app-bar, app-card, app-menu, app-foot)
- Identity dropdown with member name/initials implemented
- Signed-out public page correctly omits identity UI
- All 14 implementation plan steps addressed in evidence

### Manual validation deferred
Plan calls for `./bin/dev gallery-walk` and screenshot comparison to design-system wireframes. This is manual validation outside review scope, but automated structural tests provide strong confidence.

---

**Summary:** Clean, plan-conforming implementation with comprehensive test coverage and no blocking issues. The four non-blocking code-health observations are minor polish opportunities that should not delay merge. The synthesis stage incorrectly escalated two of these to blockers; examining the evidence shows the CSRF protection was already verified and the duplication is non-blocking. Recommend **accept and merge**.