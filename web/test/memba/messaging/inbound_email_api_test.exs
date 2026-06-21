defmodule Memba.Messaging.InboundEmailApiTest do
  use ExUnit.Case, async: true

  alias Memba.Messaging
  alias Memba.Messaging.Commands.ReceiveInboundEmail
  alias Memba.Messaging.InboundEmail
  alias Memba.Messaging.InboundEmailAttachment

  describe "receive_inbound_club_email_command/1" do
    test "builds a provider-neutral inbound email command" do
      attrs = %{
        provider: " Example Mail ",
        provider_message_id: " provider-message-123 ",
        provider_event_id: " provider-event-456 ",
        from_address: " Alice@Example.COM ",
        recipient_addresses: [" KMC@Clubs.Memba.IO ", " everyone@example.org "],
        subject: "Trip planning night",
        text_body: "Bring route ideas.",
        html_body: "<p>Bring route ideas.</p>",
        in_reply_to_message_ids: [" memba.parent-delivery.parent-message@messages.memba.io "],
        references_message_ids: [
          "<memba.root-delivery.root-message@messages.memba.io>",
          "memba.parent-delivery.parent-message@messages.memba.io"
        ],
        attachments: [
          %{
            filename: "route.gpx",
            content_type: "application/gpx+xml",
            size: 1234,
            content_id: "map-attachment"
          }
        ]
      }

      assert {:ok,
              %ReceiveInboundEmail{
                inbound_email_id: _inbound_email_id,
                inbound_email: %InboundEmail{
                  provider: "example mail",
                  provider_message_id: "provider-message-123",
                  provider_event_id: "provider-event-456",
                  from_address: "alice@example.com",
                  recipient_addresses: ["kmc@clubs.memba.io", "everyone@example.org"],
                  subject: "Trip planning night",
                  text_body: "Bring route ideas.",
                  html_body: "<p>Bring route ideas.</p>",
                  in_reply_to_message_ids: [
                    "<memba.parent-delivery.parent-message@messages.memba.io>"
                  ],
                  references_message_ids: [
                    "<memba.root-delivery.root-message@messages.memba.io>",
                    "<memba.parent-delivery.parent-message@messages.memba.io>"
                  ],
                  attachments: [
                    %InboundEmailAttachment{
                      filename: "route.gpx",
                      content_type: "application/gpx+xml",
                      size: 1234,
                      content_id: "map-attachment"
                    }
                  ]
                }
              }} = Messaging.receive_inbound_club_email_command(attrs)
    end

    test "accepts string-keyed attrs and keeps optional provider fields optional" do
      attrs = %{
        "provider" => "postmark",
        "provider_message_id" => "inbound-123",
        "from_address" => "alice@example.com",
        "recipient_addresses" => ["kmc@clubs.memba.io"],
        "subject" => "Trail conditions"
      }

      assert {:ok,
              %ReceiveInboundEmail{
                inbound_email_id: _inbound_email_id,
                inbound_email: %InboundEmail{
                  provider: "postmark",
                  provider_message_id: "inbound-123",
                  provider_event_id: nil,
                  from_address: "alice@example.com",
                  recipient_addresses: ["kmc@clubs.memba.io"],
                  subject: "Trail conditions",
                  text_body: nil,
                  html_body: nil,
                  in_reply_to_message_ids: [],
                  references_message_ids: [],
                  attachments: []
                }
              }} = Messaging.receive_inbound_club_email_command(attrs)
    end

    test "rejects malformed provider-neutral attrs before any provider-specific parsing" do
      valid_attrs = %{
        provider: "example-mail",
        provider_message_id: "provider-message-123",
        from_address: "alice@example.com",
        recipient_addresses: ["kmc@clubs.memba.io"],
        subject: "Trip planning night"
      }

      assert {:error, {:missing_required_attribute, :provider_message_id}} =
               valid_attrs
               |> Map.delete(:provider_message_id)
               |> Messaging.receive_inbound_club_email_command()

      assert {:error, :invalid_provider} =
               %{valid_attrs | provider: " "}
               |> Messaging.receive_inbound_club_email_command()

      assert {:error, :invalid_from_address} =
               %{valid_attrs | from_address: "not an email address"}
               |> Messaging.receive_inbound_club_email_command()

      assert {:error, :invalid_recipient_addresses} =
               %{valid_attrs | recipient_addresses: []}
               |> Messaging.receive_inbound_club_email_command()

      assert {:error, :invalid_attachment} =
               valid_attrs
               |> Map.put(:attachments, ["route.gpx"])
               |> Messaging.receive_inbound_club_email_command()
    end
  end
end
