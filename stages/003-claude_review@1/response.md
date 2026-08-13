Now I'll review the plan against the readiness criteria.

---

# Iteration 055 Validation Report

## Decision: READY

## Confidence: High

This is a well-structured, implementation-ready plan. It demonstrates careful design, boundary-setting, and awareness of both immediate concerns and longer-term architectural implications.

## Blocking gaps

None.

## Non-blocking improvements

1. **Step 2 ambiguity on "one current row per Person"**: The phrasing suggests a one-to-one relationship but doesn't clarify whether old photos are soft-deleted, hard-deleted, or simply overwritten in place. The implementation plan later makes this clear (replace means supersede), but step 2 could be more explicit that replacing a photo deletes the old row.

2. **Upload validation specifics**: While step 8 mentions "bound the decoded dimensions," the plan doesn't state what those bounds are. The client-side hook targets 256×256, and the 25 MB limit is clear, but the server-side dimension limits aren't specified. This is likely fine as an implementation detail, but calling it out as "TBD during implementation" or giving a reasonable upper bound (e.g., "reject anything decoded to >4096px on either dimension") would reduce ambiguity.

3. **Cache-busting left open**: "Open Technical Decisions" notes two cache-busting strategies and states a preference for hashed URLs, but leaves it unresolved. This won't block implementation—both paths work—but closing it now would save a mid-implementation decision point.

4. **No explicit mention of transaction boundaries**: The plan describes commands, events, and projection updates but doesn't specify where transaction boundaries lie (particularly for the photo upload: does the bytes write to `person_photos` happen in the same transaction as event append? Or is it a two-phase commit with the event referencing the bytes row?). This is an implementation detail the domain/Ecto layer will decide, but noting it as "settle during implementation" would flag the concern.

## Smallest viable iteration

**This is already minimal.** The plan cannot be smaller without losing utility:

- Removing "replace photo" would leave members stuck with their first choice.
- Removing "remove photo" would leave members stuck with any photo once set.
- Removing client-side validation would force a full upload-fail cycle for obvious rejections.
- Removing server-side validation would be a security hole.
- Removing any of the error states would leave members with broken UI when things go wrong.
- Removing cache headers would make every avatar render a database hit.

The plan explicitly defers interactive cropping, photo history, moderation, multiple sizes, object storage, and cross-person photo management. It is already the smallest useful slice.

## Required plan edits

None. The plan is ready for implementation as written.

## Validation plan

The plan includes a comprehensive validation section covering:

- **Domain tests**: set, replace, remove, events-not-bytes, read-model projection
- **Controller tests**: signed-in success, unauthenticated rejection, 404, ETag/conditional requests
- **LiveView tests**: all six states (empty, uploading, set, oversized, wrong type, failed, removed) plus live refresh
- **Acceptance tests**: seven Gherkin scenarios covering the four stated rules
- **Manual demo**: nine-step walkthrough hitting all observable behaviours including cross-user visibility and email fallback

The validation plan directly maps to the acceptance criteria and is concrete enough to prove success.

**Stop condition**: `dev check` passes, the seven `@iteration-055` scenarios pass with `@todo-domain @todo-ui` tags removed, and the manual demo completes without surprises.

---

## Readiness Assessment by Question

### 1. Goal clarity ✅

**Clear.** The goal states the outcome ("a signed-in member can add, replace, and remove a profile photo"), the interface (`/my/settings` Profile tab), and the user-visible effect ("the photo stands in for their initials everywhere Memba draws an avatar"). The beneficiary is the member and the people who see them. It's outcome-focused, not task-focused.

### 2. Scope focus ✅

**Focused.** The iteration delivers one coherent capability: self-service profile photos. The "Out of scope" section is extensive and precise: no interactive cropper, no public photos, no club logos, no moderation, no object storage, no multi-size storage. The plan explains *why* each deferral makes sense (e.g., emails can't carry signed-in-only images, so they're explicitly kept on initials).

**Smallest useful slice**: Already there. See above.

**Boundaries clear**: Yes. The plan explicitly names what is and isn't this iteration's problem, links to related problem notes, and states which are resolved, worsened, or left unresolved.

### 3. Acceptance criteria, BDD, and business decisions ✅

**Acceptance criteria**: Comprehensive, concrete, testable. The 15 bullets cover:
- Happy paths: add, replace, remove, render everywhere
- Error states: oversized, wrong type, failed upload
- Security: unauthenticated rejection
- Data integrity: superseded bytes don't remain served
- Performance: ETag/no re-download
- Fallback: initials for members without photos
- Regression: existing behaviours unchanged, emails still use initials

**BDD classification**: ✅ Clearly stated as "Behaviour-facing" with rationale.

**Acceptance scenarios**: ✅ The plan includes a full `## Acceptance Scenarios / Feature Files` section naming the shared feature file, listing four rules and seven scenarios, and specifying the tags (`@iteration-055 @todo-domain @todo-ui`) that exclude them from the build until implementation. The decision is explicit: "Required" with a clear rationale (member-visible, changes what others see, acceptance/rejection policy, privacy rule).

**Business decisions**: ✅ None open. The "Open Business Decisions" section states "None known" and lists four decisions made during planning (Postgres not S3, browser resize, auto-crop, signed-in-only). Each decision includes the rationale.

### 4. Implementation plan and technical decisions ✅

**Steps clear and ordered**: Yes. Sixteen numbered steps from inspection (step 1) through `dev check` (step 15). They follow a logical sequence: storage → commands/events → app service → read model → controller → JS hook → LiveView wiring → rendering → tests → acceptance tests → verification.

**Named files/modules**: Yes. The plan explicitly names:
- LiveView: `MySettingsLive`
- Aggregate: Person, `Memba.Membership`
- Avatar rendering sites: `core_components.ex`, `layouts.ex`, `member_dashboard_presentation.ex`, `club.html.heex`, `admin_components.ex`
- CSS: `styles.css`, `web/assets/css/app.css`
- Table: `person_photos`
- Integration: `Memba.ReadModelChanges` (ADR 0021)
- Feature file: `acceptance-tests/features/member_profile.feature`

**Data model clear**: Yes. `person_photos` table with bytes, content type, size, hash, timestamps; one row per Person; bytes out of the event store.

**API/UI/workflow clear**: Yes. The Designs section references the pushed cloud template, enumerates the five photo states with exact copy, names the new page-local CSS classes, notes the `<.button>` component migration, and specifies avatar rendering sites.

**Open technical decisions**: ✅ Four decisions explicitly flagged as open:
1. Where bytes are read from (projection table, access pattern TBD)
2. Cache-busting shape (hashed URL preferred, ETag acceptable)
3. Test fixtures (location/size TBD)
4. No-JS fallback necessity

All four are scoped as implementation judgements that won't block progress. The plan states a preference for #2, which guides implementation without forcing it.

### 5. Expected capability and validation ✅

**New capability**: Clearly stated in the "New Capability" section: Memba's first upload pipeline, members recognisable by face, and a reference pattern for future image features. The precedent about keeping bytes out of events is explicitly highlighted.

**Proof of success**: The "Validation Plan" section is detailed and comprehensive (see above).

**Stop condition**: Implicit but clear: `dev check` passes, acceptance tests pass, manual demo completes.

---

## Summary

This plan is implementation-ready. It demonstrates:
- **Clear boundaries**: extensive out-of-scope section, explicit problem-note links, decided business questions
- **Security awareness**: server-side validation independent of client, signed-in-only serving, awareness of the "JS hook is never trusted for safety" principle
- **Architectural thinking**: bytes out of events, cache headers, transaction concerns, reversible Postgres choice
- **Complete validation**: domain/controller/LiveView/acceptance tests plus manual demo
- **Minimal scope**: already the smallest useful slice
- **Cucumber discipline**: required BDD scenarios named, tagged, and excluded from build until implementation

The non-blocking improvements are minor clarifications that won't delay or derail implementation. Proceed.

---

{"context_updates":{"claude_review_decision":"READY","claude_review_confidence":"High","claude_review_blocking_gap_count":0,"claude_review_blocking_gaps":"None","claude_review_required_edits":"None"}}