Implemented the automatic repair for the synthesized review issue.

## 1. Review issue from the gate

### `document-source-scanning-test-guardrail`
**Issue:** Document the member design-system source-scanning test as an intentional guardrail.

## 2. Changes made

### Issue-to-fix mapping

| Review issue | Fix | Files |
|---|---|---|
| `document-source-scanning-test-guardrail` | Added `@moduledoc` explaining that the source scans are structural guardrails that complement rendered tests and gallery-walk screenshots, not replacements for semantic/visual validation. | `web/test/memba_web/member_page_design_system_alignment_test.exs` |
| `document-source-scanning-test-guardrail` | Updated the iteration validation plan to explicitly document the source-scanning test’s intended role. | `docs/iterations/034-member-page-design-system-alignment/plan.md` |

No product behaviour was changed.

## 3. Files changed

### Source-scanning guardrail documentation
- `web/test/memba_web/member_page_design_system_alignment_test.exs`
- `docs/iterations/034-member-page-design-system-alignment/plan.md`

## 4. Tests / validation run

- `mix format web/test/memba_web/member_page_design_system_alignment_test.exs` — passed.
- `mix test web/test/memba_web/member_page_design_system_alignment_test.exs` — failed because it was run from the repo root, which is not the Mix project root.
- `cd web && mix test test/memba_web/member_page_design_system_alignment_test.exs` — failed due missing local DB socket at `/tmp/devenv/postgres/.s.PGSQL.15432`.
- `PATH="$PWD/bin:$PATH" dev check` — passed.
  - ExUnit: `807 tests, 0 failures`
  - Acceptance: `82 scenarios, 493 steps passed`

## 5. Remaining gaps / human questions

None. The selected review issue is addressed with documentation in the test itself and in the iteration validation plan.

Note: `.fabro/tmp/` remains untracked from the existing review pipeline state; I did not modify or remove it.