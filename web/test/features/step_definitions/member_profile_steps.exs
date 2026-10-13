defmodule Memba.Cucumber.MemberProfileSteps do
  use Cucumber.StepDefinition
  import ExUnit.Assertions
  alias Memba.Membership.{CommandDispatch, PersonCommands, ClubCommands, AddMember}

  step "Alice is a member of Rockies Cycling Co-op", context do
    club_id = Memba.ID.generate(:club)

    {:ok, club} =
      ClubCommands.prepare_create(%{
        club_id: club_id,
        name: "Rockies Cycling Co-op",
        slug: "rockies-cycling"
      })

    assert :ok = CommandDispatch.dispatch(club, consistency: :strong)
    person_id = context.people["Alice"].person_id

    {:ok, membership} =
      AddMember.prepare(%{
        club_id: club_id,
        person_id: person_id,
        membership_id: Memba.ID.generate(:membership)
      })

    assert :ok = CommandDispatch.dispatch(membership, consistency: :strong)
    Map.put(context, :clubs, Map.put(context.clubs, "Rockies Cycling Co-op", club_id))
  end

  step "Alice is known as {string}", %{args: [name]} = context do
    case get_in(context, [:people, "Alice"]) do
      nil ->
        person_id = Memba.ID.generate(:person)

        {:ok, command} =
          PersonCommands.prepare_create(%{
            person_id: person_id,
            name: name,
            email: "alice.profile@example.test"
          })

        assert :ok = CommandDispatch.dispatch(command, consistency: :strong)

        Map.put(
          context,
          :people,
          Map.put(Map.get(context, :people, %{}), "Alice", %{
            person_id: person_id,
            email: "alice.profile@example.test"
          })
        )

      _id ->
        assert :ok = rename(context, name, person(context).name)
        context
    end
  end

  step "Alice started the conversation {string} in Kootenay Mountaineering Club",
       %{args: [subject]} = context do
    start_conversation(context, "Kootenay Mountaineering Club", subject)
  end

  step "Alice replied to the conversation {string} in Rockies Cycling Co-op",
       %{args: [subject]} = context do
    context = start_conversation(context, "Rockies Cycling Co-op", subject)
    message_id = Memba.ID.generate(:message)

    {:ok, command} =
      Memba.Messaging.PostMemberMessageReply.prepare(%{
        message_id: message_id,
        conversation_id: context.profile_messages[subject],
        sender_id: person(context).person_id,
        body: "An earlier reply."
      })

    assert :ok = Memba.Messaging.CommandDispatch.dispatch(command, consistency: :strong)

    Map.put(context, :profile_reply, message_id)
  end

  step "Alice changes their name to {string}", %{args: [name]} = context do
    assert :ok = rename(context, name, person(context).name)
    context
  end

  step ~r/^Alice should be known as "([^"]+)" in (.+)$/, %{args: [name, club_name]} = context do
    member =
      Enum.find(
        Memba.Membership.ClubGroupQueries.list_active_members_of_club(context.clubs[club_name]),
        &(&1.id == person(context).person_id)
      )

    assert member.name == name
    context
  end

  step "Alice's earlier conversation {string} should show {string} as its author",
       %{args: [subject, name]} = context do
    detail = detail(context, context.profile_messages[subject])
    assert detail.sender_name == name
    assert Enum.find(detail.conversation_entries, &(&1.kind == :original)).sender_name == name
    context
  end

  step "Alice's earlier reply to {string} should show {string} as its author",
       %{args: [subject, name]} = context do
    detail = detail(context, context.profile_messages[subject])

    reply =
      Enum.find(detail.conversation_entries, &(&1.message.message_id == context.profile_reply))

    assert reply.kind == :reply
    assert reply.sender_name == name
    context
  end

  step "Alice tries to change their name to {string}", %{args: [name]} = context do
    Map.put(context, :profile_rename_result, rename(context, name, person(context).name))
  end

  step "Alice should be told {string}", %{args: [message]} = context do
    assert {:error, reason} = context.profile_rename_result
    assert MembaWeb.PersonNameTransition.error_message(reason) == message
    context
  end

  step "Alice should be known as {string}", %{args: [name]} = context do
    assert person(context).name == name
    context
  end

  step "Alice began changing their name when it was {string}", %{args: [name]} = context do
    person_id = Memba.ID.generate(:person)

    {:ok, command} =
      PersonCommands.prepare_create(%{
        person_id: person_id,
        name: name,
        email: "alice.stale@example.test"
      })

    assert :ok = CommandDispatch.dispatch(command, consistency: :strong)

    context
    |> Map.put(:people, %{"Alice" => %{person_id: person_id, email: "alice.stale@example.test"}})
    |> Map.put(:profile_baseline, name)
  end

  step "Alice has since changed their name to {string}", %{args: [name]} = context do
    assert :ok = rename(context, name, person(context).name)
    context
  end

  step "Alice submits the older change to {string}", %{args: [name]} = context do
    Map.put(context, :profile_rename_result, rename(context, name, context.profile_baseline))
  end

  step "the change should be rejected because their name changed elsewhere", context do
    assert {:error, {:name_conflict, latest}} = context.profile_rename_result
    assert latest == person(context).name
    Map.put(context, :profile_confirmed_value, latest)
  end

  step "Alice confirms replacing {string} with {string}", %{args: [displayed, name]} = context do
    assert displayed == context.profile_confirmed_value
    assert :ok = rename(context, name, context.profile_confirmed_value)
    context
  end

  defp person(context), do: Memba.Membership.PersonQueries.get_person(context.people["Alice"].person_id)

  defp rename(context, name, expected) do
    id = person(context).person_id

    with {:ok, command} <-
           PersonCommands.prepare_rename(%{person_id: id}, %{
             person_id: id,
             name: name,
             expected_name: expected
           }) do
      CommandDispatch.dispatch(command, consistency: :strong)
    end
  end

  defp start_conversation(context, club_name, subject) do
    message_id = Memba.ID.generate(:message)

    {:ok, command} =
      Memba.Messaging.SendClubMessage.prepare_current_member(%{
        message_id: message_id,
        club_id: context.clubs[club_name],
        sender_id: person(context).person_id,
        subject: subject,
        body: "An earlier conversation."
      })

    assert :ok = Memba.Messaging.CommandDispatch.dispatch(command, consistency: :strong)

    Map.put(
      context,
      :profile_messages,
      Map.put(Map.get(context, :profile_messages, %{}), subject, message_id)
    )
  end

  defp detail(context, message_id) do
    message = Memba.Messaging.MessageQueries.get_message(message_id)

    {:ok, detail} =
      MembaWeb.MemberMessageDetail.load(
        %{"club_id" => message.club_id, "message_id" => message_id},
        [Memba.Membership.ClubGroupQueries.get_club(message.club_id)],
        %{email: person(context).email}
      )

    detail
  end
end
