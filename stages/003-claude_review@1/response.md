Now I'll review this plan against the readiness criteria.

---

# Iteration Plan Review: 036-ds-catchup-member-management-and-auth

## Decision: **READY**

## Confidence: **High**

---

## Blocking Gaps

None.

---

## Non-blocking Improvements

1. **Render verification command could be more explicit.** The plan mentions "headless Chrome render verification" multiple times but doesn't specify the exact command, tool, or script. If the project has a standard render-verification script or command (e.g., `dev render-verify`, a Playwright script, or a specific Chrome headless invocation), naming it would make step 7 more actionable.

2. **Missing explicit file-count expectation.** The plan describes 4 deliverable preview areas (invite, profile completion, check-email, badges) but leaves "one file vs two for invite variants" as an open technical decision. While this is acceptable as an implementer's choice, stating "expect 4-6 new/changed preview files" would help validate completeness at review time.

3. **Asset paths context is assumed.** "Relative asset paths" is mentioned in acceptance criteria and step 8, but the plan doesn't state which assets (icons? images? fonts?) these previews need or where they live relative to the preview location. If these previews are truly self-contained with CDN CSS and no local assets, clarify that. If they do reference local assets (e.g., logo or icons), name them.

---

## Smallest Viable Iteration

The plan is **already focused on the smallest viable slice**. The original scope was all undesigned areas (member management, onboarding requests, check-email, empty states). This iteration slices that down to **only member management and auth check-email**, explicitly deferring onboarding requests and empty states. 

Could it be smaller? Technically yes—you could defer check-email to a separate iteration and ship only member-management previews. However, the current slice is coherent (catch up the DS on two shipped feature areas), low-risk (no app behavior change), and already constrained by the WIP ordering dependency (iterations 034/035 must finish first). Further slicing would add coordination overhead for negligible risk reduction.

**Recommendation:** ship as scoped.

---

## Required Plan Edits

None. The plan is clear, complete, and actionable as written.

---

## Validation Plan

### Success Criteria

After this iteration:

1. **Visual fidelity**: headless-Chrome screenshots of each new preview match the corresponding live app surface (invite member, profile completion, check-email with delivery states, role badges).
2. **Self-containment**: each preview renders cleanly when opened standalone in a browser—no missing styles, no dependency on Tailwind utility classes, no broken component layout.
3. **Indexability**: each preview has a correct `@dsCard` header and relative asset paths (if any).
4. **No app changes**: git diff shows only new/changed preview files under `design-system/` or `spikes/ds-convert/` (whichever location is chosen), no `.feature`, LiveView, template, or route changes.
5. **Clean build**: `dev check` passes.
6. **Cloud DS convergence (manual post-merge step)**: PM pushes approved previews to cloud DS project `bc97cfc3-436c-471e-a939-7ba222859282` via DesignSync; new cards render correctly at claude.ai/design.

### Stop Condition

Stop when all 4 preview areas (invite, profile completion, check-email, badges) are authored, render-verified, and merged to main, and `dev check` is green on the merged state. The cloud DS push is a separate manual step tracked outside Fabro but required for the goal ("bring the DS up to speed").

---

## Detailed Readiness Assessment

### 1. Goal Clarity ✅

**Clearly articulated.** The goal states the user/business outcome: "bring the claude.ai/design design system back in step with the running app" so "the DS reflects how the app actually works." The beneficiary is explicit: designers and PMs iterating on these surfaces need accurate, faithful DS previews as a starting point. The "after this iteration" bullets make the concrete outcome tangible.

### 2. Scope Focus ✅

**Focused and coherent.** The scope is tightly bounded to 4 preview deliverables (invite, profile completion, check-email, badges), deliberately sliced from a larger DS-catchup backlog. Out-of-scope is explicit and detailed (no onboarding requests, no member roster, no empty states, no app code changes, no cloud push within Fabro). The scope cannot be smaller without losing coherence—these are two shipped feature areas that share the same DS-catchup delivery mechanism.

### 3. Acceptance Criteria, BDD Decision, and Business Decisions ✅

**Concrete, complete, and testable.** Acceptance criteria cover:

- Deliverables exist (new previews for invite, profile, check-email, badges)
- Self-containment requirement (daisyUI CDN + theme vars + plain CSS, no Tailwind utilities)
- Indexability (`@dsCard` headers, correct asset paths)
- Visual fidelity (renders cleanly, matches shipped surfaces)
- Scope boundaries (no app code changes, `dev check` passes)

**BDD classification is correct and justified.** The plan explicitly classifies this as "Technical/design" with **no new user-observable app behaviour**. The BDD decision is "Not applicable" with clear rationale: no application rule changes, correctness is visual fidelity verified by headless-Chrome render checks, not Gherkin scenarios. This is appropriate—design-system artifact creation is not a behaviour-facing change.

**No unresolved business decisions.** The surfaces already exist; this mirrors them. The only open decisions are technical (repo location, one vs two files for invite variants), correctly classified as implementation details.

### 4. Implementation Plan and Technical Decisions ✅

**Clear, ordered, and specific.** The 9-step plan is actionable:

1. Read the shipped surfaces (specific files named: `member_invitation_live/new.ex`, `admin/club_member_invitations_live/`, `club_member_invitation_html/profile.html.heex`, `auth_live/sign_in.ex`)
2. Confirm repo preview location and self-contained head block convention
3–6. Author each preview (specific deliverables)
7. Render-verify each file with headless Chrome
8. Ensure `@dsCard` headers and asset paths
9. Run `dev check`

**Technical decisions are scoped correctly.** Three open technical decisions are listed:

- Repo preview location (`design-system/` vs `spikes/ds-convert/`)
- One file vs two for invite variants
- Exact cloud DS target paths (PM's decision at push time)

All are genuinely implementation details that don't require product sign-off. The plan gives enough guidance (preferred repo location, implementer's call on file split, PM chooses final cloud paths) to proceed.

### 5. Expected Capability and Validation ✅

**Clear new capability.** After this iteration, the DS shows accurate previews of member invitations, profile completion, and check-email/delivery-progress—closing the first slice of the DS-to-shipped-app gap and giving future design iteration a faithful starting point.

**Provable success.** Validation plan includes:

- Headless-Chrome render screenshots visually compared to live app
- Diff inspection (preview files only, no app changes)
- `dev check` green
- Post-merge cloud DS push (manual PM step, explicitly out of Fabro scope)

**Clear stop condition.** Iteration is done when all 4 preview areas are authored, render-verified, and merged with `dev check` green. The cloud DS push is tracked separately but required for the stated goal.

---

## Summary

This is a **well-scoped, clearly specified, and ready-to-implement plan**. It articulates a coherent goal (DS-to-app convergence for two shipped feature areas), establishes concrete acceptance criteria, correctly classifies itself as technical/design with justified BDD exclusion, provides an actionable 9-step implementation plan naming specific files and integration points, and defines clear validation and stop conditions.

The scope is the smallest useful slice of a larger DS-catchup effort. The plan acknowledges risks (Tailwind-utility trap, fidelity drift, Fabro-cloud-DS boundary) with mitigations. Open technical decisions are genuinely implementation details. No unresolved product or business decisions block progress.

The plan can be marked **validated** and is ready for implementation as soon as iterations 034 and 035 vacate the WIP slot.

---

{"context_updates":{"claude_review_decision":"READY","claude_review_confidence":"High","claude_review_blocking_gap_count":0,"claude_review_blocking_gaps":"None","claude_review_required_edits":"None"}}