defmodule MembaWeb.ResendInboundEmailParserTest do
  use ExUnit.Case, async: true

  alias MembaWeb.ResendInboundEmailParser

  test "parses a realistic email.received payload into provider-neutral inbound email attrs" do
    payload = %{
      "id" => "evt_123",
      "type" => "email.received",
      "data" => %{
        "email_id" => "email_123",
        "from" => "Alice Example <Alice@Example.COM>",
        "to" => ["KMC <kmc@clubs.memba.io>"],
        "cc" => [
          %{"email" => "bob@example.com", "name" => "Bob Example"},
          "NPC <npc@clubs.memba.io>"
        ],
        "bcc" => "Archive <archive@example.com>",
        "subject" => " Trip planning night ",
        "text" => "Bring route ideas.",
        "html" => "<p>Bring route ideas.</p>",
        "attachments" => [
          %{
            "filename" => "route.gpx",
            "content_type" => "application/gpx+xml",
            "size" => 1234,
            "content_id" => "attachment-1"
          }
        ],
        "headers" => [
          %{"name" => "Message-ID", "value" => "<email_123@example.com>"}
        ]
      }
    }

    assert {:ok,
            %{
              provider: "resend",
              provider_message_id: "email_123",
              provider_event_id: "evt_123",
              from_address: "alice@example.com",
              recipient_addresses: [
                "kmc@clubs.memba.io",
                "bob@example.com",
                "npc@clubs.memba.io",
                "archive@example.com"
              ],
              subject: "Trip planning night",
              text_body: "Bring route ideas.",
              html_body: "<p>Bring route ideas.</p>",
              attachments: [
                %{
                  filename: "route.gpx",
                  content_type: "application/gpx+xml",
                  size: 1234,
                  content_id: "attachment-1"
                }
              ],
              headers: [
                %{"name" => "Message-ID", "value" => "<email_123@example.com>"}
              ]
            }} = ResendInboundEmailParser.parse(payload)
  end

  test "uses the data id as the provider message id when email_id is absent" do
    payload =
      valid_payload()
      |> put_in(["data"], Map.delete(valid_payload()["data"], "email_id"))

    assert {:ok, %{provider_message_id: "email_fallback_id"}} =
             ResendInboundEmailParser.parse(payload)
  end

  test "rejects unsupported event types" do
    payload = Map.put(valid_payload(), "type", "email.delivered")

    assert {:error, {:unsupported_event_type, "email.delivered"}} =
             ResendInboundEmailParser.parse(payload)
  end

  test "treats missing required fields as malformed" do
    required_field_removals = [
      {"data", fn payload -> Map.delete(payload, "data") end},
      {"data.email_id",
       fn payload ->
         update_in(payload, ["data"], &(&1 |> Map.delete("email_id") |> Map.delete("id")))
       end},
      {"data.from", fn payload -> update_in(payload, ["data"], &Map.delete(&1, "from")) end},
      {"data.to", fn payload -> update_in(payload, ["data"], &Map.delete(&1, "to")) end},
      {"data.subject",
       fn payload -> update_in(payload, ["data"], &Map.delete(&1, "subject")) end},
      {"data.text", fn payload -> update_in(payload, ["data"], &Map.delete(&1, "text")) end}
    ]

    for {field, remove_field} <- required_field_removals do
      assert {:error, {:missing_required_attribute, ^field}} =
               valid_payload()
               |> remove_field.()
               |> ResendInboundEmailParser.parse()
    end
  end

  test "rejects invalid required field shapes" do
    payload =
      valid_payload()
      |> put_in(["data", "to"], [])

    assert {:error, :invalid_recipient_addresses} = ResendInboundEmailParser.parse(payload)
  end

  test "rejects malformed optional inbound email fields" do
    malformed_payloads = [
      {:invalid_provider_message_id, put_in(valid_payload(), ["data", "email_id"], %{})},
      {:invalid_from_address, put_in(valid_payload(), ["data", "from"], "Alice Example")},
      {:invalid_html_body, put_in(valid_payload(), ["data", "html"], %{"body" => "<p>Hi</p>"})},
      {:invalid_attachments,
       put_in(valid_payload(), ["data", "attachments"], [
         %{"filename" => "route.gpx", "size" => -1}
       ])}
    ]

    for {reason, payload} <- malformed_payloads do
      assert {:error, ^reason} = ResendInboundEmailParser.parse(payload)
    end
  end

  defp valid_payload do
    %{
      "id" => "evt_123",
      "type" => "email.received",
      "data" => %{
        "id" => "email_fallback_id",
        "email_id" => "email_123",
        "from" => "alice@example.com",
        "to" => ["kmc@clubs.memba.io"],
        "subject" => "Trip planning night",
        "text" => "Bring route ideas."
      }
    }
  end
end
