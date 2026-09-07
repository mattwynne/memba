defmodule Memba.Cucumber.GroupConversationSteps do
  use Cucumber.StepDefinition

  import ExUnit.Assertions

  alias Memba.Membership
  alias Memba.Membership.App, as: MembershipApp
  alias Memba.Membership.Commands.AddGroupMember
  alias Memba.Membership.Commands.CreateGroup
  alias Memba.Membership.SystemGroups
  alias Memba.Messaging

  @club_name "Kootenay Mountaineering Club"

  step ~r/^(.+) are members of the Kootenay Mountaineering Club Trips committee group$/,
       %{args: [person_names_text]} = context do
    person_names = parse_person_list(person_names_text)
    {context, group_id} = ensure_group(context, @club_name, "Trips committee")

    Enum.each(person_names, fn person_name ->
      assert :ok =
               MembershipApp.dispatch(
                 %AddGroupMember{
                   club_id: club_id!(context, @club_name),
                   group_id: group_id,
                   membership_id: membership_id!(context, @club_name, person_name),
                   person_id: person_id!(context, person_name)
                 },
                 consistency: :strong
               )

      assert Membership.active_member_of_group?(group_id, person_id!(context, person_name))
    end)

    context
  end

  step ~r/^(\w+) views the (.+) home$/,
       %{args: [person_name, club_name]} = context do
    view_group(context, person_name, club_name, "Everyone")
  end

  step ~r/^(\w+) should see the (.+) group$/,
       %{args: [_person_name, group_name]} = context do
    assert Enum.any?(Map.fetch!(context, :visible_groups), &(&1.name == group_name)),
           "Expected the visible group list to include #{inspect(group_name)}"

    context
  end

  step ~r/^(\w+) should not see the (.+) group$/,
       %{args: [_person_name, group_name]} = context do
    refute Enum.any?(Map.fetch!(context, :visible_groups), &(&1.name == group_name)),
           "Expected the visible group list not to include #{inspect(group_name)}"

    context
  end

  step ~r/^(\w+) should not be listed as a member of the (.+) group$/,
       %{args: [person_name, group_name]} = context do
    group_id = group_id!(context, @club_name, group_name)
    person_id = person_id!(context, person_name)

    refute Enum.any?(Membership.list_active_members_of_group(group_id), &(&1.id == person_id))
    context
  end

  step ~r/^the (.+ Club) (.+) group has the conversation "([^"]+)"$/,
       %{args: [club_name, group_name, subject]} = context do
    send_group_message(context, club_name, group_name, subject)
  end

  step "the Everyone group has the conversation {string}",
       %{args: [subject]} = context do
    send_group_message(context, @club_name, "Everyone", subject)
  end

  step ~r/^(\w+) selects the (.+) group$/,
       %{args: [person_name, group_name]} = context do
    view_group(context, person_name, @club_name, group_name)
  end

  step ~r/^(\w+) should see the conversation "([^"]+)"$/,
       %{args: [_person_name, subject]} = context do
    assert Enum.any?(Map.fetch!(context, :current_group_conversations), &(&1.subject == subject)),
           "Expected the selected group to include conversation #{inspect(subject)}"

    context
  end

  step ~r/^(\w+) should not see the conversation "([^"]+)"$/,
       %{args: [_person_name, subject]} = context do
    refute Enum.any?(
             Map.fetch!(context, :current_group_conversations),
             &(&1.subject == subject)
           ),
           "Expected the selected group not to include conversation #{inspect(subject)}"

    context
  end

  step ~r/^(\w+) should see (\w+) in the member list$/,
       %{args: [_viewer_name, member_name]} = context do
    member_id = person_id!(context, member_name)
    assert Enum.any?(Map.fetch!(context, :current_group_members), &(&1.id == member_id))
    context
  end

  step ~r/^(\w+) should not see (\w+) in the member list$/,
       %{args: [_viewer_name, member_name]} = context do
    member_id = person_id!(context, member_name)
    refute Enum.any?(Map.fetch!(context, :current_group_members), &(&1.id == member_id))
    context
  end

  step ~r/^(\w+) sends the message "([^"]+)" to the (.+) group in the web app$/,
       %{args: [sender_name, subject, group_name]} = context do
    context
    |> send_group_message(@club_name, group_name, subject, sender_name)
    |> view_group(sender_name, @club_name, group_name)
  end

  step ~r/^(.+) should be able to read the (.+) conversation "([^"]+)"$/,
       %{args: [person_names_text, _group_name, subject]} = context do
    message = message!(context, subject)

    person_names_text
    |> parse_person_list()
    |> Enum.each(fn person_name ->
      assert Messaging.member_has_conversation_access?(
               message.message_id,
               message.club_id,
               person_id!(context, person_name),
               :read
             ),
             "Expected #{person_name} to be able to read #{inspect(subject)}"
    end)

    context
  end

  step ~r/^(\w+) should not be able to read the (.+) conversation "([^"]+)"$/,
       %{args: [person_name, _group_name, subject]} = context do
    message = message!(context, subject)

    refute Messaging.member_has_conversation_access?(
             message.message_id,
             message.club_id,
             person_id!(context, person_name),
             :read
           )

    context
  end

  step ~r/^(\w+) tries to view the (.+) group$/,
       %{args: [person_name, group_name]} = context do
    club_id = club_id!(context, @club_name)
    person_id = person_id!(context, person_name)
    requested_group_id = group_id!(context, @club_name, group_name)

    result =
      if Enum.any?(
           Membership.list_active_groups_for_member(club_id, person_id),
           &(&1.group_id == requested_group_id)
         ) do
        :ok
      else
        :not_found
      end

    Map.put(context, :group_page_result, result)
  end

  step "{word} should be shown that the page was not found", context do
    assert Map.fetch!(context, :group_page_result) == :not_found
    context
  end

  defp ensure_group(context, club_name, group_name) do
    case get_in(context, [:groups, {club_name, group_name}]) do
      group_id when is_binary(group_id) ->
        {context, group_id}

      nil ->
        group_id = Memba.ID.generate(:group)

        assert :ok =
                 MembershipApp.dispatch(
                   %CreateGroup{
                     club_id: club_id!(context, club_name),
                     group_id: group_id,
                     group_key: group_key(group_name),
                     email_slug: group_key(group_name),
                     name: group_name
                   },
                   consistency: :strong
                 )

        {put_context(context, :groups, {club_name, group_name}, group_id), group_id}
    end
  end

  defp send_group_message(context, club_name, group_name, subject, sender_name \\ nil) do
    club_id = club_id!(context, club_name)
    group_id = group_id!(context, club_name, group_name)

    sender_name =
      sender_name ||
        group_id
        |> Membership.list_active_members_of_group()
        |> List.first()
        |> case do
          %{name: name} -> name
          nil -> flunk("Expected #{group_name} to have an active member")
        end

    message_id = Memba.ID.generate(:message)
    sender_id = person_id!(context, sender_name)
    body = "#{subject} details."

    assert :ok =
             Messaging.send_club_message(
               %{
                 message_id: message_id,
                 club_id: club_id,
                 sender_id: sender_id,
                 audience_group_id: group_id,
                 subject: subject,
                 body: body
               },
               consistency: :strong
             )

    message = %{
      message_id: message_id,
      club_id: club_id,
      sender_id: sender_id,
      subject: subject,
      body: body
    }

    context
    |> Map.put(:sent_message, message)
    |> Map.put(:last_message_id, message_id)
    |> put_context(:messages, subject, message)
  end

  defp view_group(context, person_name, club_name, group_name) do
    club_id = club_id!(context, club_name)
    person_id = person_id!(context, person_name)
    groups = Membership.list_active_groups_for_member(club_id, person_id)

    selected_group =
      Enum.find(groups, &(&1.name == group_name)) ||
        flunk("Expected #{person_name} to have access to #{group_name}")

    context
    |> Map.put(:current_viewer_name, person_name)
    |> Map.put(:visible_groups, groups)
    |> Map.put(:selected_group, selected_group)
    |> Map.put(
      :current_group_members,
      Membership.list_active_members_of_group(selected_group.group_id)
    )
    |> Map.put(
      :current_group_conversations,
      Messaging.list_conversations_for_group(selected_group.group_id)
    )
  end

  defp group_id!(context, club_name, "Everyone"),
    do: SystemGroups.everyone_group_id(club_id!(context, club_name))

  defp group_id!(context, club_name, "Admin"),
    do: SystemGroups.admin_group_id(club_id!(context, club_name))

  defp group_id!(context, club_name, group_name) do
    fetch_context!(context, :groups, {club_name, group_name})
  end

  defp club_id!(context, club_name) do
    context
    |> fetch_context!(:clubs, club_name)
    |> id_from_context(:club_id)
  end

  defp person_id!(context, person_name) do
    context
    |> fetch_context!(:people, person_name)
    |> id_from_context(:person_id)
  end

  defp membership_id!(context, club_name, person_name) do
    context
    |> fetch_context!(:memberships, {club_name, person_name})
    |> id_from_context(:membership_id)
  end

  defp message!(context, subject), do: fetch_context!(context, :messages, subject)

  defp fetch_context!(context, collection_key, item_key) do
    context
    |> Map.get(collection_key, %{})
    |> Map.fetch!(item_key)
  end

  defp id_from_context(value, _field) when is_binary(value), do: value
  defp id_from_context(value, field) when is_map(value), do: Map.fetch!(value, field)

  defp put_context(context, collection_key, item_key, value) do
    collection =
      context
      |> Map.get(collection_key, %{})
      |> Map.put(item_key, value)

    Map.put(context, collection_key, collection)
  end

  defp parse_person_list(text) do
    text
    |> String.replace(~r/,?\s+and\s+/u, ", ")
    |> String.split(~r/\s*,\s*/u, trim: true)
  end

  defp group_key(name) do
    name
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/u, "-")
    |> String.trim("-")
  end
end
