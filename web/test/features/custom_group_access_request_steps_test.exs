defmodule Memba.CustomGroupAccessRequestStepsTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.DomainCucumberRunner

  @feature_basename "custom_group_access_requests.feature"

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

  test "all iteration-066 access-request examples are selected" do
    selected_names = Enum.map(@selected_scenarios, & &1.scenario.name)

    assert length(selected_names) == 3
    assert "Eve asks to join Board" in selected_names

    assert Enum.count(
             selected_names,
             &String.starts_with?(&1, "Someone outside KMC cannot request Board membership")
           ) == 2
  end
end
