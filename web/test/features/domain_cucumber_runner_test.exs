defmodule Memba.DomainCucumberRunnerTest do
  use ExUnit.Case, async: true

  alias Memba.DomainCucumberRunner

  test "selects scenarios not excluded by the configured domain tag filter" do
    discovery = DomainCucumberRunner.discover()
    selected = DomainCucumberRunner.selected_scenarios(discovery: discovery)

    selected_names = Enum.map(selected, & &1.scenario.name)

    assert "Alice signs in with her work email address" in selected_names
    assert "Alice receives a club message at her primary email address" in selected_names
    assert "Staff creates a person with primary and alternate email addresses" in selected_names
    assert "Staff changes a person's primary email address" in selected_names
    assert "Robin requests access without gaining immediate club access" in selected_names
    assert "Alice belongs to two clubs" in selected_names
    assert "Alice emails the KMC everyone address" in selected_names
    assert "Staff create a club with the suggested slug" in selected_names

    refute "Visiting the homepage" in selected_names
  end

  test "selected scenarios do not carry excluded domain tags" do
    selected = DomainCucumberRunner.selected_scenarios()

    excluded_tags = ["not-domain", "todo-domain"]

    Enum.each(selected, fn %{feature: feature, scenario: scenario} ->
      tags = Enum.map(feature.tags ++ scenario.tags, &String.trim_leading(&1, "@"))

      assert Enum.all?(excluded_tags, &(&1 not in tags)),
             "Expected #{feature.name} / #{scenario.name} not to include excluded tags; got #{inspect(tags)}"
    end)
  end

  test "unfinished iteration 059 scenarios stay excluded while the later-invitee regression runs" do
    selected_names =
      DomainCucumberRunner.selected_scenarios()
      |> Enum.map(& &1.scenario.name)

    refute "Robin accepts the first invitation to an empty club" in selected_names
    refute "Robin and Alice accept invitations at the same time" in selected_names
    refute "Pat cannot remove Robin while Robin is the only Admin" in selected_names
    refute "Pat removes Robin after Alice becomes an Admin" in selected_names
    refute "Pat cannot remove the club's only member" in selected_names

    assert "Robin invites Dana to join West Coast Paddlers" in selected_names
  end
end
