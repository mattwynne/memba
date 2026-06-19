1. **Selected todo line**
   - `006 Author the empty / first-run state preview(s).`

2. **Changes made**
   - Added `design-system/wireframes/member-empty-first-run-states.html`.
   - The preview includes:
     - `@dsCard` and `@startingPoint` headers.
     - Self-contained daisyUI CDN CSS + Memba theme/root tokens.
     - Plain CSS layout only; no Tailwind utility reliance.
     - Canonical shipped empty/first-run states:
       - Club home with no messages yet.
       - “Send the first message” CTA.
       - First-member roster state.
       - Signed-in home “No clubs found for this email”.
       - Member message detail pending-delivery-list state.
     - Sage theme/shared-component treatment using daisyUI buttons/avatar primitives and local CSS.
   - No app code, routes, LiveViews, templates, or `.feature` files changed.

3. **Focused validation commands run**
   - Static DS/self-contained/class scan:
     - `python3 - <<'PY' ...`
     - Passed: DS markers present, daisyUI CDN present, no shared CSS links, no `--club-site-*`, all non-daisy class tokens locally styled.
   - HTML parser smoke check:
     - `python3 - <<'PY' ... HTMLParser ...`
     - Passed.
   - Whitespace check:
     - `git diff --check`
     - Passed.
   - Broad quick validation:
     - `PATH="$PWD/bin:$PATH" dev check --quick`
     - Passed: `799 tests, 0 failures`.

4. **Todo check-off made**
   - Changed:
     - `- [ ] 006 Author the empty / first-run state preview(s).`
   - To:
     - `- [x] 006 Author the empty / first-run state preview(s).`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance evidence**
   - No ADRs were explicitly referenced by the plan for this task.
   - Accepted architecture constraints remain unaffected: this is a static design-system preview only.
   - No Phoenix app behavior, routing, LiveView state, email behavior, acceptance coverage, or persistence/eventing code changed.