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

  test "one WIP outline is one declaration containing all of its expanded rows" do
    feature =
      Gherkin.Parser.parse("""
      Feature: Outline WIP selection
        @wip
        Scenario Outline: Selected outline for <value>
          Given the value <value>

          Examples:
            | value  |
            | first  |
            | second |
      """)
      |> Map.put(:file, "test/fixtures/domain_cucumber/outline_wip.feature")

    assert {:ok, selected_rows} =
             DomainCucumberRunner.one_wip_scenario(discovery: %{features: [feature]})

    assert length(selected_rows) == 2

    assert Enum.map(selected_rows, & &1.scenario.name) == [
             "Selected outline for <value> (row 1)",
             "Selected outline for <value> (row 2)"
           ]

    assert scenario_step_texts(selected_rows) == ["the value first", "the value second"]
  end

  test "one locally WIP Examples declaration contains all and only its expanded rows" do
    feature =
      Gherkin.Parser.parse("""
      Feature: Examples WIP selection
        Scenario Outline: Outline with independently selectable examples for <value>
          Given the value <value>

          @wip
          Examples: selected declaration
            | value  |
            | first  |
            | second |

          Examples: ordinary regression declaration
            | value |
            | third |
      """)
      |> Map.put(:file, "test/fixtures/domain_cucumber/examples_wip.feature")

    assert {:ok, selected_rows} =
             DomainCucumberRunner.one_wip_scenario(discovery: %{features: [feature]})

    assert length(selected_rows) == 2

    assert Enum.map(selected_rows, & &1.scenario.name) == [
             "Outline with independently selectable examples for <value> " <>
               "(selected declaration: row 1)",
             "Outline with independently selectable examples for <value> " <>
               "(selected declaration: row 2)"
           ]

    assert scenario_step_texts(selected_rows) == ["the value first", "the value second"]
  end

  test "outline-level WIP remains one declaration across separate Examples blocks" do
    feature =
      Gherkin.Parser.parse("""
      Feature: Inherited outline WIP
        @wip
        Scenario Outline: One selected outline for <value>
          Given the value <value>

          Examples: first group
            | value |
            | first |

          Examples: second group
            | value  |
            | second |
      """)
      |> Map.put(:file, "test/fixtures/domain_cucumber/inherited_outline_wip.feature")

    assert {:ok, selected_rows} =
             DomainCucumberRunner.one_wip_scenario(discovery: %{features: [feature]})

    assert length(selected_rows) == 2

    assert Enum.map(selected_rows, & &1.scenario.name) == [
             "One selected outline for <value> (first group: row 1)",
             "One selected outline for <value> (second group: row 1)"
           ]

    assert scenario_step_texts(selected_rows) == ["the value first", "the value second"]
  end

  test "separately WIP Examples blocks are separate declarations even on one outline" do
    feature =
      Gherkin.Parser.parse("""
      Feature: Multiple selected Examples declarations
        Scenario Outline: Same outline for <value>
          Given the value <value>

          @wip
          Examples: first selected declaration
            | value       |
            | first       |
            | first-again |

          @wip
          Examples: second selected declaration
            | value  |
            | second |
      """)
      |> Map.put(:file, "features/multiple_examples_wip.feature")

    assert {:error, message} =
             DomainCucumberRunner.one_wip_scenario(discovery: %{features: [feature]})

    assert message =~ "found 2"
  end

  test "identical rows in one WIP declaration remain separate executions" do
    feature =
      Gherkin.Parser.parse("""
      Feature: Repeated WIP rows
        @wip
        Scenario Outline: Repeated value <value>
          Given the value <value>

          Examples:
            | value |
            | same  |
            | same  |
      """)
      |> Map.put(:file, "test/fixtures/domain_cucumber/repeated_wip_rows.feature")

    assert {:ok, selected_rows} =
             DomainCucumberRunner.one_wip_scenario(discovery: %{features: [feature]})

    assert length(selected_rows) == 2

    assert Enum.map(selected_rows, & &1.scenario.name) == [
             "Repeated value <value> (row 1)",
             "Repeated value <value> (row 2)"
           ]

    assert scenario_step_texts(selected_rows) == ["the value same", "the value same"]
  end

  test "inherited feature WIP counts logical scenarios and outlines, not expanded rows" do
    feature =
      Gherkin.Parser.parse("""
      @wip
      Feature: Multiple inherited WIP declarations
        Scenario Outline: First declaration for <value>
          Given the value <value>

          Examples:
            | value  |
            | first  |
            | second |

        Scenario: Second declaration
          Given another condition
      """)
      |> Map.put(:file, "features/inherited_multiple_wip.feature")

    assert {:error, message} =
             DomainCucumberRunner.one_wip_scenario(discovery: %{features: [feature]})

    assert message =~ "found 2"
  end

  test "inherited rule WIP counts logical scenarios and outlines, not expanded rows" do
    feature =
      Gherkin.Parser.parse("""
      Feature: Rule-level WIP selection
        @wip
        Rule: Multiple inherited WIP declarations
          Scenario Outline: First declaration for <value>
            Given the value <value>

            Examples:
              | value  |
              | first  |
              | second |

          Scenario: Second declaration
            Given another condition
      """)
      |> Map.put(:file, "features/inherited_rule_multiple_wip.feature")

    assert {:error, message} =
             DomainCucumberRunner.one_wip_scenario(discovery: %{features: [feature]})

    assert message =~ "found 2"
  end

  test "a WIP Examples declaration excluded by the normal tag filter is not eligible" do
    feature =
      Gherkin.Parser.parse("""
      Feature: Filtered Examples WIP
        Scenario Outline: Filtered outline for <value>
          Given the value <value>

          @wip @todo
          Examples: future declaration
            | value |
            | later |

          Examples: current ordinary regression declaration
            | value |
            | now   |
      """)
      |> Map.put(:file, "test/fixtures/domain_cucumber/filtered_examples_wip.feature")

    assert {:error, message} =
             DomainCucumberRunner.one_wip_scenario(discovery: %{features: [feature]})

    assert message =~ "found none"
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

    assert {:ok, [%{scenario: %{name: "Current red example"}}]} =
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

  defp scenario_step_texts(selected_rows) do
    Enum.map(selected_rows, fn %{scenario: %{steps: [step | _]}} -> step.text end)
  end
end
