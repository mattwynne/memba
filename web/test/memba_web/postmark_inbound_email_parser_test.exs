defmodule MembaWeb.PostmarkInboundEmailParserTest do
  use ExUnit.Case, async: true

  alias MembaWeb.PostmarkInboundEmailParser

  test "parses a realistic Postmark inbound payload into provider-neutral inbound email attrs" do
    payload = %{
      "MessageID" => "73e6d360-66eb-11e1-8e72-a8904824019b",
      "MessageStream" => "inbound",
      "From" => "Alice Example <Alice@Example.COM>",
      "FromFull" => %{
        "Email" => "Alice@Example.COM",
        "Name" => "Alice Example",
        "MailboxHash" => ""
      },
      "OriginalRecipient" => "kmc@clubs.memba.io",
      "To" => "KMC <kmc@clubs.memba.io>, Board <board@example.com>",
      "ToFull" => [
        %{"Email" => "kmc@clubs.memba.io", "Name" => "KMC", "MailboxHash" => ""}
      ],
      "Cc" => "NPC <npc@clubs.memba.io>",
      "CcFull" => [
        %{"Email" => "bob@example.com", "Name" => "Bob Example", "MailboxHash" => ""}
      ],
      "Bcc" => "Audit <audit@example.com>",
      "BccFull" => [
        %{"Email" => "archive@example.com", "Name" => "Archive", "MailboxHash" => ""}
      ],
      "Subject" => " Trip planning night ",
      "TextBody" => "Bring route ideas.",
      "HtmlBody" => "<p>Bring route ideas.</p>",
      "Headers" => [
        %{"Name" => "Message-ID", "Value" => "<postmark-message@example.com>"},
        %{"Name" => "X-Spam-Status", "Value" => "No"}
      ],
      "Attachments" => [
        %{
          "Name" => "route.gpx",
          "ContentType" => "application/gpx+xml",
          "ContentLength" => 1234,
          "ContentID" => "attachment-1",
          "Content" => "ignored-base64-content"
        }
      ]
    }

    assert {:ok,
            %{
              provider: "postmark",
              provider_message_id: "73e6d360-66eb-11e1-8e72-a8904824019b",
              from_address: "alice@example.com",
              recipient_addresses: [
                "kmc@clubs.memba.io",
                "board@example.com",
                "bob@example.com",
                "npc@clubs.memba.io",
                "archive@example.com",
                "audit@example.com"
              ],
              subject: "Trip planning night",
              text_body: "Bring route ideas.",
              html_body: "<p>Bring route ideas.</p>",
              original_message_id: "<postmark-message@example.com>",
              in_reply_to_message_ids: [],
              references_message_ids: [],
              attachments: [
                %{
                  filename: "route.gpx",
                  content_type: "application/gpx+xml",
                  size: 1234,
                  content_id: "attachment-1"
                }
              ],
              headers: [
                %{"Name" => "Message-ID", "Value" => "<postmark-message@example.com>"},
                %{"Name" => "X-Spam-Status", "Value" => "No"}
              ]
            }} = PostmarkInboundEmailParser.parse(payload)
  end

  test "parses In-Reply-To and all References Message-IDs from Postmark headers" do
    payload =
      valid_payload(%{
        "Headers" => [
          %{
            "Name" => "In-Reply-To",
            "Value" => " \r\n\t<memba.parent-delivery.parent-message@messages.memba.io> "
          },
          %{
            "Name" => "References",
            "Value" =>
              "<memba.root-delivery.root-message@messages.memba.io>\r\n " <>
                "<external-parent@example.net>, " <>
                "memba.latest-delivery.latest-message@messages.memba.io"
          },
          %{
            "Name" => "references",
            "Value" => "<memba.trailing-delivery.trailing-message@messages.memba.io>"
          }
        ]
      })

    assert {:ok,
            %{
              in_reply_to_message_ids: [
                "<memba.parent-delivery.parent-message@messages.memba.io>"
              ],
              references_message_ids: [
                "<memba.root-delivery.root-message@messages.memba.io>",
                "<external-parent@example.net>",
                "<memba.latest-delivery.latest-message@messages.memba.io>",
                "<memba.trailing-delivery.trailing-message@messages.memba.io>"
              ]
            }} = PostmarkInboundEmailParser.parse(payload)
  end

  test "uses OriginalRecipient when the visible recipient is a Postmark forwarding address" do
    payload =
      valid_payload(%{
        "OriginalRecipient" => "KMC@clubs.memba.io",
        "To" => "inbound-stream@example.postmarkapp.com",
        "ToFull" => [
          %{"Email" => "inbound-stream@example.postmarkapp.com", "Name" => "Postmark Inbound"}
        ]
      })

    assert {:ok,
            %{
              recipient_addresses: [
                "kmc@clubs.memba.io",
                "inbound-stream@example.postmarkapp.com"
              ]
            }} = PostmarkInboundEmailParser.parse(payload)
  end

  test "uses the top-level Postmark MessageID as the provider retry identity" do
    payload =
      valid_payload(%{
        "MessageID" => "postmark-stable-provider-id",
        "Headers" => [
          %{"Name" => "Message-ID", "Value" => "<original-sender-message@example.com>"}
        ]
      })

    assert {:ok,
            %{
              provider: "postmark",
              provider_message_id: "postmark-stable-provider-id"
            }} = PostmarkInboundEmailParser.parse(payload)
  end

  test "allows missing plain text so shared inbound handling can reject HTML-only messages" do
    payload =
      valid_payload(%{
        "HtmlBody" => "<p>This HTML must not be converted into a club message.</p>"
      })
      |> Map.delete("TextBody")

    assert {:ok,
            %{
              text_body: nil,
              html_body: "<p>This HTML must not be converted into a club message.</p>"
            }} = PostmarkInboundEmailParser.parse(payload)
  end

  test "treats missing required fields as malformed" do
    required_field_removals = [
      {"MessageID", fn payload -> Map.delete(payload, "MessageID") end},
      {"Subject", fn payload -> Map.delete(payload, "Subject") end}
    ]

    for {field, remove_field} <- required_field_removals do
      assert {:error, {:missing_required_attribute, ^field}} =
               valid_payload()
               |> remove_field.()
               |> PostmarkInboundEmailParser.parse()
    end
  end

  test "rejects malformed inbound address fields" do
    malformed_payloads = [
      {:invalid_from_address,
       valid_payload(%{"From" => nil, "FromFull" => %{"Name" => "Alice Example"}})},
      {:invalid_recipient_addresses,
       valid_payload(%{"OriginalRecipient" => nil, "To" => nil, "ToFull" => []})}
    ]

    for {reason, payload} <- malformed_payloads do
      assert {:error, ^reason} = PostmarkInboundEmailParser.parse(payload)
    end
  end

  test "rejects malformed optional fields" do
    malformed_payloads = [
      {:invalid_text_body, valid_payload(%{"TextBody" => %{"body" => "Hi"}})},
      {:invalid_html_body, valid_payload(%{"HtmlBody" => %{"body" => "<p>Hi</p>"}})},
      {:invalid_attachments,
       valid_payload(%{
         "Attachments" => [
           %{"Name" => "route.gpx", "ContentLength" => -1}
         ]
       })}
    ]

    for {reason, payload} <- malformed_payloads do
      assert {:error, ^reason} = PostmarkInboundEmailParser.parse(payload)
    end
  end

  defp valid_payload(overrides \\ %{}) do
    Map.merge(
      %{
        "MessageID" => "73e6d360-66eb-11e1-8e72-a8904824019b",
        "MessageStream" => "inbound",
        "From" => "Alice Example <alice@example.com>",
        "To" => "KMC <kmc@clubs.memba.io>",
        "OriginalRecipient" => "kmc@clubs.memba.io",
        "Subject" => "Trip planning night",
        "TextBody" => "Bring route ideas."
      },
      overrides
    )
  end
end
