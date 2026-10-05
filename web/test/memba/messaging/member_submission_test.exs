defmodule Memba.Messaging.MemberSubmissionTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.Messaging.App
  alias Memba.Messaging.Commands.SendMessage
  alias Memba.Messaging.MemberSubmission
  alias Memba.Messaging.Recipient

  for kind <- [:club_message, :reply, :group_access] do
    test "#{kind}: commit followed by lost acknowledgement is accepted without redispatch" do
      kind = unquote(kind)
      club_id = Memba.ID.generate(:club)
      sender_id = Memba.ID.generate(:person)
      group_id = Memba.ID.generate(:group)

      operation =
        MemberSubmission.new(kind, %{
          "club_id" => club_id,
          "sender_id" => sender_id,
          "group_id" => group_id,
          "body" => "Meet at 9"
        })

      parent = self()

      dispatch = fn params ->
        send(parent, {:dispatched, params})

        assert :ok =
                 App.dispatch(
                   %SendMessage{
                     message_id: params["message_id"],
                     operation_intent: params["operation_intent"],
                     club_id: club_id,
                     sender_id: sender_id,
                     audience_group_id: group_id,
                     subject: "Trail day",
                     body: "Meet at 9",
                     recipients: [
                       %Recipient{
                         delivery_id: Memba.ID.generate(:delivery),
                         person_id: sender_id,
                         name: "Sender",
                         email: "sender@example.com"
                       }
                     ]
                   },
                   consistency: :strong
                 )

        {:error, :timeout}
      end

      assert {:accepted, id} = MemberSubmission.submit(operation, dispatch)
      assert id == operation.message_id
      assert_received {:dispatched, _}

      assert {:accepted, ^id} =
               MemberSubmission.submit(operation, fn _ -> flunk("duplicate dispatch") end)

      # A pre-existing stream with a different intent must never be mistaken for
      # this submission, even though the aggregate would report :already_sent.
      other_intent = %{operation | intent: "different-intent"}

      assert {:rejected, :operation_id_conflict} =
               MemberSubmission.submit(other_intent, fn _ -> flunk("conflicting dispatch") end)
    end
  end

  test "an already_sent response reconciles against the authoritative stream" do
    club_id = Memba.ID.generate(:club)
    sender_id = Memba.ID.generate(:person)
    group_id = Memba.ID.generate(:group)
    operation = MemberSubmission.new(:club_message, %{"body" => "Hello"})

    assert {:accepted, operation.message_id} ==
             MemberSubmission.submit(operation, fn params ->
               assert :ok =
                        App.dispatch(
                          %SendMessage{
                            message_id: params["message_id"],
                            operation_intent: params["operation_intent"],
                            club_id: club_id,
                            sender_id: sender_id,
                            audience_group_id: group_id,
                            subject: "Subject",
                            body: "Hello",
                            recipients: [
                              %Recipient{
                                delivery_id: Memba.ID.generate(:delivery),
                                person_id: sender_id,
                                name: "Sender",
                                email: "sender@example.com"
                              }
                            ]
                          },
                          consistency: :strong
                        )

               {:error, :already_sent}
             end)
  end

  test "an uncommitted timeout is uncertain and a retry keeps its ID" do
    operation = MemberSubmission.new(:reply, %{"body" => "Hello"})

    assert {:uncertain, :timeout} =
             MemberSubmission.submit(operation, fn _ -> {:error, :timeout} end)

    assert {:uncertain, :timeout} =
             MemberSubmission.submit(operation, fn params ->
               assert params["message_id"] == operation.message_id
               {:error, :timeout}
             end)

    refute MemberSubmission.same_intent?(operation, :reply, %{"body" => "Different"})
  end
end
