defmodule Memba.CucumberConfigurationTest do
  use Memba.EventSourcedCase, async: false

  alias Cucumber.Discovery
  alias Cucumber.Runtime
  alias Gherkin.Step
  alias Memba.Membership

  @member_message_background_steps [
    {"Given", "Kootenay Mountaineering Club is a club", 6},
    {"And", "Nelson Paddling Club is a club", 7},
    {"And", "Alice, Bob, and Carol are people", 8},
    {"And", "Pat is a person", 9},
    {"And", "Alice, Bob, and Carol are members of Kootenay Mountaineering Club", 10},
    {"And", "Pat is a member of Nelson Paddling Club", 11}
  ]

  @member_message_scenario_steps [
    {"When",
     "Alice sends the message \"Trip planning night\" to Kootenay Mountaineering Club members",
     16},
    {"Then", "the message should be addressed to Alice, Bob, and Carol", 17},
    {"And", "the message should not be addressed to Pat", 18},
    {"And", "each addressed member should have a separate delivery record", 19},
    {"And", "each delivery should be sent through the email provider", 20}
  ]

  @operator_membership_background_steps [
    {"Given", "Kootenay Mountaineering Club is a club", 6},
    {"And", "Alice and Bob are people", 7},
    {"And", "Alice and Bob are members of Kootenay Mountaineering Club", 8}
  ]

  @required_membership_background_steps [
    "Kootenay Mountaineering Club is a club",
    "Nelson Paddling Club is a club",
    "Alice, Bob, and Carol are people",
    "Pat is a person",
    "Alice, Bob, and Carol are members of Kootenay Mountaineering Club",
    "Pat is a member of Nelson Paddling Club",
    "Alice and Bob are people",
    "Alice and Bob are members of Kootenay Mountaineering Club"
  ]

  @required_member_message_scenario_steps Enum.map(@member_message_scenario_steps, fn {_keyword,
                                                                                       text,
                                                                                       _line} ->
                                            text
                                          end)

  test "Cucumber discovers shared features and the member message scenario passes" do
    shared_feature_paths = configured_feature_paths()
    assert shared_feature_paths == expected_shared_feature_paths()

    assert_shared_features_contain_steps!(
      shared_feature_paths,
      @required_membership_background_steps ++ @required_member_message_scenario_steps
    )

    %Discovery.DiscoveryResult{} = discovery = Discovery.discover(features: [])

    Enum.each(@required_membership_background_steps, fn step_text ->
      assert Map.has_key?(discovery.step_registry, step_text)
    end)

    member_message_feature_file =
      feature_file_named!(shared_feature_paths, "member_message_deliverability.feature")

    member_context =
      execute_steps(
        member_message_feature_file,
        "member message Background smoke test",
        @member_message_background_steps,
        discovery.step_registry
      )

    assert_active_member_names(member_context, "Kootenay Mountaineering Club", [
      "Alice",
      "Bob",
      "Carol"
    ])

    assert_active_member_names(member_context, "Nelson Paddling Club", ["Pat"])

    member_context
    |> Map.put(:scenario_name, "A member sends a club message")
    |> execute_steps(@member_message_scenario_steps, discovery.step_registry)

    operator_feature_file =
      feature_file_named!(shared_feature_paths, "operator_email_deliverability.feature")

    operator_context =
      execute_steps(
        operator_feature_file,
        "operator email membership Background smoke test",
        @operator_membership_background_steps,
        discovery.step_registry
      )

    assert_active_member_names(operator_context, "Kootenay Mountaineering Club", [
      "Alice",
      "Bob"
    ])
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

  defp assert_shared_features_contain_steps!(paths, step_texts) do
    Enum.each(step_texts, fn step_text ->
      assert Enum.any?(paths, fn path ->
               path
               |> File.read!()
               |> String.contains?(step_text)
             end)
    end)
  end

  defp feature_file_named!(paths, basename) do
    Enum.find(paths, &(Path.basename(&1) == basename)) ||
      flunk("Expected to discover shared feature file: #{basename}")
  end

  defp execute_steps(feature_file, scenario_name, steps, step_registry) do
    feature_file
    |> base_cucumber_context(scenario_name)
    |> execute_steps(steps, step_registry)
  end

  defp execute_steps(context, steps, step_registry) do
    Enum.reduce(steps, context, fn {keyword, text, line}, context ->
      step = %Step{keyword: keyword, text: text, line: line}

      Runtime.execute_step(context, step, step_registry)
    end)
  end

  defp base_cucumber_context(feature_file, scenario_name) do
    %{
      feature_file: feature_file,
      scenario_name: scenario_name,
      step_history: []
    }
  end

  defp assert_active_member_names(context, club_name, expected_names) do
    club_id = get_in(context, [:clubs, club_name])

    active_member_names =
      club_id
      |> Membership.list_active_members_of_club()
      |> Enum.map(& &1.name)

    assert active_member_names == expected_names
  end
end
