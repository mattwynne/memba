defmodule Memba.Messaging.MessageProjectionTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.Messaging
  alias Memba.Messaging.App
  alias Memba.Messaging.Commands.SendMessage
  alias Memba.Messaging.Projections.EmailDelivery, as: EmailDeliveryProjection

  alias Memba.Messaging.Projections.ConversationGroupAccess,
    as: ConversationGroupAccessProjection

  alias Memba.Messaging.Projections.Message, as: MessageProjection
  alias Memba.Messaging.OutboundMessageID
  alias Memba.Messaging.Recipient

  test "SendMessage is projected into public Messaging message and delivery queries" do
    message_id = Memba.ID.generate(:message)
    club_id = Memba.ID.generate(:club)
    sender_id = Memba.ID.generate(:person)
    bob_id = Memba.ID.generate(:person)
    alice_delivery_id = Memba.ID.generate(:delivery)
    bob_delivery_id = Memba.ID.generate(:delivery)

    assert is_nil(Messaging.get_message(message_id))
    assert Messaging.list_recipient_deliveries(message_id) == []

    assert :ok =
             App.dispatch(
               %SendMessage{
                 message_id: message_id,
                 club_id: club_id,
                 sender_id: sender_id,
                 subject: "Trip planning night",
                 body: "Bring route ideas.",
                 recipients: [
                   %Recipient{
                     delivery_id: alice_delivery_id,
                     person_id: sender_id,
                     name: "Alice",
                     email: "alice@example.com"
                   },
                   %Recipient{
                     delivery_id: bob_delivery_id,
                     person_id: bob_id,
                     name: "Bob",
                     email: "bob@example.com"
                   }
                 ]
               },
               consistency: :strong
             )

    assert %MessageProjection{
             message_id: ^message_id,
             club_id: ^club_id,
             sender_id: ^sender_id,
             conversation_id: ^message_id,
             reply_to_message_id: nil,
             subject: "Trip planning night",
             body: "Bring route ideas."
           } = Messaging.get_message(message_id)

    assert [
             %EmailDeliveryProjection{
               delivery_id: ^alice_delivery_id,
               message_id: ^message_id,
               outbound_message_id: alice_outbound_message_id,
               recipient_id: ^sender_id,
               recipient_name: "Alice",
               recipient_address: "alice@example.com",
               channel: "email",
               status: "pending",
               attempt_count: 0,
               latest_error: nil,
               latest_detail: nil,
               last_dispatch_attempted_at: nil,
               sent_at: nil,
               failed_at: nil
             },
             %EmailDeliveryProjection{
               delivery_id: ^bob_delivery_id,
               message_id: ^message_id,
               outbound_message_id: bob_outbound_message_id,
               recipient_id: ^bob_id,
               recipient_name: "Bob",
               recipient_address: "bob@example.com",
               channel: "email",
               status: "pending",
               attempt_count: 0,
               latest_error: nil,
               latest_detail: nil,
               last_dispatch_attempted_at: nil,
               sent_at: nil,
               failed_at: nil
             }
           ] = Messaging.list_recipient_deliveries(message_id)

    assert alice_outbound_message_id ==
             OutboundMessageID.for_delivery(alice_delivery_id, message_id)

    assert bob_outbound_message_id == OutboundMessageID.for_delivery(bob_delivery_id, message_id)

    assert %{
             outbound_message_id: ^alice_outbound_message_id,
             delivery_id: ^alice_delivery_id,
             message_id: ^message_id,
             conversation_id: ^message_id,
             club_id: ^club_id
           } = Messaging.get_outbound_message_reference(alice_outbound_message_id)

    assert %{
             outbound_message_id: ^bob_outbound_message_id,
             delivery_id: ^bob_delivery_id,
             message_id: ^message_id,
             conversation_id: ^message_id,
             club_id: ^club_id
           } =
             Messaging.get_outbound_message_reference(String.trim(bob_outbound_message_id, "<>"))

    assert is_nil(Messaging.get_outbound_message_reference("<unknown@example.test>"))

    assert %EmailDeliveryProjection{
             delivery_id: ^bob_delivery_id,
             message_id: ^message_id,
             recipient_id: ^bob_id
           } = Messaging.get_email_delivery(bob_delivery_id)
  end

  test "message and delivery queries return empty results for missing or invalid IDs" do
    assert is_nil(Messaging.get_message(Memba.ID.generate(:message)))
    assert is_nil(Messaging.get_message(nil))
    assert is_nil(Messaging.get_message("not-a-uuid"))

    assert Messaging.list_conversation_messages(Memba.ID.generate(:message)) == []
    assert Messaging.list_conversation_messages(nil) == []
    assert Messaging.list_conversation_messages("not-a-uuid") == []

    assert Messaging.list_conversations_for_club(Memba.ID.generate(:club)) == []
    assert Messaging.list_conversations_for_club(nil) == []
    assert Messaging.list_conversations_for_club("not-a-uuid") == []

    assert Messaging.list_conversations_for_group(Memba.ID.generate(:group)) == []
    assert Messaging.list_conversations_for_group(nil) == []
    assert Messaging.list_conversations_for_group("not-a-uuid") == []

    assert Messaging.list_conversation_messages_for_group(
             Memba.ID.generate(:message),
             Memba.ID.generate(:group)
           ) == []

    assert Messaging.list_conversation_messages_for_group(nil, Memba.ID.generate(:group)) == []
    assert Messaging.list_conversation_messages_for_group("not-a-uuid", "not-a-uuid") == []

    assert is_nil(Messaging.get_email_delivery(Memba.ID.generate(:delivery)))
    assert is_nil(Messaging.get_email_delivery(nil))
    assert is_nil(Messaging.get_email_delivery("not-a-uuid"))

    assert Messaging.list_recipient_deliveries(Memba.ID.generate(:message)) == []
    assert Messaging.list_recipient_deliveries(nil) == []
    assert Messaging.list_recipient_deliveries("not-a-uuid") == []
  end

  describe "list_conversations_for_club/1" do
    test "returns root conversations with reply counts and latest replier names" do
      club_id = Memba.ID.generate(:club)
      other_club_id = Memba.ID.generate(:club)

      alice =
        insert_membership_person!(
          person_id: Memba.ID.generate(:person),
          name: "Alice Ridge",
          email: "alice-ridge@example.com"
        )

      bob =
        insert_membership_person!(
          person_id: Memba.ID.generate(:person),
          name: "Bob Maps",
          email: "bob-maps@example.com"
        )

      carol =
        insert_membership_person!(
          person_id: Memba.ID.generate(:person),
          name: "Carol Snacks",
          email: "carol-snacks@example.com"
        )

      newer_root =
        insert_message_projection!(
          club_id: club_id,
          sender_id: alice.person_id,
          subject: "Sunday weather window",
          body: "Looks good for a short hike.",
          inserted_at: ~U[2026-06-05 12:00:00.000000Z]
        )

      older_root =
        insert_message_projection!(
          club_id: club_id,
          sender_id: alice.person_id,
          subject: "Saturday ridge walk",
          body: "Meet at the trailhead.",
          inserted_at: ~U[2026-06-05 10:00:00.000000Z]
        )

      older_reply =
        insert_message_projection!(
          club_id: club_id,
          sender_id: bob.person_id,
          conversation_id: older_root.message_id,
          reply_to_message_id: older_root.message_id,
          subject: "Saturday ridge walk",
          body: "I can bring maps.",
          inserted_at: ~U[2026-06-05 10:10:00.000000Z]
        )

      newer_reply_to_older_conversation =
        insert_message_projection!(
          club_id: club_id,
          sender_id: carol.person_id,
          conversation_id: older_root.message_id,
          reply_to_message_id: older_reply.message_id,
          subject: "Saturday ridge walk",
          body: "I can bring snacks.",
          inserted_at: ~U[2026-06-05 13:00:00.000000Z]
        )

      unrelated_root =
        insert_message_projection!(
          club_id: other_club_id,
          sender_id: bob.person_id,
          subject: "Other club thread",
          inserted_at: ~U[2026-06-05 14:00:00.000000Z]
        )

      _unrelated_reply =
        insert_message_projection!(
          club_id: other_club_id,
          sender_id: carol.person_id,
          conversation_id: unrelated_root.message_id,
          reply_to_message_id: unrelated_root.message_id,
          subject: "Other club thread",
          inserted_at: ~U[2026-06-05 14:05:00.000000Z]
        )

      assert [
               %{
                 message: %MessageProjection{message_id: newer_root_id},
                 message_id: newer_root_id,
                 conversation_id: newer_root_id,
                 sender_id: newer_sender_id,
                 subject: "Sunday weather window",
                 body: "Looks good for a short hike.",
                 inserted_at: ~U[2026-06-05 12:00:00.000000Z],
                 reply_count: 0,
                 latest_replier_id: nil,
                 latest_replier_name: nil
               },
               %{
                 message: %MessageProjection{message_id: older_root_id},
                 message_id: older_root_id,
                 conversation_id: older_root_id,
                 sender_id: older_sender_id,
                 subject: "Saturday ridge walk",
                 body: "Meet at the trailhead.",
                 inserted_at: ~U[2026-06-05 10:00:00.000000Z],
                 reply_count: 2,
                 latest_replier_id: latest_replier_id,
                 latest_replier_name: "Carol Snacks"
               }
             ] = Messaging.list_conversations_for_club(club_id)

      assert newer_root_id == newer_root.message_id
      assert older_root_id == older_root.message_id
      assert newer_sender_id == alice.person_id
      assert older_sender_id == alice.person_id
      assert latest_replier_id == carol.person_id
      refute newer_reply_to_older_conversation.message_id in [newer_root_id, older_root_id]
      refute unrelated_root.message_id in [newer_root_id, older_root_id]
    end

    test "returns distinct reply participants per conversation ordered by first reply" do
      club_id = Memba.ID.generate(:club)
      alice_id = Memba.ID.generate(:person)
      bob_id = Memba.ID.generate(:person)
      carol_id = Memba.ID.generate(:person)
      dave_id = Memba.ID.generate(:person)

      quiet_root =
        insert_message_projection!(
          club_id: club_id,
          sender_id: alice_id,
          subject: "Quiet route idea",
          inserted_at: ~U[2026-06-05 11:00:00.000000Z]
        )

      active_root =
        insert_message_projection!(
          club_id: club_id,
          sender_id: alice_id,
          subject: "Busy route idea",
          inserted_at: ~U[2026-06-05 10:00:00.000000Z]
        )

      _originator_reply =
        insert_message_projection!(
          club_id: club_id,
          sender_id: alice_id,
          conversation_id: active_root.message_id,
          reply_to_message_id: active_root.message_id,
          subject: "Busy route idea",
          inserted_at: ~U[2026-06-05 10:01:00.000000Z]
        )

      _carol_first_reply =
        insert_message_projection!(
          club_id: club_id,
          sender_id: carol_id,
          conversation_id: active_root.message_id,
          reply_to_message_id: active_root.message_id,
          subject: "Busy route idea",
          inserted_at: ~U[2026-06-05 10:02:00.000000Z]
        )

      _bob_first_reply =
        insert_message_projection!(
          club_id: club_id,
          sender_id: bob_id,
          conversation_id: active_root.message_id,
          reply_to_message_id: active_root.message_id,
          subject: "Busy route idea",
          inserted_at: ~U[2026-06-05 10:03:00.000000Z]
        )

      _carol_duplicate_reply =
        insert_message_projection!(
          club_id: club_id,
          sender_id: carol_id,
          conversation_id: active_root.message_id,
          reply_to_message_id: active_root.message_id,
          subject: "Busy route idea",
          inserted_at: ~U[2026-06-05 10:04:00.000000Z]
        )

      _dave_reply =
        insert_message_projection!(
          club_id: club_id,
          sender_id: dave_id,
          conversation_id: active_root.message_id,
          reply_to_message_id: active_root.message_id,
          subject: "Busy route idea",
          inserted_at: ~U[2026-06-05 10:05:00.000000Z]
        )

      assert [
               %{message_id: quiet_root_id, participant_ids: []},
               %{message_id: active_root_id, participant_ids: participant_ids}
             ] = Messaging.list_conversations_for_club(club_id)

      assert quiet_root_id == quiet_root.message_id
      assert active_root_id == active_root.message_id
      assert participant_ids == [carol_id, bob_id, dave_id]
    end
  end

  describe "list_conversations_for_group/1" do
    test "returns only conversations with a read-capable grant for the supplied group" do
      club_id = Memba.ID.generate(:club)
      everyone_group_id = Memba.ID.generate(:group)
      admin_group_id = Memba.ID.generate(:group)
      sender_id = Memba.ID.generate(:person)
      replier_id = Memba.ID.generate(:person)

      insert_membership_person!(
        person_id: replier_id,
        name: "Robin Replier",
        email: "robin-replier@example.com"
      )

      everyone_root =
        insert_message_projection!(
          club_id: club_id,
          sender_id: sender_id,
          subject: "Everyone conversation",
          inserted_at: ~U[2026-06-05 10:00:00.000000Z]
        )

      _everyone_reply =
        insert_message_projection!(
          club_id: club_id,
          sender_id: replier_id,
          conversation_id: everyone_root.message_id,
          reply_to_message_id: everyone_root.message_id,
          subject: "Everyone conversation",
          inserted_at: ~U[2026-06-05 10:05:00.000000Z]
        )

      admin_root =
        insert_message_projection!(
          club_id: club_id,
          sender_id: sender_id,
          subject: "Admin conversation",
          inserted_at: ~U[2026-06-05 11:00:00.000000Z]
        )

      shared_root =
        insert_message_projection!(
          club_id: club_id,
          sender_id: sender_id,
          subject: "Shared conversation",
          inserted_at: ~U[2026-06-05 12:00:00.000000Z]
        )

      _ungranted_root =
        insert_message_projection!(
          club_id: club_id,
          sender_id: sender_id,
          subject: "No group access",
          inserted_at: ~U[2026-06-05 13:00:00.000000Z]
        )

      grant_group_access!(everyone_root, everyone_group_id, "write")
      grant_group_access!(admin_root, admin_group_id, "write")
      grant_group_access!(shared_root, everyone_group_id, "read")
      grant_group_access!(shared_root, admin_group_id, "write")

      assert [
               %{message_id: shared_root_id, reply_count: 0, latest_replier_name: nil},
               %{
                 message_id: everyone_root_id,
                 reply_count: 1,
                 latest_replier_id: ^replier_id,
                 latest_replier_name: "Robin Replier"
               }
             ] = Messaging.list_conversations_for_group(everyone_group_id)

      assert shared_root_id == shared_root.message_id
      assert everyone_root_id == everyone_root.message_id

      assert [
               %{message_id: shared_root_id},
               %{message_id: admin_root_id}
             ] = Messaging.list_conversations_for_group(admin_group_id)

      assert shared_root_id == shared_root.message_id
      assert admin_root_id == admin_root.message_id
    end

    test "does not expose a conversation through a cross-club access row" do
      root =
        insert_message_projection!(
          club_id: Memba.ID.generate(:club),
          sender_id: Memba.ID.generate(:person),
          subject: "Private conversation",
          inserted_at: ~U[2026-06-05 10:00:00.000000Z]
        )

      group_id = Memba.ID.generate(:group)
      grant_group_access!(root, group_id, "read", club_id: Memba.ID.generate(:club))

      assert Messaging.list_conversations_for_group(group_id) == []
    end
  end

  describe "list_conversation_messages/1" do
    test "returns the root message followed by replies in posted order" do
      club_id = Memba.ID.generate(:club)
      alice_id = Memba.ID.generate(:person)
      bob_id = Memba.ID.generate(:person)
      carol_id = Memba.ID.generate(:person)

      unrelated =
        insert_message_projection!(
          club_id: club_id,
          sender_id: alice_id,
          subject: "Unrelated thread",
          inserted_at: ~U[2026-06-05 09:00:00.000000Z]
        )

      root =
        insert_message_projection!(
          club_id: club_id,
          sender_id: alice_id,
          subject: "Trip planning night",
          body: "Bring route ideas.",
          inserted_at: ~U[2026-06-05 12:00:00.000000Z]
        )

      newer_reply =
        insert_message_projection!(
          club_id: club_id,
          sender_id: carol_id,
          conversation_id: root.message_id,
          reply_to_message_id: root.message_id,
          subject: "Trip planning night",
          body: "I can bring snacks.",
          inserted_at: ~U[2026-06-05 12:03:00.000000Z]
        )

      older_reply =
        insert_message_projection!(
          club_id: club_id,
          sender_id: bob_id,
          conversation_id: root.message_id,
          reply_to_message_id: root.message_id,
          subject: "Trip planning night",
          body: "I can bring maps.",
          inserted_at: ~U[2026-06-05 12:01:00.000000Z]
        )

      assert [
               %MessageProjection{message_id: root_id, reply_to_message_id: nil},
               %MessageProjection{
                 message_id: older_reply_id,
                 reply_to_message_id: older_reply_to_message_id
               },
               %MessageProjection{
                 message_id: newer_reply_id,
                 reply_to_message_id: newer_reply_to_message_id
               }
             ] = Messaging.list_conversation_messages(root.message_id)

      assert root_id == root.message_id
      assert older_reply_id == older_reply.message_id
      assert newer_reply_id == newer_reply.message_id
      assert older_reply_to_message_id == root.message_id
      assert newer_reply_to_message_id == root.message_id
      refute unrelated.message_id in [root_id, older_reply_id, newer_reply_id]
    end

    test "accepts a reply message id and returns its root conversation" do
      club_id = Memba.ID.generate(:club)
      alice_id = Memba.ID.generate(:person)
      bob_id = Memba.ID.generate(:person)

      root =
        insert_message_projection!(
          club_id: club_id,
          sender_id: alice_id,
          subject: "Trip planning night",
          inserted_at: ~U[2026-06-05 12:00:00.000000Z]
        )

      reply =
        insert_message_projection!(
          club_id: club_id,
          sender_id: bob_id,
          conversation_id: root.message_id,
          reply_to_message_id: root.message_id,
          subject: "Trip planning night",
          inserted_at: ~U[2026-06-05 12:01:00.000000Z]
        )

      assert [
               %MessageProjection{message_id: root_id},
               %MessageProjection{message_id: reply_id}
             ] = Messaging.list_conversation_messages(reply.message_id)

      assert root_id == root.message_id
      assert reply_id == reply.message_id
    end

    test "returns an empty list for orphaned reply projections without a root" do
      missing_root_id = Memba.ID.generate(:message)

      _orphaned_reply =
        insert_message_projection!(
          club_id: Memba.ID.generate(:club),
          sender_id: Memba.ID.generate(:person),
          conversation_id: missing_root_id,
          reply_to_message_id: missing_root_id,
          subject: "Trip planning night",
          inserted_at: ~U[2026-06-05 12:01:00.000000Z]
        )

      assert Messaging.list_conversation_messages(missing_root_id) == []
    end
  end

  describe "list_conversation_messages_for_group/2" do
    test "returns a complete conversation through its root access grant" do
      club_id = Memba.ID.generate(:club)
      group_id = Memba.ID.generate(:group)
      other_group_id = Memba.ID.generate(:group)

      root =
        insert_message_projection!(
          club_id: club_id,
          sender_id: Memba.ID.generate(:person),
          subject: "Private trip planning",
          inserted_at: ~U[2026-06-05 12:00:00.000000Z]
        )

      reply =
        insert_message_projection!(
          club_id: club_id,
          sender_id: Memba.ID.generate(:person),
          conversation_id: root.message_id,
          reply_to_message_id: root.message_id,
          subject: "Private trip planning",
          inserted_at: ~U[2026-06-05 12:01:00.000000Z]
        )

      grant_group_access!(root, group_id, "read")

      assert [
               %MessageProjection{message_id: root_id},
               %MessageProjection{message_id: reply_id}
             ] = Messaging.list_conversation_messages_for_group(reply.message_id, group_id)

      assert root_id == root.message_id
      assert reply_id == reply.message_id

      assert Messaging.list_conversation_messages_for_group(root.message_id, other_group_id) == []
    end

    test "requires the access row to match the root conversation's club" do
      root =
        insert_message_projection!(
          club_id: Memba.ID.generate(:club),
          sender_id: Memba.ID.generate(:person),
          subject: "Private conversation",
          inserted_at: ~U[2026-06-05 12:00:00.000000Z]
        )

      group_id = Memba.ID.generate(:group)
      grant_group_access!(root, group_id, "write", club_id: Memba.ID.generate(:club))

      assert Messaging.list_conversation_messages_for_group(root.message_id, group_id) == []
    end
  end

  describe "list_operator_messages/0" do
    test "returns projected messages with club and sender context where available" do
      kootenay = insert_membership_club!(name: "Kootenay Mountaineering Club")
      nelson = insert_membership_club!(name: "Nelson Cycling Club")
      alice = insert_membership_person!(name: "Alice", email: "alice@example.com")
      bob = insert_membership_person!(name: "Bob", email: "bob@example.com")

      older_projected_at = ~U[2026-06-05 10:00:00.000000Z]
      missing_context_projected_at = ~U[2026-06-05 11:00:00.000000Z]
      newer_projected_at = ~U[2026-06-05 12:00:00.000000Z]

      older =
        insert_message_projection!(
          club_id: kootenay.club_id,
          sender_id: alice.person_id,
          subject: "Trip planning night",
          inserted_at: older_projected_at
        )

      missing_context =
        insert_message_projection!(
          club_id: Memba.ID.generate(:club),
          sender_id: Memba.ID.generate(:person),
          subject: "Context not projected",
          inserted_at: missing_context_projected_at
        )

      newer =
        insert_message_projection!(
          club_id: nelson.club_id,
          sender_id: bob.person_id,
          subject: "Ride update",
          inserted_at: newer_projected_at
        )

      assert [
               %{
                 message_id: newer_id,
                 subject: "Ride update",
                 club_id: newer_club_id,
                 club_name: "Nelson Cycling Club",
                 club_slug: nelson_slug,
                 sender_id: newer_sender_id,
                 sender_name: "Bob",
                 sender_email: "bob@example.com",
                 projected_at: ^newer_projected_at
               },
               %{
                 message_id: missing_context_id,
                 subject: "Context not projected",
                 club_name: nil,
                 club_slug: nil,
                 sender_name: nil,
                 sender_email: nil,
                 projected_at: ^missing_context_projected_at
               },
               %{
                 message_id: older_id,
                 subject: "Trip planning night",
                 club_id: older_club_id,
                 club_name: "Kootenay Mountaineering Club",
                 club_slug: kootenay_slug,
                 sender_id: older_sender_id,
                 sender_name: "Alice",
                 sender_email: "alice@example.com",
                 projected_at: ^older_projected_at
               }
             ] = Messaging.list_operator_messages()

      assert newer_id == newer.message_id
      assert newer_club_id == nelson.club_id
      assert newer_sender_id == bob.person_id
      assert older_id == older.message_id
      assert older_club_id == kootenay.club_id
      assert older_sender_id == alice.person_id
      assert missing_context_id == missing_context.message_id
      assert nelson_slug == nelson.slug
      assert kootenay_slug == kootenay.slug
    end
  end

  defp insert_message_projection!(attrs) when is_list(attrs) do
    inserted_at = Keyword.fetch!(attrs, :inserted_at)
    message_id = Keyword.get_lazy(attrs, :message_id, fn -> Memba.ID.generate(:message) end)

    Repo.insert!(%MessageProjection{
      message_id: message_id,
      club_id: Keyword.fetch!(attrs, :club_id),
      sender_id: Keyword.fetch!(attrs, :sender_id),
      subject: Keyword.fetch!(attrs, :subject),
      body: Keyword.get(attrs, :body, "Message body."),
      conversation_id: Keyword.get(attrs, :conversation_id, message_id),
      reply_to_message_id: Keyword.get(attrs, :reply_to_message_id),
      inserted_at: inserted_at,
      updated_at: Keyword.get(attrs, :updated_at, inserted_at)
    })
  end

  defp grant_group_access!(conversation, group_id, access_level, opts \\ []) do
    Repo.insert!(%ConversationGroupAccessProjection{
      conversation_id: conversation.message_id,
      club_id: Keyword.get(opts, :club_id, conversation.club_id),
      group_id: group_id,
      access_level: access_level
    })
  end
end
