{
  "preferred_next_label": "needs_human",
  "outcome": "succeeded",
  "failure_reason": "The iteration plan is not ready for implementation. All reviewers identified unresolved product, scope, acceptance, implementation, technical-design, capability, and validation decisions. In addition, the Claude review branch failed and did not provide the required Markdown review report, so this validation pass must fail closed.",
  "context_updates": {
    "plan_ready": false,
    "plan_needs_fix": false,
    "plan_needs_human": true,
    "repair_coordinator_decision": "NEEDS MATT",
    "repair_coordinator_evidence_complete": false,
    "repair_coordinator_blocking_gap_count": 9,
    "repair_coordinator_blocking_gaps": "Claude reviewer branch failed and lacks the required Markdown report; goal lacks a specific actor, problem, and outcome; scope is unresolved and unbounded; acceptance criteria are subjective and untestable; iteration classification and acceptance-scenario strategy are missing; material business decisions remain open; implementation steps are not actionable; material technical decisions remain open; resulting capability and validation stop condition are undefined",
    "repair_coordinator_questions_for_matt": "What actor and messaging problem is this iteration for, and what measurable outcome should it produce? What is the smallest useful in-scope behavior and what is explicitly out of scope? What exact behavior, edge cases, permissions, and errors must be accepted? Is this behaviour-facing or technical/engineering, and which shared feature scenarios apply or why is Gherkin not useful? What business and UX policies should govern the behavior? What architecture, storage, integration, and testing choices should be used? What exact new capability should exist? What evidence and stop condition will prove completion?"
  }
}