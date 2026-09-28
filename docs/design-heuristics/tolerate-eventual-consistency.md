# Tolerate eventual consistency when the consequences are acceptable

When a read model lags behind a change, don't treat the delay itself as a defect. First ask:

- How likely is someone to encounter the stale view?
- What's the worst realistic thing that could happen during that window?
- What could they see or do that they could not see or do before?

A page may briefly show an option that no longer works. It is acceptable for the person to get a clear refusal or error when they try it, provided the command checks their current authority and does not make the change. If the stale view itself could cause meaningful harm, raise that specific risk instead of requiring every view to be immediately consistent.

This is an application for friendly volunteer clubs, not a high-risk security system. That context matters when judging how much protection a brief window warrants.

When reviewing a possible edge case, explain the likelihood and the concrete incremental harm. Say when either is unknown; do not turn a hypothetical timing window into a new policy without discussing its consequences.

## Example: iteration 066

A former club admin could briefly see a Members page they had been allowed to see until recently. They might see updates made since losing access, but opening the page does not add anyone. An attempted Add must be refused after their authority has been removed.
