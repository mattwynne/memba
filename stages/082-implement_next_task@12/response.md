Implemented task 012 and left it unchecked for independent review.

1. Selected todo line

`- [ ] 012 Ensure removal completion/rapid re-add cannot reactivate stale follows.`

2. Changes made

- Updated [membership.ex](/workspace/memba/web/lib/memba/membership.ex:430) so `Membership.remove_member/2` waits for both:
  - system-group membership reconciliation;
  - the custom-group follow-clearing policy.
- Preserved caller-supplied consistency options while ensuring both lifecycle handlers are included. `:strong` retains its existing meaning.
- Documented that successful member removal returns only after these consequences complete.
- Added a deterministic regression test in [clear_removed_group_member_follows_policy_test.exs](/workspace/memba/web/test/memba/membership/clear_removed_group_member_follows_policy_test.exs:79) which:
  - suspends the follow-clearing handler;
  - proves member removal remains blocked after the system-group handler finishes;
  - resumes the handler and verifies removal completes;
  - immediately rejoins the person using a new membership identity;
  - verifies Everyone membership returns, custom membership remains inactive, and the old conversation follow remains cleared.
- No acceptance feature files were changed.

3. Focused validation

- TDD red run: the new ordering test failed because removal returned while the follow-clearing handler was suspended.
- Focused policy test: 4 tests, 0 failures.
- Combined membership lifecycle and Messaging follow suite: 16 tests, 0 failures.
- `dev check --quick`: 1,319 tests, 0 failures.
- `git diff --check`: passed.

4. Todo state

Still unchecked and ready for independent review:

`- [ ] 012 Ensure removal completion/rapid re-add cannot reactivate stale follows.`

5. Todo changes

None. No tasks were split, added, removed, reordered, or checked.

6. ADR conformance

- ADR 0002: removal and follow changes remain command/event workflows with an explicit consistency guarantee.
- ADR 0007: cross-context follow clearing remains inside the existing policy and uses Messaging’s public API.
- ADR 0009: no cross-context behavior was added to projectors.
- ADR 0011: rejoining uses a new caller-generated membership identity.
- ADR 0022: the application service waits for the domain-specific follow-clearing completion signal instead of relying on projection timing.
- ADR 0024: the Club aggregate remains the authoritative membership lifecycle boundary; this change only coordinates completion of its downstream consequences.