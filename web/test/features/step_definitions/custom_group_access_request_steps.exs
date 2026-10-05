defmodule Memba.Cucumber.CustomGroupAccessRequestSteps do
  use Cucumber.StepDefinition

  import ExUnit.Assertions

  alias Memba.Membership
  alias Memba.Membership.SystemGroups
  alias Memba.Messaging
  alias MembaWeb.ClubSite

  @club_name "Kootenay Mountaineering Club"
  @board_name "Board"
  @request_subject "Access request: Board"

  step "KMC is a club", context do
    club_id = Memba.ID.generate(:club)

    assert :ok =
             Membership.create_club(
               %{club_id: club_id, name: @club_name, slug: "kmc"},
               consistency: :strong
             )

    put_context(context, :clubs, @club_name, club_id)
  end

  step "Eve is its ordinary active club member", context do
    context
    |> ensure_person("Eve")
    |> add_club_member(@club_name, "Eve")
  end

  step "Alice belongs to its group Board", context do
    group_id = Memba.ID.generate(:group)

    assert :ok =
             Membership.create_custom_group(
               %{
                 club_id: club_id!(context),
                 group_id: group_id,
                 actor_person_id: person_id!(context, "Alice"),
                 name: @board_name
               },
               consistency: :strong
             )

    assert Membership.active_member_of_group_authoritatively?(
             club_id!(context),
             group_id,
             person_id!(context, "Alice")
           )

    put_context(context, :groups, {@club_name, @board_name}, group_id)
  end

  step ~r/^(\w+) requests access to Board$/,
       %{args: [person_name]} = context do
    request_group_access(context, person_name)
  end

  step ~r/^(\w+) tries to request access to Board$/,
       %{args: [person_name]} = context do
    request_group_access(context, person_name)
  end

  step "a standard message identifying Eve and Board should be sent to the KMC Admin Group",
       context do
    request = access_request!(context)
    message = request.message
    club_id = club_id!(context)
    admin_group_id = SystemGroups.admin_group_id(club_id)

    assert request.result == :ok
    assert message.message_id == request.message_id
    assert message.conversation_id == request.message_id
    assert message.club_id == club_id
    assert message.sender_id == person_id!(context, "Eve")
    assert message.subject == @request_subject
    assert message.body =~ "Eve would like to join Board."
    assert message.body =~ "Eve asked from Board's page in #{@club_name}."
    assert message.body =~ "You'll confirm on the website before Eve is added."
    assert Messaging.group_has_conversation_access?(message.message_id, admin_group_id, :write)

    assert Enum.any?(
             Messaging.list_conversations_for_group(admin_group_id),
             &(&1.message_id == message.message_id and &1.subject == @request_subject)
           )

    context
  end

  step "Alice and Dan should be its email recipients", context do
    request = access_request!(context)

    actual_recipient_ids =
      request.message_id
      |> Messaging.list_recipient_deliveries()
      |> Enum.map(& &1.recipient_id)
      |> Enum.sort()

    expected_recipient_ids =
      ["Alice", "Dan"]
      |> Enum.map(&person_id!(context, &1))
      |> Enum.sort()

    assert actual_recipient_ids == expected_recipient_ids
    context
  end

  step "the message should link to adding Eve to Board", context do
    request = access_request!(context)
    club = Membership.get_club(club_id!(context))

    expected_url =
      ClubSite.url(
        club,
        "/groups/#{board_id!(context)}/members/add/#{person_id!(context, "Eve")}"
      )

    assert request.message.body =~ "Add Eve to Board:\n#{expected_url}"
    context
  end

  step "Eve should still not belong to Board", context do
    request = access_request!(context)
    club_id = club_id!(context)
    eve_id = person_id!(context, "Eve")

    refute Membership.active_member_of_group_authoritatively?(
             club_id,
             board_id!(context),
             eve_id
           )

    refute Messaging.member_has_conversation_access?(
             request.message_id,
             club_id,
             eve_id,
             :read
           )

    refute Messaging.following_conversation?(request.message_id, eve_id)
    context
  end

  step "Eve's KMC membership has ended", context do
    assert :ok =
             Membership.remove_member(
               %{membership_id: membership_id!(context, @club_name, "Eve")},
               consistency: :strong
             )

    context
  end

  step "no access-request message should be sent to the KMC Admin Group", context do
    request = access_request!(context)
    club_id = club_id!(context)
    admin_group_id = SystemGroups.admin_group_id(club_id)

    assert request.result == {:error, :member_not_active}
    assert request.message == nil
    assert Messaging.get_message(request.message_id) == nil
    assert Messaging.list_recipient_deliveries(request.message_id) == []

    refute Messaging.group_has_conversation_access?(
             request.message_id,
             admin_group_id,
             :write
           )

    refute Enum.any?(
             Messaging.list_conversations_for_group(admin_group_id),
             &(&1.message_id == request.message_id)
           )

    refute Messaging.member_has_conversation_access?(
             request.message_id,
             club_id,
             request.requester_person_id,
             :read
           )

    refute Messaging.following_conversation?(
             request.message_id,
             request.requester_person_id
           )

    context
  end

  step ~r/^(\w+) should gain no access to KMC groups$/,
       %{args: [person_name]} = context do
    request = access_request!(context)
    club_id = club_id!(context)
    person_id = person_id!(context, person_name)

    refute Membership.active_member_of_club_authoritatively?(club_id, person_id)

    for group_id <- [
          board_id!(context),
          SystemGroups.everyone_group_id(club_id),
          SystemGroups.admin_group_id(club_id)
        ] do
      refute Membership.active_member_of_group_authoritatively?(club_id, group_id, person_id)
    end

    for access_level <- [:read, :write] do
      refute Messaging.member_has_conversation_access?(
               request.message_id,
               club_id,
               person_id,
               access_level
             )
    end

    refute Messaging.following_conversation?(request.message_id, person_id)
    context
  end

  defp request_group_access(context, person_name) do
    message_id = Memba.ID.generate(:message)
    requester_person_id = person_id!(context, person_name)

    result =
      Messaging.request_group_access(
        %{
          message_id: message_id,
          club_id: club_id!(context),
          requester_person_id: requester_person_id,
          group_id: board_id!(context)
        },
        consistency: :strong
      )

    Map.put(context, :last_access_request, %{
      message: Messaging.get_message(message_id),
      message_id: message_id,
      requester_person_id: requester_person_id,
      result: result
    })
  end

  defp ensure_person(context, person_name) do
    person_id = Memba.ID.generate(:person)
    email = "#{String.downcase(person_name)}-#{scenario_suffix(context)}@example.test"

    assert :ok =
             Membership.create_person(
               %{
                 person_id: person_id,
                 name: person_name,
                 email_addresses: [%{email: email, is_primary: true}]
               },
               consistency: :strong
             )

    put_context(context, :people, person_name, %{
      person_id: person_id,
      email: email,
      name: person_name
    })
  end

  defp add_club_member(context, club_name, person_name) do
    membership_id = Memba.ID.generate(:membership)

    assert :ok =
             Membership.add_member(
               %{
                 club_id: club_id!(context),
                 membership_id: membership_id,
                 person_id: person_id!(context, person_name)
               },
               consistency: :strong
             )

    put_context(context, :memberships, {club_name, person_name}, membership_id)
  end

  defp access_request!(context), do: Map.fetch!(context, :last_access_request)

  defp club_id!(context) do
    context
    |> Map.fetch!(:clubs)
    |> Map.fetch!(@club_name)
  end

  defp board_id!(context) do
    context
    |> Map.fetch!(:groups)
    |> Map.fetch!({@club_name, @board_name})
  end

  defp person_id!(context, person_name) do
    context
    |> Map.fetch!(:people)
    |> Map.fetch!(person_name)
    |> id_from_context(:person_id)
  end

  defp membership_id!(context, club_name, person_name) do
    context
    |> Map.fetch!(:memberships)
    |> Map.fetch!({club_name, person_name})
    |> id_from_context(:membership_id)
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

  defp scenario_suffix(context) do
    context
    |> Map.get(:scenario_name, "scenario")
    |> :erlang.phash2(1_000_000)
    |> Integer.to_string(36)
  end
end
