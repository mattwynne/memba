defmodule Memba.Messaging.InboundEmailEventsTest do
  use ExUnit.Case, async: true

  alias Memba.Messaging.Events.InboundClubEmailAccepted
  alias Memba.Messaging.Events.InboundClubEmailRejected

  test "InboundClubEmailAccepted records provider identity, routing, sender, and message identity" do
    club_id = Ecto.UUID.generate()
    sender_id = Ecto.UUID.generate()
    message_id = Ecto.UUID.generate()

    event = %InboundClubEmailAccepted{
      inbound_email_id: "inbound-email:resend:email-123",
      provider: "resend",
      provider_message_id: "email-123",
      provider_event_id: "event-456",
      from_address: "alice@example.com",
      to_address: "kmc@clubs.memba.io",
      club_id: club_id,
      sender_id: sender_id,
      message_id: message_id
    }

    assert %{
             "inbound_email_id" => "inbound-email:resend:email-123",
             "provider" => "resend",
             "provider_message_id" => "email-123",
             "provider_event_id" => "event-456",
             "from_address" => "alice@example.com",
             "to_address" => "kmc@clubs.memba.io",
             "club_id" => ^club_id,
             "sender_id" => ^sender_id,
             "message_id" => ^message_id
           } = Jason.decode!(Jason.encode!(event))
  end

  test "InboundClubEmailRejected records provider identity, available addresses, reason, and rejection delivery reference" do
    event = %InboundClubEmailRejected{
      inbound_email_id: "inbound-email:resend:email-123",
      provider: "resend",
      provider_message_id: "email-123",
      provider_event_id: "event-456",
      from_address: "unknown@example.com",
      to_address: "kmc@clubs.memba.io",
      rejection_reason: "unknown sender",
      rejection_email_delivery_reference: "resend-rejection-789"
    }

    assert %{
             "inbound_email_id" => "inbound-email:resend:email-123",
             "provider" => "resend",
             "provider_message_id" => "email-123",
             "provider_event_id" => "event-456",
             "from_address" => "unknown@example.com",
             "to_address" => "kmc@clubs.memba.io",
             "rejection_reason" => "unknown sender",
             "rejection_email_delivery_reference" => "resend-rejection-789"
           } = Jason.decode!(Jason.encode!(event))
  end

  test "InboundClubEmailRejected can omit destination and rejection delivery reference" do
    event = %InboundClubEmailRejected{
      inbound_email_id: "inbound-email:resend:email-123",
      provider: "resend",
      provider_message_id: "email-123",
      from_address: "unknown@example.com",
      rejection_reason: "unsupported recipient"
    }

    assert %{
             "to_address" => nil,
             "provider_event_id" => nil,
             "rejection_email_delivery_reference" => nil
           } = Jason.decode!(Jason.encode!(event))
  end
end
