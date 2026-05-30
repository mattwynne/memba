defmodule Memba.Messaging.MessageTest do
  use ExUnit.Case, async: true

  alias Memba.Messaging.Commands.SendMessage
  alias Memba.Messaging.Events.MessageSent
  alias Memba.Messaging.Events.RecipientDeliveryCreated
  alias Memba.Messaging.Message
  alias Memba.Messaging.Recipient

  describe "execute/2 SendMessage" do
    test "emits MessageSent and one RecipientDeliveryCreated per resolved recipient" do
      message_id = Ecto.UUID.generate()
      club_id = Ecto.UUID.generate()
      sender_id = Ecto.UUID.generate()
      alice_delivery_id = Ecto.UUID.generate()
      bob_delivery_id = Ecto.UUID.generate()
      bob_id = Ecto.UUID.generate()

      command = %SendMessage{
        message_id: message_id,
        club_id: club_id,
        sender_id: sender_id,
        subject: " Trail day ",
        body: " Meet at 9am. ",
        recipients: [
          %Recipient{
            delivery_id: alice_delivery_id,
            person_id: sender_id,
            name: " Alice Sender ",
            email: " Alice@Example.COM "
          },
          %Recipient{
            delivery_id: bob_delivery_id,
            person_id: bob_id,
            name: " Bob Recipient ",
            email: " Bob@Example.COM "
          }
        ]
      }

      assert [
               %MessageSent{
                 message_id: ^message_id,
                 club_id: ^club_id,
                 sender_id: ^sender_id,
                 subject: "Trail day",
                 body: "Meet at 9am."
               },
               %RecipientDeliveryCreated{
                 message_id: ^message_id,
                 delivery_id: ^alice_delivery_id,
                 recipient_id: ^sender_id,
                 recipient_name: "Alice Sender",
                 recipient_email: "alice@example.com"
               },
               %RecipientDeliveryCreated{
                 message_id: ^message_id,
                 delivery_id: ^bob_delivery_id,
                 recipient_id: ^bob_id,
                 recipient_name: "Bob Recipient",
                 recipient_email: "bob@example.com"
               }
             ] = Message.execute(%Message{}, command)
    end

    test "rejects missing or malformed UUIDs" do
      valid_command = valid_send_message()

      assert {:error, :invalid_message_id} =
               Message.execute(%Message{}, %SendMessage{valid_command | message_id: nil})

      assert {:error, :invalid_club_id} =
               Message.execute(%Message{}, %SendMessage{valid_command | club_id: "not-a-uuid"})

      assert {:error, :invalid_sender_id} =
               Message.execute(%Message{}, %SendMessage{valid_command | sender_id: nil})
    end

    test "rejects blank subject or body" do
      valid_command = valid_send_message()

      assert {:error, :invalid_subject} =
               Message.execute(%Message{}, %SendMessage{valid_command | subject: "  "})

      assert {:error, :invalid_body} =
               Message.execute(%Message{}, %SendMessage{valid_command | body: "  "})
    end

    test "rejects invalid recipient lists" do
      valid_command = valid_send_message()

      assert {:error, :invalid_recipients} =
               Message.execute(%Message{}, %SendMessage{valid_command | recipients: []})

      assert {:error, :invalid_delivery_id} =
               Message.execute(%Message{}, %SendMessage{
                 valid_command
                 | recipients: [%Recipient{hd(valid_command.recipients) | delivery_id: nil}]
               })

      assert {:error, :invalid_recipient_email} =
               Message.execute(%Message{}, %SendMessage{
                 valid_command
                 | recipients: [%Recipient{hd(valid_command.recipients) | email: "invalid"}]
               })
    end

    test "rejects duplicate recipients or delivery identities" do
      valid_command = valid_send_message()
      [recipient] = valid_command.recipients

      assert {:error, :duplicate_recipient} =
               Message.execute(%Message{}, %SendMessage{
                 valid_command
                 | recipients: [
                     recipient,
                     %Recipient{recipient | delivery_id: Ecto.UUID.generate()}
                   ]
               })

      assert {:error, :duplicate_delivery} =
               Message.execute(%Message{}, %SendMessage{
                 valid_command
                 | recipients: [
                     recipient,
                     %Recipient{recipient | person_id: Ecto.UUID.generate()}
                   ]
               })
    end

    test "rejects commands whose resolved recipients omit the sender" do
      valid_command = valid_send_message()
      [recipient] = valid_command.recipients

      assert {:error, :sender_not_in_recipients} =
               Message.execute(%Message{}, %SendMessage{
                 valid_command
                 | recipients: [%Recipient{recipient | person_id: Ecto.UUID.generate()}]
               })
    end

    test "rejects sending the same message aggregate twice" do
      message_id = Ecto.UUID.generate()

      message =
        Message.apply(%Message{}, %MessageSent{
          message_id: message_id,
          club_id: Ecto.UUID.generate(),
          sender_id: Ecto.UUID.generate(),
          subject: "Trail day",
          body: "Meet at 9am."
        })

      assert {:error, :already_sent} =
               Message.execute(message, %SendMessage{
                 valid_send_message()
                 | message_id: message_id
               })
    end
  end

  test "apply/2 records message identity and recipient delivery state" do
    message_id = Ecto.UUID.generate()
    club_id = Ecto.UUID.generate()
    sender_id = Ecto.UUID.generate()
    delivery_id = Ecto.UUID.generate()

    message =
      %Message{}
      |> Message.apply(%MessageSent{
        message_id: message_id,
        club_id: club_id,
        sender_id: sender_id,
        subject: "Trail day",
        body: "Meet at 9am."
      })
      |> Message.apply(%RecipientDeliveryCreated{
        message_id: message_id,
        delivery_id: delivery_id,
        recipient_id: sender_id,
        recipient_name: "Alice Sender",
        recipient_email: "alice@example.com"
      })

    assert %Message{
             message_id: ^message_id,
             club_id: ^club_id,
             sender_id: ^sender_id,
             recipient_delivery_ids: recipient_delivery_ids,
             recipient_ids: recipient_ids
           } = message

    assert MapSet.equal?(recipient_delivery_ids, MapSet.new([delivery_id]))
    assert MapSet.equal?(recipient_ids, MapSet.new([sender_id]))
  end

  defp valid_send_message do
    sender_id = Ecto.UUID.generate()

    %SendMessage{
      message_id: Ecto.UUID.generate(),
      club_id: Ecto.UUID.generate(),
      sender_id: sender_id,
      subject: "Trail day",
      body: "Meet at 9am.",
      recipients: [
        %Recipient{
          delivery_id: Ecto.UUID.generate(),
          person_id: sender_id,
          name: "Alice Sender",
          email: "alice@example.com"
        }
      ]
    }
  end
end
