defmodule Memba.Messaging.MessageTest do
  use ExUnit.Case, async: true

  alias Memba.Messaging.Commands.GrantConversationAccessToGroup
  alias Memba.Messaging.Commands.ReportEmailDeliveryBounced
  alias Memba.Messaging.Commands.ReportEmailDeliveryDelayed
  alias Memba.Messaging.Commands.ReportEmailDeliveryDelivered
  alias Memba.Messaging.Commands.ReportEmailDeliverySpamComplaint
  alias Memba.Messaging.Commands.PostMessageReply
  alias Memba.Messaging.Commands.SendMessage
  alias Memba.Messaging.Events.ConversationAccessGrantedToGroup
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
    test "emits MessageSent, the audience group write grant, and one EmailDeliveryCreated per resolved recipient" do
      message_id = Memba.ID.generate(:message)
      club_id = Memba.ID.generate(:club)
      sender_id = Memba.ID.generate(:person)
      group_id = Memba.ID.generate(:group)
      alice_delivery_id = Memba.ID.generate(:delivery)
      bob_delivery_id = Memba.ID.generate(:delivery)
      bob_id = Memba.ID.generate(:person)

      command = %SendMessage{
        message_id: message_id,
        club_id: club_id,
        sender_id: sender_id,
        audience_group_id: group_id,
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
                 conversation_id: ^message_id,
                 reply_to_message_id: nil,
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

      assert {:error, :invalid_audience_group_id} =
               Message.execute(%Message{}, %SendMessage{
                 valid_command
                 | audience_group_id: "not-a-group-id"
               })
    end

    test "rejects blank subject or body" do
      valid_command = valid_send_message()

      assert {:error, :invalid_subject} =
               Message.execute(%Message{}, %SendMessage{valid_command | subject: "  "})

      assert {:error, :invalid_body} =
               Message.execute(%Message{}, %SendMessage{valid_command | body: "  "})
    end

    test "models a reply as another message in the root message conversation" do
      root_message_id = Memba.ID.generate(:message)
      reply_message_id = Memba.ID.generate(:message)
      sender_id = Memba.ID.generate(:person)

      command = %SendMessage{
        valid_send_message()
        | message_id: reply_message_id,
          sender_id: sender_id,
          conversation_id: root_message_id,
          reply_to_message_id: root_message_id,
          subject: "Re: Trail day",
          body: "I'll bring maps.",
          recipients: [
            %Recipient{
              delivery_id: Memba.ID.generate(:delivery),
              person_id: sender_id,
              name: "Alice Sender",
              email: "alice@example.com"
            }
          ]
      }

      assert [
               %MessageSent{
                 message_id: ^reply_message_id,
                 sender_id: ^sender_id,
                 conversation_id: ^root_message_id,
                 reply_to_message_id: ^root_message_id,
                 subject: "Re: Trail day",
                 body: "I'll bring maps."
               },
               %EmailDeliveryCreated{}
             ] = Message.execute(%Message{}, command)
    end

    test "rejects malformed conversation references" do
      valid_command = valid_send_message()

      assert {:error, :invalid_conversation_id} =
               Message.execute(%Message{}, %SendMessage{
                 valid_command
                 | conversation_id: "not-a-uuid",
                   reply_to_message_id: valid_command.message_id
               })

      assert {:error, :invalid_reply_to_message_id} =
               Message.execute(%Message{}, %SendMessage{
                 valid_command
                 | conversation_id: valid_command.message_id,
                   reply_to_message_id: "not-a-uuid"
               })
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
                     %Recipient{recipient | delivery_id: Memba.ID.generate(:delivery)}
                   ]
               })

      assert {:error, :duplicate_delivery} =
               Message.execute(%Message{}, %SendMessage{
                 valid_command
                 | recipients: [
                     recipient,
                     %Recipient{recipient | person_id: Memba.ID.generate(:person)}
                   ]
               })
    end

    test "rejects commands whose resolved recipients omit the sender" do
      valid_command = valid_send_message()
      [recipient] = valid_command.recipients

      assert {:error, :sender_not_in_recipients} =
               Message.execute(%Message{}, %SendMessage{
                 valid_command
                 | recipients: [%Recipient{recipient | person_id: Memba.ID.generate(:person)}]
               })
    end

    test "rejects sending the same message aggregate twice" do
      message_id = Memba.ID.generate(:message)

      message =
        Message.apply(%Message{}, %MessageSent{
          message_id: message_id,
          club_id: Memba.ID.generate(:club),
          sender_id: Memba.ID.generate(:person),
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

  describe "execute/2 PostMessageReply" do
    test "emits a reply MessageSent in the root conversation" do
      root_message_id = Memba.ID.generate(:message)
      reply_message_id = Memba.ID.generate(:message)
      club_id = Memba.ID.generate(:club)
      sender_id = Memba.ID.generate(:person)
      recipient_id = Memba.ID.generate(:person)
      delivery_id = Memba.ID.generate(:delivery)

      command = %PostMessageReply{
        message_id: reply_message_id,
        club_id: club_id,
        sender_id: sender_id,
        conversation_id: root_message_id,
        reply_to_message_id: root_message_id,
        subject: "Trail day",
        body: " I'll bring maps. ",
        recipients: [
          %Recipient{
            delivery_id: delivery_id,
            person_id: recipient_id,
            name: " Alice Recipient ",
            email: " Alice@Example.COM "
          }
        ]
      }

      assert [
               %MessageSent{
                 message_id: ^reply_message_id,
                 club_id: ^club_id,
                 sender_id: ^sender_id,
                 conversation_id: ^root_message_id,
                 reply_to_message_id: ^root_message_id,
                 subject: "Trail day",
                 body: "I'll bring maps."
               },
               %EmailDeliveryCreated{
                 message_id: ^reply_message_id,
                 delivery_id: ^delivery_id,
                 recipient_id: ^recipient_id,
                 recipient_name: "Alice Recipient",
                 recipient_email: "alice@example.com"
               }
             ] = Message.execute(%Message{}, command)
    end

    test "allows a reply with no email delivery recipients after excluding the author" do
      valid_command = valid_post_message_reply()

      assert [
               %MessageSent{
                 message_id: message_id,
                 conversation_id: conversation_id,
                 reply_to_message_id: reply_to_message_id
               }
             ] =
               Message.execute(%Message{}, %PostMessageReply{
                 valid_command
                 | recipients: []
               })

      assert message_id == valid_command.message_id
      assert conversation_id == valid_command.conversation_id
      assert reply_to_message_id == valid_command.reply_to_message_id
    end

    test "rejects reply recipients that include the reply author" do
      valid_command = valid_post_message_reply()
      [recipient] = valid_command.recipients

      assert {:error, :reply_author_in_recipients} =
               Message.execute(%Message{}, %PostMessageReply{
                 valid_command
                 | recipients: [%Recipient{recipient | person_id: valid_command.sender_id}]
               })
    end

    test "rejects replies without a root conversation, replied-to message, or body" do
      valid_command = valid_post_message_reply()

      assert {:error, :invalid_conversation_id} =
               Message.execute(%Message{}, %PostMessageReply{valid_command | conversation_id: nil})

      assert {:error, :invalid_reply_to_message_id} =
               Message.execute(%Message{}, %PostMessageReply{
                 valid_command
                 | reply_to_message_id: nil
               })

      assert {:error, :invalid_body} =
               Message.execute(%Message{}, %PostMessageReply{valid_command | body: "  "})
    end

    test "rejects a reply command whose conversation points at the reply itself" do
      valid_command = valid_post_message_reply()

      assert {:error, :invalid_conversation_reference} =
               Message.execute(%Message{}, %PostMessageReply{
                 valid_command
                 | conversation_id: valid_command.message_id,
                   reply_to_message_id: valid_command.conversation_id
               })
    end
  end

  describe "execute/2 GrantConversationAccessToGroup" do
    test "emits a conversation group access grant for an existing root conversation" do
      conversation_id = Memba.ID.generate(:message)
      club_id = Memba.ID.generate(:club)
      group_id = Memba.ID.generate(:group)
      message = root_message(conversation_id, club_id)

      assert %ConversationAccessGrantedToGroup{
               conversation_id: ^conversation_id,
               club_id: ^club_id,
               group_id: ^group_id,
               access_level: "read"
             } =
               Message.execute(message, %GrantConversationAccessToGroup{
                 conversation_id: conversation_id,
                 club_id: club_id,
                 group_id: group_id,
                 access_level: :read
               })
    end

    test "treats repeated grants and read requests satisfied by write access as no-ops" do
      conversation_id = Memba.ID.generate(:message)
      club_id = Memba.ID.generate(:club)
      group_id = Memba.ID.generate(:group)

      read_message =
        conversation_id
        |> root_message(club_id)
        |> Message.apply(%ConversationAccessGrantedToGroup{
          conversation_id: conversation_id,
          club_id: club_id,
          group_id: group_id,
          access_level: "read"
        })

      assert [] =
               Message.execute(read_message, %GrantConversationAccessToGroup{
                 conversation_id: conversation_id,
                 club_id: club_id,
                 group_id: group_id,
                 access_level: "read"
               })

      write_message =
        conversation_id
        |> root_message(club_id)
        |> Message.apply(%ConversationAccessGrantedToGroup{
          conversation_id: conversation_id,
          club_id: club_id,
          group_id: group_id,
          access_level: "write"
        })

      assert [] =
               Message.execute(write_message, %GrantConversationAccessToGroup{
                 conversation_id: conversation_id,
                 club_id: club_id,
                 group_id: group_id,
                 access_level: "read"
               })
    end

    test "upgrades an existing read grant to write access" do
      conversation_id = Memba.ID.generate(:message)
      club_id = Memba.ID.generate(:club)
      group_id = Memba.ID.generate(:group)

      message =
        conversation_id
        |> root_message(club_id)
        |> Message.apply(%ConversationAccessGrantedToGroup{
          conversation_id: conversation_id,
          club_id: club_id,
          group_id: group_id,
          access_level: "read"
        })

      assert %ConversationAccessGrantedToGroup{
               conversation_id: ^conversation_id,
               club_id: ^club_id,
               group_id: ^group_id,
               access_level: "write"
             } =
               Message.execute(message, %GrantConversationAccessToGroup{
                 conversation_id: conversation_id,
                 club_id: club_id,
                 group_id: group_id,
                 access_level: "write"
               })
    end

    test "rejects invalid IDs and access levels" do
      message = root_message(Memba.ID.generate(:message), Memba.ID.generate(:club))
      command = valid_conversation_access_grant(message)

      assert {:error, :invalid_conversation_id} =
               Message.execute(message, %GrantConversationAccessToGroup{
                 command
                 | conversation_id: "not-a-uuid"
               })

      assert {:error, :invalid_club_id} =
               Message.execute(message, %GrantConversationAccessToGroup{command | club_id: nil})

      assert {:error, :invalid_group_id} =
               Message.execute(message, %GrantConversationAccessToGroup{
                 command
                 | group_id: "not-a-group-id"
               })

      assert {:error, :invalid_access_level} =
               Message.execute(message, %GrantConversationAccessToGroup{
                 command
                 | access_level: "admin"
               })
    end

    test "targets existing root conversations only and rejects identity mismatches" do
      conversation_id = Memba.ID.generate(:message)
      club_id = Memba.ID.generate(:club)
      message = root_message(conversation_id, club_id)

      assert {:error, :conversation_not_found} =
               Message.execute(%Message{}, valid_conversation_access_grant(message))

      assert {:error, :club_id_mismatch} =
               Message.execute(message, %GrantConversationAccessToGroup{
                 valid_conversation_access_grant(message)
                 | club_id: Memba.ID.generate(:club)
               })

      assert {:error, :conversation_id_mismatch} =
               Message.execute(message, %GrantConversationAccessToGroup{
                 valid_conversation_access_grant(message)
                 | conversation_id: Memba.ID.generate(:message)
               })

      reply =
        Message.apply(%Message{}, %MessageSent{
          message_id: Memba.ID.generate(:message),
          club_id: club_id,
          sender_id: Memba.ID.generate(:person),
          conversation_id: conversation_id,
          reply_to_message_id: conversation_id,
          subject: "Re: Trail day",
          body: "I'll bring maps."
        })

      assert {:error, :conversation_id_mismatch} =
               Message.execute(reply, %GrantConversationAccessToGroup{
                 valid_conversation_access_grant(message)
                 | conversation_id: reply.message_id
               })
    end
  end

  describe "execute/2 delivery status reports" do
    test "emits delivered, delayed, bounced, and spam complaint events" do
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
                 message_id: Memba.ID.generate(:message),
                 delivery_id: ids.delivery_id
               })

      assert {:error, :unknown_delivery} =
               Message.execute(message, %ReportEmailDeliveryDelivered{
                 message_id: ids.message_id,
                 delivery_id: Memba.ID.generate(:delivery)
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
    end
  end

  test "apply/2 records message identity and email delivery state" do
    message_id = Memba.ID.generate(:message)
    club_id = Memba.ID.generate(:club)
    sender_id = Memba.ID.generate(:person)
    delivery_id = Memba.ID.generate(:delivery)

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
             conversation_id: ^message_id,
             reply_to_message_id: nil,
             delivery_statuses: delivery_statuses,
             email_delivery_ids: email_delivery_ids,
             recipient_ids: recipient_ids,
             group_access: %{}
           } = message

    assert MapSet.equal?(email_delivery_ids, MapSet.new([delivery_id]))
    assert MapSet.equal?(recipient_ids, MapSet.new([sender_id]))
    assert delivery_statuses == %{delivery_id => %{status: :sent, reason: nil}}
  end

  test "apply/2 treats historic MessageSent events without conversation fields as conversation roots" do
    message_id = Memba.ID.generate(:message)

    message =
      Message.apply(%Message{}, %MessageSent{
        message_id: message_id,
        club_id: Memba.ID.generate(:club),
        sender_id: Memba.ID.generate(:person),
        subject: "Trail day",
        body: "Meet at 9am."
      })

    assert %Message{
             message_id: ^message_id,
             conversation_id: ^message_id,
             reply_to_message_id: nil
           } = message
  end

  test "apply/2 records conversation group access grants" do
    conversation_id = Memba.ID.generate(:message)
    club_id = Memba.ID.generate(:club)
    group_id = Memba.ID.generate(:group)

    assert %Message{group_access: %{^group_id => "write"}} =
             conversation_id
             |> root_message(club_id)
             |> Message.apply(%ConversationAccessGrantedToGroup{
               conversation_id: conversation_id,
               club_id: club_id,
               group_id: group_id,
               access_level: :write
             })
  end

  test "apply/2 records delivery status changes and ignores historic opened events" do
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

    assert message ==
             Message.apply(message, %EmailDeliveryOpened{
               message_id: ids.message_id,
               delivery_id: ids.delivery_id
             })
  end

  defp root_message(conversation_id, club_id) do
    Message.apply(%Message{}, %MessageSent{
      message_id: conversation_id,
      club_id: club_id,
      sender_id: Memba.ID.generate(:person),
      conversation_id: conversation_id,
      reply_to_message_id: nil,
      subject: "Trail day",
      body: "Meet at 9am."
    })
  end

  defp valid_conversation_access_grant(%Message{} = message) do
    %GrantConversationAccessToGroup{
      conversation_id: message.conversation_id,
      club_id: message.club_id,
      group_id: Memba.ID.generate(:group),
      access_level: "read"
    }
  end

  defp valid_send_message do
    sender_id = Memba.ID.generate(:person)

    %SendMessage{
      message_id: Memba.ID.generate(:message),
      club_id: Memba.ID.generate(:club),
      sender_id: sender_id,
      audience_group_id: Memba.ID.generate(:group),
      subject: "Trail day",
      body: "Meet at 9am.",
      recipients: [
        %Recipient{
          delivery_id: Memba.ID.generate(:delivery),
          person_id: sender_id,
          name: "Alice Sender",
          email: "alice@example.com"
        }
      ]
    }
  end

  defp valid_post_message_reply do
    sender_id = Memba.ID.generate(:person)
    root_message_id = Memba.ID.generate(:message)
    recipient_id = Memba.ID.generate(:person)

    %PostMessageReply{
      message_id: Memba.ID.generate(:message),
      club_id: Memba.ID.generate(:club),
      sender_id: sender_id,
      conversation_id: root_message_id,
      reply_to_message_id: root_message_id,
      subject: "Trail day",
      body: "I'll bring maps.",
      recipients: [
        %Recipient{
          delivery_id: Memba.ID.generate(:delivery),
          person_id: recipient_id,
          name: "Alice Recipient",
          email: "alice@example.com"
        }
      ]
    }
  end

  defp sent_message do
    message_id = Memba.ID.generate(:message)
    club_id = Memba.ID.generate(:club)
    sender_id = Memba.ID.generate(:person)
    delivery_id = Memba.ID.generate(:delivery)

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
