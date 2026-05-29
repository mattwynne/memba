defmodule Memba.CucumberConfigurationTest do
  use Memba.EventSourcedCase, async: false

  alias Cucumber.Discovery
  alias Cucumber.Runtime
  alias Gherkin.Step
  alias Memba.Membership
  alias Memba.Membership.Projections.Club, as: ClubProjection

  @club_name "Kootenay Mountaineering Club"
  @club_background_step "#{@club_name} is a club"

  test "Cucumber discovers shared features and the selected Background step passes" do
    shared_feature_paths = configured_feature_paths()
    assert shared_feature_paths == expected_shared_feature_paths()

    assert shared_feature_paths_contain_step?(
             shared_feature_paths,
             "Given #{@club_background_step}"
           )

    %Discovery.DiscoveryResult{} = discovery = Discovery.discover(features: [])
    assert Map.has_key?(discovery.step_registry, @club_background_step)

    feature_file =
      feature_file_containing_step!(shared_feature_paths, "Given #{@club_background_step}")

    step = %Step{keyword: "Given", text: @club_background_step, line: 6}

    context =
      Runtime.execute_step(
        %{
          feature_file: feature_file,
          scenario_name: "selected Background step smoke test",
          step_history: []
        },
        step,
        discovery.step_registry
      )

    club_id = get_in(context, [:clubs, @club_name])

    assert %ClubProjection{club_id: ^club_id, name: @club_name} = Membership.get_club(club_id)
  end

  defp configured_feature_paths do
    :cucumber
    |> Application.fetch_env!(:features)
    |> List.wrap()
    |> Enum.flat_map(&Path.wildcard/1)
    |> Enum.map(&Path.expand/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp expected_shared_feature_paths do
    __DIR__
    |> Path.join("../../../acceptance-tests/features/**/*.feature")
    |> Path.expand()
    |> Path.wildcard()
    |> Enum.map(&Path.expand/1)
    |> Enum.sort()
  end

  defp shared_feature_paths_contain_step?(paths, gherkin_step_text) do
    Enum.any?(paths, fn path ->
      path
      |> File.read!()
      |> String.contains?(gherkin_step_text)
    end)
  end

  defp feature_file_containing_step!(paths, gherkin_step_text) do
    Enum.find(paths, fn path ->
      path
      |> File.read!()
      |> String.contains?(gherkin_step_text)
    end) || flunk("Expected to find shared Background step: #{gherkin_step_text}")
  end
end
