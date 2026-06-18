defmodule Memba.Messaging.EmailDeliveryOpenedReplayTest do
  use Memba.EventSourcedCase, async: false

  alias Commanded.Commands.ExecutionResult
  alias Commanded.Event.Mapper
  alias Memba.Messaging
  alias Memba.Messaging.App
  alias Memba.Messaging.Commands.SendMessage
  alias Memba.Messaging.Events.EmailDeliveryOpened
  alias Memba.Messaging.Message
  alias Memba.Messaging.Projectors.MemberEmailDelivery, as: MemberEmailDeliveryProjector
  alias Memba.Messaging.Projectors.MembaStaffEmailDelivery, as: MembaStaffEmailDeliveryProjector
  alias Memba.Messaging.Projections.MemberEmailDelivery, as: MemberEmailDeliveryProjection
  alias Memba.Messaging.Projections.MembaStaffEmailDelivery, as: MembaStaffEmailDeliveryProjection
  alias Memba.Messaging.Recipient

  @delivery_projectors [MemberEmailDeliveryProjector, MembaStaffEmailDeliveryProjector]

  test "historic opened events replay and rebuild without changing delivery read models" do
    message_id = Memba.ID.generate(:message)
    club_id = Memba.ID.generate(:club)
    sender_id = Memba.ID.generate(:person)
    delivery_id = Memba.ID.generate(:delivery)

    recipient = %Recipient{
      delivery_id: delivery_id,
      person_id: sender_id,
      name: "Alice Sender",
      email: "alice@example.com"
    }

    assert {:ok, %ExecutionResult{aggregate_version: aggregate_version}} =
             App.dispatch(
               %SendMessage{
                 message_id: message_id,
                 club_id: club_id,
                 sender_id: sender_id,
                 subject: "Trail day",
                 body: "Meet at 9am.",
                 recipients: [recipient]
               },
               returning: :execution_result,
               consistency: :strong
             )

    assert_delivery_read_models_sent(message_id, sender_id, delivery_id)

    append_historic_opened_event!(message_id, aggregate_version, delivery_id)
    checkpoint = Memba.ProjectionBarrier.current_checkpoint()
    Memba.ProjectionBarrier.await!(@delivery_projectors, checkpoint: checkpoint)

    assert_delivery_read_models_sent(message_id, sender_id, delivery_id)

    Memba.EventSourcedCase.stop_event_sourced_aggregate_instances!()

    assert %Message{
             delivery_statuses: %{
               ^delivery_id => %{status: :sent, reason: nil}
             }
           } = App.aggregate_state(Message, message_id)

    Memba.EventSourcedCase.rebuild_event_sourced_projections!()
    Memba.ProjectionBarrier.await!(@delivery_projectors, checkpoint: checkpoint)

    assert_delivery_read_models_sent(message_id, sender_id, delivery_id)
  end

  defp append_historic_opened_event!(message_id, aggregate_version, delivery_id) do
    opened_event_data =
      Mapper.map_to_event_data(%EmailDeliveryOpened{
        message_id: message_id,
        delivery_id: delivery_id
      })

    assert :ok =
             Commanded.EventStore.append_to_stream(
               App,
               message_id,
               aggregate_version,
               [opened_event_data]
             )
  end

  defp assert_delivery_read_models_sent(message_id, recipient_id, delivery_id) do
    assert [
             %MemberEmailDeliveryProjection{
               delivery_id: ^delivery_id,
               message_id: ^message_id,
               recipient_id: ^recipient_id,
               status: "sent"
             }
           ] = Messaging.list_member_email_deliverys(message_id)

    assert %MemberEmailDeliveryProjection{
             delivery_id: ^delivery_id,
             message_id: ^message_id,
             recipient_id: ^recipient_id,
             status: "sent"
           } = Messaging.get_member_email_delivery(message_id, recipient_id)

    assert [
             %MembaStaffEmailDeliveryProjection{
               delivery_id: ^delivery_id,
               message_id: ^message_id,
               recipient_id: ^recipient_id,
               status: "sent",
               reason: nil
             }
           ] = Messaging.list_operator_email_deliveries(message_id)

    assert %MembaStaffEmailDeliveryProjection{
             delivery_id: ^delivery_id,
             message_id: ^message_id,
             recipient_id: ^recipient_id,
             status: "sent",
             reason: nil
           } = Messaging.get_memba_staff_email_delivery(message_id, recipient_id)
  end
end
