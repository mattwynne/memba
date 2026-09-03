defmodule Memba.Messaging.SendMessageDispatchTest do
  use Memba.EventSourcedCase, async: false

  alias Commanded.Commands.ExecutionResult
  alias Memba.Messaging
  alias Memba.Messaging.App
  alias Memba.Messaging.Commands.ReportEmailDeliveryDelivered
  alias Memba.Messaging.Commands.SendMessage
  alias Memba.Messaging.Events.ConversationAccessGrantedToGroup
  alias Memba.Messaging.Events.MessageSent
  alias Memba.Messaging.Events.EmailDeliveryCreated
  alias Memba.Messaging.Events.EmailDeliveryDelivered
  alias Memba.Messaging.Message
  alias Memba.Messaging.Recipient

  test "Messaging app dispatch routes SendMessage to the Message aggregate" do
    message_id = Memba.ID.generate(:message)
    club_id = Memba.ID.generate(:club)
    sender_id = Memba.ID.generate(:person)
    group_id = Memba.ID.generate(:group)
    bob_id = Memba.ID.generate(:person)
    alice_delivery_id = Memba.ID.generate(:delivery)
    bob_delivery_id = Memba.ID.generate(:delivery)

    command = %SendMessage{
      message_id: message_id,
      club_id: club_id,
      sender_id: sender_id,
      audience_group_id: group_id,
      subject: "Trail day",
      body: "Meet at 9am.",
      recipients: [
        %Recipient{
          delivery_id: alice_delivery_id,
          person_id: sender_id,
          name: "Alice Sender",
          email: "alice@example.com"
        },
        %Recipient{
          delivery_id: bob_delivery_id,
          person_id: bob_id,
          name: "Bob Recipient",
          email: "bob@example.com"
        }
      ]
    }

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^message_id,
              aggregate_version: 4,
              events: [
                %MessageSent{
                  message_id: ^message_id,
                  club_id: ^club_id,
                  sender_id: ^sender_id,
                  subject: "Trail day",
                  body: "Meet at 9am."
                },
                %ConversationAccessGrantedToGroup{
                  conversation_id: ^message_id,
                  club_id: ^club_id,
                  group_id: ^group_id,
                  access_level: "write"
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
              ],
              aggregate_state: %Message{
                message_id: ^message_id,
                club_id: ^club_id,
                sender_id: ^sender_id,
                email_delivery_ids: email_delivery_ids,
                recipient_ids: recipient_ids
              }
            }} = App.dispatch(command, returning: :execution_result, consistency: :strong)

    assert MapSet.equal?(email_delivery_ids, MapSet.new([alice_delivery_id, bob_delivery_id]))
    assert MapSet.equal?(recipient_ids, MapSet.new([sender_id, bob_id]))
    assert Messaging.group_has_conversation_access?(message_id, group_id, :write)
    assert Messaging.group_has_conversation_access?(message_id, group_id, :read)

    assert %Message{
             message_id: ^message_id,
             club_id: ^club_id,
             sender_id: ^sender_id,
             email_delivery_ids: persisted_delivery_ids,
             recipient_ids: persisted_recipient_ids
           } = App.aggregate_state(Message, message_id)

    assert MapSet.equal?(persisted_delivery_ids, MapSet.new([alice_delivery_id, bob_delivery_id]))
    assert MapSet.equal?(persisted_recipient_ids, MapSet.new([sender_id, bob_id]))
  end

  test "Messaging app rejects a duplicate SendMessage for the same aggregate identity" do
    command = %SendMessage{
      message_id: Memba.ID.generate(:message),
      club_id: Memba.ID.generate(:club),
      sender_id: Memba.ID.generate(:person),
      subject: "Trail day",
      body: "Meet at 9am.",
      recipients: []
    }

    [recipient_command] = with_sender_recipient(command)

    command = %SendMessage{command | recipients: [recipient_command]}

    assert :ok = App.dispatch(command, consistency: :strong)
    assert {:error, :already_sent} = App.dispatch(command)
  end

  test "Messaging app dispatch routes delivery status reports to the Message aggregate" do
    command = %SendMessage{
      message_id: Memba.ID.generate(:message),
      club_id: Memba.ID.generate(:club),
      sender_id: Memba.ID.generate(:person),
      subject: "Trail day",
      body: "Meet at 9am.",
      recipients: []
    }

    [recipient_command] = with_sender_recipient(command)
    delivery_id = recipient_command.delivery_id
    command = %SendMessage{command | recipients: [recipient_command]}
    message_id = command.message_id

    assert :ok = App.dispatch(command, consistency: :strong)

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^message_id,
              aggregate_version: 3,
              events: [
                %EmailDeliveryDelivered{
                  message_id: ^message_id,
                  delivery_id: ^delivery_id
                }
              ],
              aggregate_state: %Message{
                delivery_statuses: %{
                  ^delivery_id => %{status: :delivered, reason: nil}
                }
              }
            }} =
             App.dispatch(
               %ReportEmailDeliveryDelivered{
                 message_id: message_id,
                 delivery_id: delivery_id
               },
               returning: :execution_result,
               consistency: :strong
             )
  end

  defp with_sender_recipient(%SendMessage{} = command) do
    [
      %Recipient{
        delivery_id: Memba.ID.generate(:delivery),
        person_id: command.sender_id,
        name: "Alice Sender",
        email: "alice@example.com"
      }
    ]
  end
end
