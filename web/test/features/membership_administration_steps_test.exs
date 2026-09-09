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
  @iteration_059_scenario_names [
    "Robin accepts the first invitation to an empty club",
    "Robin and Alice accept invitations at the same time",
    "Pat cannot remove Robin while Robin is the only Admin",
    "Pat removes Robin after Alice becomes an Admin",
    "Pat cannot remove the club's only member"
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

  test "every iteration-059 step has domain executable plumbing" do
    discovery = DomainCucumberRunner.discover()
    feature = feature!(discovery, @feature_basename)

    iteration_scenarios =
      feature
      |> feature_scenarios()
      |> Enum.filter(&(&1.name in @iteration_059_scenario_names))

    assert length(iteration_scenarios) == length(@iteration_059_scenario_names)

    incorrectly_defined_steps =
      iteration_scenarios
      |> Enum.flat_map(& &1.steps)
      |> Enum.map(&{&1.text, matching_step_definition_count(&1.text, discovery.step_registry)})
      |> Enum.reject(fn {_step_text, definition_count} -> definition_count == 1 end)

    assert incorrectly_defined_steps == []
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

  defp matching_step_definition_count(step_text, step_registry) do
    Enum.count(step_registry, fn
      {{:expression, expression}, _definition} ->
        match?(
          {:match, _args},
          Cucumber.Expression.match(step_text, Cucumber.Expression.compile(expression))
        )

      {{:regex, {source, opts}}, _definition} ->
        source
        |> then(&Regex.compile!("\\A(?:#{&1})\\z", opts))
        |> Regex.match?(step_text)
    end)
  end
end
