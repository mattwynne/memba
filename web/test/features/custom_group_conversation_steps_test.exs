defmodule Memba.CustomGroupConversationStepsTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.DomainCucumberRunner

  @feature_basename "custom_group_conversations.feature"

  @selected_scenarios DomainCucumberRunner.selected_scenarios()
                      |> Enum.filter(&(Path.basename(&1.feature.file) == @feature_basename))

  for %{scenario: scenario} = selected_scenario <- @selected_scenarios do
    test "domain step definitions execute #{scenario.name}" do
      discovery = DomainCucumberRunner.discover()

      DomainCucumberRunner.run_scenario(
        unquote(Macro.escape(selected_scenario)),
        discovery.step_registry
      )
    end
  end

  test "all iteration-062 conversation examples are selected" do
    selected_names = Enum.map(@selected_scenarios, & &1.scenario.name)

    assert length(selected_names) == 13
    assert "Bob starts a Board discussion without addressing Everyone" in selected_names
    assert "Carol's email reply stays in Bob's Board conversation" in selected_names
    assert "Carol stops following but can still read Board's agenda" in selected_names
  end
end
