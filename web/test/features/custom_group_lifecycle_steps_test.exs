defmodule Memba.CustomGroupLifecycleStepsTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.DomainCucumberRunner

  @feature_basename "custom_group_lifecycle.feature"

  @selected_scenarios DomainCucumberRunner.selected_scenarios()
                      |> Enum.filter(fn selected ->
                        Path.basename(selected.feature.file) == @feature_basename and
                          "iteration-064" in selected.rule.tags
                      end)

  for %{scenario: scenario} = selected_scenario <- @selected_scenarios do
    test "domain step definitions execute #{scenario.name}" do
      discovery = DomainCucumberRunner.discover()

      DomainCucumberRunner.run_scenario(
        unquote(Macro.escape(selected_scenario)),
        discovery.step_registry
      )
    end
  end

  test "selects only lifecycle scenarios genuinely covered by domain steps" do
    selected_names = Enum.map(@selected_scenarios, & &1.scenario.name)

    assert length(selected_names) == 8
    assert "Carol's follow resumes for messages posted after she rejoins" in selected_names
    assert "Eve cannot post to empty Board from outside the group" in selected_names

    refute Enum.any?(
             selected_names,
             &String.starts_with?(
               &1,
               "Carol loses access even with an old Board conversation open"
             )
           )
  end
end
