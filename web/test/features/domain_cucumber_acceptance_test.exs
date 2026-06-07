defmodule Memba.DomainCucumberAcceptanceTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.DomainCucumberRunner

  @selected_scenarios DomainCucumberRunner.selected_scenarios()

  for %{feature: feature, scenario: scenario} = selected_scenario <- @selected_scenarios do
    @tag :domain_cucumber
    @tag feature_file: feature.file
    @tag scenario_name: scenario.name
    test "#{Path.basename(feature.file)}: #{scenario.name}" do
      discovery = DomainCucumberRunner.discover()

      DomainCucumberRunner.run_scenario(
        unquote(Macro.escape(selected_scenario)),
        discovery.step_registry
      )
    end
  end
end
