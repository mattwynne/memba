{
  "context_updates": {
    "gemini_review_decision": "NOT READY",
    "gemini_review_confidence": "High",
    "gemini_review_blocking_gap_count": 2,
    "gemini_review_blocking_gaps": "Open technical decisions on idempotency approach and Resend payload schema are unresolved; Missing explicit database schema and migration steps for storing provider_message_id to support idempotency.",
    "gemini_review_required_edits": "Resolve the open technical decisions regarding Resend payload fields and idempotency mechanism; Add explicit implementation steps for Ecto migrations to store provider_message_id and enforce unique constraints to prevent duplicate messages from webhook retries."
  }
}