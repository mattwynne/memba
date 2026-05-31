# Implementation Review Report

## Decision: REJECT

## Confidence: Medium

## ADR Conformance: FAIL

---

## ADR Violations

1. **ADR-011 Section "Decision" - Layout distinctness not implemented**
   - **ADR text**: "Staff admin surface (`/admin/*`)... Uses a utilitarian admin layout with Memba chrome"
   - **Evidence**: All LiveViews use the same `app.html.heex` layout template. Admin pages at `/admin/clubs`, `/admin/messages/:id`, etc. render with identical chrome as the public homepage at `/`.
   - **File**: `web/lib/memba_web/components/layouts/app.html.heex` is the single layout template used by both surfaces
   - **Impact**: Admin and public surfaces are visually indistinguishable despite ADR decision requiring distinct layouts

2. **ADR-011 Section "Consequences" - Three layouts commitment unmet**
   - **ADR text**: "Negative: Three layouts to maintain"
   - **Evidence**: Only one layout template exists (`app.html.heex`). No `admin.html.heex` or visual differentiation mechanism present.
   - **Gap**: If only one layout exists, the stated consequence of maintaining three layouts is not realized

---

## Blocking Issues

1. **ADR-011 conformance failure requiring human judgment**
   - The implementation provides routing infrastructure (pipelines, namespaces, paths) but omits distinct visual layouts stated in ADR-011's decision
   - No automated test verifies distinct admin chrome vs. public chrome
   - Plan validation steps check routing behavior but not visual distinction
   - **Human decision needed**: Should distinct admin layout template with utilitarian chrome be added now, or should ADR-011 be amended to clarify "layout infrastructure only" scope for this iteration?
   - **Files**: Need either `web/lib/memba_web/components/layouts/admin.html.heex` or ADR update

2. **Incomplete layout infrastructure without usage**
   - Three `on_mount/4` hooks defined in `MembaWeb.Layouts` (`:public`, `:admin`, `:club_site`) but never invoked by any LiveView
   - **Evidence**: `web/lib/memba_web/live/admin/clubs_live/index.ex` and other admin LiveViews have no `on_mount __MODULE__` calls
   - **Gap**: Infrastructure exists but is dead code without wiring or documentation of intent
   - **Files**: `web/lib/memba_web/components/layouts.ex` lines 12-38

---

## Bounded-Safe Fixes

1. **Add auth insertion point documentation to `:staff_browser` pipeline**
   ```elixir
   # In web/lib/memba_web/router.ex after line 13
   pipeline :staff_browser do
     plug :accepts, ["html"]
     plug :fetch_session
     plug :fetch_live_flash
     plug :put_root_layout, html: {MembaWeb.Layouts, :root}
     plug :protect_from_forgery
     plug :put_secure_browser_headers
     # TODO: Insert staff authentication plug here (e.g., plug :require_staff_auth)
   end
   ```
   - **Rationale**: Plan says pipeline should be "obvious auth insertion point" but current code requires knowing where auth belongs; explicit comment improves clarity

2. **Document purpose of unused `on_mount` hooks**
   ```elixir
   # In web/lib/memba_web/components/layouts.ex before line 12
   # Layout lifecycle hooks for future use:
   # - Call via `on_mount {__MODULE__, :admin}` in LiveView modules
   # - :public and :admin currently no-ops, ready for layout-specific assigns
   # - :club_site sets default theme for white-label infrastructure
   ```
   - **Rationale**: Hooks exist but aren't called anywhere; documentation clarifies intent vs. dead code

---

## Judgement-Worthy Non-Blocking Code-Health Findings

1. **Plan/ADR semantic misalignment on "layout" scope**
   - **Files**: `docs/iterations/009-routing-and-liveview-surface-split/plan.md` step 4, `docs/adr/011-three-routing-surfaces.md` decision section
   - **Smell**: Plan says "Add or adjust layout **functions**" (ambiguous), ADR says "Uses a utilitarian admin **layout**" (implies template). Implementation provides hooks but no templates.
   - **Why judgement**: Unclear whether plan intended minimal infrastructure (seam) vs. full visual distinction. Plan validation doesn't verify chrome differences. ADR consequences assume three distinct templates.
   - **Risk**: Future work expecting distinct admin UI per ADR will find identical shared layout. White-label club_site theme assigns (`club_theme_primary`, etc.) exist but no template or CSS consumes them.

2. **Club-site layout assigns without consumer**
   - **Files**: `web/lib/memba_web/components/layouts.ex` lines 30-38
   - **Smell**: `on_mount(:club_site, ...)` sets `:club_theme_primary`, `:club_theme_accent`, `:club_name` with CSS custom property defaults, but no template references these assigns and no CSS defines corresponding properties
   - **Why judgement**: Is this sufficient "seam" infrastructure per plan, or incomplete implementation? No club_site.html.heex exists to render themed content.
   - **Risk**: Infrastructure may not be exercised until real club routing added; unclear if current design will work

3. **`:staff_browser` pipeline duplication**
   - **Files**: `web/lib/memba_web/router.ex` lines 4-11 and 13-20
   - **Smell**: `:staff_browser` is byte-for-byte duplicate of `:browser` (no distinct plugs, root layout, or session config)
   - **Why judgement**: Could be composed (`plug :browser`) or differentiated now. Current duplication risks divergence if :browser changes.
   - **Risk**: Maintenance burden if pipelines evolve separately; opportunity to signal "same for now" intent via composition

---

## Suggested Fixes

**For ADR conformance (blocking):**
- **Option A**: Add distinct admin layout template
  1. Create `web/lib/memba_web/components/layouts/admin.html.heex` with utilitarian chrome (requires product/design judgment about what "utilitarian" means)
  2. Update `web/lib/memba_web.ex` live_view macro to accept layout override
  3. Pass `layout: {MembaWeb.Layouts, :admin}` in admin routes or use `on_mount` to set layout
  4. Add test verifying admin layout differs from public layout
  
- **Option B**: Update ADR-011 to match implementation scope
  1. Amend ADR-011 decision to clarify "layout infrastructure" (pipelines, hooks, assigns) vs. "distinct layout templates"
  2. Move "utilitarian admin layout" visual distinction to future work / consequences
  3. Update "three layouts to maintain" consequence to reflect current single template

**For incomplete infrastructure (blocking):**
- Document or remove unused `on_mount` hooks; if keeping for future use, wire up at least one (e.g., call `on_mount {MembaWeb.Layouts, :admin}` in admin LiveViews)

**For bounded-safe fixes (apply directly):**
- Add auth insertion point comment to `:staff_browser` pipeline (code snippet in bounded-safe fixes section)
- Document purpose of `on_mount` hooks (code snippet in bounded-safe fixes section)

---

## Validation Notes

### Tests Confirming Plan Deliverables
- ✅ `web/test/memba_web/router_test.exs` verifies all routes go through correct pipelines (`:browser`, `:staff_browser`, `:api`)
- ✅ Old harness paths (`/clubs`, `/messages/:id`) return 404 without redirects (lines 56-67)
- ✅ Admin LiveViews render at new `/admin/*` paths
- ✅ Webhook route preserved and uses `:api` pipeline
- ✅ All LiveView tests updated with `~p"/admin/..."` verified routes

### Tests Not Covering ADR Requirements
- ❌ No test verifies admin layout differs from public layout (because implementation uses same template)
- ❌ No test verifies club_site theme assigns are consumed (because no template uses them)
- ❌ No test verifies staff auth boundary (intentionally deferred per plan, acceptable)

### Manual Validation from Plan Would Show
- Public homepage renders at `/` ✅ (per dev check)
- Admin clubs list renders at `/admin/clubs` ✅ (per dev check)
- But: admin pages look identical to public pages ❌ (ADR violation)

---

## Summary

The implementation successfully reorganizes routing structure, namespaces, and file organization per the plan. Routes work correctly, tests pass, and the mechanical refactoring is sound. However, **ADR-011's decision requiring distinct layouts is not satisfied**—admin and public surfaces use the same visual template despite the ADR stating admin should have "utilitarian admin layout with Memba chrome."

This is a **conformance gap** requiring human judgment about whether to enhance the implementation now or update the ADR to match the minimal infrastructure scope the plan delivered. The gap exists because the plan's validation steps check routing behavior but not visual distinction, and "layout functions" in the plan could mean either hooks or templates.