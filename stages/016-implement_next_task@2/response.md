Implemented next unchecked iteration task **006**.

1. **Selected todo line**
   - `006 Add an optional member_name assign (default nil) to club_site, and a private Layouts.initials/1 helper that derives avatar initials from a name.`

2. **Changes made**
   - Updated `web/lib/memba_web/components/layouts.ex`:
     - Added optional `attr :member_name, :string, default: nil` to `Layouts.club_site/1`.
     - Added private `defp initials/1`.
     - Refactored `club_identity_initials/1` to delegate email-local-part initials through the new `initials/1` helper.
     - Improved initials splitting to handle Unicode letters/numbers, e.g. `élodie.durand` → `ÉD`.
   - Updated `web/test/memba_web/components/layouts_test.exs`:
     - Added coverage that `club_site` accepts `member_name`.
     - Added coverage for name-like/Unicode initials derivation.

3. **Validation commands/results**
   - TDD red check:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/components/layouts_test.exs`
     - Failed as expected before implementation: expected `ÉD`, got `LD`.
   - Focused test:
     - `PATH="$PWD/bin:$PATH" dev test test/memba_web/components/layouts_test.exs`
     - Passed: `6 tests, 0 failures`.
   - Formatting:
     - `cd web && mix format --check-formatted lib/memba_web/components/layouts.ex test/memba_web/components/layouts_test.exs`
     - Passed.
   - Full project check:
     - `PATH="$PWD/bin:$PATH" dev check`
     - Passed, including acceptance: `85 scenarios (85 passed), 523 steps (523 passed)`.

4. **Todo check-off made**
   - Changed exactly:
     - `- [ ] 006 Add an optional ...`
   - to:
     - `- [x] 006 Add an optional ...`

5. **Todo splits/additions/reordering**
   - None.

6. **ADR conformance**
   - The plan references no ADRs explicitly.
   - No `docs/adr/*.md` files are present.
   - No acceptance feature files were changed.
   - The change stays within the approved plan: only adds the `member_name` assign and the private initials helper; rendering from `member_name` remains for the next task.