defmodule Memba.Messaging.InboundEmailDispatchTest do
  use Memba.EventSourcedCase, async: false

  alias Commanded.Commands.ExecutionResult
  alias Memba.Messaging
  alias Memba.Messaging.App
  alias Memba.Messaging.Events.InboundEmailReceived
  alias Memba.Messaging.InboundEmailReceipt

  test "Messaging app dispatch routes ReceiveInboundEmail to the inbound email aggregate" do
    assert {:ok, command} =
             Messaging.receive_inbound_club_email_command(%{
               provider: "resend",
               provider_message_id: "email-123",
               provider_event_id: "event-456",
               from_address: "alice@example.com",
               recipient_addresses: ["kmc@clubs.memba.io"],
               subject: "Trip planning night",
               text_body: "Bring route ideas."
             })

    inbound_email_id = command.inbound_email_id

    assert {:ok,
            %ExecutionResult{
              aggregate_uuid: ^inbound_email_id,
              aggregate_version: 1,
              events: [
                %InboundEmailReceived{
                  inbound_email_id: ^inbound_email_id,
                  provider: "resend",
                  provider_message_id: "email-123",
                  provider_event_id: "event-456"
                }
              ],
              aggregate_state: %InboundEmailReceipt{
                inbound_email_id: ^inbound_email_id,
                provider: "resend",
                provider_message_id: "email-123"
              }
            }} = App.dispatch(command, returning: :execution_result, consistency: :strong)

    assert %InboundEmailReceipt{
             inbound_email_id: ^inbound_email_id,
             provider: "resend",
             provider_message_id: "email-123"
           } = App.aggregate_state(InboundEmailReceipt, inbound_email_id)
  end
end
