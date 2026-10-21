defmodule Memba.Cucumber.MemberProfileSteps do
  use Cucumber.StepDefinition

  import ExUnit.Assertions

  alias Memba.Accounts
  alias Memba.Membership.ClubGroupQueries
  alias Memba.Membership.CommandDispatch
  alias Memba.Membership.PersonCommands
  alias Memba.Membership.PersonQueries
  alias MembaWeb.MemberMessageDetail

  step "{word} is known as {string}", %{args: [person_label, requested_name]} = context do
    %{person_id: person_id} =
      context
      |> Map.get(:people, %{})
      |> Map.fetch!(person_label)

    person = PersonQueries.get_person(person_id)

    assert {:ok, command} =
             PersonCommands.prepare_rename(person, %{
               name: requested_name,
               expected_name: person.name
             })

    assert :ok = CommandDispatch.dispatch(command, consistency: :strong)
    assert %{person_id: ^person_id, name: ^requested_name} = PersonQueries.get_person(person_id)

    context
  end

  step "{word} changes their name to {string}",
       %{args: [person_label, requested_name]} = context do
    %{person_id: person_id} = person_from_context!(context, person_label)
    person = PersonQueries.get_person(person_id)

    assert {:ok, command} =
             PersonCommands.prepare_rename(person, %{
               name: requested_name,
               expected_name: person.name
             })

    assert :ok = CommandDispatch.dispatch(command, consistency: :strong)
    assert %{person_id: ^person_id, name: ^requested_name} = PersonQueries.get_person(person_id)

    context
  end

  step "{word} should be known as {string} in Kootenay Mountaineering Club",
       %{args: [person_label, expected_name]} = context do
    assert_club_member_name(context, person_label, expected_name, "Kootenay Mountaineering Club")
  end

  step "{word} should be known as {string} in Rockies Cycling Co-op",
       %{args: [person_label, expected_name]} = context do
    assert_club_member_name(context, person_label, expected_name, "Rockies Cycling Co-op")
  end

  step ~r/^(\S+)'s earlier conversation "([^"]+)" should show "([^"]+)" as its author$/,
       %{args: [person_label, subject, expected_name]} = context do
    %{person_id: person_id} = person_from_context!(context, person_label)
    %{message_id: message_id} = message_from_context!(context, subject)

    detail = load_message_detail!(context, person_label, subject, message_id)

    assert %{
             kind: :original,
             sender_name: ^expected_name,
             message: %{message_id: ^message_id, sender_id: ^person_id}
           } =
             Enum.find(
               detail.conversation_entries,
               &(&1.message.message_id == message_id)
             )

    context
  end

  step ~r/^(\S+)'s earlier reply to "([^"]+)" should show "([^"]+)" as its author$/,
       %{args: [person_label, subject, expected_name]} = context do
    %{person_id: person_id} = person_from_context!(context, person_label)
    %{message_id: conversation_id} = message_from_context!(context, subject)

    assert [reply] =
             context
             |> Map.fetch!({:replies, subject})
             |> Map.values()
             |> Enum.filter(
               &(&1.sender_id == person_id and &1.conversation_id == conversation_id)
             )

    detail = load_message_detail!(context, person_label, subject, reply.message_id)

    assert %{
             kind: :reply,
             sender_name: ^expected_name,
             message: %{message_id: reply_message_id, sender_id: ^person_id}
           } =
             Enum.find(
               detail.conversation_entries,
               &(&1.message.message_id == reply.message_id)
             )

    assert reply_message_id == reply.message_id

    context
  end

  defp assert_club_member_name(context, person_label, expected_name, club_name) do
    %{person_id: person_id} = person_from_context!(context, person_label)
    club_id = context |> Map.get(:clubs, %{}) |> Map.fetch!(club_name)

    assert %{id: ^person_id, name: ^expected_name} =
             Enum.find(
               ClubGroupQueries.list_active_members_of_club(club_id),
               &(&1.id == person_id)
             )

    context
  end

  defp load_message_detail!(context, person_label, subject, message_id) do
    %{email: email} = person_from_context!(context, person_label)
    %{club_id: club_id} = message_from_context!(context, subject)

    active_club =
      email
      |> Accounts.list_active_clubs_for_email()
      |> Enum.find(&(&1.club_id == club_id))

    assert active_club

    assert {:ok, detail} =
             MemberMessageDetail.load(
               %{"club_id" => club_id, "message_id" => message_id},
               [active_club],
               %{email: email}
             )

    detail
  end

  defp message_from_context!(context, subject) do
    context
    |> Map.fetch!(:messages)
    |> Map.fetch!(subject)
  end

  defp person_from_context!(context, person_label) do
    context
    |> Map.get(:people, %{})
    |> Map.fetch!(person_label)
  end
end
