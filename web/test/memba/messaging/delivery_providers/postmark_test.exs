defmodule Memba.Messaging.DeliveryProviders.PostmarkTest do
  use ExUnit.Case, async: true

  import Swoosh.TestAssertions

  alias Memba.Messaging.DeliveryProviders.Postmark
  alias Memba.Messaging.DeliveryRequest

  setup do
    original_config = Application.get_env(:memba, Postmark)

    Application.put_env(:memba, Postmark,
      from: {"Memba", "messages@mail.memba.io"},
      reply_to: {"Matt Wynne", "matt@mattwynne.net"},
      message_stream: "outbound-member-broadcasts",
      track_opens: true,
      track_links: "None"
    )

    on_exit(fn -> Application.put_env(:memba, Postmark, original_config) end)

    :ok
  end

  test "delivers member broadcasts with Postmark metadata and tracking options" do
    request = delivery_request()

    assert :ok = Postmark.deliver(request)

    assert_email_sent(fn email ->
      assert email.from == {"Memba", "messages@mail.memba.io"}
      assert email.to == [{request.recipient_name, request.recipient_address}]
      assert email.reply_to == {"Matt Wynne", "matt@mattwynne.net"}
      assert email.subject == request.subject
      assert email.text_body == request.body
      assert email.provider_options.message_stream == "outbound-member-broadcasts"
      assert email.provider_options.track_opens == true
      assert email.provider_options.track_links == "None"

      assert email.provider_options.metadata == %{
               "memba_message_id" => request.message_id,
               "memba_delivery_id" => request.delivery_id,
               "memba_club_id" => request.club_id,
               "memba_recipient_id" => request.recipient_id
             }
    end)
  end

  defp delivery_request do
    %DeliveryRequest{
      message_id: Ecto.UUID.generate(),
      club_id: Ecto.UUID.generate(),
      delivery_id: Ecto.UUID.generate(),
      recipient_id: Ecto.UUID.generate(),
      recipient_name: "Matt Wynne",
      recipient_address: "matt@mattwynne.net",
      channel: :email,
      subject: "Local Postmark smoke test",
      body: "Testing Memba Postmark delivery."
    }
  end
end
