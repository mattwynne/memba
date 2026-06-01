defmodule Memba.CucumberConfigurationTest do
  use Memba.EventSourcedCase, async: false

  alias Cucumber.Discovery
  alias Cucumber.Runtime
  alias Gherkin.Step
  alias Memba.Membership

  @member_message_background_steps [
    {"Given", "Kootenay Mountaineering Club is a club", 6},
    {"And", "Nelson Paddling Club is a club", 7},
    {"And", "Alice, Bob, Carol, and Dana are people", 8},
    {"And", "Pat is a person", 9},
    {"And", "Alice, Bob, Carol, and Dana are members of Kootenay Mountaineering Club", 10},
    {"And", "Pat is a member of Nelson Paddling Club", 11}
  ]

  @member_message_scenarios [
    {"Alice sends a club message",
     [
       {"When",
        "Alice sends the message \"Trip planning night\" to Kootenay Mountaineering Club members",
        16},
       {"Then",
        "Alice should see the message \"Trip planning night\" in Kootenay Mountaineering Club",
        17},
       {"And", "Alice should see the message was addressed to Alice, Bob, Carol, and Dana", 18},
       {"And", "Alice should not see Pat in the addressed members", 19},
       {"And", "Alice should see every addressed member's receipt status as \"Sending\"", 20}
     ]},
    {"Alice sees different receipt statuses for different members",
     [
       {"Given",
        "Alice has sent the message \"Trip planning night\" to Kootenay Mountaineering Club members",
        25},
       {"And", "Bob's email for \"Trip planning night\" has been reported as delivered", 26},
       {"And",
        "Carol's email for \"Trip planning night\" has been reported as bounced because \"mailbox does not exist\"",
        27},
       {"And", "Dana has opened the email for \"Trip planning night\"", 28},
       {"When", "Alice views the message \"Trip planning night\"", 29},
       {"Then",
        "Alice should see Bob's receipt status for \"Trip planning night\" as \"Delivered\"", 30},
       {"And",
        "Alice should see Carol's receipt status for \"Trip planning night\" as \"Delivery problem\"",
        31},
       {"And", "Alice should see Dana's receipt status for \"Trip planning night\" as \"Opened\"",
        32},
       {"And",
        "Alice should see Alice's receipt status for \"Trip planning night\" as \"Sending\"", 33}
     ]},
    {"Bob sees the same shared receipt statuses",
     [
       {"Given",
        "Alice has sent the message \"Trip planning night\" to Kootenay Mountaineering Club members",
        36},
       {"And", "Bob's email for \"Trip planning night\" has been reported as delivered", 37},
       {"And",
        "Carol's email for \"Trip planning night\" has been reported as delayed because \"recipient server is temporarily unavailable\"",
        38},
       {"When", "Bob views the message \"Trip planning night\"", 39},
       {"Then",
        "Bob should see Alice's receipt status for \"Trip planning night\" as \"Sending\"", 40},
       {"And", "Bob should see Bob's receipt status for \"Trip planning night\" as \"Delivered\"",
        41},
       {"And",
        "Bob should see Carol's receipt status for \"Trip planning night\" as \"Delivery problem\"",
        42}
     ]}
  ]

  @operator_background_steps [
    {"Given", "Kootenay Mountaineering Club is a club", 6},
    {"And", "Alice, Bob, and Carol are people", 7},
    {"And", "Alice, Bob, and Carol are members of Kootenay Mountaineering Club", 8}
  ]

  @operator_scenarios [
    {"Deliveries from different messages appear together",
     [
       {"Given",
        "Alice has sent the message \"Trip planning night\" to Kootenay Mountaineering Club members",
        13},
       {"And",
        "Alice has sent the message \"Avalanche bulletin\" to Kootenay Mountaineering Club members",
        14},
       {"When",
        "Bob's email for \"Trip planning night\" is reported as delayed because \"recipient server is temporarily unavailable\"",
        15},
       {"And",
        "Carol's email for \"Avalanche bulletin\" is reported as bounced because \"mailbox does not exist\"",
        16},
       {"Then", "operators should see Bob's delivery for \"Trip planning night\" as \"delayed\"",
        17},
       {"And",
        "operators should see Bob's delivery reason \"recipient server is temporarily unavailable\"",
        18},
       {"And", "operators should see Carol's delivery for \"Avalanche bulletin\" as \"bounced\"",
        19},
       {"And", "operators should see Carol's delivery reason \"mailbox does not exist\"", 20}
     ]},
    {"Spam complaints keep the provider reason",
     [
       {"Given",
        "Alice has sent the message \"Trip planning night\" to Kootenay Mountaineering Club members",
        23},
       {"When",
        "Bob's email for \"Trip planning night\" is reported as a spam complaint because \"recipient marked the message as spam\"",
        24},
       {"Then",
        "operators should see Bob's delivery for \"Trip planning night\" as \"spam complaint\"",
        25},
       {"And",
        "operators should see Bob's delivery reason \"recipient marked the message as spam\"", 26}
     ]},
    {"Opens are visible after delivery",
     [
       {"Given",
        "Alice has sent the message \"Trip planning night\" to Kootenay Mountaineering Club members",
        29},
       {"And", "Bob's email for \"Trip planning night\" has been reported as delivered", 30},
       {"When", "Bob opens the email for \"Trip planning night\"", 31},
       {"Then", "operators should see Bob's delivery for \"Trip planning night\" as \"opened\"",
        32}
     ]}
  ]

  @authentication_scenarios [
    {"Logged-out visitor sees a club marketing page",
     [
       {"Given", "Alice is a member of Kootenay Mountaineering Club", 7},
       {"When", "Robin opens the Kootenay Mountaineering Club page", 8},
       {"Then", "Robin should see the Kootenay Mountaineering Club marketing page", 9},
       {"And", "the club page should show Powered by Memba in the footer", 10}
     ]},
    {"A club member signs in and sees their club",
     [
       {"Given", "Alice is a member of Kootenay Mountaineering Club", 15},
       {"When", "Alice requests a sign-in link for their email address", 16},
       {"Then", "Alice should receive a sign-in link", 17},
       {"When", "Alice follows the sign-in link", 18},
       {"Then", "Alice should be signed in", 19},
       {"And", "Alice should see Kootenay Mountaineering Club in their clubs", 20},
       {"When", "Alice opens the Kootenay Mountaineering Club page", 21},
       {"Then", "Alice should see they are signed in on the club page", 22},
       {"And", "the club page should show Powered by Memba in the footer", 23}
     ]},
    {"A club member with memberships in two clubs sees both clubs",
     [
       {"Given", "Alice is a member of Kootenay Mountaineering Club", 26},
       {"And", "Alice is a member of Nelson Paddling Club", 27},
       {"When", "Alice requests a sign-in link for their email address", 28},
       {"Then", "Alice should receive a sign-in link", 29},
       {"When", "Alice follows the sign-in link", 30},
       {"Then", "Alice should be signed in", 31},
       {"And", "Alice should see Kootenay Mountaineering Club in their clubs", 32},
       {"And", "Alice should see Nelson Paddling Club in their clubs", 33}
     ]},
    {"New Memba staff sign themselves up",
     [
       {"Given", "Pat is not a member of any club", 38},
       {"When", "Pat requests a sign-in link for \"pat@memba.io\"", 39},
       {"Then", "Pat should receive a sign-in link", 40},
       {"When", "Pat follows the sign-in link", 41},
       {"Then", "Pat should be signed in as Memba staff", 42},
       {"And", "Pat should be on the staff-only homepage", 43}
     ]},
    {"Memba staff who are also club members can use both kinds of access",
     [
       {"Given", "Pat is a member of Kootenay Mountaineering Club", 46},
       {"When", "Pat requests a sign-in link for \"pat@memba.io\"", 47},
       {"Then", "Pat should receive a sign-in link", 48},
       {"When", "Pat follows the sign-in link", 49},
       {"Then", "Pat should be signed in as Memba staff", 50},
       {"And", "Pat should be on the staff-only homepage", 51},
       {"And", "Pat should be able to see Kootenay Mountaineering Club in their clubs", 52}
     ]},
    {"Unknown person requests a sign-in link",
     [
       {"Given", "Robin is not a member of any club", 57},
       {"When", "Robin requests a sign-in link for their email address", 58},
       {"Then", "Robin should not receive a sign-in link", 59}
     ]},
    {"A signed-out person cannot reuse a sign-in link",
     [
       {"Given", "Alice is a member of Kootenay Mountaineering Club", 64},
       {"And", "Alice has received a sign-in link for their email address", 65},
       {"And", "Alice has already followed the sign-in link", 66},
       {"And", "Alice has signed out", 67},
       {"When", "Alice follows the same sign-in link again", 68},
       {"Then", "Alice should not be signed in", 69}
     ]},
    {"Reopening a used sign-in link after signing in",
     [
       {"Given", "Alice is a member of Kootenay Mountaineering Club", 72},
       {"And", "Alice has received a sign-in link for their email address", 73},
       {"And", "Alice has already followed the sign-in link", 74},
       {"When", "Alice follows the same sign-in link again", 75},
       {"Then", "Alice should still be signed in", 76},
       {"And", "Alice should be on the homepage", 77}
     ]},
    {"Following an expired sign-in link",
     [
       {"Given", "Alice is a member of Kootenay Mountaineering Club", 82},
       {"And", "Alice has received a sign-in link for their email address", 83},
       {"And", "the sign-in link has expired", 84},
       {"When", "Alice follows the sign-in link", 85},
       {"Then", "Alice should not be signed in", 86}
     ]},
    {"Following a link that Memba did not issue",
     [
       {"When", "Robin follows a sign-in link that Memba did not issue", 91},
       {"Then", "Robin should not be signed in", 92}
     ]},
    {"Staff signs in after trying to open the staff-only area",
     [
       {"Given", "Pat is not a member of any club", 97},
       {"And", "Pat has tried to open the staff-only area", 98},
       {"When", "Pat requests a sign-in link for \"pat@memba.io\"", 99},
       {"Then", "Pat should receive a sign-in link", 100},
       {"When", "Pat follows the sign-in link", 101},
       {"Then", "Pat should be signed in as Memba staff", 102},
       {"And", "Pat should be on the staff-only homepage", 103}
     ]},
    {"Staff signs out",
     [
       {"Given", "Pat is not a member of any club", 108},
       {"When", "Pat requests a sign-in link for \"pat@memba.io\"", 109},
       {"Then", "Pat should receive a sign-in link", 110},
       {"When", "Pat follows the sign-in link", 111},
       {"Then", "Pat should be signed in as Memba staff", 112},
       {"When", "Pat signs out", 113},
       {"Then", "Pat should be signed out", 114}
     ]},
    {"Club member signs out from a club page",
     [
       {"Given", "Alice is a member of Kootenay Mountaineering Club", 117},
       {"When", "Alice requests a sign-in link for their email address", 118},
       {"Then", "Alice should receive a sign-in link", 119},
       {"When", "Alice follows the sign-in link", 120},
       {"Then", "Alice should be signed in", 121},
       {"When", "Alice opens the Kootenay Mountaineering Club page", 122},
       {"And", "Alice signs out", 123},
       {"Then", "Alice should be signed out", 124}
     ]}
  ]

  @required_membership_background_steps [
    "Kootenay Mountaineering Club is a club",
    "Nelson Paddling Club is a club",
    "Alice, Bob, Carol, and Dana are people",
    "Pat is a person",
    "Alice, Bob, Carol, and Dana are members of Kootenay Mountaineering Club",
    "Pat is a member of Nelson Paddling Club"
  ]

  @required_member_message_scenario_steps for {_scenario_name, steps} <-
                                                @member_message_scenarios,
                                              {_keyword, text, _line} <- steps,
                                              do: text

  @required_operator_scenario_steps for {_scenario_name, steps} <- @operator_scenarios,
                                        {_keyword, text, _line} <- steps,
                                        do: text

  @required_authentication_scenario_steps for {_scenario_name, steps} <-
                                                @authentication_scenarios,
                                              {_keyword, text, _line} <- steps,
                                              do: text

  @required_authentication_step_patterns [
    "{word} is a member of Kootenay Mountaineering Club",
    "Alice is a member of Nelson Paddling Club",
    "{word} is not a member of any club",
    "{word} requests a sign-in link for their email address",
    "{word} requests a sign-in link for {string}",
    "{word} should receive a sign-in link",
    "{word} should not receive a sign-in link",
    "{word} follows the sign-in link",
    "{word} follows the same sign-in link again",
    "{word} follows a sign-in link that Memba did not issue",
    "{word} opens the Kootenay Mountaineering Club page",
    "{word} has received a sign-in link for their email address",
    "{word} has already followed the sign-in link",
    "{word} has signed out",
    "the sign-in link has expired",
    "{word} has tried to open the staff-only area",
    "{word} should be signed in",
    "{word} should be signed in as Memba staff",
    "{word} should not be signed in",
    "{word} should still be signed in",
    "{word} should see they are signed in on the club page",
    "{word} should see the Kootenay Mountaineering Club marketing page",
    "the club page should show Powered by Memba in the footer",
    "{word} signs out",
    "{word} should be signed out",
    "{word} should be on the staff-only homepage",
    "{word} should be on the homepage",
    "{word} should see Kootenay Mountaineering Club in their clubs",
    "{word} should see Nelson Paddling Club in their clubs",
    "{word} should be able to see Kootenay Mountaineering Club in their clubs"
  ]

  @required_messaging_step_patterns [
    "{word} sends the message {string} to Kootenay Mountaineering Club members",
    "{word} has sent the message {string} to Kootenay Mountaineering Club members",
    "{word} email for {string} is reported as delivered",
    "{word} email for {string} has been reported as delivered",
    "{word} email for {string} is reported as delayed because {string}",
    "{word} email for {string} has been reported as delayed because {string}",
    "{word} email for {string} is reported as bounced because {string}",
    "{word} email for {string} has been reported as bounced because {string}",
    "{word} email for {string} is reported as a spam complaint because {string}",
    "{word} opens the email for {string}",
    "{word} has opened the email for {string}",
    "{word} receipt status for {string} should be {string}",
    "{word} should see the message {string} in Kootenay Mountaineering Club",
    "{word} should see the message was addressed to Alice, Bob, Carol, and Dana",
    "{word} should not see {word} in the addressed members",
    "{word} should see every addressed member's receipt status as {string}",
    "{word} views the message {string}",
    "{word} should see {word} receipt status for {string} as {string}",
    "{word} operator deliverability status should be {string}",
    "{word} operator deliverability reason should be {string}",
    "operators should see {word} delivery for {string} as {string}",
    "operators should see {word} delivery reason {string}",
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
      required_shared_feature_steps(shared_feature_paths)
    )

    %Discovery.DiscoveryResult{} = discovery = discover_steps()

    Enum.each(@required_membership_background_steps, fn step_text ->
      assert Map.has_key?(discovery.step_registry, step_text)
    end)

    Enum.each(@required_messaging_step_patterns, fn step_pattern ->
      assert Map.has_key?(discovery.step_registry, step_pattern)
    end)

    Enum.each(@required_authentication_step_patterns, fn step_pattern ->
      assert Map.has_key?(discovery.step_registry, step_pattern)
    end)
  end

  test "domain Cucumber configuration excludes only wip planning scenarios" do
    assert Application.fetch_env!(:cucumber, :tags) == "not @wip"

    operator_feature_file =
      configured_feature_paths()
      |> feature_file_named!("operator_email_deliverability.feature")

    refute File.read!(operator_feature_file) =~ ~r/^\s*@todo-web\s*\n\s*Feature:/m
  end

  test "all member message deliverability scenarios pass through Cucumber runtime" do
    %Discovery.DiscoveryResult{} = discovery = discover_steps()

    member_message_feature_file =
      feature_file_named!(configured_feature_paths(), "member_message_deliverability.feature")

    unless feature_tagged?(member_message_feature_file, "@wip") do
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
          "Carol",
          "Dana"
        ])

        assert_active_member_names(member_context, "Nelson Paddling Club", ["Pat"])

        member_context
        |> Map.put(:scenario_name, scenario_name)
        |> execute_steps(scenario_steps, discovery.step_registry)
      end)
    end
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
        "Bob",
        "Carol"
      ])

      operator_context
      |> Map.put(:scenario_name, scenario_name)
      |> execute_steps(scenario_steps, discovery.step_registry)
    end)
  end

  test "all authentication scenarios pass through Cucumber runtime" do
    %Discovery.DiscoveryResult{} = discovery = discover_steps()

    authentication_feature_file =
      configured_feature_paths()
      |> feature_file_named!("authentication.feature")

    Enum.each(@authentication_scenarios, fn {scenario_name, scenario_steps} ->
      authentication_feature_file
      |> base_cucumber_context(scenario_name)
      |> execute_steps(scenario_steps, discovery.step_registry)
    end)
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

  defp required_shared_feature_steps(shared_feature_paths) do
    member_message_feature_file =
      feature_file_named!(shared_feature_paths, "member_message_deliverability.feature")

    member_message_steps =
      if feature_tagged?(member_message_feature_file, "@wip") do
        []
      else
        @required_membership_background_steps ++ @required_member_message_scenario_steps
      end

    Enum.uniq(
      member_message_steps ++
        @required_operator_scenario_steps ++ @required_authentication_scenario_steps
    )
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

  defp feature_tagged?(feature_file, tag) do
    feature_file
    |> feature_tags()
    |> Enum.member?(tag)
  end

  defp feature_tags(feature_file) do
    feature_file
    |> File.read!()
    |> String.split(~r/\R/)
    |> Enum.reduce_while([], fn line, tags ->
      trimmed = String.trim(line)

      cond do
        trimmed == "" ->
          {:cont, tags}

        String.starts_with?(trimmed, "@") ->
          {:cont, tags ++ String.split(trimmed)}

        String.starts_with?(trimmed, "Feature:") ->
          {:halt, tags}

        true ->
          {:halt, tags}
      end
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
