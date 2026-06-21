defmodule Memba.Messaging.EmailDeliveryProviders.ResendTest do
  use ExUnit.Case, async: false

  import Swoosh.TestAssertions

  alias Memba.Messaging.EmailDeliveryProviders.Resend
  alias Memba.Messaging.EmailDeliveryRequest
  alias Memba.Messaging.OutboundMessageID

  setup do
    original_mailer_config = Application.get_env(:memba, Memba.Mailer)
    original_resend_config = Application.get_env(:memba, Resend)

    Application.put_env(:memba, Memba.Mailer,
      adapter: Swoosh.Adapters.Test,
      api_key: "resend-key"
    )

    on_exit(fn ->
      restore_env(Memba.Mailer, original_mailer_config)
      restore_env(Resend, original_resend_config)
    end)

    :ok
  end

  test "builds and sends a multipart email with Resend correlation tags and headers" do
    Application.put_env(:memba, Resend,
      from: "messages@mail.memba.io",
      reply_to: "help@memba.io"
    )

    request =
      email_delivery_request(
        club_name: "Kootenay <Mountaineers>",
        club_slug: "kmc",
        body: "Hello <Alice> & Bob\n\nBring route ideas.\n<script>alert(1)</script>"
      )

    assert :ok = Resend.deliver(request)

    assert_received {:email, %Swoosh.Email{} = email}

    assert email.from == {"Bob Barker via Memba", "messages@mail.memba.io"}
    assert email.reply_to == {"Kootenay <Mountaineers>", "kmc@clubs.memba.io"}
    assert email.to == [{"Alice Adams", "alice@example.com"}]
    assert email.headers["Message-ID"] == request.outbound_message_id
    assert email.subject == "[kmc] Trip planning night"

    assert email.text_body ==
             "Hello <Alice> & Bob\n\nBring route ideas.\n<script>alert(1)</script>"

    assert email.html_body =~ "<!doctype html>"
    assert email.html_body =~ "Kootenay &lt;Mountaineers&gt;"
    assert email.html_body =~ "Members message"
    assert email.html_body =~ "Bob Barker"
    assert email.html_body =~ "to all members of Kootenay &lt;Mountaineers&gt;"
    assert email.html_body =~ "Trip planning night"
    assert email.html_body =~ "Hello &lt;Alice&gt; &amp; Bob"
    assert email.html_body =~ "Bring route ideas.<br>\n&lt;script&gt;alert(1)&lt;/script&gt;"
    assert email.html_body =~ "Reply to this email to post back to"
    assert email.html_body =~ "Kootenay &lt;Mountaineers&gt;"
    assert email.html_body =~ "Delivered for Kootenay &lt;Mountaineers&gt; by"
    assert email.html_body =~ "active member of Kootenay &lt;Mountaineers&gt;"

    refute email.html_body =~ "<Alice>"
    refute email.html_body =~ "<script>"

    assert email.provider_options == %{
             tags: [
               %{name: "memba_message_id", value: request.message_id},
               %{name: "memba_delivery_id", value: request.delivery_id},
               %{name: "memba_club_id", value: request.club_id},
               %{name: "memba_email_kind", value: "member_message"}
             ]
           }

    assert email.headers["X-Memba-Message-ID"] == request.message_id
    assert email.headers["X-Memba-Delivery-ID"] == request.delivery_id
    assert email.headers["X-Memba-Club-ID"] == request.club_id
  end

  test "sanitizes Resend member-message header display values while preserving the text body" do
    Application.put_env(:memba, Resend, from: "messages@mail.memba.io")

    request =
      email_delivery_request(
        recipient_name: "Alice\nAdams",
        sender_name: "Bob\nBarker",
        subject: "Trip planning\nnight",
        body: "Hello exactly as written.\nDo not add guidance here."
      )

    assert :ok = Resend.deliver(request)

    assert_received {:email, %Swoosh.Email{} = email}

    assert email.from == {"Bob Barker via Memba", "messages@mail.memba.io"}
    assert email.reply_to == {"Bob Barker", "bob@example.com"}
    assert email.to == [{"Alice Adams", "alice@example.com"}]
    assert email.subject == "Trip planning night"
    assert email.text_body == "Hello exactly as written.\nDo not add guidance here."
    refute email.text_body =~ "Reply to this email"
  end

  test "uses the verified Memba sender address even when no provider reply-to is configured" do
    Application.put_env(:memba, Resend, from: "messages@mail.memba.io")

    assert :ok = Resend.deliver(email_delivery_request())

    assert_received {:email,
                     %Swoosh.Email{
                       from: {"Bob Barker via Memba", "messages@mail.memba.io"},
                       reply_to: {"Bob Barker", "bob@example.com"}
                     }}
  end

  test "sets email reply-thread headers for Resend reply notifications" do
    Application.put_env(:memba, Resend, from: "messages@mail.memba.io")

    request =
      email_delivery_request(
        club_name: "Kootenay Mountaineers",
        club_slug: "kmc",
        conversation_id: Memba.ID.generate(:message),
        reply_to_message_id: Memba.ID.generate(:message),
        in_reply_to_outbound_message_id: "<memba.parent@example.test>",
        references_outbound_message_ids: [
          "<memba.root@example.test>",
          "<memba.parent@example.test>"
        ]
      )

    assert :ok = Resend.deliver(request)

    assert_received {:email, %Swoosh.Email{} = email}

    assert email.reply_to == {"Kootenay Mountaineers", "kmc@clubs.memba.io"}
    assert email.headers["Message-ID"] == request.outbound_message_id
    assert email.headers["In-Reply-To"] == "<memba.parent@example.test>"
    assert email.headers["References"] == "<memba.root@example.test> <memba.parent@example.test>"
  end

  test "does not hand an email to Swoosh when required Resend configuration is missing" do
    Application.put_env(:memba, Memba.Mailer, adapter: Swoosh.Adapters.Test)
    Application.put_env(:memba, Resend, from: "messages@mail.memba.io")

    assert {:error, {:resend_configuration_error, message}} =
             Resend.deliver(email_delivery_request())

    assert message =~ "Resend email delivery provider is enabled"
    assert message =~ "MEMBA_RESEND_API_KEY"

    assert_no_email_sent()
  end

  test "does not hand unsupported delivery channels to Swoosh" do
    Application.put_env(:memba, Resend, from: "messages@mail.memba.io")

    assert {:error, {:unsupported_delivery_channel, :sms}} =
             Resend.deliver(email_delivery_request(channel: :sms))

    assert_no_email_sent()
  end

  test "returns a visible Resend delivery error when Swoosh reports an API failure" do
    Application.put_env(:memba, Memba.Mailer,
      adapter: Memba.TestSupport.FailingSwooshAdapter,
      api_key: "resend-key",
      test_owner: self(),
      test_delivery_result: {:error, {401, %{"message" => "Invalid API key"}}}
    )

    Application.put_env(:memba, Resend, from: "messages@mail.memba.io")

    assert {:error, {:resend_delivery_error, {401, %{"message" => "Invalid API key"}}}} =
             Resend.deliver(email_delivery_request())

    assert_received {:failing_swoosh_adapter_deliver, %Swoosh.Email{}}
  end

  test "returns a visible Resend delivery exception when Swoosh configuration raises" do
    Application.put_env(:memba, Memba.Mailer,
      adapter: Memba.TestSupport.FailingSwooshAdapter,
      api_key: "resend-key",
      test_validate_config_error: "missing Resend API client",
      test_delivery_result: {:ok, %{id: "not-sent"}}
    )

    Application.put_env(:memba, Resend, from: "messages@mail.memba.io")

    assert {:error, {:resend_delivery_exception, ArgumentError, "missing Resend API client"}} =
             Resend.deliver(email_delivery_request())

    refute_received {:failing_swoosh_adapter_deliver, %Swoosh.Email{}}
  end

  defp email_delivery_request(overrides \\ []) do
    message_id = Keyword.get_lazy(overrides, :message_id, fn -> Memba.ID.generate(:message) end)

    delivery_id =
      Keyword.get_lazy(overrides, :delivery_id, fn -> Memba.ID.generate(:delivery) end)

    %EmailDeliveryRequest{
      message_id: message_id,
      club_id: Keyword.get_lazy(overrides, :club_id, fn -> Memba.ID.generate(:club) end),
      delivery_id: delivery_id,
      outbound_message_id:
        Keyword.get(
          overrides,
          :outbound_message_id,
          OutboundMessageID.for_delivery(delivery_id, message_id)
        ),
      recipient_id:
        Keyword.get_lazy(overrides, :recipient_id, fn -> Memba.ID.generate(:person) end),
      recipient_name: Keyword.get(overrides, :recipient_name, "Alice Adams"),
      recipient_address: Keyword.get(overrides, :recipient_address, "alice@example.com"),
      club_name: Keyword.get(overrides, :club_name, "Kootenay Mountaineering Club"),
      club_slug: Keyword.get(overrides, :club_slug),
      sender_name: Keyword.get(overrides, :sender_name, "Bob Barker"),
      sender_address: Keyword.get(overrides, :sender_address, "bob@example.com"),
      conversation_id: Keyword.get(overrides, :conversation_id),
      reply_to_message_id: Keyword.get(overrides, :reply_to_message_id),
      in_reply_to_outbound_message_id: Keyword.get(overrides, :in_reply_to_outbound_message_id),
      references_outbound_message_ids: Keyword.get(overrides, :references_outbound_message_ids),
      channel: Keyword.get(overrides, :channel, :email),
      subject: Keyword.get(overrides, :subject, "Trip planning night"),
      body: Keyword.get(overrides, :body, "Bring route ideas.")
    }
  end

  defp restore_env(key, nil), do: Application.delete_env(:memba, key)
  defp restore_env(key, value), do: Application.put_env(:memba, key, value)
end
