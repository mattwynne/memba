defmodule Memba.CustomGroupMembershipStepsTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.DomainCucumberRunner

  @feature_basename "custom_group_membership.feature"

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

  test "implemented membership examples are selected" do
    selected_names = Enum.map(@selected_scenarios, & &1.scenario.name)

    assert length(selected_names) == 15
    assert "Bob adds Carol without becoming a club admin" in selected_names
    assert "Dan adds Carol without joining Board himself" in selected_names
    assert "Dan adds himself before reading Board's discussions" in selected_names
    assert "Adding Carol again does not welcome her a second time" in selected_names
    assert "Board membership cannot grant Eve club-admin authority" in selected_names
    assert "Bob removes Alice without removing her club authority" in selected_names
    assert "Dan removes Bob without joining Board himself" in selected_names
    assert "Eve cannot remove Bob while outside Board" in selected_names
    assert "Bob cannot leave Everyone while remaining an active club member" in selected_names
    assert "The last club admin cannot leave Admin using custom-group controls" in selected_names

    assert Enum.count(
             selected_names,
             &String.starts_with?(&1, "Eve cannot change Board's membership")
           ) == 2

    assert Enum.count(
             selected_names,
             &String.starts_with?(&1, "Bob cannot add someone who is not an active KMC member")
           ) == 3
  end
end
