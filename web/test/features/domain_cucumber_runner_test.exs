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

  test "selects one WIP scenario using inherited Gherkin tags" do
    feature_tagged =
      Gherkin.Parser.parse("""
      @wip
      Feature: Feature-level WIP
        Scenario: Inherits WIP from its feature
          Given a feature condition
      """)

    rule_and_scenario_tagged =
      Gherkin.Parser.parse("""
      Feature: WIP selection
        @wip
        Rule: Current work
          Scenario: Inherits WIP from its rule
            Given a condition

        Rule: Other work
          @wip
          Scenario: Carries WIP itself
            Given another condition
      """)

    selected =
      DomainCucumberRunner.wip_scenarios(
        discovery: %{features: [feature_tagged, rule_and_scenario_tagged]}
      )

    assert Enum.map(selected, & &1.scenario.name) == [
             "Inherits WIP from its feature",
             "Inherits WIP from its rule",
             "Carries WIP itself"
           ]
  end

  test "WIP selection remains limited to current domain scenarios" do
    feature =
      Gherkin.Parser.parse("""
      Feature: WIP layer selection
        @wip
        Scenario: Current domain example
          Given a condition

        @wip @journey
        Scenario: Browser journey
          Given a browser condition

        @wip @todo
        Scenario: Future domain example
          Given a future condition
      """)

    selected = DomainCucumberRunner.wip_scenarios(discovery: %{features: [feature]})

    assert Enum.map(selected, & &1.scenario.name) == ["Current domain example"]
  end

  test "reports zero and multiple WIP scenarios clearly" do
    no_wip =
      Gherkin.Parser.parse("""
      Feature: No WIP
        Scenario: Ordinary coverage
          Given a condition
      """)

    assert {:error, no_wip_message} =
             DomainCucumberRunner.one_wip_scenario(discovery: %{features: [no_wip]})

    assert no_wip_message =~ "exactly one domain/application scenario tagged @wip"
    assert no_wip_message =~ "found none"

    two_wip =
      Gherkin.Parser.parse("""
      Feature: Too much WIP
        @wip
        Scenario: First WIP
          Given a condition

        @wip
        Scenario: Second WIP
          Given another condition
      """)
      |> Map.put(:file, "features/too_much_wip.feature")

    assert {:error, multiple_wip_message} =
             DomainCucumberRunner.one_wip_scenario(discovery: %{features: [two_wip]})

    assert multiple_wip_message =~ "found 2"
    assert multiple_wip_message =~ "First WIP"
    assert multiple_wip_message =~ "Second WIP"
  end

  test "WIP is still included in ordinary domain regression selection" do
    feature =
      Gherkin.Parser.parse("""
      Feature: Ordinary coverage
        @wip
        Scenario: Current red example
          Given a condition
      """)

    assert [%{scenario: %{name: "Current red example"}}] =
             DomainCucumberRunner.selected_scenarios(discovery: %{features: [feature]})

    assert {:ok, %{scenario: %{name: "Current red example"}}} =
             DomainCucumberRunner.one_wip_scenario(discovery: %{features: [feature]})
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
