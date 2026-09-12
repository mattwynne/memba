{
  "preferred_next_label": "validated",
  "outcome": "succeeded",
  "failure_reason": "",
  "suggested_next_ids": [],
  "decision": "READY",
  "confidence": "High",
  "blocking_gaps": [],
  "non_blocking_improvements": [
    "Document a repeatable browser procedure for independently triggering the client/network and server interruption classes so manual validation is less dependent on implementer knowledge.",
    "Name the expected stylesheet location if implementation reveals that Tailwind utilities alone cannot clearly express safe-area or reduced-motion behavior.",
    "State the stop condition explicitly: every acceptance criterion has automated or recorded manual evidence and dev check passes on the delivery candidate."
  ],
  "smallest_viable_iteration": "Set disconnectedTimeout to 1500 milliseconds, replace only the two generated reconnect error toasts in the shared flash group with the approved non-dismissible status pill, preserve ordinary flash behavior, and verify brief, client, server, reconnect, accessibility, responsive, and reduced-motion states.",
  "required_plan_edits": [],
  "validation_plan": [
    "Assert the shared rendered markup has stable client/server IDs, exact copy, initially hidden states, role=status and polite announcement semantics, matching LiveView selectors, automatic phx-connected hiding, shared visual treatment, and no close controls.",
    "Assert the effective LiveSocket configuration uses disconnectedTimeout: 1500 while retaining existing options.",
    "Run existing flash and layout coverage to prove ordinary informational and error flashes remain unchanged.",
    "In a real browser, verify an interruption shorter than 1.5 seconds stays silent.",
    "Verify longer client/network and server interruptions show only their corresponding copy while leaving the current page visible and unobstructed, then disappear on reconnection.",
    "Check narrow and desktop viewport placement, safe-area handling, keyboard focus, pointer interaction, and reduced-motion behavior.",
    "Run dev check on the exact delivery candidate."
  ],
  "context_updates": {
    "codex_review_decision": "READY",
    "codex_review_confidence": "High",
    "codex_review_blocking_gap_count": 0,
    "codex_review_blocking_gaps": "None",
    "codex_review_required_edits": "None"
  }
}