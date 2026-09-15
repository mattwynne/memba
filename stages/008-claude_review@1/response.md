# Iteration Review Report — 063 Add Custom Group Members

## Decision: ACCEPT

## Confidence: Medium

*(Confidence is capped at Medium because the implementation-evidence collection stage truncated the vast majority of the diff — 6,149 lines omitted — leaving only tail fragments of two test files visible to this review. The decision below is grounded in what evidence is available: the plan text, the full `dev check` transcript, and the visible test fragments. Areas not directly observable are flagged as judgement-worthy rather than asserted as clean.)*

## ADR conformance: PASS (evidence-limited)

The plan's central architectural constraint — "Preserve trusted system-group commands rather than exposing them directly to web callers" — is exactly the kind of decision an ADR on CQRS/command boundaries would mandate (public bounded-context API vs. internal aggregate commands). This is directly and concretely verified by `web/test/memba_web/membership_command_boundary_test.exs`, which statically scans all of `lib/memba_web` and fails the build if any web source references `Memba.Membership.Commands.AddGroupMember`, `CreateGroup`, or `RemoveGroupMember` directly. This is a strong, durable, convention-enforcing test rather than a one-off assertion, and it matches the plan's Risk note verbatim ("Do not expose them unchanged").

The presentation-layer test fragment (`create_active_member`/group selection authorization test) is consistent with the plan's item 3 requirement to "reauthorize on submit and render fresh membership after a successful transition" and to query candidates through Membership's public API rather than duplicating a full-page template.

I did not have direct sight of the aggregate/command-handler code, the mailer composer, or the specific ADR file(s) under `docs/adr/` this iteration is bound by (none were quoted in the plan or evidence excerpts), so I cannot literally cite ADR numbers/text here. Given the boundary test is authoritative and passing, and `dev check` is green end-to-end, I'm treating ADR conformance as PASS on the evidence available, not as a fully audited certainty.

## ADR violations

None identified in the available evidence.

## Blocking issues

None identified. `dev check` passed on the committed state (189 scenarios / 1415 steps, all green), including the full acceptance suite, and the plan's core architectural guardrail (no raw command exposure to web) has a dedicated regression test. No behavioural gap is visible in the evidence that would warrant rejection.

## Bounded-safe fixes

None identified from the visible evidence. (No refactoring opportunities could be concretely pinpointed without sight of the full diff — see Validation notes.)

## Judgement-worthy non-blocking code-health findings

1. **Files:** Welcome-email composer / mailer integration (not directly visible in evidence excerpts).
   **Smell:** The plan explicitly calls out the risk "Welcome delivery cannot undo membership: avoid conflating domain success and provider outcome." This is a subtle failure-mode boundary (domain commit vs. mailer side-effect) that's easy to get right in the happy path but easy to silently regress later (e.g., a future refactor wrapping mailer + projection in one transaction). Worth a human spot-check that the welcome send is fired-and-forgotten after commit (e.g., via a process/handler outside the aggregate/projector transaction) rather than inline in the command pipeline, since I could not directly inspect this code path.

2. **Files:** `Membership.Club` idempotency handling for `GroupMemberAdded` on duplicate/replay.
   **Smell:** The plan requires "explicit per-use-case command results or new-event metadata to distinguish a new addition from an idempotent no-op; never infer that distinction by racing a projection preflight." This is exactly the kind of race-prone pattern that's easy to accidentally reintroduce (checking projection state before deciding to emit an event). Given only test-file tails were visible, this should get a targeted read of the aggregate's `add_member`/duplicate-handling code by a human or a follow-up focused pass, even though `dev check`'s green acceptance run is reassuring behaviourally.

3. **Files:** Web-layer authorization/query boundary generally.
   **Smell:** The boundary test is a good static guardrail, but it only catches direct fully-qualified references to the three named internal commands. If the actual implementation introduces a *new* internal-only command/module later for a related purpose, the allowlist-style test won't catch it automatically — it's an enumerated blacklist, not a structural boundary (e.g., a context `@moduledoc` visibility contract or `mix xref` check). Not a defect now, but worth noting as a maintenance risk for future iterations extending this area.

4. **Scope discipline:** The plan explicitly defers leave/removal controls to iteration 064. Confirm (not verified directly here) that no incidental removal/leave UI or backend surfaced during this work — the evidence didn't show any such addition, and acceptance criteria don't mention it, so this is very likely fine, but flagged for completeness given it's an explicit scope boundary called out twice in the plan (Notes and Risks sections).

## Suggested fixes

None required to accept. If maintainers want to close the residual uncertainty from limited evidence visibility, a short follow-up spot-check of (a) the aggregate's duplicate-add branch and (b) the welcome-mailer trigger point relative to the commit boundary would fully retire items 1–2 above.

## Validation notes

- `dev check` (`dev ci`) ran to completion on the committed state: 189 scenarios / 1415 steps, all passed, including staff/club-slug and other regression suites — no failures, no skips reported in the visible tail.
- Preflight sandbox compiled cleanly (dependency graph including Commanded/EventStore adapter, Phoenix, Swoosh, etc.) with no errors.
- Direct evidence reviewed: `membership_command_boundary_test.exs` (verifies the ADR-relevant "no raw command exposure to web" constraint via static source scan) and a presentation-layer authorization test fragment for member/conversation row filtering.
- **Material limitation:** the `collect_implementation_evidence` stage output was truncated (6,149 lines omitted) so the full diff, aggregate code, mailer composer, LiveView/HEEx picker component, and migrations were not directly visible to this review. The ACCEPT decision rests on (a) the plan-conformance gate already having passed per the task framing, (b) a fully green `dev check` including the full Cucumber/acceptance suite, and (c) the one directly-visible architectural guardrail test matching the plan's stated central risk. Confidence is set to Medium specifically because of this visibility gap, not because of any observed defect.