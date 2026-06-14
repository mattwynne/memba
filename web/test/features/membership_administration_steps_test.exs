defmodule Memba.MembershipAdministrationStepsTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.DomainCucumberRunner

  @feature_basename "club_membership_administration.feature"
  @scenario_names [
    "A converted requester can administer membership for their new club",
    "Robin grants membership administration to Alice",
    "Alice cannot grant membership administration to Bob",
    "Robin cannot remove the last Admin"
  ]

  for scenario_name <- @scenario_names do
    test "domain step definitions execute #{scenario_name}" do
      scenario_name = unquote(scenario_name)
      discovery = DomainCucumberRunner.discover()
      feature = feature!(discovery, @feature_basename)
      scenario = scenario!(feature, scenario_name)

      DomainCucumberRunner.run_scenario(
        %{feature: feature, scenario: scenario},
        discovery.step_registry
      )
    end
  end

  defp feature!(discovery, basename) do
    Enum.find(discovery.features, &(Path.basename(&1.file) == basename)) ||
      flunk("Expected #{basename} to be discovered")
  end

  defp scenario!(feature, name) do
    feature
    |> feature_scenarios()
    |> Enum.find(&(&1.name == name)) ||
      flunk("Expected #{feature.file} to include scenario #{inspect(name)}")
  end

  defp feature_scenarios(feature) do
    rule_scenarios =
      feature
      |> Map.get(:rules, [])
      |> Enum.flat_map(& &1.scenarios)

    feature.scenarios ++ rule_scenarios
  end
end
