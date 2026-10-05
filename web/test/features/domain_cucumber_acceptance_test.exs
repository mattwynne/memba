defmodule Memba.DomainCucumberAcceptanceTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.DomainCucumberRunner

  # These focused suites generate a test for every selected scenario in their feature.
  # Leave their executions in place so `mix test test/features/*_steps_test.exs`
  # remains useful; the full gate runs the other selected scenarios here.
  @focused_feature_files ~w(
    custom_group_access_requests.feature
    custom_group_conversations.feature
    custom_group_creation.feature
    custom_group_membership.feature
  )

  @selected_scenarios DomainCucumberRunner.selected_scenarios()
                      |> Enum.reject(fn selected ->
                        basename = Path.basename(selected.feature.file)

                        basename in @focused_feature_files or
                          (basename == "custom_group_lifecycle.feature" and
                             "iteration-064" in Map.get(selected, :rule, %{tags: []}).tags)
                      end)

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
