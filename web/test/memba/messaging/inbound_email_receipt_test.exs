defmodule Memba.Messaging.InboundEmailReceiptTest do
  use ExUnit.Case, async: true

  alias Memba.Messaging.Commands.ReceiveInboundEmail
  alias Memba.Messaging.Events.InboundEmailReceived
  alias Memba.Messaging.InboundEmail
  alias Memba.Messaging.InboundEmailReceipt

  describe "execute/2 ReceiveInboundEmail" do
    test "records the first receipt for a provider message id" do
      command = receive_command()

      assert %InboundEmailReceived{
               inbound_email_id: "inbound-email:resend:email-123",
               provider: "resend",
               provider_message_id: "email-123",
               provider_event_id: "event-456"
             } = InboundEmailReceipt.execute(%InboundEmailReceipt{}, command)
    end

    test "returns no events for duplicate provider message ids" do
      command = receive_command()

      receipt =
        InboundEmailReceipt.apply(%InboundEmailReceipt{}, %InboundEmailReceived{
          inbound_email_id: "inbound-email:resend:email-123",
          provider: "resend",
          provider_message_id: "email-123",
          provider_event_id: "event-456"
        })

      assert [] = InboundEmailReceipt.execute(receipt, command)
    end

    test "rejects commands whose aggregate identity is not derived from the inbound email" do
      command = %ReceiveInboundEmail{receive_command() | inbound_email_id: "inbound-email:resend:other"}

      assert {:error, :inbound_email_id_mismatch} =
               InboundEmailReceipt.execute(%InboundEmailReceipt{}, command)
    end

    test "rejects malformed command payloads" do
      assert {:error, :invalid_inbound_email} =
               InboundEmailReceipt.execute(%InboundEmailReceipt{}, %ReceiveInboundEmail{
                 inbound_email_id: "inbound-email:resend:email-123",
                 inbound_email: nil
               })

      assert {:error, :invalid_inbound_email_id} =
               InboundEmailReceipt.execute(%InboundEmailReceipt{}, %ReceiveInboundEmail{
                 receive_command()
                 | inbound_email_id: " "
               })
    end
  end

  describe "apply/2 InboundEmailReceived" do
    test "stores only the provider identity needed to reject duplicates" do
      assert %InboundEmailReceipt{
               inbound_email_id: "inbound-email:resend:email-123",
               provider: "resend",
               provider_message_id: "email-123"
             } =
               InboundEmailReceipt.apply(%InboundEmailReceipt{}, %InboundEmailReceived{
                 inbound_email_id: "inbound-email:resend:email-123",
                 provider: "resend",
                 provider_message_id: "email-123",
                 provider_event_id: nil
               })
    end
  end

  defp receive_command do
    inbound_email = %InboundEmail{
      provider: "resend",
      provider_message_id: "email-123",
      provider_event_id: "event-456",
      from_address: "alice@example.com",
      recipient_addresses: ["kmc@clubs.memba.io"],
      subject: "Trip planning night",
      text_body: "Bring route ideas."
    }

    %ReceiveInboundEmail{
      inbound_email_id: InboundEmail.identity(inbound_email),
      inbound_email: inbound_email
    }
  end
end
