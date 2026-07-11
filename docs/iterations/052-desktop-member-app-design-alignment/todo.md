# Implementation TODO

- [x] 001 Inspect the current design-system CSS definitions for `.message*`, `.composer*`, and `.page-title` and port them into `web/assets/css/app.css` using exact class names.
- [ ] 002 Rewrite the message detail HEEx/component markup to use the ported semantic classes while preserving IDs/test hooks and LiveView events needed by existing tests.
- [ ] 003 Apply the five message-detail decisions: `All conversations`, no helper sentence, inline `Replying as`, quiet posted note, compact member-app footer only.
- [ ] 004 Remove the desktop club-home `Prefer email?` card/copy.
- [ ] 005 Adjust shared member app layout/footer rendering so authenticated member app pages use only the compact app footer and public/marketing/legal pages keep the full public footer.
- [ ] 006 Add/update the allowed `@iteration-052` Cucumber scenarios and supporting step definitions if needed.
- [ ] 007 Add/update Phoenix/LiveView/rendered tests for: ported class usage on message entries/composer/title;
- [ ] 008 Add/update Phoenix/LiveView/rendered tests for: absence of helper sentence and green success-alert styling;
- [ ] 009 Add/update Phoenix/LiveView/rendered tests for: `All conversations` back link;
- [ ] 010 Add/update Phoenix/LiveView/rendered tests for: no `Prefer email?` card on desktop club home;
- [ ] 011 Add/update Phoenix/LiveView/rendered tests for: no full public footer on member app pages while public pages retain it.
- [ ] 012 Run the detailed gallery-walk validation below, then `dev check`.
