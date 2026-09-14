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

    context
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
