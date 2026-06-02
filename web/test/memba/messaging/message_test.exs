defmodule Memba.Messaging.MessageTest do
  use ExUnit.Case, async: true

  alias Memba.Messaging.Commands.ReportEmailDeliveryBounced
  alias Memba.Messaging.Commands.ReportEmailDeliveryDelayed
  alias Memba.Messaging.Commands.ReportEmailDeliveryDelivered
  alias Memba.Messaging.Commands.ReportEmailDeliveryOpened
  alias Memba.Messaging.Commands.ReportEmailDeliverySpamComplaint
  alias Memba.Messaging.Commands.SendMessage
  alias Memba.Messaging.Events.MessageSent
  alias Memba.Messaging.Events.EmailDeliveryBounced
  alias Memba.Messaging.Events.EmailDeliveryCreated
  alias Memba.Messaging.Events.EmailDeliveryDelayed
  alias Memba.Messaging.Events.EmailDeliveryDelivered
  alias Memba.Messaging.Events.EmailDeliveryOpened
  alias Memba.Messaging.Events.EmailDeliverySpamComplaint
  alias Memba.Messaging.Message
  alias Memba.Messaging.Recipient

  describe "execute/2 SendMessage" do
    test "emits MessageSent and one EmailDeliveryCreated per resolved recipient" do
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
               %EmailDeliveryCreated{
                 message_id: ^message_id,
                 delivery_id: ^alice_delivery_id,
                 recipient_id: ^sender_id,
                 recipient_name: "Alice Sender",
                 recipient_email: "alice@example.com"
               },
               %EmailDeliveryCreated{
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

  describe "execute/2 delivery status reports" do
    test "emits delivered, delayed, bounced, spam complaint, and opened events" do
      {message, ids} = sent_message()

      assert %EmailDeliveryDelivered{
               message_id: ids.message_id,
               delivery_id: ids.delivery_id
             } ==
               Message.execute(message, %ReportEmailDeliveryDelivered{
                 message_id: ids.message_id,
                 delivery_id: ids.delivery_id
               })

      assert %EmailDeliveryDelayed{
               message_id: ids.message_id,
               delivery_id: ids.delivery_id,
               reason: "recipient server is temporarily unavailable"
             } ==
               Message.execute(message, %ReportEmailDeliveryDelayed{
                 message_id: ids.message_id,
                 delivery_id: ids.delivery_id,
                 reason: " recipient server is temporarily unavailable "
               })

      assert %EmailDeliveryBounced{
               message_id: ids.message_id,
               delivery_id: ids.delivery_id,
               reason: "mailbox does not exist"
             } ==
               Message.execute(message, %ReportEmailDeliveryBounced{
                 message_id: ids.message_id,
                 delivery_id: ids.delivery_id,
                 reason: "mailbox does not exist"
               })

      assert %EmailDeliverySpamComplaint{
               message_id: ids.message_id,
               delivery_id: ids.delivery_id,
               reason: "recipient marked the message as spam"
             } ==
               Message.execute(message, %ReportEmailDeliverySpamComplaint{
                 message_id: ids.message_id,
                 delivery_id: ids.delivery_id,
                 reason: "recipient marked the message as spam"
               })

      delivered_message =
        Message.apply(
          message,
          %EmailDeliveryDelivered{message_id: ids.message_id, delivery_id: ids.delivery_id}
        )

      assert %EmailDeliveryOpened{
               message_id: ids.message_id,
               delivery_id: ids.delivery_id
             } ==
               Message.execute(delivered_message, %ReportEmailDeliveryOpened{
                 message_id: ids.message_id,
                 delivery_id: ids.delivery_id
               })
    end

    test "rejects malformed status report commands" do
      {message, ids} = sent_message()

      assert {:error, :invalid_message_id} =
               Message.execute(message, %ReportEmailDeliveryDelivered{
                 message_id: nil,
                 delivery_id: ids.delivery_id
               })

      assert {:error, :invalid_delivery_id} =
               Message.execute(message, %ReportEmailDeliveryDelivered{
                 message_id: ids.message_id,
                 delivery_id: "not-a-uuid"
               })

      assert {:error, :invalid_reason} =
               Message.execute(message, %ReportEmailDeliveryDelayed{
                 message_id: ids.message_id,
                 delivery_id: ids.delivery_id,
                 reason: "  "
               })

      assert {:error, :message_not_sent} =
               Message.execute(%Message{}, %ReportEmailDeliveryDelivered{
                 message_id: ids.message_id,
                 delivery_id: ids.delivery_id
               })

      assert {:error, :message_id_mismatch} =
               Message.execute(message, %ReportEmailDeliveryDelivered{
                 message_id: Ecto.UUID.generate(),
                 delivery_id: ids.delivery_id
               })

      assert {:error, :unknown_delivery} =
               Message.execute(message, %ReportEmailDeliveryDelivered{
                 message_id: ids.message_id,
                 delivery_id: Ecto.UUID.generate()
               })
    end

    test "allows delayed delivery to recover or become a terminal problem" do
      {message, ids} = sent_message()

      delayed_message =
        Message.apply(message, %EmailDeliveryDelayed{
          message_id: ids.message_id,
          delivery_id: ids.delivery_id,
          reason: "recipient server is temporarily unavailable"
        })

      assert %EmailDeliveryDelivered{} =
               Message.execute(delayed_message, %ReportEmailDeliveryDelivered{
                 message_id: ids.message_id,
                 delivery_id: ids.delivery_id
               })

      assert %EmailDeliveryBounced{} =
               Message.execute(delayed_message, %ReportEmailDeliveryBounced{
                 message_id: ids.message_id,
                 delivery_id: ids.delivery_id,
                 reason: "mailbox does not exist"
               })

      assert %EmailDeliverySpamComplaint{} =
               Message.execute(delayed_message, %ReportEmailDeliverySpamComplaint{
                 message_id: ids.message_id,
                 delivery_id: ids.delivery_id,
                 reason: "recipient marked the message as spam"
               })
    end

    test "rejects invalid delivery status transitions" do
      {message, ids} = sent_message()

      assert {:error, :invalid_delivery_status_transition} =
               Message.execute(message, %ReportEmailDeliveryOpened{
                 message_id: ids.message_id,
                 delivery_id: ids.delivery_id
               })

      delivered_message =
        Message.apply(
          message,
          %EmailDeliveryDelivered{message_id: ids.message_id, delivery_id: ids.delivery_id}
        )

      assert {:error, :invalid_delivery_status_transition} =
               Message.execute(delivered_message, %ReportEmailDeliveryDelayed{
                 message_id: ids.message_id,
                 delivery_id: ids.delivery_id,
                 reason: "recipient server is temporarily unavailable"
               })

      opened_message =
        Message.apply(
          delivered_message,
          %EmailDeliveryOpened{message_id: ids.message_id, delivery_id: ids.delivery_id}
        )

      assert {:error, :invalid_delivery_status_transition} =
               Message.execute(opened_message, %ReportEmailDeliveryDelivered{
                 message_id: ids.message_id,
                 delivery_id: ids.delivery_id
               })

      bounced_message =
        Message.apply(message, %EmailDeliveryBounced{
          message_id: ids.message_id,
          delivery_id: ids.delivery_id,
          reason: "mailbox does not exist"
        })

      assert {:error, :invalid_delivery_status_transition} =
               Message.execute(bounced_message, %ReportEmailDeliveryDelivered{
                 message_id: ids.message_id,
                 delivery_id: ids.delivery_id
               })
    end

    test "treats repeated equivalent reports as idempotent" do
      {message, ids} = sent_message()

      delivered_message =
        Message.apply(
          message,
          %EmailDeliveryDelivered{message_id: ids.message_id, delivery_id: ids.delivery_id}
        )

      assert [] =
               Message.execute(delivered_message, %ReportEmailDeliveryDelivered{
                 message_id: ids.message_id,
                 delivery_id: ids.delivery_id
               })

      delayed_message =
        Message.apply(message, %EmailDeliveryDelayed{
          message_id: ids.message_id,
          delivery_id: ids.delivery_id,
          reason: "recipient server is temporarily unavailable"
        })

      assert [] =
               Message.execute(delayed_message, %ReportEmailDeliveryDelayed{
                 message_id: ids.message_id,
                 delivery_id: ids.delivery_id,
                 reason: "recipient server is temporarily unavailable"
               })

      assert {:error, :conflicting_delivery_status_reason} =
               Message.execute(delayed_message, %ReportEmailDeliveryDelayed{
                 message_id: ids.message_id,
                 delivery_id: ids.delivery_id,
                 reason: "different temporary failure"
               })

      opened_message =
        Message.apply(
          delivered_message,
          %EmailDeliveryOpened{message_id: ids.message_id, delivery_id: ids.delivery_id}
        )

      assert [] =
               Message.execute(opened_message, %ReportEmailDeliveryOpened{
                 message_id: ids.message_id,
                 delivery_id: ids.delivery_id
               })
    end
  end

  test "apply/2 records message identity and email delivery state" do
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
      |> Message.apply(%EmailDeliveryCreated{
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
             delivery_statuses: delivery_statuses,
             email_delivery_ids: email_delivery_ids,
             recipient_ids: recipient_ids
           } = message

    assert MapSet.equal?(email_delivery_ids, MapSet.new([delivery_id]))
    assert MapSet.equal?(recipient_ids, MapSet.new([sender_id]))
    assert delivery_statuses == %{delivery_id => %{status: :sent, reason: nil}}
  end

  test "apply/2 records delivery status changes" do
    {message, ids} = sent_message()
    delivery_id = ids.delivery_id

    assert %{^delivery_id => %{status: :delivered, reason: nil}} =
             message
             |> Message.apply(%EmailDeliveryDelivered{
               message_id: ids.message_id,
               delivery_id: ids.delivery_id
             })
             |> Map.fetch!(:delivery_statuses)

    assert %{^delivery_id => %{status: :delayed, reason: "temporary failure"}} =
             message
             |> Message.apply(%EmailDeliveryDelayed{
               message_id: ids.message_id,
               delivery_id: ids.delivery_id,
               reason: "temporary failure"
             })
             |> Map.fetch!(:delivery_statuses)

    assert %{^delivery_id => %{status: :opened, reason: nil}} =
             message
             |> Message.apply(%EmailDeliveryDelivered{
               message_id: ids.message_id,
               delivery_id: ids.delivery_id
             })
             |> Message.apply(%EmailDeliveryOpened{
               message_id: ids.message_id,
               delivery_id: ids.delivery_id
             })
             |> Map.fetch!(:delivery_statuses)
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

  defp sent_message do
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
      |> Message.apply(%EmailDeliveryCreated{
        message_id: message_id,
        delivery_id: delivery_id,
        recipient_id: sender_id,
        recipient_name: "Alice Sender",
        recipient_email: "alice@example.com"
      })

    {message, %{message_id: message_id, delivery_id: delivery_id}}
  end
end
