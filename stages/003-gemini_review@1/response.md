- Decision: NOT READY
- Confidence: High
- Blocking gaps:
  1. **Goal clarity**: The goal ("Make messaging better for everyone") is vague, lacks a specific business or user outcome, and does not clearly identify the beneficiary.
  2. **Scope focus**: The scope is explicitly "TBD" and completely open-ended, meaning the iteration has no clear boundaries or non-goals.
  3. **Acceptance criteria**: Criteria are subjective ("better", "happier", "works correctly") and impossible to objectively test or automate.
  4. **Acceptance Scenarios**: The plan lacks an `## Acceptance Scenarios / Feature Files` section to outline behavior-facing changes or state why Gherkin would not be useful.
  5. **Unresolved decisions**: Fundamental business and technical decisions (who the users are, what problem is being solved, what the technical approach is) are explicitly left unresolved.
  6. **Implementation plan**: The plan ("Start coding and figure it out") provides zero specific steps, files, or technical details, making it impossible to evaluate the approach.
- Non-blocking improvements:
  1. Add detailed background context with examples of the confusing messaging aspects to justify the priority of the work once the problem is defined.
- Smallest viable iteration: Identify a single, specific point of confusion in a single messaging workflow for a specific user persona (e.g., "Add 'message sent' confirmation toast for users sending direct messages") and implement only that.
- Required plan edits:
  - Define a specific, measurable goal and clearly state the target user.
  - Constrain the scope to a single, coherent outcome and explicitly list non-goals.
  - Write concrete, objective, and testable acceptance criteria that cover both happy paths and edge cases.
  - Add an `## Acceptance Scenarios / Feature Files` section naming the intended Gherkin feature files, or provide an explicit rationale for omitting them.
  - Provide a step-by-step implementation plan detailing the intended technical changes, including specific files, modules, and data model changes.
  - Resolve all open business and technical decisions prior to starting implementation.
  - Define a concrete validation plan explaining how to prove the specific capability was successfully added.
- Validation plan: Success will be proven when all defined (and currently missing) objective acceptance criteria are met, automated tests verify the new capability, and manual testing confirms the specific user outcome was achieved.

{
  "context_updates": {
    "gemini_review_decision": "NOT READY",
    "gemini_review_confidence": "High",
    "gemini_review_blocking_gap_count": 6,
    "gemini_review_blocking_gaps": "Goal lacks specific outcome; Scope is unfocused and TBD; Acceptance criteria are subjective; Missing Acceptance Scenarios section; Unresolved business and technical decisions; Implementation plan provides no steps or details",
    "gemini_review_required_edits": "Define a specific goal; Constrain scope; Write objective acceptance criteria; Add Acceptance Scenarios section; Resolve all open decisions; Detail step-by-step implementation plan"
  }
}