defmodule Memba.Messaging.MessageProjectionTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.Messaging
  alias Memba.Messaging.App
  alias Memba.Messaging.Commands.SendMessage
  alias Memba.Messaging.Projections.Message, as: MessageProjection
  alias Memba.Messaging.Projections.EmailDelivery, as: EmailDeliveryProjection
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
             subject: "Trip planning night",
             body: "Bring route ideas."
           } = Messaging.get_message(message_id)

    assert [
             %EmailDeliveryProjection{
               delivery_id: ^alice_delivery_id,
               message_id: ^message_id,
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

    assert is_nil(Messaging.get_email_delivery(Memba.ID.generate(:delivery)))
    assert is_nil(Messaging.get_email_delivery(nil))
    assert is_nil(Messaging.get_email_delivery("not-a-uuid"))

    assert Messaging.list_recipient_deliveries(Memba.ID.generate(:message)) == []
    assert Messaging.list_recipient_deliveries(nil) == []
    assert Messaging.list_recipient_deliveries("not-a-uuid") == []
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

    Repo.insert!(%MessageProjection{
      message_id: Keyword.get_lazy(attrs, :message_id, fn -> Memba.ID.generate(:message) end),
      club_id: Keyword.fetch!(attrs, :club_id),
      sender_id: Keyword.fetch!(attrs, :sender_id),
      subject: Keyword.fetch!(attrs, :subject),
      body: Keyword.get(attrs, :body, "Message body."),
      inserted_at: inserted_at,
      updated_at: Keyword.get(attrs, :updated_at, inserted_at)
    })
  end
end
