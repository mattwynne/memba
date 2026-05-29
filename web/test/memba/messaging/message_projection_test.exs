defmodule Memba.Messaging.MessageProjectionTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.Messaging
  alias Memba.Messaging.App
  alias Memba.Messaging.Commands.SendMessage
  alias Memba.Messaging.Projections.Message, as: MessageProjection
  alias Memba.Messaging.Projections.RecipientDelivery, as: RecipientDeliveryProjection
  alias Memba.Messaging.Recipient

  test "SendMessage is projected into public Messaging message and delivery queries" do
    message_id = Ecto.UUID.generate()
    club_id = Ecto.UUID.generate()
    sender_id = Ecto.UUID.generate()
    bob_id = Ecto.UUID.generate()
    alice_delivery_id = Ecto.UUID.generate()
    bob_delivery_id = Ecto.UUID.generate()

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
             %RecipientDeliveryProjection{
               delivery_id: ^alice_delivery_id,
               message_id: ^message_id,
               recipient_id: ^sender_id,
               recipient_name: "Alice",
               recipient_address: "alice@example.com",
               channel: "email",
               status: "sent"
             },
             %RecipientDeliveryProjection{
               delivery_id: ^bob_delivery_id,
               message_id: ^message_id,
               recipient_id: ^bob_id,
               recipient_name: "Bob",
               recipient_address: "bob@example.com",
               channel: "email",
               status: "sent"
             }
           ] = Messaging.list_recipient_deliveries(message_id)

    assert %RecipientDeliveryProjection{
             delivery_id: ^bob_delivery_id,
             message_id: ^message_id,
             recipient_id: ^bob_id
           } = Messaging.get_recipient_delivery(bob_delivery_id)
  end

  test "message and delivery queries return empty results for missing or invalid IDs" do
    assert is_nil(Messaging.get_message(Ecto.UUID.generate()))
    assert is_nil(Messaging.get_message(nil))
    assert is_nil(Messaging.get_message("not-a-uuid"))

    assert is_nil(Messaging.get_recipient_delivery(Ecto.UUID.generate()))
    assert is_nil(Messaging.get_recipient_delivery(nil))
    assert is_nil(Messaging.get_recipient_delivery("not-a-uuid"))

    assert Messaging.list_recipient_deliveries(Ecto.UUID.generate()) == []
    assert Messaging.list_recipient_deliveries(nil) == []
    assert Messaging.list_recipient_deliveries("not-a-uuid") == []
  end
end
