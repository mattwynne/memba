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
  @board_subject "September agenda"
  @trips_subject "Trips planning"

  step "Alice and Bob are the only members of its custom group Board", context do
    context = ensure_custom_group(context, @board_name, "board")

    Enum.reduce(["Alice", "Bob"], context, fn person_name, context ->
      add_group_member(context, @board_name, person_name)
    end)
  end

  step "Board has the conversation {string} with the reply {string}",
       %{args: [subject, reply_body]} = context do
    context = create_conversation(context, @board_name, "Alice", subject)
    context = create_reply(context, subject, "Bob", reply_body)
    drain_email_deliveries()
    Fake.reset()
    context
  end

  step "Carol belongs to Board and the custom group Trips", context do
    context =
      context
      |> ensure_custom_group(@trips_name, "trips")
      |> add_group_member(@board_name, "Carol")
      |> add_group_member(@trips_name, "Alice")
      |> add_group_member(@trips_name, "Carol")

    create_conversation(context, @trips_name, "Alice", @trips_subject)
  end

  step "Carol follows conversations in both groups", context do
    context
    |> follow_conversation("Carol", @board_subject)
    |> follow_conversation("Carol", @trips_subject)
  end

  step "Carol's KMC membership ends", context do
    end_carol_membership(context)
  end

  step "Carol should no longer belong to Board or Trips", context do
    refute_group_memberships(context, ["Board", "Trips"])
    context
  end

  step "Carol should no longer follow their conversations", context do
    refute_conversation_follows(context, [@board_subject, @trips_subject])
    context
  end

  step "Carol should have no access to their conversations", context do
    refute_conversation_access(context, [@board_subject, @trips_subject])
    context
  end

  step "Carol should receive no future conversation or followed-reply emails from either group",
       context do
    assert_no_future_group_emails(context)
  end

  step "Carol belonged to Board and Trips before her KMC membership ended", context do
    context =
      context
      |> ensure_custom_group(@trips_name, "trips")
      |> add_group_member(@board_name, "Carol")
      |> add_group_member(@trips_name, "Alice")
      |> add_group_member(@trips_name, "Carol")
      |> create_conversation(@trips_name, "Alice", @trips_subject)
      |> follow_conversation("Carol", @board_subject)
      |> follow_conversation("Carol", @trips_subject)

    end_carol_membership(context)
  end

  step "Carol becomes an active KMC member again", context do
    membership_id = Memba.ID.generate(:membership)

    assert :ok =
             Membership.add_member(
               %{
                 club_id: club_id!(context),
                 membership_id: membership_id,
                 person_id: person_id!(context, "Carol")
               },
               consistency: :strong
             )

    put_context(context, :memberships, {@club_name, "Carol"}, membership_id)
  end

  step "Carol should belong to Everyone", context do
    assert Membership.active_member_of_group?(
             SystemGroups.everyone_group_id(club_id!(context)),
             person_id!(context, "Carol")
           )

    context
  end

  step "Carol should belong to neither Board nor Trips", context do
    refute_group_memberships(context, [@board_name, @trips_name])
    context
  end

  step "Carol should have no access to their conversations or future group emails", context do
    refute_conversation_access(context, [@board_subject, @trips_subject])
    refute_conversation_follows(context, [@board_subject, @trips_subject])
    assert_no_future_group_emails(context)
  end

  step "Carol should see their access guidance", context do
    discoverable_group_ids =
      context
      |> club_id!()
      |> Membership.list_discoverable_groups_for_member(person_id!(context, "Carol"))
      |> Enum.map(& &1.group_id)

    active_group_ids =
      context
      |> club_id!()
      |> Membership.list_active_groups_for_member(person_id!(context, "Carol"))
      |> Enum.map(& &1.group_id)

    Enum.each([@board_name, @trips_name], fn group_name ->
      group_id = group_id!(context, group_name)
      assert group_id in discoverable_group_ids
      refute group_id in active_group_ids
    end)

    context
  end

  step "Carol belongs to Board and follows {string}", %{args: [subject]} = context do
    context
    |> add_group_member(@board_name, "Carol")
    |> follow_conversation("Carol", subject)
  end

  step "Carol belongs to Board", context do
    add_group_member(context, @board_name, "Carol")
  end

  step "Carol leaves Board", context do
    remove_group_member(context, "Carol", "Carol")
  end

  step "Bob has posted the reply {string} to {string}", %{args: [body, subject]} = context do
    create_reply(context, subject, "Bob", body)
  end

  step "Bob starts the Board conversation {string}", %{args: [subject]} = context do
    create_conversation(context, @board_name, "Bob", subject)
  end

  step "no email delivery should be created for Carol for {string} or {string}",
       %{args: [reply_body, subject]} = context do
    Enum.each([reply_body, subject], fn message_key ->
      message = message!(context, message_key)

      refute Enum.any?(
               Messaging.list_recipient_deliveries(message.message_id),
               &(&1.recipient_id == person_id!(context, "Carol"))
             )
    end)

    context
  end

  step "Carol's email delivery for {string} is queued", %{args: [body]} = context do
    delivery = carol_delivery!(context, body)
    assert delivery.status == "pending"
    Map.put(context, :last_delivery_message, message!(context, body))
  end

  step "Carol should still receive {string} by email", %{args: [body]} = context do
    message = message!(context, body)
    drain_email_deliveries()

    assert Enum.any?(
             Fake.deliveries(),
             &(&1.message_id == message.message_id and
                 &1.recipient_id == person_id!(context, "Carol"))
           )

    context
  end

  step "its conversation link should no longer give Carol access", context do
    context
    |> Map.fetch!(:last_delivery_message)
    |> then(&refute_carol_access(context, &1))

    context
  end

  step "Carol has received the Board message {string} by email", %{args: [subject]} = context do
    context = create_conversation(context, @board_name, "Bob", subject)
    message = message!(context, subject)
    drain_email_deliveries()

    assert Enum.any?(
             Fake.deliveries(),
             &(&1.message_id == message.message_id and
                 &1.recipient_id == person_id!(context, "Carol"))
           )

    Map.put(context, :received_delivery, carol_delivery!(context, subject))
  end

  step "Carol's delivered copy of {string} should not be withdrawn",
       %{args: [subject]} = context do
    message = message!(context, subject)
    delivery = carol_delivery!(context, subject)
    assert delivery.status == "sent"
    assert delivery.delivery_id == Map.fetch!(context, :received_delivery).delivery_id
    Map.put(context, :last_delivery_message, message)
  end

  step "Carol should still follow {string}", %{args: [subject]} = context do
    assert_carol_follows(context, subject)
  end

  step "the follow should not give Carol access to it", context do
    refute_carol_access(context, message!(context, @board_subject))
    context
  end

  step "Bob adds Carol back to Board", context do
    add_custom_group_member(context, "Bob", "Carol")
  end

  step "Carol should receive no email or backlog for {string}", %{args: [body]} = context do
    message = message!(context, body)

    refute Enum.any?(
             Messaging.list_recipient_deliveries(message.message_id),
             &(&1.recipient_id == person_id!(context, "Carol"))
           )

    context
  end

  step "Carol should be able to read {string} on the website", %{args: [body]} = context do
    message = message!(context, body)

    assert Messaging.member_has_conversation_access?(
             message.message_id,
             message.club_id,
             person_id!(context, "Carol"),
             :read
           )

    context
  end

  step "Carol followed {string} before leaving Board", %{args: [subject]} = context do
    context
    |> add_group_member(@board_name, "Carol")
    |> follow_conversation("Carol", subject)
    |> remove_group_member("Carol", "Carol")
  end

  step "Bob has added Carol back to Board", context do
    add_custom_group_member(context, "Bob", "Carol")
  end

  step "Carol should receive {string} by email", %{args: [body]} = context do
    message = message!(context, body)
    drain_email_deliveries()

    assert Enum.any?(
             Fake.deliveries(),
             &(&1.message_id == message.message_id and
                 &1.recipient_id == person_id!(context, "Carol"))
           )

    context
  end

  step "Carol should still be following {string}", %{args: [subject]} = context do
    assert_carol_follows(context, subject)
  end

  step "Bob is Board's only remaining member", context do
    context
    |> remove_group_member("Alice", "Bob")
    |> snapshot_board()
  end

  step "Bob leaves Board", context do
    remove_group_member(context, "Bob", "Bob")
  end

  step "Board has no members", context do
    context =
      Enum.reduce(
        Membership.list_active_members_of_group(group_id!(context, @board_name)),
        context,
        fn
          member, context -> remove_group_member(context, member.name, member.name)
        end
      )

    snapshot_board(context)
  end

  step "Board should have no members", context do
    assert Membership.list_active_members_of_group(group_id!(context, @board_name)) == []
    context
  end

  step "Board should remain listed for KMC members", context do
    Enum.each(["Alice", "Bob", "Carol", "Dan", "Eve"], fn person_name ->
      assert group_id!(context, @board_name) in Enum.map(
               Membership.list_discoverable_groups_for_member(
                 club_id!(context),
                 person_id!(context, person_name)
               ),
               & &1.group_id
             )
    end)

    context
  end

  step "its name, email address, and conversation history should be unchanged", context do
    assert board_snapshot(context) == Map.fetch!(context, :board_snapshot)
    context
  end

  step "Board should not be archived", context do
    assert Membership.get_group(group_id!(context, @board_name)) != nil
    context
  end

  step "Carol should be Board's only member", context do
    assert Enum.map(
             Membership.list_active_members_of_group(group_id!(context, @board_name)),
             & &1.name
           ) ==
             ["Carol"]

    context
  end

  step "Board should not have the conversation {string}", %{args: [subject]} = context do
    refute Enum.any?(
             Messaging.list_conversations_for_group(group_id!(context, @board_name)),
             &(&1.subject == subject)
           )

    context
  end

  step "Eve should receive the usual authorization rejection", context do
    assert {:ok, %{status: :rejected}} = Map.fetch!(context, :last_inbound_email_result)
    assert_received {:email, %Swoosh.Email{text_body: text_body}}
    assert text_body =~ "wasn't posted"
    context
  end

  step "no group recipient should receive an email for it", context do
    assert Fake.deliveries() == []
    context
  end

  defp ensure_custom_group(context, group_name, email_slug) do
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

  defp create_conversation(context, group_name, sender_name, subject) do
    case get_in(context, [:messages, subject]) do
      %{message_id: message_id} when is_binary(message_id) ->
        context

      nil ->
        message_id = Memba.ID.generate(:message)

        assert :ok =
                 Messaging.send_club_message_as_current_member(
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

        put_context(context, :messages, subject, %{
          club_id: club_id!(context),
          group_id: group_id!(context, group_name),
          message_id: message_id,
          subject: subject
        })
    end
  end

  defp create_reply(context, subject, sender_name, body) do
    root = message!(context, subject)
    reply_id = Memba.ID.generate(:message)

    assert :ok =
             Messaging.post_message_reply(
               %{
                 message_id: reply_id,
                 conversation_id: root.message_id,
                 sender_id: person_id!(context, sender_name),
                 body: body
               },
               consistency: :strong
             )

    put_context(context, :messages, body, Messaging.get_message(reply_id))
  end

  defp follow_conversation(context, person_name, subject) do
    message = message!(context, subject)

    assert :ok =
             Messaging.follow_conversation_as_current_member(
               %{
                 club_id: message.club_id,
                 conversation_id: message.message_id,
                 member_id: person_id!(context, person_name)
               },
               consistency: :strong
             )

    context
  end

  defp remove_group_member(context, target_name, actor_name) do
    assert {:ok, %Membership.CustomGroupRemoval{transition: :member_removed}} =
             Membership.remove_custom_group_member(
               %{
                 club_id: club_id!(context),
                 group_id: group_id!(context, @board_name),
                 membership_id: membership_id!(context, target_name),
                 person_id: person_id!(context, target_name),
                 actor_person_id: person_id!(context, actor_name),
                 removal_operation_id: Ecto.UUID.generate()
               },
               consistency: :strong
             )

    context
  end

  defp add_custom_group_member(context, actor_name, target_name) do
    assert {:ok, %Membership.CustomGroupAdmission{}} =
             Membership.add_custom_group_member(
               %{
                 club_id: club_id!(context),
                 group_id: group_id!(context, @board_name),
                 membership_id: membership_id!(context, target_name),
                 person_id: person_id!(context, target_name),
                 actor_person_id: person_id!(context, actor_name)
               },
               consistency: :strong
             )

    context
  end

  defp carol_delivery!(context, message_key) do
    message = message!(context, message_key)
    carol_id = person_id!(context, "Carol")

    message.message_id
    |> Messaging.list_recipient_deliveries()
    |> Enum.find(&(&1.recipient_id == carol_id))
    |> case do
      nil -> flunk("Expected Carol delivery for #{inspect(message_key)}")
      delivery -> delivery
    end
  end

  defp refute_carol_access(context, message) do
    for access_level <- [:read, :write] do
      refute Messaging.member_has_conversation_access?(
               message.message_id,
               message.club_id,
               person_id!(context, "Carol"),
               access_level
             )
    end
  end

  defp assert_carol_follows(context, subject) do
    assert Messaging.following_conversation?(
             message!(context, subject).message_id,
             person_id!(context, "Carol")
           )

    context
  end

  defp snapshot_board(context), do: Map.put(context, :board_snapshot, board_snapshot(context))

  defp board_snapshot(context) do
    group = Membership.get_group(group_id!(context, @board_name))

    %{
      name: group.name,
      email_slug: group.email_slug,
      conversation_ids:
        context
        |> group_id!(@board_name)
        |> Messaging.list_conversations_for_group()
        |> Enum.map(& &1.message_id)
        |> Enum.sort(),
      history:
        context
        |> message!(@board_subject)
        |> Map.fetch!(:message_id)
        |> Messaging.list_conversation_messages()
        |> Enum.map(&{&1.message_id, &1.body})
        |> Enum.sort()
    }
  end

  defp end_carol_membership(context) do
    drain_email_deliveries()
    Fake.reset()

    assert :ok =
             Membership.remove_member(
               %{membership_id: membership_id!(context, "Carol")},
               consistency: :strong
             )

    Map.put(context, :carol_membership_ended, true)
  end

  defp refute_group_memberships(context, group_names) do
    Enum.each(group_names, fn group_name ->
      refute Membership.active_member_of_group?(
               group_id!(context, group_name),
               person_id!(context, "Carol")
             )
    end)
  end

  defp refute_conversation_follows(context, subjects) do
    Enum.each(subjects, fn subject ->
      refute Messaging.following_conversation?(
               message!(context, subject).message_id,
               person_id!(context, "Carol")
             )
    end)
  end

  defp refute_conversation_access(context, subjects) do
    Enum.each(subjects, fn subject ->
      message = message!(context, subject)

      for access_level <- [:read, :write] do
        refute Messaging.member_has_conversation_access?(
                 message.message_id,
                 message.club_id,
                 person_id!(context, "Carol"),
                 access_level
               )
      end
    end)
  end

  defp assert_no_future_group_emails(context) do
    Fake.reset()

    future_message_ids =
      Enum.flat_map(
        [
          {@board_name, @board_subject, "Future Board conversation"},
          {@trips_name, @trips_subject, "Future Trips conversation"}
        ],
        fn {group_name, existing_subject, future_subject} ->
          root_id = Memba.ID.generate(:message)

          assert :ok =
                   Messaging.send_club_message_as_current_member(
                     %{
                       message_id: root_id,
                       club_id: club_id!(context),
                       sender_id: person_id!(context, "Alice"),
                       audience_group_id: group_id!(context, group_name),
                       subject: future_subject,
                       body: "#{future_subject} details."
                     },
                     consistency: :strong
                   )

          reply_id = Memba.ID.generate(:message)

          assert :ok =
                   Messaging.post_message_reply(
                     %{
                       message_id: reply_id,
                       conversation_id: message!(context, existing_subject).message_id,
                       sender_id: person_id!(context, "Alice"),
                       body: "Future reply in #{group_name}"
                     },
                     consistency: :strong
                   )

          [root_id, reply_id]
        end
      )

    carol_id = person_id!(context, "Carol")

    Enum.each(future_message_ids, fn message_id ->
      refute Enum.any?(
               Messaging.list_recipient_deliveries(message_id),
               &(&1.recipient_id == carol_id)
             )
    end)

    drain_email_deliveries()

    refute Enum.any?(
             Fake.deliveries(),
             &(&1.message_id in future_message_ids and &1.recipient_id == carol_id)
           )

    context
  end

  defp drain_email_deliveries do
    _deliveries = EmailDeliveryDispatcher.dispatch_pending_email_deliveries()
    :ok
  end

  defp club_id!(context), do: fetch_context!(context, :clubs, @club_name)

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

  defp message!(context, key) do
    case get_in(context, [:messages, key]) do
      nil ->
        context
        |> Map.fetch!(:messages)
        |> Map.values()
        |> Enum.flat_map(&Messaging.list_conversation_messages(&1.message_id))
        |> Enum.find(&(&1.body == key))
        |> case do
          nil -> flunk("Expected message for #{inspect(key)}")
          message -> message
        end

      message ->
        message
    end
  end

  defp fetch_context!(context, collection_key, item_key) do
    context
    |> Map.fetch!(collection_key)
    |> Map.fetch!(item_key)
  end

  defp put_context(context, collection_key, item_key, value) do
    Map.update(context, collection_key, %{item_key => value}, &Map.put(&1, item_key, value))
  end
end
