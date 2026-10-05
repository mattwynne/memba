# Historical rehearsal: iteration 066, one scenario

Date: 2026-10-05. **Non-publishing experiment.** Source: pre-implementation
iteration 066 checkpoint `2a2b908a0`, with the approved scenario's delivered
step driver copied in as test support and its feature-level `@todo` moved to
scenario-level `@todo`. No 066 production implementation was copied in. The
bounded target was only `Eve asks to join Board` from
`acceptance-tests/features/custom_group_access_requests.feature`, not the
remaining outline, browser journey, or the complete old plan.

## Observations

- A local feasibility probe selected exactly one scenario and reached the
  `When Eve requests access to Board` step; it failed because product API
  `Memba.Messaging.request_group_access/2` was undefined/private. It was not
  an undefined Cucumber step. Preparation checkpoint:
  `356571606d...` on `experiment/066-bdd-replay`.
- Initial Fabro run `01M45DQEMEZR4RKFW9C3DV954H` stopped before its shot:
  `max_visits=1` prevents the **first** node visit in Fabro 0.316. The graph
  was fixed to 2 and a contract test added. Run
  `01M45DWA57W39TZZPJTYS7KEN0` then stopped in `call_shot` because OpenAI
  returned `server_is_overloaded` after its retries; no product change.
- Run `01M45DZW9SVESGQ8DBXYK8SV20` **did** call and verify the shot. Its
  deterministic gate added the scenario-level `@wip` and recorded
  `predicted_red`, exit 2, with the exact missing-product-API diagnostic in
  `.delivery/goal-directed-bdd/before.json`. OpenAI overload later interrupted
  the worker before it saved an implementation. Its checkpoint was retained;
  no green or task acceptance was fabricated.
- The fail-closed resume branch `experiment/066-bdd-resume` (source
  `20dd6c3b3a594dc2e45792e42f18416002feb96e`) reused that saved red,
  checked its trusted gate commit and feature hash, and switched the pilot's
  model to Anthropic `claude-sonnet-5` after a successful model/tool probe.
  Run **`01M45EKSVMVZJF071CH3WCHVZV` succeeded**. One worker changed only
  `web/lib/memba/messaging.ex` and new focused unit tests; the same selected
  scenario passed (**177 generated tests; one selected, zero failures**).
  Independent review accepted on its first pass after directly rerunning the
  scenario and checking the 5 new tests and the 284-test Messaging suite.
  Only the verdict gate removed `@wip`. No human interruption occurred in
  the successful continuation.
- The final, non-publishing `dev ci` exited **0** on the accepted tree
  `09214aa1b72ff94915f29d5bf9f2b3c71bb7b1e0`: **1,578 web tests, zero
  failures; 5 browser scenarios and 88 steps passed**. The accepted, final
  gate and report commits have identical trees. `origin/main` remained
  `e16727a5898efb24401c9830b2ce4a53df20c526`; no PR or merge occurred.

## Cost, interpretation and next proof

The successful continuation reported **25m22s / $6.55**. It spent ~14m50s
in the worker, ~3m36s in independent review and ~5m35s in the final gate.
The preceding failed starts and model outage add setup/wall time: the first
launch began at 06:58:54 UTC and the successful run ended at ~07:40:51 UTC,
so the full attempted experiment took ~42 minutes, not 25 minutes. A
preceding OpenAI-interrupted attempt reported another ~$0.59. These are
observations for **one historical scenario**, not a claim that the new process
is faster than the original complete iteration or ready for live publication.

The pilot proved real before-implementation intended red, minimal behaviour
plus unit tests, observed green, independent review and exact-tree full
quality gate. It did **not** exercise review rejection/rework, multiple
scenarios, browser-scenario WIP, an actual human policy question, restart
after a partially edited worker candidate, full-plan conformance or guarded
publication. The gate currently anchors `before.json` to its trusted Fabro
checkpoint; before production use, also pin the green/review artifact to its
trusted checkpoint and verify the independent reviewer made no candidate
edits. The hard-coded scenario and non-publishing final node must become an
approved-manifest loop and real final-artifact gate rather than an implicit
promotion of this one-scenario rehearsal.
