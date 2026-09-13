defmodule Memba.Cucumber.GroupConversationSteps do
  use Cucumber.StepDefinition

  import ExUnit.Assertions

  alias Memba.ClubInboundEmailAddress
  alias Memba.Membership
  alias Memba.Membership.App, as: MembershipApp
  alias Memba.Membership.Authorization
  alias Memba.Membership.Commands.AddClubMember
  alias Memba.Membership.Commands.AddGroupMember
  alias Memba.Membership.Commands.CreateClub
  alias Memba.Membership.Commands.CreateGroup
  alias Memba.Membership.Commands.CreatePerson
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
    context
    |> view_group(person_name, @club_name, group_name)
    |> Map.put(:group_page_result, :access_guidance)
  end

  step ~r/^(\w+) is not a club admin$/,
       %{args: [person_name]} = context do
    refute club_admin?(context, @club_name, person_name)
    context
  end

  step ~r/^(\w+) is a club admin$/,
       %{args: [person_name]} = context do
    assert club_admin?(context, @club_name, person_name)
    context
  end

  step ~r/^(.+) are members of the Kootenay Mountaineering Club Board group$/,
       %{args: [person_names_text]} = context do
    ensure_named_group_members(context, "Board", parse_person_list(person_names_text))
  end

  step ~r/^(.+) are the only members of the Kootenay Mountaineering Club Board group$/,
       %{args: [person_names_text]} = context do
    context = ensure_named_group_members(context, "Board", parse_person_list(person_names_text))
    board_id = group_id!(context, @club_name, "Board")

    assert Enum.map(Membership.list_active_members_of_group(board_id), & &1.name) ==
             parse_person_list(person_names_text)

    context
  end

  step ~r/^(\w+) is the only member of the Kootenay Mountaineering Club Board group$/,
       %{args: [person_name]} = context do
    context = ensure_named_group_members(context, "Board", [person_name])
    board_id = group_id!(context, @club_name, "Board")

    assert Enum.map(Membership.list_active_members_of_group(board_id), & &1.name) == [
             person_name
           ]

    context
  end

  step ~r/^(\w+) is a member of the Kootenay Mountaineering Club Board group$/,
       %{args: [person_name]} = context do
    ensure_named_group_members(context, "Board", [person_name])
  end

  step ~r/^Board has the conversation "([^"]+)"$/,
       %{args: [subject]} = context do
    send_group_message(context, @club_name, "Board", subject)
  end

  step ~r/^(\w+) opens Board$/,
       %{args: [person_name]} = context do
    view_group(context, person_name, @club_name, "Board")
  end

  step ~r/^(\w+) views Board's members$/,
       %{args: [person_name]} = context do
    view_group(context, person_name, @club_name, "Board")
  end

  step ~r/^(\w+) should be told that she does not belong to Admin$/,
       %{args: [_person_name]} = context do
    assert Map.fetch!(context, :group_page_result) == :access_guidance
    assert Map.fetch!(context, :current_group_access) == :ordinary_non_member
    context
  end

  step ~r/^(\w+) should see the club Admin email address$/,
       %{args: [_person_name]} = context do
    assert Map.fetch!(context, :club_admin_email_address) ==
             club_admin_email_address(context, @club_name)

    context
  end

  step ~r/^(\w+) should see neither (.+) conversations nor its membership list$/,
       %{args: [_person_name, group_name]} = context do
    assert Map.fetch!(context, :selected_group).name == group_name
    assert Map.fetch!(context, :current_group_conversations) == []
    assert Map.fetch!(context, :current_group_members) == []
    context
  end

  step ~r/^(\w+) should see Board's name and the club Admin email address$/,
       %{args: [_person_name]} = context do
    assert Map.fetch!(context, :selected_group).name == "Board"

    assert Map.fetch!(context, :club_admin_email_address) ==
             club_admin_email_address(context, @club_name)

    context
  end

  step ~r/^(\w+) should not become a member of (.+)$/,
       %{args: [person_name, group_name]} = context do
    group_name =
      group_name
      |> String.replace_prefix("the ", "")
      |> String.replace_suffix(" group", "")

    refute Membership.active_member_of_group?(
             group_id!(context, @club_name, group_name),
             person_id!(context, person_name)
           )

    context
  end

  step ~r/^(\w+) should see (.+) as Board's members$/,
       %{args: [_person_name, member_names_text]} = context do
    assert Enum.map(Map.fetch!(context, :current_group_members), & &1.name) ==
             parse_person_list(member_names_text)

    context
  end

  step ~r/^(\w+) should not belong to Board$/,
       %{args: [person_name]} = context do
    refute Membership.active_member_of_group?(
             group_id!(context, @club_name, "Board"),
             person_id!(context, person_name)
           )

    context
  end

  step ~r/^(\w+) should not have access to Board conversations$/,
       %{args: [person_name]} = context do
    refute Membership.active_member_of_group?(
             group_id!(context, @club_name, "Board"),
             person_id!(context, person_name)
           )

    assert Map.fetch!(context, :current_group_conversations) == []

    context
  end

  step ~r/^(\w+) directly tries to (.+)$/,
       %{args: [person_name, action]} = context do
    try_direct_board_action(context, person_name, action)
  end

  step "the attempt should be refused", context do
    assert {:error, _reason} = Map.fetch!(context, :direct_action_result)
    context
  end

  step ~r/^no Board conversation content should be disclosed to (\w+)$/,
       %{args: [person_name]} = context do
    message = message!(context, "September agenda")

    refute Messaging.member_has_conversation_access?(
             message.message_id,
             message.club_id,
             person_id!(context, person_name),
             :read
           )

    assert Map.fetch!(context, :direct_action_content) == []
    context
  end

  step "no message, reply, or follow should be created by the attempt", context do
    attempt = Map.fetch!(context, :direct_action_attempt)

    assert Messaging.get_message(attempt.generated_message_id) == nil

    assert Enum.count(Messaging.list_conversation_messages(attempt.conversation_id)) ==
             attempt.conversation_message_count

    assert Messaging.following_conversation?(attempt.conversation_id, attempt.person_id) ==
             attempt.following?

    context
  end

  step "Pat belongs to Nelson Paddling Club but not Kootenay Mountaineering Club", context do
    context = ensure_other_club_member(context, "Pat", "Nelson Paddling Club")

    refute Membership.active_member_of_club?(
             club_id!(context, @club_name),
             person_id!(context, "Pat")
           )

    context
  end

  step "Pat opens a link to Kootenay Mountaineering Club's Board", context do
    visible_groups =
      Membership.list_discoverable_groups_for_member(
        club_id!(context, @club_name),
        person_id!(context, "Pat")
      )

    Map.put(context, :foreign_member_visible_groups, visible_groups)
  end

  step "no KMC group details should be disclosed to Pat", context do
    assert Map.fetch!(context, :foreign_member_visible_groups) == []
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

  defp ensure_named_group_members(context, group_name, person_names) do
    {context, group_id} = ensure_group(context, @club_name, group_name)

    Enum.each(person_names, fn person_name ->
      unless Membership.active_member_of_group?(group_id, person_id!(context, person_name)) do
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
      end
    end)

    context
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
    groups = Membership.list_discoverable_groups_for_member(club_id, person_id)
    participating_groups = Membership.list_active_groups_for_member(club_id, person_id)

    selected_group =
      Enum.find(groups, &(&1.name == group_name)) ||
        flunk("Expected #{person_name} to be able to discover #{group_name}")

    participating? =
      Enum.any?(participating_groups, &(&1.group_id == selected_group.group_id))

    current_group_access =
      cond do
        participating? -> :participating_member
        club_admin?(context, club_name, person_name) -> :outside_admin
        true -> :ordinary_non_member
      end

    members =
      if current_group_access in [:participating_member, :outside_admin] do
        Membership.list_active_members_of_group(selected_group.group_id)
      else
        []
      end

    conversations =
      if current_group_access == :participating_member do
        Messaging.list_conversations_for_group(selected_group.group_id)
      else
        []
      end

    context
    |> Map.put(:current_viewer_name, person_name)
    |> Map.put(:visible_groups, groups)
    |> Map.put(:selected_group, selected_group)
    |> Map.put(:current_group_access, current_group_access)
    |> Map.put(:club_admin_email_address, club_admin_email_address(context, club_name))
    |> Map.put(:current_group_members, members)
    |> Map.put(:current_group_conversations, conversations)
  end

  defp try_direct_board_action(context, person_name, action) do
    message = message!(context, "September agenda")
    person_id = person_id!(context, person_name)
    generated_message_id = Memba.ID.generate(:message)

    attempt = %{
      conversation_id: message.message_id,
      conversation_message_count:
        Enum.count(Messaging.list_conversation_messages(message.message_id)),
      following?: Messaging.following_conversation?(message.message_id, person_id),
      generated_message_id: generated_message_id,
      person_id: person_id
    }

    result =
      cond do
        String.starts_with?(action, "read ") ->
          {:error, :not_found}

        String.starts_with?(action, "reply ") ->
          Messaging.post_message_reply(
            %{
              message_id: generated_message_id,
              conversation_id: message.message_id,
              sender_id: person_id,
              body: "This must not be posted."
            },
            consistency: :strong
          )

        String.starts_with?(action, "follow ") ->
          Messaging.follow_conversation_as_current_member(
            %{
              club_id: message.club_id,
              conversation_id: message.message_id,
              member_id: person_id
            },
            consistency: :strong
          )

        String.starts_with?(action, "start ") ->
          board_id = group_id!(context, @club_name, "Board")

          if Membership.active_member_of_group?(board_id, person_id) do
            Messaging.send_club_message(
              %{
                message_id: generated_message_id,
                club_id: message.club_id,
                sender_id: person_id,
                audience_group_id: board_id,
                subject: "Forbidden Board conversation",
                body: "This must not be posted."
              },
              consistency: :strong
            )
          else
            {:error, :not_current_member}
          end

        true ->
          flunk("Unsupported direct Board action: #{inspect(action)}")
      end

    context
    |> Map.put(:direct_action_attempt, attempt)
    |> Map.put(:direct_action_content, [])
    |> Map.put(:direct_action_result, result)
  end

  defp ensure_other_club_member(context, person_name, club_name) do
    club_id = Memba.ID.generate(:club)
    person_id = Memba.ID.generate(:person)
    membership_id = Memba.ID.generate(:membership)
    slug = "nelson-#{String.slice(club_id, -8, 8)}"
    email = "pat-#{String.slice(person_id, -8, 8)}@example.test"

    assert :ok =
             MembershipApp.dispatch(
               %CreateClub{club_id: club_id, name: club_name, slug: slug},
               consistency: :strong
             )

    assert :ok =
             MembershipApp.dispatch(
               %CreatePerson{
                 person_id: person_id,
                 name: person_name,
                 email: email,
                 email_addresses: [%{email: email, is_primary: true}]
               },
               consistency: :strong
             )

    assert :ok =
             MembershipApp.dispatch(
               %AddClubMember{
                 membership_id: membership_id,
                 club_id: club_id,
                 person_id: person_id
               },
               consistency: :strong
             )

    context
    |> put_context(:clubs, club_name, club_id)
    |> put_context(:people, person_name, person_id)
    |> put_context(:memberships, {club_name, person_name}, membership_id)
  end

  defp club_admin?(context, club_name, person_name) do
    Authorization.authorize_manage_members(
      club_id!(context, club_name),
      person_id!(context, person_name)
    ) == :ok
  end

  defp club_admin_email_address(context, club_name) do
    club = Membership.get_club(club_id!(context, club_name))
    ClubInboundEmailAddress.address(club.slug, SystemGroups.admin_email_slug())
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
