defmodule Memba.Cucumber.CustomGroupLifecycleSteps do
  use Cucumber.StepDefinition

  import ExUnit.Assertions

  alias Memba.Membership
  alias Memba.Membership.App, as: MembershipApp
  alias Memba.Membership.Commands.AddGroupMember
  alias Memba.Membership.Commands.CreateGroup
  alias Memba.Membership.SystemGroups
  alias Memba.Messaging
  alias Memba.Messaging.EmailDeliveryDispatcher
  alias Memba.Messaging.EmailDeliveryProviders.Fake

  @club_name "Kootenay Mountaineering Club"
  @board_name "Board"
  @trips_name "Trips"
  @agenda_subject "September agenda"
  @trips_subject "Trips departure planning"

  step "Alice and Bob are the only members of its custom group Board", context do
    context = ensure_group(context, @board_name, "board")

    context =
      Enum.reduce(["Alice", "Bob"], context, fn person_name, context ->
        add_group_member(context, @board_name, person_name)
      end)

    member_names =
      context
      |> group_id!(@board_name)
      |> Membership.list_active_members_of_group()
      |> Enum.map(& &1.name)

    assert member_names == ["Alice", "Bob"]
    context
  end

  step "Board has the conversation {string} with the reply {string}",
       %{args: [subject, reply_body]} = context do
    context = create_group_conversation(context, @board_name, "Alice", subject)
    post_reply(context, subject, "Bob", reply_body)
  end

  step "Carol belongs to Board and the custom group Trips", context do
    setup_departure_memberships(context)
  end

  step "Carol follows conversations in both groups", context do
    follow_lifecycle_conversations(context)
  end

  step "Carol's KMC membership ends", context do
    end_carol_membership(context)
  end

  step "Carol should no longer belong to Board or Trips", context do
    assert_custom_memberships_ended(context)
  end

  step "Carol should no longer follow their conversations", context do
    Enum.each(lifecycle_conversations(context), fn message ->
      refute Messaging.following_conversation?(message.message_id, carol_person_id!(context))
    end)

    context
  end

  step "Carol should have no access to their conversations", context do
    assert_no_conversation_access(context)
  end

  step "Carol should receive no future conversation or followed-reply emails from either group",
       context do
    assert_no_future_group_email(context)
  end

  step "Carol belonged to Board and Trips before her KMC membership ended", context do
    context
    |> setup_departure_memberships()
    |> follow_lifecycle_conversations()
    |> end_carol_membership()
  end

  step "Carol becomes an active KMC member again", context do
    membership_id = Memba.ID.generate(:membership)

    assert :ok =
             Membership.add_member(
               %{
                 club_id: club_id!(context),
                 membership_id: membership_id,
                 person_id: carol_person_id!(context)
               },
               consistency: :strong
             )

    put_context(context, :memberships, {@club_name, "Carol"}, membership_id)
  end

  step "Carol should belong to Everyone", context do
    assert Membership.active_member_of_group?(
             SystemGroups.everyone_group_id(club_id!(context)),
             carol_person_id!(context)
           )

    context
  end

  step "Carol should belong to neither Board nor Trips", context do
    assert_custom_memberships_ended(context)
  end

  step "Carol should have no access to their conversations or future group emails", context do
    context
    |> assert_no_conversation_access()
    |> assert_no_future_group_email()
  end

  step "Carol should see their access guidance", context do
    discoverable_ids =
      context
      |> club_id!()
      |> Membership.list_discoverable_groups_for_member(carol_person_id!(context))
      |> Enum.map(& &1.group_id)
      |> MapSet.new()

    participating_ids =
      context
      |> club_id!()
      |> Membership.list_active_groups_for_member(carol_person_id!(context))
      |> Enum.map(& &1.group_id)
      |> MapSet.new()

    Enum.each([@board_name, @trips_name], fn group_name ->
      group_id = group_id!(context, group_name)
      assert MapSet.member?(discoverable_ids, group_id)
      refute MapSet.member?(participating_ids, group_id)
    end)

    context
  end

  defp setup_departure_memberships(context) do
    context = add_group_member(context, @board_name, "Carol")
    context = ensure_group(context, @trips_name, "trips")

    context =
      Enum.reduce(["Alice", "Carol"], context, fn person_name, context ->
        add_group_member(context, @trips_name, person_name)
      end)

    context = create_group_conversation(context, @trips_name, "Alice", @trips_subject)

    dispatch_pending_email_deliveries()
    Fake.reset()
    context
  end

  defp follow_lifecycle_conversations(context) do
    Enum.each(lifecycle_conversations(context), fn message ->
      assert :ok =
               Messaging.follow_conversation_as_current_member(
                 %{
                   club_id: club_id!(context),
                   conversation_id: message.message_id,
                   member_id: carol_person_id!(context)
                 },
                 consistency: :strong
               )

      assert Messaging.following_conversation?(message.message_id, carol_person_id!(context))
    end)

    context
  end

  defp end_carol_membership(context) do
    assert :ok =
             Membership.remove_member(
               %{
                 club_id: club_id!(context),
                 membership_id: membership_id!(context, "Carol"),
                 person_id: carol_person_id!(context)
               },
               consistency: :strong
             )

    context
  end

  defp assert_custom_memberships_ended(context) do
    Enum.each([@board_name, @trips_name], fn group_name ->
      group_id = group_id!(context, group_name)
      assert Membership.get_group(group_id)
      refute Membership.active_member_of_group?(group_id, carol_person_id!(context))

      refute Membership.active_member_of_group_authoritatively?(
               club_id!(context),
               group_id,
               carol_person_id!(context)
             )
    end)

    context
  end

  defp assert_no_conversation_access(context) do
    Enum.each(lifecycle_conversations(context), fn message ->
      for access_level <- [:read, :write] do
        refute Messaging.member_has_conversation_access?(
                 message.message_id,
                 club_id!(context),
                 carol_person_id!(context),
                 access_level
               )
      end
    end)

    context
  end

  defp assert_no_future_group_email(context) do
    dispatch_pending_email_deliveries()
    Fake.reset()

    future_message_ids =
      Enum.flat_map([@board_name, @trips_name], fn group_name ->
        root = message!(context, lifecycle_subject(group_name))
        reply_id = Memba.ID.generate(:message)
        future_subject = "#{group_name} after Carol's departure"
        future_root_id = Memba.ID.generate(:message)

        assert :ok =
                 Messaging.post_message_reply(
                   %{
                     message_id: reply_id,
                     conversation_id: root.message_id,
                     sender_id: person_id!(context, "Alice"),
                     body: "#{group_name} followed reply after departure."
                   },
                   consistency: :strong
                 )

        assert :ok =
                 Messaging.send_club_message(
                   %{
                     message_id: future_root_id,
                     club_id: club_id!(context),
                     sender_id: person_id!(context, "Alice"),
                     audience_group_id: group_id!(context, group_name),
                     subject: future_subject,
                     body: "#{future_subject} details."
                   },
                   consistency: :strong
                 )

        [reply_id, future_root_id]
      end)

    Enum.each(future_message_ids, fn message_id ->
      refute Enum.any?(
               Messaging.list_recipient_deliveries(message_id),
               &(&1.recipient_id == carol_person_id!(context))
             )
    end)

    dispatch_pending_email_deliveries()

    refute Enum.any?(
             Fake.deliveries(),
             &(&1.message_id in future_message_ids and
                 &1.recipient_id == carol_person_id!(context))
           )

    context
  end

  defp ensure_group(context, group_name, email_slug) do
    case get_in(context, [:groups, {@club_name, group_name}]) do
      group_id when is_binary(group_id) ->
        context

      nil ->
        group_id = Memba.ID.generate(:group)

        assert :ok =
                 MembershipApp.dispatch(
                   %CreateGroup{
                     club_id: club_id!(context),
                     group_id: group_id,
                     group_key: nil,
                     email_slug: email_slug,
                     name: group_name
                   },
                   consistency: :strong
                 )

        put_context(context, :groups, {@club_name, group_name}, group_id)
    end
  end

  defp add_group_member(context, group_name, person_name) do
    group_id = group_id!(context, group_name)
    person_id = person_id!(context, person_name)

    unless Membership.active_member_of_group?(group_id, person_id) do
      assert :ok =
               MembershipApp.dispatch(
                 %AddGroupMember{
                   club_id: club_id!(context),
                   group_id: group_id,
                   membership_id: membership_id!(context, person_name),
                   person_id: person_id
                 },
                 consistency: :strong
               )
    end

    context
  end

  defp create_group_conversation(context, group_name, sender_name, subject) do
    message_id = Memba.ID.generate(:message)

    assert :ok =
             Messaging.send_club_message(
               %{
                 message_id: message_id,
                 club_id: club_id!(context),
                 sender_id: person_id!(context, sender_name),
                 audience_group_id: group_id!(context, group_name),
                 subject: subject,
                 body: "#{subject} details."
               },
               consistency: :strong
             )

    message = Messaging.get_message(message_id)

    context
    |> Map.put(:last_message_subject, subject)
    |> put_context(:messages, subject, message)
  end

  defp post_reply(context, subject, sender_name, body) do
    reply_id = Memba.ID.generate(:message)

    assert :ok =
             Messaging.post_message_reply(
               %{
                 message_id: reply_id,
                 conversation_id: message!(context, subject).message_id,
                 sender_id: person_id!(context, sender_name),
                 body: body
               },
               consistency: :strong
             )

    context
  end

  defp lifecycle_conversations(context) do
    Enum.map([@agenda_subject, @trips_subject], &message!(context, &1))
  end

  defp lifecycle_subject(@board_name), do: @agenda_subject
  defp lifecycle_subject(@trips_name), do: @trips_subject

  defp dispatch_pending_email_deliveries do
    _deliveries = EmailDeliveryDispatcher.dispatch_pending_email_deliveries()
    :ok
  end

  defp club_id!(context), do: fetch_context!(context, :clubs, @club_name)
  defp carol_person_id!(context), do: person_id!(context, "Carol")

  defp person_id!(context, person_name) do
    context
    |> fetch_context!(:people, person_name)
    |> Map.fetch!(:person_id)
  end

  defp membership_id!(context, person_name) do
    fetch_context!(context, :memberships, {@club_name, person_name})
  end

  defp group_id!(context, group_name) do
    fetch_context!(context, :groups, {@club_name, group_name})
  end

  defp message!(context, subject), do: fetch_context!(context, :messages, subject)

  defp fetch_context!(context, collection_key, item_key) do
    context
    |> Map.fetch!(collection_key)
    |> Map.fetch!(item_key)
  end

  defp put_context(context, collection_key, item_key, value) do
    Map.update(context, collection_key, %{item_key => value}, &Map.put(&1, item_key, value))
  end
end
