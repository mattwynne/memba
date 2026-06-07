defmodule Memba.DomainCucumberRunnerTest do
  use ExUnit.Case, async: true

  alias Memba.DomainCucumberRunner

  test "selects scenarios not excluded by the configured domain tag filter" do
    discovery = DomainCucumberRunner.discover()
    selected = DomainCucumberRunner.selected_scenarios(discovery: discovery)

    selected_names = Enum.map(selected, & &1.scenario.name)

    assert "Alice signs in with her work email address" in selected_names
    assert "Alice receives a club message at her primary email address" in selected_names
    assert "Staff creates a person with primary and alternate email addresses" in selected_names
    assert "Staff changes a person's primary email address" in selected_names

    refute "Visiting the homepage" in selected_names
    refute "Alice belongs to two clubs" in selected_names
    refute "Alice emails the KMC everyone address" in selected_names
  end

  test "selected scenarios do not carry excluded domain tags" do
    selected = DomainCucumberRunner.selected_scenarios()

    excluded_tags = ["not-domain", "todo-domain", "todo", "wip"]

    Enum.each(selected, fn %{feature: feature, scenario: scenario} ->
      tags = Enum.map(feature.tags ++ scenario.tags, &String.trim_leading(&1, "@"))

      assert Enum.all?(excluded_tags, &(&1 not in tags)),
             "Expected #{feature.name} / #{scenario.name} not to include excluded tags; got #{inspect(tags)}"
    end)
  end
end
