defmodule Memba.CucumberConfigurationTest do
  use Memba.EventSourcedCase, async: false

  alias Cucumber.Discovery
  alias Cucumber.Runtime
  alias Gherkin.Step
  alias Memba.Membership

  @homepage_scenarios [
    {"Visiting the homepage",
     [
       {"When", "I visit the homepage", 3},
       {"Then", "I should see the Memba homepage", 4}
     ]}
  ]

  @member_message_background_steps [
    {"Given", "Kootenay Mountaineering Club is a club", 6},
    {"And", "Nelson Paddling Club is a club", 7},
    {"And", "Alice, Bob, and Carol are people", 8},
    {"And", "Pat is a person", 9},
    {"And", "Alice, Bob, and Carol are members of Kootenay Mountaineering Club", 10},
    {"And", "Pat is a member of Nelson Paddling Club", 11}
  ]

  @member_message_scenarios [
    {"A member sends a club message",
     [
       {"When",
        "Alice sends the message \"Trip planning night\" to Kootenay Mountaineering Club members",
        16},
       {"Then", "the message should be addressed to Alice, Bob, and Carol", 17},
       {"And", "the message should not be addressed to Pat", 18},
       {"And", "each addressed member should have a separate delivery record", 19},
       {"And", "each delivery should be sent through the email provider", 20}
     ]},
    {"A sent message is waiting for delivery confirmation",
     [
       {"When",
        "Alice sends the message \"Trip planning night\" to Kootenay Mountaineering Club members",
        25},
       {"Then", "Bob's receipt status for \"Trip planning night\" should be \"sent\"", 26}
     ]},
    {"A delivered message is shown as delivered",
     [
       {"Given",
        "Alice has sent the message \"Trip planning night\" to Kootenay Mountaineering Club members",
        29},
       {"When", "Bob's email for \"Trip planning night\" is reported as delivered", 30},
       {"Then", "Bob's receipt status for \"Trip planning night\" should be \"delivered\"", 31}
     ]},
    {"A delayed delivery is shown as a delivery problem",
     [
       {"Given",
        "Alice has sent the message \"Trip planning night\" to Kootenay Mountaineering Club members",
        34},
       {"When",
        "Bob's email for \"Trip planning night\" is reported as delayed because \"recipient server is temporarily unavailable\"",
        35},
       {"Then", "Bob's receipt status for \"Trip planning night\" should be \"delivery problem\"",
        36}
     ]},
    {"A bounced delivery is shown as a delivery problem",
     [
       {"Given",
        "Alice has sent the message \"Trip planning night\" to Kootenay Mountaineering Club members",
        39},
       {"When",
        "Bob's email for \"Trip planning night\" is reported as bounced because \"mailbox does not exist\"",
        40},
       {"Then", "Bob's receipt status for \"Trip planning night\" should be \"delivery problem\"",
        41}
     ]},
    {"A spam complaint is shown as a delivery problem",
     [
       {"Given",
        "Alice has sent the message \"Trip planning night\" to Kootenay Mountaineering Club members",
        44},
       {"When",
        "Bob's email for \"Trip planning night\" is reported as a spam complaint because \"recipient marked the message as spam\"",
        45},
       {"Then", "Bob's receipt status for \"Trip planning night\" should be \"delivery problem\"",
        46}
     ]},
    {"An opened message is shown as opened",
     [
       {"Given",
        "Alice has sent the message \"Trip planning night\" to Kootenay Mountaineering Club members",
        49},
       {"And", "Bob's email for \"Trip planning night\" has been reported as delivered", 50},
       {"When", "Bob opens the email for \"Trip planning night\"", 51},
       {"Then", "Bob's receipt status for \"Trip planning night\" should be \"opened\"", 52}
     ]}
  ]

  @operator_background_steps [
    {"Given", "Kootenay Mountaineering Club is a club", 6},
    {"And", "Alice and Bob are people", 7},
    {"And", "Alice and Bob are members of Kootenay Mountaineering Club", 8},
    {"And",
     "Alice has sent the message \"Trip planning night\" to Kootenay Mountaineering Club members",
     9}
  ]

  @operator_scenarios [
    {"A delivered email is visible to operators",
     [
       {"When", "Bob's email for \"Trip planning night\" is reported as delivered", 14},
       {"Then", "Bob's operator deliverability status should be \"delivered\"", 15}
     ]},
    {"A delayed delivery is visible to operators",
     [
       {"When",
        "Bob's email for \"Trip planning night\" is reported as delayed because \"recipient server is temporarily unavailable\"",
        18},
       {"Then", "Bob's operator deliverability status should be \"delayed\"", 19},
       {"And",
        "Bob's operator deliverability reason should be \"recipient server is temporarily unavailable\"",
        20}
     ]},
    {"A bounced delivery is visible to operators",
     [
       {"When",
        "Bob's email for \"Trip planning night\" is reported as bounced because \"mailbox does not exist\"",
        23},
       {"Then", "Bob's operator deliverability status should be \"bounced\"", 24},
       {"And", "Bob's operator deliverability reason should be \"mailbox does not exist\"", 25}
     ]},
    {"A spam complaint is visible to operators",
     [
       {"When",
        "Bob's email for \"Trip planning night\" is reported as a spam complaint because \"recipient marked the message as spam\"",
        28},
       {"Then", "Bob's operator deliverability status should be \"spam complaint\"", 29},
       {"And",
        "Bob's operator deliverability reason should be \"recipient marked the message as spam\"",
        30}
     ]},
    {"An opened email is visible to operators",
     [
       {"Given", "Bob's email for \"Trip planning night\" has been reported as delivered", 33},
       {"When", "Bob opens the email for \"Trip planning night\"", 34},
       {"Then", "Bob's operator deliverability status should be \"opened\"", 35}
     ]}
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

  @required_homepage_scenario_steps for {_scenario_name, steps} <- @homepage_scenarios,
                                        {_keyword, text, _line} <- steps,
                                        do: text

  @required_member_message_scenario_steps for {_scenario_name, steps} <-
                                                @member_message_scenarios,
                                              {_keyword, text, _line} <- steps,
                                              do: text

  @required_operator_scenario_steps for {_scenario_name, steps} <- @operator_scenarios,
                                        {_keyword, text, _line} <- steps,
                                        do: text

  @required_homepage_step_patterns [
    "I visit the homepage",
    "I should see the Memba homepage"
  ]

  @required_messaging_step_patterns [
    "{word} sends the message {string} to Kootenay Mountaineering Club members",
    "{word} has sent the message {string} to Kootenay Mountaineering Club members",
    "{word} email for {string} is reported as delivered",
    "{word} email for {string} has been reported as delivered",
    "{word} email for {string} is reported as delayed because {string}",
    "{word} email for {string} is reported as bounced because {string}",
    "{word} email for {string} is reported as a spam complaint because {string}",
    "{word} opens the email for {string}",
    "{word} receipt status for {string} should be {string}",
    "{word} operator deliverability status should be {string}",
    "{word} operator deliverability reason should be {string}",
    "the message should be addressed to Alice, Bob, and Carol",
    "the message should not be addressed to {word}",
    "each addressed member should have a separate delivery record",
    "each delivery should be sent through the email provider"
  ]

  test "Cucumber discovers shared features and required step definitions" do
    shared_feature_paths = configured_feature_paths()
    assert shared_feature_paths == expected_shared_feature_paths()

    assert_shared_features_contain_steps!(
      shared_feature_paths,
      Enum.uniq(
        @required_homepage_scenario_steps ++
          @required_membership_background_steps ++
          @required_member_message_scenario_steps ++ @required_operator_scenario_steps
      )
    )

    %Discovery.DiscoveryResult{} = discovery = discover_steps()

    Enum.each(@required_membership_background_steps, fn step_text ->
      assert Map.has_key?(discovery.step_registry, step_text)
    end)

    Enum.each(@required_homepage_step_patterns, fn step_pattern ->
      assert Map.has_key?(discovery.step_registry, step_pattern)
    end)

    Enum.each(@required_messaging_step_patterns, fn step_pattern ->
      assert Map.has_key?(discovery.step_registry, step_pattern)
    end)
  end

  test "homepage scenario passes through Cucumber runtime" do
    %Discovery.DiscoveryResult{} = discovery = discover_steps()

    homepage_feature_file =
      feature_file_named!(configured_feature_paths(), "homepage.feature")

    Enum.each(@homepage_scenarios, fn {scenario_name, scenario_steps} ->
      homepage_feature_file
      |> base_cucumber_context(scenario_name)
      |> execute_steps(scenario_steps, discovery.step_registry)
    end)
  end

  test "all member message deliverability scenarios pass through Cucumber runtime" do
    %Discovery.DiscoveryResult{} = discovery = discover_steps()

    member_message_feature_file =
      feature_file_named!(configured_feature_paths(), "member_message_deliverability.feature")

    Enum.each(@member_message_scenarios, fn {scenario_name, scenario_steps} ->
      member_context =
        execute_steps(
          member_message_feature_file,
          "#{scenario_name} Background",
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
      |> Map.put(:scenario_name, scenario_name)
      |> execute_steps(scenario_steps, discovery.step_registry)
    end)
  end

  test "all operator email deliverability scenarios pass through Cucumber runtime" do
    %Discovery.DiscoveryResult{} = discovery = discover_steps()

    shared_feature_paths = configured_feature_paths()

    operator_feature_file =
      feature_file_named!(shared_feature_paths, "operator_email_deliverability.feature")

    Enum.each(@operator_scenarios, fn {scenario_name, scenario_steps} ->
      operator_context =
        execute_steps(
          operator_feature_file,
          "#{scenario_name} Background",
          @operator_background_steps,
          discovery.step_registry
        )

      assert_active_member_names(operator_context, "Kootenay Mountaineering Club", [
        "Alice",
        "Bob"
      ])

      operator_context
      |> Map.put(:scenario_name, scenario_name)
      |> execute_steps(scenario_steps, discovery.step_registry)
    end)
  end

  test "operator email deliverability scenarios are tagged todo-web for browser acceptance" do
    operator_feature_file =
      configured_feature_paths()
      |> feature_file_named!("operator_email_deliverability.feature")

    feature_text = File.read!(operator_feature_file)

    Enum.each(@operator_scenarios, fn {scenario_name, _scenario_steps} ->
      assert scenario_has_tag?(feature_text, scenario_name, "@todo-web"),
             "Expected operator scenario #{inspect(scenario_name)} to be tagged @todo-web"
    end)
  end

  test "browser Cucumber default profile excludes todo-web scenarios" do
    assert browser_cucumber_default_config()["tags"] == "not @todo-web"
  end

  test "Elixir acceptance path includes every shared scenario regardless of todo-web tags" do
    shared_feature_paths = configured_feature_paths()

    shared_scenarios = shared_feature_scenarios(shared_feature_paths)
    shared_scenario_keys = MapSet.new(shared_scenarios, &scenario_key/1)
    acceptance_scenario_keys = MapSet.new(elixir_acceptance_scenario_keys())

    assert acceptance_scenario_keys == shared_scenario_keys

    todo_web_scenario_keys =
      shared_scenarios
      |> Enum.filter(&("@todo-web" in &1.tags))
      |> MapSet.new(&scenario_key/1)

    assert MapSet.size(todo_web_scenario_keys) == length(@operator_scenarios)
    assert MapSet.subset?(todo_web_scenario_keys, acceptance_scenario_keys)
    refute Keyword.has_key?(Application.get_all_env(:cucumber), :tags)
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

  defp browser_cucumber_default_config do
    script = """
    const config = require('./acceptance-tests/cucumber.js');
    process.stdout.write(JSON.stringify(config.default));
    """

    {json, 0} = System.cmd("node", ["-e", script], cd: repo_root(), stderr_to_stdout: true)

    Jason.decode!(json)
  end

  defp repo_root do
    __DIR__
    |> Path.join("../../..")
    |> Path.expand()
  end

  defp discover_steps do
    cache_key = {__MODULE__, :discovery}

    case :persistent_term.get(cache_key, nil) do
      nil ->
        %Discovery.DiscoveryResult{} = discovery = Discovery.discover(features: [])
        :persistent_term.put(cache_key, discovery)
        discovery

      %Discovery.DiscoveryResult{} = discovery ->
        discovery
    end
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

  defp shared_feature_scenarios(paths) do
    Enum.flat_map(paths, fn path ->
      lines =
        path
        |> File.read!()
        |> String.split("\n")

      lines
      |> Enum.with_index()
      |> Enum.flat_map(fn {line, line_index} ->
        trimmed_line = String.trim(line)

        if String.starts_with?(trimmed_line, "Scenario: ") do
          [
            %{
              feature: Path.basename(path),
              line: line_index + 1,
              name: String.replace_prefix(trimmed_line, "Scenario: ", ""),
              tags: scenario_tags_before(lines, line_index)
            }
          ]
        else
          []
        end
      end)
    end)
  end

  defp scenario_key(%{feature: feature, name: name}), do: {feature, name}

  defp elixir_acceptance_scenario_keys do
    [
      {"homepage.feature", @homepage_scenarios},
      {"member_message_deliverability.feature", @member_message_scenarios},
      {"operator_email_deliverability.feature", @operator_scenarios}
    ]
    |> Enum.flat_map(fn {feature, scenarios} ->
      Enum.map(scenarios, fn {scenario_name, _steps} -> {feature, scenario_name} end)
    end)
  end

  defp scenario_has_tag?(feature_text, scenario_name, expected_tag) do
    lines = String.split(feature_text, "\n")

    case Enum.find_index(lines, &(String.trim(&1) == "Scenario: #{scenario_name}")) do
      nil ->
        false

      scenario_line_index ->
        lines
        |> scenario_tags_before(scenario_line_index)
        |> Enum.member?(expected_tag)
    end
  end

  defp scenario_tags_before(lines, scenario_line_index) do
    lines
    |> Enum.take(scenario_line_index)
    |> Enum.reverse()
    |> Enum.take_while(fn line ->
      trimmed_line = String.trim(line)
      trimmed_line == "" || String.starts_with?(trimmed_line, "@")
    end)
    |> Enum.flat_map(&String.split/1)
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
