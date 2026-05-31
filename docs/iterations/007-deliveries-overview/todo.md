# Implementation TODO

- [x] 001 Update the operator feature language around the rule "Operators monitor detailed delivery records across messages", keeping scenarios BRIEF and focused on cross-message visibility, reason preservation, and opened status.
- [ ] 002 Write failing PhoenixTest coverage for `/deliveries`, including records from more than one message and problem reason text.
- [ ] 003 Reshape the public Messaging operator-deliverability query toward a deliveries-overview API, for example an options-shaped list function. Preserve any existing message-scoped needs through options or a compatibility wrapper only if still required by current code.
- [ ] 004 Add the `/deliveries` LiveView route under the browser pipeline.
- [ ] 005 Build the deliveries LiveView as a simple read-only table with stable accessible labels or IDs for browser acceptance.
- [ ] 006 Update browser Cucumber step definitions for `operator_email_deliverability.feature` so operator assertions inspect `/deliveries`.
- [ ] 007 Remove `@todo-web` tags from operator scenarios once they are browser-backed.
- [ ] 008 Verify browser Cucumber still defaults to excluding `@todo-web`, while now including the operator scenarios because they are no longer tagged.
- [ ] 009 Run the browser acceptance suite and `dev check`, fixing any issues.
