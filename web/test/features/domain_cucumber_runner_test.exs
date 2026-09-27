defmodule Memba.DomainCucumberRunnerTest do
  use ExUnit.Case, async: true

  alias Memba.DomainCucumberRunner

  test "selects untagged domain rules but not browser journeys or future work" do
    feature =
      Gherkin.Parser.parse("""
      Feature: Runner selection
        Scenario: Untagged business rule
          Given a domain condition

        @journey
        Scenario: Browser journey
          Given a browser condition

        @todo
        Scenario: Future business rule
          Given a future condition

        Rule: Current rule
          Scenario: Current rule example
            Given another domain condition

        @journey
        Rule: Browser rule
          Scenario: Browser rule example
            Given another browser condition
      """)

    selected = DomainCucumberRunner.selected_scenarios(discovery: %{features: [feature]})

    assert Enum.map(selected, & &1.scenario.name) == [
             "Untagged business rule",
             "Current rule example"
           ]
  end

  test "feature-level tags exclude every scenario in a journey or future feature" do
    for tag <- ["@journey", "@todo"] do
      feature =
        Gherkin.Parser.parse("""
        #{tag}
        Feature: Tagged feature
          Scenario: Example
            Given a condition
        """)

      assert DomainCucumberRunner.selected_scenarios(discovery: %{features: [feature]}) == []
    end
  end

  test "discovered domain scenarios contain neither browser nor future tags at any level" do
    selected = DomainCucumberRunner.selected_scenarios()

    assert selected != []

    Enum.each(selected, fn %{feature: feature, scenario: scenario} = selected_scenario ->
      tags =
        feature.tags ++
          Map.get(Map.get(selected_scenario, :rule, %{}), :tags, []) ++ scenario.tags

      assert Enum.all?(tags, &(&1 not in ["@journey", "@todo"])),
             "Expected #{feature.name} / #{scenario.name} to be a domain example; got #{inspect(tags)}"
    end)
  end
end
