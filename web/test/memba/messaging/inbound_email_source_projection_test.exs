defmodule Memba.Messaging.InboundEmailSourceProjectionTest do
  use Memba.EventSourcedCase, async: false

  alias Memba.Messaging
  alias Memba.Messaging.Events.InboundClubEmailAccepted
  alias Memba.Messaging.Events.InboundClubEmailRejected
  alias Memba.Messaging.Projectors.InboundEmailSource, as: InboundEmailSourceProjector
  alias Memba.Messaging.Projections.InboundEmailSource, as: InboundEmailSourceProjection

  test "accepted inbound club email events project source status and created message identity" do
    inbound_email_id = Memba.ID.deterministic(:inbound_email, ["resend", "email-123"])
    club_id = Memba.ID.generate(:club)
    sender_id = Memba.ID.generate(:person)
    message_id = Memba.ID.generate(:message)

    assert :ok =
             InboundEmailSourceProjector.handle(
               %InboundClubEmailAccepted{
                 inbound_email_id: inbound_email_id,
                 provider: "resend",
                 provider_message_id: "email-123",
                 provider_event_id: "event-456",
                 from_address: "alice@example.com",
                 to_address: "kmc@clubs.memba.io",
                 club_id: club_id,
                 sender_id: sender_id,
                 message_id: message_id
               },
               projector_metadata(1)
             )

    assert %InboundEmailSourceProjection{
             inbound_email_id: ^inbound_email_id,
             provider: "resend",
             provider_message_id: "email-123",
             provider_event_id: "event-456",
             from_address: "alice@example.com",
             to_address: "kmc@clubs.memba.io",
             status: "accepted",
             club_id: ^club_id,
             sender_id: ^sender_id,
             message_id: ^message_id,
             rejection_reason: nil,
             rejection_email_delivery_reference: nil,
             inserted_at: %DateTime{},
             updated_at: %DateTime{}
           } = Messaging.get_inbound_email_source("resend", "email-123")
  end

  test "rejected inbound club email events project source status and rejection audit fields" do
    inbound_email_id = Memba.ID.deterministic(:inbound_email, ["resend", "email-456"])

    assert :ok =
             InboundEmailSourceProjector.handle(
               %InboundClubEmailRejected{
                 inbound_email_id: inbound_email_id,
                 provider: "resend",
                 provider_message_id: "email-456",
                 provider_event_id: "event-789",
                 from_address: "unknown@example.com",
                 to_address: "kmc@clubs.memba.io",
                 rejection_reason: "unknown sender",
                 rejection_email_delivery_reference: "resend-rejection-123"
               },
               projector_metadata(2)
             )

    assert %InboundEmailSourceProjection{
             inbound_email_id: ^inbound_email_id,
             provider: "resend",
             provider_message_id: "email-456",
             provider_event_id: "event-789",
             from_address: "unknown@example.com",
             to_address: "kmc@clubs.memba.io",
             status: "rejected",
             message_id: nil,
             rejection_reason: "unknown sender",
             rejection_email_delivery_reference: "resend-rejection-123",
             inserted_at: %DateTime{},
             updated_at: %DateTime{}
           } = Messaging.get_inbound_email_source(" resend ", " EMAIL-456 ")
  end

  test "inbound source projection enforces provider message id uniqueness defensively" do
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    Repo.insert!(%InboundEmailSourceProjection{
      inbound_email_id: Memba.ID.generate(:inbound_email),
      provider: "resend",
      provider_message_id: "duplicate",
      from_address: "alice@example.com",
      to_address: "kmc@clubs.memba.io",
      status: "accepted",
      message_id: Memba.ID.generate(:message),
      inserted_at: now,
      updated_at: now
    })

    assert_raise Ecto.ConstraintError,
                 ~r/messaging_inbound_email_sources_provider_message_id_index/,
                 fn ->
                   Repo.insert!(%InboundEmailSourceProjection{
                     inbound_email_id: Memba.ID.generate(:inbound_email),
                     provider: "resend",
                     provider_message_id: "duplicate",
                     from_address: "alice@example.com",
                     to_address: "kmc@clubs.memba.io",
                     status: "accepted",
                     message_id: Memba.ID.generate(:message),
                     inserted_at: now,
                     updated_at: now
                   })
                 end
  end

  test "inbound source query returns nil for absent or invalid provider identity" do
    assert is_nil(Messaging.get_inbound_email_source("resend", "missing"))
    assert is_nil(Messaging.get_inbound_email_source(nil, "email-123"))
    assert is_nil(Messaging.get_inbound_email_source("resend", nil))
    assert is_nil(Messaging.get_inbound_email_source("", "email-123"))
    assert is_nil(Messaging.get_inbound_email_source("resend", ""))
  end

  defp projector_metadata(event_number) do
    %{
      handler_name: "inbound-email-source-projection-test-#{Ecto.UUID.generate()}",
      event_number: event_number
    }
  end
end
