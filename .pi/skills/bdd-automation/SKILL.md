---
name: bdd-automation
description: Design trustworthy, maintainable acceptance-test automation across domain, service, and UI boundaries in any technology stack.
---

# BDD automation (draft — review required)

Use when turning agreed examples into executable checks or revising acceptance automation. This skill does not decide product behaviour.

## Acceptance is not a test level

Acceptance tests prove user-relevant behaviour; they need not run end-to-end or through a UI. Acceptance is a **purpose**, orthogonal to the test pyramid's execution levels. The point is to automate customer-facing acceptance tests in whatever way is reasonable from an engineering and test-risk perspective. Fast domain-level execution gives feedback on rules; wider execution gives evidence about the wiring, interface and deployed system.

## Keep scenarios independent of the execution boundary

A scenario uses a domain-language interface; concrete test-side drivers (adapters) carry out its actions and observations at the domain, service or browser boundary. **The same applicable scenario should be able to run at multiple levels** without duplicating its specification. Run slower variants selectively or occasionally; capability does not mean every example runs at every level on every change.

Each adapter must perform the action and observe the relevant result at **its own boundary**, not bypass it with hidden direct calls. Arrange preconditions at the cheapest trustworthy boundary, but do not shortcut the action or outcome under test. Keep external effects behind controllable ports with deterministic fakes where appropriate. A domain run cannot prove a browser transition; a UI-only risk need not have a domain adapter.

## Choose checks by the risk

Scope the probes of a test across the narrowest area that will still prove the point of the test:

- Keep illustrative scenarios focused on one business rule, with concrete data and stakeholder language. Run variants and edge cases quickly against domain/application code. Prefer pushing detailed permutations down to engineer-facing unit/property-based tests, but keep customer-valuable examples in the acceptance tests.
- Test routing, authorization, forms, rendering and other interface behaviour at the narrowest boundary that observes the risk. Use a real browser for outcomes that depend on real-browser behaviour, such as cross-host transitions, history, client-side navigation or connected interaction. Name the risk and observable outcome.
- Keep a few distinct browser journeys for transitions whose user outcome matters. A journey may cross features and be longer than a rule example, but must not replace focused rule examples. Prove each browser-specific risk once across the suite; keep each journey coherent and independently diagnosable.
- Aim for many fast rule examples, targeted interface tests and few costly browser journeys. Use separate integration or manual smoke checks for real external providers where appropriate; disclose meaningful risks left uncovered.

### Do not bypass navigation under test

Ask whether arriving at a page is setup or the behaviour to prove. Direct navigation (`goto`, `visit`, etc.) is valid for setup, deep links, out-of-band emailed URLs, or direct-URL authorization/host checks; assert the relevant response, address or visible outcome. If the risk is following a link, a post-submit redirect, crossing hosts through the UI or client-side navigation, use the actual affordance and assert its resulting location and state. Wait for the relevant event or state, not necessarily a full page load.

**Never click and then unconditionally navigate directly to the expected URL.** It can make a failed link or redirect pass. Investigate the failure; test direct-address behaviour separately if it matters.

## Listen to the tests

Use a customer-facing acceptance check as an outer feedback loop: state an observable outcome, then use smaller, faster tests to shape responsibilities and seams. Awkward or slow setup, infrastructure coupling, and hard-to-observe or hard-to-diagnose outcomes are design feedback. Consider clearer ports, adapters, completion signals or responsibility boundaries instead of accumulating test workarounds. These are heuristics, not a demand to redesign for every difficult test. Prefer production-useful observability and swappable integration boundaries over product behaviour or hooks added solely to satisfy automation. Do not add custom product-side JavaScript merely for tests; fix broken user interactions on their own merits within authorized scope.

## Keep checks maintainable

Express the responsibility and significant example values in the readable check; put incidental invocation details and fixture mechanics in small reusable support. Name repeated action/outcome patterns for the concept they reveal without abstracting repetition that is clearer left explicit. Keep important preconditions visible and mutable scenario state isolated. Assert the actual outcome, not merely a success message. Synchronize on observable completion without arbitrary sleeps; make failures diagnostic. Do not suppress a failing check or silently move it to a boundary that cannot observe its risk. [Emery's worked example](references/dale-emery-maintainable-acceptance-tests.md) and [Meszaros's pattern notes](references/gerard-meszaros-xunit-test-patterns.md) offer details for refactoring helpers, fixtures, doubles and assertions when needed.

When summarizing an automation approach, name its rule examples, browser risks (if any), proving boundaries, pending coverage and deliberate omissions. Ask the person responsible for the scenarios when a coverage trade-off or new product interaction is material.

## Sources

These sources ground the guidance; the references hold attribution and evidence limits rather than prescribing every choice above.

- [Ham Vocke, “The Practical Test Pyramid”](https://martinfowler.com/articles/practical-test-pyramid.html#acceptance) (on Martin Fowler's site): acceptance purpose versus pyramid level.
- [Dale H. Emery, “Writing Maintainable Automated Acceptance Tests”](https://dhemery.com/pdf/writing_maintainable_automated_acceptance_tests.pdf): [notes](references/dale-emery-maintainable-acceptance-tests.md).
- [Gerard Meszaros, *xUnit Test Patterns*](http://xunitpatterns.com/): [notes](references/gerard-meszaros-xunit-test-patterns.md).
- [Steve Freeman and Nat Pryce, *Growing Object-Oriented Software, Guided by Tests*](https://www.informit.com/store/growing-object-oriented-software-guided-by-tests-9780321503626): [reference from accessible excerpts, figures and author commentary](references/freeman-pryce-goos-acceptance-tdd.md), not a full-book reading.
- [RiverGlide, “Refactoring page objects — The Screenplay Pattern”](https://www.slideshare.net/RiverGlide/refactoring-page-objects-the-screenplay-pattern): [notes](references/riverglide-screenplay-pattern.md) on actors, tasks and questions; this skill's multi-boundary adapters are a separate choice.
- [Seb Rose, “Introduction to Formulation”](https://cucumber.io/blog/bdd/introduction-to-formulation/) and [Gáspár Nagy, “Clean up bad BDD scenarios”](https://gasparnagy.com/2019/05/clean-up-bad-bdd-scenarios/): focused rule examples versus deliberate journeys.
- [Nat Pryce, CukenFest 2017 video](https://www.youtube.com/watch?v=Fk4rCn4YLLU) and [CukeUp slides](https://speakerdeck.com/npryce/having-our-cake-and-eating-it-at-cukeup-2017): [condensed reading edition](references/nat-pryce-cukenfest-2017-edited-transcript.md) and [complete uncorrected auto-captions](references/nat-pryce-cukenfest-2017-auto-transcript.txt). Milliseconds applies to in-memory tests, not browser execution.
