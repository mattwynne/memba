Implemented the next unchecked task.

1. **Selected todo line**
   - `003 Replace member-page buttons with <.button>, mapping each to the right variant/size; preserve href/navigate/form behaviour.`

2. **Changes made**
   - Replaced bespoke member/public club button markup with `<.button>` on:
     - Club home CTAs: send message, empty-state send, invite member.
     - Club-site sign-out form button.
     - Message detail receipt group toggle.
     - Compose success/error/form actions.
     - Public club page CTAs.
   - Mapped actions to shared variants/sizes:
     - Primary actions: `variant="primary"`, often `size="lg"`.
     - Secondary actions: `variant="secondary"`.
     - Low-emphasis navigation: `variant="ghost"`.
   - Preserved existing `href`, `type="submit"`, `type="button"`, `phx-click`, and ARIA behaviour.
   - Updated focused tests to assert the shared daisyUI button classes (`btn`, `btn-primary`, `btn-soft`, `btn-ghost`, `btn-lg`, `btn-sm`) on the changed controls.
   - Verified no raw `<button>` tags remain in the four selected member page files.

3. **Validation run**
   - `PATH="$PWD/bin:$PATH" bin/mix format --check-formatted ...` — passed.
   - `devenv shell -- bash -lc 'cd web && mix test ...focused member/layout/page tests...'` — passed:
     - `80 tests, 0 failures`
   - `git diff --check` — passed.
   - `PGHOST=/tmp/devenv-1d7df38/postgres PGPORT=15432 PATH="$PWD/bin:$PATH" dev check` — passed:
     - Acceptance: `82 scenarios (82 passed), 493 steps (493 passed)`
   - `PATH="$PWD/bin:$PATH" dev down` — completed.

4. **Todo check-off**
   - Changed exactly:
     - `- [ ] 003 Replace member-page buttons with <.button>...`
   - to:
     - `- [x] 003 Replace member-page buttons with <.button>...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - The plan does not explicitly reference an ADR.
   - Inspected current ADRs; ADR 0015 (“Use LiveView for member application pages”) remains respected.
   - No acceptance feature files were changed.