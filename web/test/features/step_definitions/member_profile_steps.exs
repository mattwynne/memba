defmodule Memba.Cucumber.MemberProfileSteps do
  use Cucumber.StepDefinition

  import ExUnit.Assertions

  alias Memba.Membership.ClubGroupQueries
  alias Memba.Membership.CommandDispatch
  alias Memba.Membership.PersonCommands
  alias Memba.Membership.PersonQueries
  alias MembaWeb.MemberDashboardQuery
  alias MembaWeb.MemberMessageDetailQuery

  step "{word} is known as {string}", %{args: [person_name, requested_name]} = context do
    case get_in(context, [:people, person_name]) do
      nil ->
        create_person(context, person_name, requested_name)

      _person ->
        rename_person!(context, person_name, requested_name)
        context
    end
  end

  step "{word} changes their name to {string}",
       %{args: [person_name, requested_name]} = context do
    rename_person!(context, person_name, requested_name)
    context
  end

  step "{word} tries to change their name to {string}",
       %{args: [person_name, requested_name]} = context do
    person = fetch_person!(context, person_name)
    expected_name = PersonQueries.get_person(person.person_id).name

    result =
      with {:ok, command} <-
             PersonCommands.prepare_rename(
               %{email: person.email},
               %{name: requested_name, expected_name: expected_name}
             ) do
        CommandDispatch.dispatch(command, consistency: :strong)
      end

    Map.put(context, :last_name_change_result, result)
  end

  step "{word} should be told {string}",
       %{args: [_person_name, expected_message]} = context do
    result = Map.fetch!(context, :last_name_change_result)

    assert {:error, :invalid_name} = result

    message =
      case result do
        {:error, :invalid_name} -> "Enter the name your clubs should see."
      end

    assert message == expected_message
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

  step ~r/^(\w+)'s earlier reply to "([^"]+)" should show "([^"]+)" as its author$/,
       %{args: [person_name, subject, expected_name]} = context do
    person = fetch_person!(context, person_name)
    root_message = context |> Map.fetch!(:messages) |> Map.fetch!(subject)
    reply = Map.fetch!(context, :last_reply)
    person_id = person.person_id
    club_id = root_message.club_id
    root_message_id = root_message.message_id

    assert %{
             club_id: ^club_id,
             conversation_id: ^root_message_id,
             sender_id: ^person_id,
             subject: ^subject
           } = reply

    assert {:ok, detail} =
             MemberMessageDetailQuery.load(club_id, root_message_id, person.email)

    reply_message_id = reply.message_id

    assert %{
             kind: :reply,
             message: %{message_id: ^reply_message_id, sender_id: ^person_id},
             sender_name: ^expected_name
           } =
             Enum.find(
               detail.conversation_entries,
               &(&1.message.message_id == reply_message_id)
             )

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

  defp create_person(context, person_name, requested_name) do
    person_id = Memba.ID.generate(:person)
    email = scenario_email(context, person_name)

    assert {:ok, command} =
             PersonCommands.prepare_create(%{
               person_id: person_id,
               name: requested_name,
               email: email
             })

    assert :ok = CommandDispatch.dispatch(command, consistency: :strong)
    assert %{person_id: ^person_id, name: ^requested_name} = PersonQueries.get_person(person_id)

    people =
      context
      |> Map.get(:people, %{})
      |> Map.put(person_name, %{person_id: person_id, email: email})

    Map.put(context, :people, people)
  end

  defp scenario_email(context, person_name) do
    local_part =
      person_name
      |> String.downcase()
      |> String.replace(~r/[^a-z0-9]+/, ".")
      |> String.trim(".")

    suffix =
      context
      |> Map.get(:scenario_name, "scenario")
      |> :erlang.phash2(1_000_000)
      |> Integer.to_string(36)
      |> String.downcase()

    "#{local_part}-#{suffix}@example.test"
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
