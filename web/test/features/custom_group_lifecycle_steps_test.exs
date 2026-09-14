defmodule Memba.CustomGroupLifecycleStepsTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.DomainCucumberRunner

  @feature_basename "custom_group_lifecycle.feature"

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

  test "all iteration-062 lifecycle examples are selected" do
    selected_names = Enum.map(@selected_scenarios, & &1.scenario.name)

    assert selected_names == [
             "Carol's club departure ends Board and Trips membership",
             "Returning to KMC does not put Carol back into Board or Trips"
           ]
  end
end
