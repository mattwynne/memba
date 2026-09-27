# Gáspár Nagy: Clean up bad BDD scenarios

Source: [“Clean up bad BDD scenarios” — Gáspár Nagy](https://gasparnagy.com/2019/05/clean-up-bad-bdd-scenarios/). These are Memba's paraphrased reading notes, not a copy of the article.

## Keep rule examples focused

Nagy applies the **Focused** part of BRIEF to automated scenarios: an illustrative scenario should demonstrate one business rule or acceptance criterion. A long chain of actions and checks (`Given–When–Then–When–Then`) can conceal several rules inside a single test. That makes the rule harder to read and the automated scenario harder to maintain.

When a scenario has accumulated multiple outcomes, identify the separate rules behind those checks and formulate concrete examples for each. Keep incidental setup out of each example unless it is essential to understanding the rule.

## Applying this in Memba

This is guidance for **rule examples**, not a prohibition on intentional user journeys. [ADR 0026](../adr/0026-keep-browser-journeys-distinct-from-domain-examples.md) keeps domain scenarios focused and uses a few explicitly selected, broader browser journeys to exercise real-browser boundaries. A journey should not become the sole specification of all the rules it passes through.
