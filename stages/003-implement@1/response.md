I’ll start by inspecting the existing Phoenix app and then implement the iteration end-to-end in this order:

1) infra/deps/config (EventStore, projections, cucumber),
2) Membership context + tests,
3) Messaging context + tests,
4) projections/query APIs + tests,
5) shared-feature Cucumber step definitions,
6) run `mix precommit` (and `devenv shell mix precommit` if available) and fix failures.

I’ll proceed now and report back with concrete changes and test results.