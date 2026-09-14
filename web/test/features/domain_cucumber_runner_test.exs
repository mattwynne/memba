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

  test "iteration 059 scenarios and the later-invitee regression run at the domain layer" do
    selected_names =
      DomainCucumberRunner.selected_scenarios()
      |> Enum.map(& &1.scenario.name)

    assert "Robin accepts the first invitation to an empty club" in selected_names
    assert "Robin and Alice accept invitations at the same time" in selected_names
    assert "Pat cannot remove Robin while Robin is the only Admin" in selected_names
    assert "Pat removes Robin after Alice becomes an Admin" in selected_names
    assert "Pat cannot remove the club's only member" in selected_names
    assert "Robin invites Dana to join West Coast Paddlers" in selected_names
  end

  test "iteration 061 scenarios run at the domain layer except browser-only state examples" do
    selected_names =
      DomainCucumberRunner.selected_scenarios()
      |> Enum.map(& &1.scenario.name)

    assert "Alice sees Admin without belonging to it" in selected_names
    assert "Alice follows an Admin group link" in selected_names
    assert "Alice can find Board but cannot read its discussions" in selected_names
    assert "Bob inspects Board's members without joining" in selected_names
    assert "Another club's member cannot discover KMC groups" in selected_names

    outline_names =
      Enum.filter(
        selected_names,
        &String.starts_with?(
          &1,
          "Neither ordinary membership nor club administration grants Board access"
        )
      )

    assert Enum.count(outline_names) == 6
    refute "Bob has Members but no Conversations while outside Board" in selected_names
    refute "Alice returns to a group she has not joined" in selected_names
  end

  test "iteration 062 custom-group creation scenarios run at the domain layer except live input examples" do
    selected_names =
      DomainCucumberRunner.selected_scenarios()
      |> Enum.map(& &1.scenario.name)

    assert "Alice creates Board and belongs to it immediately" in selected_names
    assert "Alice and Dan both try to create Board" in selected_names
    assert "Board receives its own club-scoped email address" in selected_names
    assert "A stored address identifies a group even when its name is different" in selected_names
    refute "Alice sees the email address before creating Trips" in selected_names
  end

  test "iteration 062 custom-group conversation scenarios run at the domain layer" do
    selected_names =
      DomainCucumberRunner.selected_scenarios()
      |> Enum.map(& &1.scenario.name)

    assert "Bob starts a Board discussion without addressing Everyone" in selected_names
    assert "Eve emails Board while remaining outside it" in selected_names
    assert "Bob receives the ordinary recipient copy of his own Board email" in selected_names
    assert "Carol's email reply stays in Bob's Board conversation" in selected_names
    assert "Carol follows Board's agenda while Alice does not" in selected_names
    assert "Carol stops following but can still read Board's agenda" in selected_names

    assert Enum.count(
             selected_names,
             &String.starts_with?(
               &1,
               "Someone outside the active club membership cannot email Board"
             )
           ) == 3

    assert Enum.count(
             selected_names,
             &String.starts_with?(
               &1,
               "Sending Board an email does not let Eve or Dan reply to it"
             )
           ) == 4
  end

  test "iteration 062 custom-group lifecycle scenarios run at the domain layer" do
    selected_names =
      DomainCucumberRunner.selected_scenarios()
      |> Enum.map(& &1.scenario.name)

    assert "Carol's club departure ends Board and Trips membership" in selected_names
    assert "Returning to KMC does not put Carol back into Board or Trips" in selected_names
  end
end
