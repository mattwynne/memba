{
  "outcome": "succeeded",
  "failure_reason": "",
  "review": {
    "decision": "NOT READY",
    "confidence": "High",
    "blocking_gaps": [
      "The goal does not identify the intended actor, the messaging problem to solve, or a concrete user or business outcome.",
      "The scope is explicitly TBD and potentially includes unrelated UI, data-model, provider, permissions, analytics, retry, and template work; no boundaries or non-goals are established.",
      "The acceptance criteria are subjective and not objectively testable. They do not define expected behaviour, happy paths, edge cases, permissions, error states, or data and state changes.",
      "The plan does not classify the iteration as behaviour-facing or technical. Given the apparent behaviour-facing scope, it also lacks an Acceptance Scenarios / Feature Files section and provides no rationale for omitting stakeholder-readable Gherkin scenarios.",
      "Core business and technical decisions remain unresolved, and the implementation plan does not identify ordered steps, affected files or modules, interfaces, integrations, migrations, or tests.",
      "The expected new capability is unknown, and the validation plan supplies neither concrete proof of success nor a clear stop condition."
    ],
    "non_blocking_improvements": [
      "After choosing a concrete outcome, document relevant dependencies, risks, and an explicit baseline if success will be measured quantitatively.",
      "Record major scope tradeoffs so later iterations can distinguish intentionally deferred messaging improvements from omissions."
    ],
    "smallest_viable_iteration": "Choose one clearly identified user group and one observable messaging problem on one product surface. Deliver one end-to-end behaviour change for that problem, including its primary success path and the most important permission or failure case. Exclude provider, storage, analytics, retry, template, and broader UI work unless directly required by that single behaviour.",
    "required_plan_edits": [
      "Rewrite the goal to name the actor, current problem, desired behaviour, and user or business outcome.",
      "Replace the TBD scope with one bounded behaviour and add explicit non-goals.",
      "Resolve who the users are, which messaging problem is being addressed, what behaviour changes, and what constitutes success.",
      "Replace subjective acceptance criteria with concrete Given/When/Then-style observable outcomes covering the success path and relevant edge, permission, error, and state-change cases.",
      "Classify the iteration as behaviour-facing or technical. If behaviour-facing, add an Acceptance Scenarios / Feature Files section naming the shared feature file and scenarios; otherwise explain why Gherkin adds no useful stakeholder-readable examples.",
      "Resolve the open technical decisions and provide ordered implementation steps naming expected modules, files, interfaces, persistence changes, integrations, and test layers where applicable.",
      "State the exact capability available after completion and define specific validation commands, automated tests, acceptance scenarios, and the pass/fail stop condition."
    ],
    "validation_plan": "Run the named shared Cucumber scenarios for the selected user-visible behaviour, targeted automated tests for the affected domain and interface layers, and the repository's required dev check. Verify the primary success path and the identified permission or failure case, including any expected persisted state or external interaction. The iteration succeeds only when every acceptance criterion and named scenario passes and no unresolved business or technical decisions remain."
  },
  "context_updates": {
    "codex_review_decision": "NOT READY",
    "codex_review_confidence": "High",
    "codex_review_blocking_gap_count": 6,
    "codex_review_blocking_gaps": "Goal lacks a specific actor, problem, and outcome; Scope is TBD and unbounded; Acceptance criteria are subjective and omit required paths and state details; Behaviour classification and feature scenarios or rationale are absent; Business and technical decisions plus actionable implementation steps remain unresolved; New capability, proof of success, and stop condition are undefined",
    "codex_review_required_edits": "Define the actor, problem, changed behaviour, and outcome; Bound scope and state non-goals; Add objective acceptance criteria for success and relevant edge, permission, error, and state cases; Classify the iteration and add named feature scenarios or an explicit rationale; Resolve business and technical decisions and provide ordered file/module-specific implementation steps; Define the new capability, validation procedure, and stop condition"
  }
}