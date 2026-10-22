defmodule Memba.Cucumber.MemberProfileSteps do
  use Cucumber.StepDefinition

  import ExUnit.Assertions

  alias Memba.Membership.ClubGroupQueries
  alias Memba.Membership.CommandDispatch
  alias Memba.Membership.PersonCommands
  alias Memba.Membership.PersonQueries
  alias MembaWeb.MemberDashboardQuery

  step "{word} is known as {string}", %{args: [person_name, requested_name]} = context do
    rename_person!(context, person_name, requested_name)
    context
  end

  step "{word} changes their name to {string}",
       %{args: [person_name, requested_name]} = context do
    rename_person!(context, person_name, requested_name)
    context
  end

  step ~r/^(\w+) should be known as "([^"]+)" in (.+)$/,
       %{args: [person_name, expected_name, club_name]} = context do
    person = fetch_person!(context, person_name)
    club_id = fetch_club_id!(context, club_name)

    assert %{name: ^expected_name} =
             Enum.find(
               ClubGroupQueries.list_active_members_of_club(club_id),
               &(&1.id == person.person_id)
             )

    context
  end

  step ~r/^(\w+)'s earlier conversation "([^"]+)" should show "([^"]+)" as its author$/,
       %{args: [person_name, subject, expected_name]} = context do
    person = fetch_person!(context, person_name)
    message = context |> Map.fetch!(:messages) |> Map.fetch!(subject)

    assert {:ok, dashboard} =
             MemberDashboardQuery.load(message.club_id, person.email, nil)

    person_id = person.person_id

    assert %{originator_id: ^person_id, originator_name: ^expected_name} =
             Enum.find(dashboard.message_rows, &(&1.message_id == message.message_id))

    context
  end

  defp rename_person!(context, person_name, requested_name) do
    person = fetch_person!(context, person_name)
    expected_name = PersonQueries.get_person(person.person_id).name

    assert {:ok, command} =
             PersonCommands.prepare_rename(
               %{email: person.email},
               %{name: requested_name, expected_name: expected_name}
             )

    assert :ok = CommandDispatch.dispatch(command, consistency: :strong)

    assert %{name: projected_name} = PersonQueries.get_person(person.person_id)
    assert projected_name == normalize_name(requested_name)
  end

  defp normalize_name(name) do
    name
    |> String.trim()
    |> String.replace(~r/\s+/u, " ")
  end

  defp fetch_person!(context, person_name) do
    context
    |> Map.get(:people, %{})
    |> Map.fetch(person_name)
    |> case do
      {:ok, person} -> person
      :error -> flunk("Expected #{inspect(person_name)} to be present in :people")
    end
  end

  defp fetch_club_id!(context, club_name) do
    context
    |> Map.get(:clubs, %{})
    |> Map.fetch(club_name)
    |> case do
      {:ok, club_id} -> club_id
      :error -> flunk("Expected #{inspect(club_name)} to be present in :clubs")
    end
  end
end
