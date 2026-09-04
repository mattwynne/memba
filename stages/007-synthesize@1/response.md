{
  "preferred_next_label": "needs_human",
  "context_updates": {
    "plan_ready": false,
    "plan_needs_fix": false,
    "plan_needs_human": true,
    "provisional_decision": "NEEDS MATT",
    "review_evidence_complete": true,
    "review_consensus": "All three reviewers concluded NOT READY with High confidence. The plan requires material product, scope, acceptance, and technical decisions that GPT-5.6 Sol must not invent.",
    "blocking_gap_count": 8,
    "blocking_gaps": [
      "The goal does not define a concrete actor, problem, or observable outcome.",
      "The scope is unbounded and lacks a selected smallest useful slice and explicit non-goals.",
      "Acceptance criteria are subjective and cannot objectively establish completion.",
      "The iteration is not classified as behaviour-facing or technical/engineering, and the required acceptance-scenario decision is absent.",
      "Material product and business behaviour decisions remain open.",
      "The implementation plan contains no actionable ordered steps or identified change surfaces.",
      "Material technical design and testing decisions remain open.",
      "The expected capability, validation evidence, and completion stop condition are undefined."
    ],
    "questions_for_matt": [
      "Which user or role has what specific messaging problem, and what observable outcome should this iteration produce?",
      "What is the single smallest useful slice, and which UI, data-model, provider, permission, analytics, retry, and template changes are explicitly out of scope?",
      "What exact behaviour should occur on the happy path and on relevant permission, error, edge, and state-change paths?",
      "Is this a behaviour-facing/domain-policy iteration or a technical/engineering iteration?",
      "If behaviour-facing or domain-policy-related, which shared Cucumber feature files and scenarios cover it, or why would Gherkin not add useful stakeholder-readable examples?",
      "If shared acceptance feature files will change, which exact files may change, what kind of change is allowed in each, why, and how will coverage be preserved or intentionally changed?",
      "Which application layers, modules, interfaces, storage changes, integrations, and testing approach should the implementation use?",
      "What exact new capability will exist, what evidence will prove it works, and what is the completion stop condition?"
    ]
  }
}