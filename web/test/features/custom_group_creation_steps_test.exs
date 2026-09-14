defmodule Memba.CustomGroupCreationStepsTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.DomainCucumberRunner

  @feature_basename "custom_group_creation.feature"

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

  test "all domain-intended iteration-062 creation examples are selected" do
    selected_names = Enum.map(@selected_scenarios, & &1.scenario.name)

    assert length(selected_names) == 13
    assert "Alice creates Board and belongs to it immediately" in selected_names
    assert "Alice and Dan both try to create Board" in selected_names
    assert "A stored address identifies a group even when its name is different" in selected_names
    refute "Alice sees the email address before creating Trips" in selected_names
  end
end
