defmodule Memba.Messaging.InboundEmailReceiptTest do
  use ExUnit.Case, async: true

  alias Memba.Messaging.Commands.ReceiveInboundEmail
  alias Memba.Messaging.Commands.RejectInboundClubEmail
  alias Memba.Messaging.Events.InboundClubEmailRejected
  alias Memba.Messaging.Events.InboundEmailReceived
  alias Memba.Messaging.InboundEmail
  alias Memba.Messaging.InboundEmailReceipt

  describe "execute/2 ReceiveInboundEmail" do
    test "records the first receipt for a provider message id" do
      command = receive_command()

      assert %InboundEmailReceived{
               inbound_email_id: inbound_email_id,
               provider: "resend",
               provider_message_id: "email-123",
               provider_event_id: "event-456"
             } = InboundEmailReceipt.execute(%InboundEmailReceipt{}, command)

      assert Memba.ID.valid?(:inbound_email, inbound_email_id)
    end

    test "returns no events for duplicate provider message ids" do
      command = receive_command()

      receipt =
        InboundEmailReceipt.apply(%InboundEmailReceipt{}, %InboundEmailReceived{
          inbound_email_id: inbound_email_id(),
          provider: "resend",
          provider_message_id: "email-123",
          provider_event_id: "event-456"
        })

      assert [] = InboundEmailReceipt.execute(receipt, command)
    end

    test "rejects commands whose aggregate identity is not derived from the inbound email" do
      command = %ReceiveInboundEmail{
        receive_command()
        | inbound_email_id: Memba.ID.generate(:inbound_email)
      }

      assert {:error, :inbound_email_id_mismatch} =
               InboundEmailReceipt.execute(%InboundEmailReceipt{}, command)
    end

    test "rejects malformed command payloads" do
      assert {:error, :invalid_inbound_email} =
               InboundEmailReceipt.execute(%InboundEmailReceipt{}, %ReceiveInboundEmail{
                 inbound_email_id: inbound_email_id(),
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
               inbound_email_id: inbound_email_id,
               provider: "resend",
               provider_message_id: "email-123"
             } =
               InboundEmailReceipt.apply(%InboundEmailReceipt{}, %InboundEmailReceived{
                 inbound_email_id: inbound_email_id(),
                 provider: "resend",
                 provider_message_id: "email-123",
                 provider_event_id: nil
               })

      assert Memba.ID.valid?(:inbound_email, inbound_email_id)
    end
  end

  describe "execute/2 RejectInboundClubEmail" do
    test "records a rejected outcome for a received provider message id" do
      receipt = received_receipt()
      command = reject_command()

      assert %InboundClubEmailRejected{
               inbound_email_id: inbound_email_id,
               provider: "resend",
               provider_message_id: "email-123",
               provider_event_id: "event-456",
               from_address: "alice@example.com",
               to_address: "kmc@clubs.memba.io",
               rejection_reason: "plain_text_required",
               rejection_email_delivery_reference: nil
             } = InboundEmailReceipt.execute(receipt, command)

      assert Memba.ID.valid?(:inbound_email, inbound_email_id)
    end

    test "returns no events for duplicate rejected outcomes with the same reason" do
      receipt =
        received_receipt()
        |> InboundEmailReceipt.apply(%InboundClubEmailRejected{
          inbound_email_id: inbound_email_id(),
          provider: "resend",
          provider_message_id: "email-123",
          provider_event_id: "event-456",
          from_address: "alice@example.com",
          to_address: "kmc@clubs.memba.io",
          rejection_reason: "plain_text_required"
        })

      assert [] = InboundEmailReceipt.execute(receipt, reject_command())
    end

    test "does not reject an already accepted provider message id" do
      receipt = %InboundEmailReceipt{
        received_receipt()
        | status: :accepted,
          message_id: Memba.ID.generate(:message)
      }

      assert {:error, :inbound_email_already_accepted} =
               InboundEmailReceipt.execute(receipt, reject_command())
    end
  end

  describe "apply/2 InboundClubEmailRejected" do
    test "stores the rejected status and reason for duplicate receipts" do
      assert %InboundEmailReceipt{
               status: :rejected,
               rejection_reason: "plain_text_required"
             } =
               received_receipt()
               |> InboundEmailReceipt.apply(%InboundClubEmailRejected{
                 inbound_email_id: inbound_email_id(),
                 provider: "resend",
                 provider_message_id: "email-123",
                 provider_event_id: nil,
                 from_address: "alice@example.com",
                 to_address: "kmc@clubs.memba.io",
                 rejection_reason: "plain_text_required"
               })
    end
  end

  defp inbound_email_id, do: InboundEmail.identity(inbound_email())

  defp inbound_email do
    %InboundEmail{
      provider: "resend",
      provider_message_id: "email-123",
      provider_event_id: "event-456",
      from_address: "alice@example.com",
      recipient_addresses: ["kmc@clubs.memba.io"],
      subject: "Trip planning night",
      text_body: "Bring route ideas."
    }
  end

  defp receive_command do
    inbound_email = inbound_email()

    %ReceiveInboundEmail{
      inbound_email_id: InboundEmail.identity(inbound_email),
      inbound_email: inbound_email
    }
  end

  defp reject_command do
    receive_command = receive_command()

    %RejectInboundClubEmail{
      inbound_email_id: receive_command.inbound_email_id,
      inbound_email: receive_command.inbound_email,
      to_address: "kmc@clubs.memba.io",
      rejection_reason: "plain_text_required"
    }
  end

  defp received_receipt do
    InboundEmailReceipt.apply(%InboundEmailReceipt{}, %InboundEmailReceived{
      inbound_email_id: inbound_email_id(),
      provider: "resend",
      provider_message_id: "email-123",
      provider_event_id: "event-456"
    })
  end
end
