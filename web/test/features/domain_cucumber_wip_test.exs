# Ordinary `mix test` loads this file without defining an extra test. The focused
# command opts in so its red-development cardinality guard cannot alter the green gate.
if System.get_env("MEMBA_WIP_TEST") == "1" do
  defmodule Memba.DomainCucumberWipTest do
    use Memba.EventSourcedCase, async: false

    alias Memba.DomainCucumberRunner

    case DomainCucumberRunner.one_wip_scenario() do
      {:ok, %{feature: feature, scenario: scenario} = selected_scenario} ->
        @tag :domain_cucumber
        @tag feature_file: feature.file
        @tag scenario_name: scenario.name
        test "WIP: #{Path.basename(feature.file)}: #{scenario.name}" do
          discovery = DomainCucumberRunner.discover()

          DomainCucumberRunner.run_scenario(
            unquote(Macro.escape(selected_scenario)),
            discovery.step_registry
          )
        end

      {:error, message} ->
        test "requires exactly one domain/application @wip scenario" do
          flunk(unquote(message))
        end
    end
  end
end
