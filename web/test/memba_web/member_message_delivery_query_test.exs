defmodule MembaWeb.MemberMessageDeliveryQueryTest do
  use Memba.EventSourcedCase, async: false

  alias LiveQuery.Query
  alias LiveQuery.Source
  alias Memba.Membership
  alias Memba.Membership.Projections.Group
  alias Memba.Membership.Projections.GroupMembership
  alias Memba.Membership.SystemGroups
  alias Memba.Messaging
  alias Memba.Messaging.Events.EmailDeliveryDelivered
  alias Memba.Messaging.Projections.MemberEmailDelivery
  alias Memba.Messaging.Projections.MembaStaffEmailDelivery
  alias MembaWeb.LiveQuery.MembaReadModelSource
  alias MembaWeb.MemberMessageDeliveryQuery

  test "describes and loads one delivery-specific result with exact represented interests" do
    context = create_delivery_context()
    query = MemberMessageDeliveryQuery.query()

    assert query.id == :member_message_delivery
    assert query.assign == :delivery_detail

    inputs = %{
      club_id: context.club_id,
      message_id: context.message.message_id,
      authenticated_email: "  VIEWER@EXAMPLE.COM "
    }

    assert {:ok, result, interests} = Query.load(query, inputs)

    assert Map.keys(result) |> Enum.sort() == [
             :conversation_audience,
             :current_member,
             :delivery_message_id,
             :member_email_delivery_count,
             :member_email_delivery_groups,
             :member_email_delivery_ids,
             :member_email_delivery_summary,
             :member_email_deliverys,
             :message,
             :page_title,
             :selected_club,
             :sender_name
           ]

    assert result.selected_club.club_id == context.club_id
    assert result.current_member.id == context.viewer.person_id
    assert result.message.message_id == context.message.message_id
    assert result.delivery_message_id == context.message.message_id
    assert result.conversation_audience.conversation_id == context.message.message_id
    assert result.sender_name == "Sender Example"
    assert result.member_email_delivery_ids == [context.delivery.delivery_id]
    assert result.member_email_delivery_count == 1

    assert [
             %{
               recipient_id: recipient_id,
               recipient_name: "Recipient Example",
               status: "delivered",
               reason: nil
             }
           ] = result.member_email_deliverys

    assert recipient_id == context.recipient.person_id

    expected_interests = [
      {:club, context.club_id},
      {:membership, context.viewer.membership_id},
      {:person, context.viewer.person_id},
      {:person_club, context.club_id, context.viewer.person_id},
      {:group_participation, context.club_id, context.everyone_group_id,
       context.viewer.person_id},
      {:conversation, context.message.message_id},
      {:conversation_access, context.everyone_group_id, context.message.message_id},
      {:message, context.message.message_id},
      {:message_deliveries, context.message.message_id},
      {:delivery, context.delivery.delivery_id},
      {:person, context.sender.person_id},
      {:person, context.recipient.person_id}
    ]

    assert MapSet.new(interests) == MapSet.new(expected_interests)
    assert length(interests) == length(expected_interests)

    excluded_result_keys = [
      :root_message,
      :conversation_entries,
      :following_conversation,
      :can_follow_conversation,
      :member_email_delivery_records,
      :route_params,
      :group_id,
      :disclosure,
      :flash,
      :navigation
    ]

    refute Enum.any?(excluded_result_keys, &Map.has_key?(result, &1))
    refute {:conversation_messages, context.message.message_id} in interests

    refute {:conversation_follow, context.message.message_id, context.viewer.person_id} in interests
  end

  test "normalizes attached-email identity and rereads active membership authority" do
    context = create_delivery_context()

    insert_membership_person_email_address!(
      person_id: context.viewer.person_id,
      email: "viewer.attached@example.com",
      is_primary: false
    )

    assert {:ok, result} =
             MemberMessageDeliveryQuery.load(
               context.club_id,
               context.message.message_id,
               "  VIEWER.ATTACHED@EXAMPLE.COM "
             )

    assert result.current_member.id == context.viewer.person_id

    assert :ok =
             Membership.remove_member(
               %{membership_id: context.viewer.membership_id},
               consistency: :strong
             )

    assert {:error, :forbidden} =
             MemberMessageDeliveryQuery.load(
               context.club_id,
               context.message.message_id,
               "viewer.attached@example.com"
             )
  end

  test "preserves forbidden and not-found semantics across fresh authority and access checks" do
    context = create_delivery_context()
    foreign_sender = create_active_member("foreign@example.com", "Foreign Sender")
    foreign_message = create_message(foreign_sender, "Foreign message")
    private_group = create_group(context.club_id, context.sender, "Private Planning")
    add_group_member(private_group, context.sender)
    add_group_member(private_group, context.viewer, context.sender)
    private_message = create_message(context.sender, "Private message", private_group.group_id)

    assert {:error, :forbidden} =
             MemberMessageDeliveryQuery.load(
               nil,
               context.message.message_id,
               context.viewer.email
             )

    assert {:error, :forbidden} =
             MemberMessageDeliveryQuery.load(
               foreign_sender.club_id,
               foreign_message.message_id,
               context.viewer.email
             )

    assert {:error, :not_found} =
             MemberMessageDeliveryQuery.load(
               context.club_id,
               Memba.ID.generate(:message),
               context.viewer.email
             )

    assert {:error, :not_found} =
             MemberMessageDeliveryQuery.load(
               context.club_id,
               foreign_message.message_id,
               context.viewer.email
             )

    assert :ok =
             Messaging.revoke_conversation_access_from_group(
               %{
                 conversation_id: private_message.message_id,
                 club_id: context.club_id,
                 group_id: private_group.group_id,
                 access_level: :write
               },
               consistency: :strong
             )

    assert {:error, :not_found} =
             MemberMessageDeliveryQuery.load(
               context.club_id,
               private_message.message_id,
               context.viewer.email
             )
  end

  test "a routed reply presents its metadata but retains the root delivery scope" do
    context = create_delivery_context()
    reply = create_reply(context.message, context.viewer, "Reply body")

    assert {:ok, result} =
             MemberMessageDeliveryQuery.load(
               context.club_id,
               reply.message_id,
               context.viewer.email
             )

    interests = MemberMessageDeliveryQuery.interests(result)

    assert result.message.message_id == reply.message_id
    assert result.message.conversation_id == context.message.message_id
    assert result.delivery_message_id == context.message.message_id
    assert result.member_email_delivery_ids == [context.delivery.delivery_id]
    assert {:message, reply.message_id} in interests
    assert {:message, context.message.message_id} in interests
    assert {:message_deliveries, context.message.message_id} in interests
    refute {:message_deliveries, reply.message_id} in interests
  end

  test "both delivery projector notifications match the exact root scope and unrelated messages do not" do
    context = create_delivery_context()

    assert {:ok, result} =
             MemberMessageDeliveryQuery.load(
               context.club_id,
               context.message.message_id,
               context.viewer.email
             )

    interests = MemberMessageDeliveryQuery.interests(result)
    source = MembaReadModelSource.new()

    for projector <- [
          Memba.Messaging.Projectors.MemberEmailDelivery,
          Memba.Messaging.Projectors.MembaStaffEmailDelivery
        ] do
      notification =
        notification(
          projector,
          %EmailDeliveryDelivered{
            message_id: context.message.message_id,
            delivery_id: context.delivery.delivery_id
          }
        )

      assert {:ok, invalidations} = Source.classify(source, notification)
      assert query_matches?(source, interests, invalidations)

      unrelated =
        notification(
          projector,
          %EmailDeliveryDelivered{
            message_id: Memba.ID.generate(:message),
            delivery_id: Memba.ID.generate(:delivery)
          }
        )

      assert {:ok, unrelated_invalidations} = Source.classify(source, unrelated)
      refute query_matches?(source, interests, unrelated_invalidations)
    end
  end

  test "fresh reads converge member status and staff reason in either contributor order" do
    context = create_delivery_context(status: "sent")

    Repo.insert!(%MembaStaffEmailDelivery{
      delivery_id: context.delivery.delivery_id,
      message_id: context.message.message_id,
      recipient_id: context.recipient.person_id,
      recipient_name: "Recipient Example",
      recipient_address: context.recipient.email,
      channel: "email",
      status: "sent",
      reason: nil
    })

    update_staff_delivery(context.delivery.delivery_id, "delayed", "Temporary delay")
    assert_delivery(context, "sent", nil)

    update_member_delivery(context.delivery.delivery_id, "delivery problem")
    assert_delivery(context, "delivery problem", "Temporary delay")

    update_staff_delivery(context.delivery.delivery_id, "bounced", "Mailbox unavailable")
    assert_delivery(context, "delivery problem", "Mailbox unavailable")

    update_member_delivery(context.delivery.delivery_id, "delivered")
    assert_delivery(context, "delivered", nil)
  end

  test "returns the established safe zero-recipient presentation and no represented delivery interests" do
    context = create_delivery_context(receipt?: false)

    assert {:ok, result} =
             MemberMessageDeliveryQuery.load(
               context.club_id,
               context.message.message_id,
               context.viewer.email
             )

    interests = MemberMessageDeliveryQuery.interests(result)

    assert result.member_email_deliverys == []
    assert result.member_email_delivery_ids == []
    assert result.member_email_delivery_count == 0
    assert result.member_email_delivery_groups == []
    assert Enum.map(result.member_email_delivery_summary, & &1.percentage) == [0, 0, 0]
    refute Enum.any?(interests, &(elem(&1, 0) == :delivery))
    assert {:message_deliveries, context.message.message_id} in interests
  end

  defp create_delivery_context(options \\ []) do
    sender = create_active_member("sender@example.com", "Sender Example")
    viewer = create_active_member("viewer@example.com", "Viewer Example", sender.club_id)
    recipient = create_active_member("recipient@example.com", "Recipient Example", sender.club_id)
    message = create_message(sender, "Delivery query")

    delivery =
      if Keyword.get(options, :receipt?, true) do
        Repo.insert!(%MemberEmailDelivery{
          delivery_id: Memba.ID.generate(:delivery),
          message_id: message.message_id,
          recipient_id: recipient.person_id,
          recipient_name: "Recipient Example",
          status: Keyword.get(options, :status, "delivered")
        })
      end

    %{
      club_id: sender.club_id,
      everyone_group_id: SystemGroups.everyone_group_id(sender.club_id),
      sender: sender,
      viewer: viewer,
      recipient: recipient,
      message: message,
      delivery: delivery
    }
  end

  defp create_active_member(email, name, club_id \\ Memba.ID.generate(:club)) do
    unless Membership.get_club(club_id) do
      assert :ok =
               Membership.create_club(
                 membership_club_attrs(club_id: club_id, name: "Query Club"),
                 consistency: :strong
               )
    end

    person_id = Memba.ID.generate(:person)

    assert :ok =
             Membership.create_person(
               %{person_id: person_id, name: name, email: email},
               consistency: :strong
             )

    membership_id = Memba.ID.generate(:membership)

    assert :ok =
             Membership.add_member(
               %{membership_id: membership_id, club_id: club_id, person_id: person_id},
               consistency: :strong
             )

    %{
      club_id: club_id,
      person_id: person_id,
      membership_id: membership_id,
      email: email
    }
  end

  defp create_message(member, subject, audience_group_id \\ nil) do
    message_id = Memba.ID.generate(:message)

    assert :ok =
             Messaging.send_club_message_as_current_member(
               %{
                 message_id: message_id,
                 club_id: member.club_id,
                 sender_id: member.person_id,
                 audience_group_id:
                   audience_group_id || SystemGroups.everyone_group_id(member.club_id),
                 subject: subject,
                 body: "Bring your maps."
               },
               consistency: :strong
             )

    clear_deliveries(message_id)
    Messaging.get_message(message_id)
  end

  defp create_reply(message, member, body) do
    message_id = Memba.ID.generate(:message)

    assert :ok =
             Messaging.post_message_reply(
               %{
                 message_id: message_id,
                 conversation_id: message.message_id,
                 sender_id: member.person_id,
                 body: body
               },
               consistency: :strong
             )

    clear_deliveries(message_id)
    Messaging.get_message(message_id)
  end

  defp clear_deliveries(message_id) do
    Repo.delete_all(
      from(delivery in MemberEmailDelivery, where: delivery.message_id == ^message_id)
    )

    Repo.delete_all(
      from(delivery in MembaStaffEmailDelivery, where: delivery.message_id == ^message_id)
    )
  end

  defp create_group(club_id, actor, name) do
    group_id = Memba.ID.generate(:group)

    assert :ok =
             Membership.create_custom_group(
               %{
                 group_id: group_id,
                 club_id: club_id,
                 actor_person_id: actor.person_id,
                 name: name
               },
               consistency: :strong
             )

    Repo.get!(Group, group_id)
  end

  defp add_group_member(group, member, actor \\ nil) do
    actor = actor || member

    case Membership.add_custom_group_member(
           %{
             club_id: member.club_id,
             group_id: group.group_id,
             membership_id: member.membership_id,
             person_id: member.person_id,
             actor_person_id: actor.person_id
           },
           consistency: :strong
         ) do
      {:ok, _admission} ->
        Repo.get_by!(GroupMembership, group_id: group.group_id, person_id: member.person_id)

      {:error, :already_active_group_member} ->
        Repo.get_by!(GroupMembership, group_id: group.group_id, person_id: member.person_id)
    end
  end

  defp notification(projector, event) do
    {:read_model_changed,
     %{projector: projector, source_event: event, metadata: %{}, changes: %{}}}
  end

  defp query_matches?(source, interests, invalidations) do
    Enum.any?(interests, fn interest ->
      Enum.any?(invalidations, &Source.matches?(source, interest, &1))
    end)
  end

  defp update_member_delivery(delivery_id, status) do
    MemberEmailDelivery
    |> where([delivery], delivery.delivery_id == ^delivery_id)
    |> Repo.update_all(set: [status: status])
  end

  defp update_staff_delivery(delivery_id, status, reason) do
    MembaStaffEmailDelivery
    |> where([delivery], delivery.delivery_id == ^delivery_id)
    |> Repo.update_all(set: [status: status, reason: reason])
  end

  defp assert_delivery(context, status, reason) do
    assert {:ok, result} =
             MemberMessageDeliveryQuery.load(
               context.club_id,
               context.message.message_id,
               context.viewer.email
             )

    assert [%{status: ^status, reason: ^reason}] = result.member_email_deliverys
  end
end
