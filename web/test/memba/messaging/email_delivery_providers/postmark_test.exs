defmodule Memba.Messaging.EmailDeliveryProviders.PostmarkTest do
  use ExUnit.Case, async: false

  import Swoosh.TestAssertions

  alias Memba.Messaging.EmailDeliveryProviders.Postmark
  alias Memba.Messaging.EmailDeliveryRequest

  setup do
    original_mailer_config = Application.get_env(:memba, Memba.Mailer)
    original_postmark_config = Application.get_env(:memba, Postmark)

    Application.put_env(:memba, Memba.Mailer,
      adapter: Swoosh.Adapters.Test,
      api_key: "server-token"
    )

    on_exit(fn ->
      restore_env(Memba.Mailer, original_mailer_config)
      restore_env(Postmark, original_postmark_config)
    end)

    :ok
  end

  test "builds and sends a multipart member-message email with Postmark correlation metadata and no open tracking" do
    Application.put_env(:memba, Postmark,
      from: "messages@mail.memba.io",
      reply_to: "help@memba.io"
    )

    request =
      email_delivery_request(
        club_name: "Kootenay <Mountaineers>",
        club_slug: "kmc",
        body: "Hello <Alice> & Bob\n\nBring route ideas.\n<script>alert(1)</script>"
      )

    assert :ok = Postmark.deliver(request)

    assert_received {:email, %Swoosh.Email{} = email}

    assert email.from == {"Bob Barker via Memba", "messages@mail.memba.io"}
    assert email.reply_to == {"Bob Barker", "bob@example.com"}
    assert email.to == [{"Alice Adams", "alice@example.com"}]
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
    assert email.html_body =~ "Reply to this email and it goes straight to"
    assert email.html_body =~ "not to the whole group"
    assert email.html_body =~ "Delivered for Kootenay &lt;Mountaineers&gt; by"
    assert email.html_body =~ "active member of Kootenay &lt;Mountaineers&gt;"

    refute email.html_body =~ "<Alice>"
    refute email.html_body =~ "<script>"

    assert email.provider_options == %{
             metadata: %{
               "memba_message_id" => request.message_id,
               "memba_delivery_id" => request.delivery_id,
               "memba_club_id" => request.club_id
             }
           }

    refute Map.has_key?(email.provider_options, :track_opens)
  end

  test "sanitizes member-message header display values while preserving the text body" do
    Application.put_env(:memba, Postmark, from: "messages@mail.memba.io")

    request =
      email_delivery_request(
        recipient_name: "Alice\nAdams",
        sender_name: "Bob\nBarker",
        subject: "Trip planning\nnight",
        body: "Hello exactly as written.\nDo not add guidance here."
      )

    assert :ok = Postmark.deliver(request)

    assert_received {:email, %Swoosh.Email{} = email}

    assert email.from == {"Bob Barker via Memba", "messages@mail.memba.io"}
    assert email.reply_to == {"Bob Barker", "bob@example.com"}
    assert email.to == [{"Alice Adams", "alice@example.com"}]
    assert email.subject == "Trip planning night"
    assert email.text_body == "Hello exactly as written.\nDo not add guidance here."
    refute email.text_body =~ "Reply to this email"
  end

  test "renders a reply notification from the club with conversation context" do
    Application.put_env(:memba, Postmark, from: "messages@mail.memba.io")

    conversation_id = Memba.ID.generate(:message)

    request =
      email_delivery_request(
        club_name: "Kootenay <Mountaineers>",
        club_slug: "kmc",
        conversation_id: conversation_id,
        reply_to_message_id: conversation_id,
        conversation_url: "https://kmc.memba.test/messages/#{conversation_id}",
        reply_to_sender_name: "Alice Sender",
        reply_to_body: "Bring route ideas.",
        sender_name: "Bob Barker",
        body: "I can bring maps."
      )

    assert :ok = Postmark.deliver(request)

    assert_received {:email, %Swoosh.Email{} = email}

    assert email.from == {"Kootenay <Mountaineers> via Memba", "messages@mail.memba.io"}
    assert email.reply_to == {"Bob Barker", "bob@example.com"}
    assert email.to == [{"Alice Adams", "alice@example.com"}]
    assert email.subject == "[kmc] Re: Trip planning night"

    assert email.text_body =~
             "Bob Barker replied in the Trip planning night conversation"

    assert email.text_body =~ "I can bring maps."
    assert email.text_body =~ "View the conversation:"
    assert email.text_body =~ request.conversation_url
    assert email.text_body =~ "In reply to Alice Sender:"
    assert email.text_body =~ "Bring route ideas."

    assert email.html_body =~ "<!doctype html>"
    assert email.html_body =~ "New reply"
    assert email.html_body =~ "In the conversation"
    assert email.html_body =~ "Trip planning night"
    assert email.html_body =~ "Bob Barker replied"
    assert email.html_body =~ "I can bring maps."
    assert email.html_body =~ "View the conversation"
    assert email.html_body =~ request.conversation_url
    assert email.html_body =~ "In reply to Alice Sender:"
    assert email.html_body =~ "Bring route ideas."
    assert email.html_body =~ "Delivered for Kootenay &lt;Mountaineers&gt; by"
    assert email.html_body =~ "active member of Kootenay &lt;Mountaineers&gt;"

    refute email.html_body =~ "You're following"
    refute email.html_body =~ "Stop following"
  end

  test "uses the verified Memba sender address even when no provider reply-to is configured" do
    Application.put_env(:memba, Postmark, from: "messages@mail.memba.io")

    assert :ok = Postmark.deliver(email_delivery_request())

    assert_received {:email,
                     %Swoosh.Email{
                       from: {"Bob Barker via Memba", "messages@mail.memba.io"},
                       reply_to: {"Bob Barker", "bob@example.com"}
                     }}
  end

  test "does not hand an email to Swoosh when required Postmark configuration is missing" do
    Application.put_env(:memba, Memba.Mailer, adapter: Swoosh.Adapters.Test)
    Application.put_env(:memba, Postmark, from: "messages@mail.memba.io")

    assert {:error, {:postmark_configuration_error, message}} =
             Postmark.deliver(email_delivery_request())

    assert message =~ "Postmark email delivery provider is enabled"
    assert message =~ "MEMBA_POSTMARK_SERVER_TOKEN"

    assert_no_email_sent()
  end

  test "does not hand unsupported delivery channels to Swoosh" do
    Application.put_env(:memba, Postmark, from: "messages@mail.memba.io")

    assert {:error, {:unsupported_delivery_channel, :sms}} =
             Postmark.deliver(email_delivery_request(channel: :sms))

    assert_no_email_sent()
  end

  test "returns a visible Postmark delivery error when Swoosh reports an API failure" do
    Application.put_env(:memba, Memba.Mailer,
      adapter: Memba.TestSupport.FailingSwooshAdapter,
      api_key: "server-token",
      test_owner: self(),
      test_delivery_result: {:error, {401, %{"Message" => "Invalid server token"}}}
    )

    Application.put_env(:memba, Postmark, from: "messages@mail.memba.io")

    assert {:error, {:postmark_delivery_error, {401, %{"Message" => "Invalid server token"}}}} =
             Postmark.deliver(email_delivery_request())

    assert_received {:failing_swoosh_adapter_deliver, %Swoosh.Email{}}
  end

  test "returns a visible Postmark delivery exception when Swoosh configuration raises" do
    Application.put_env(:memba, Memba.Mailer,
      adapter: Memba.TestSupport.FailingSwooshAdapter,
      api_key: "server-token",
      test_validate_config_error: "missing Postmark API client",
      test_delivery_result: {:ok, %{id: "not-sent"}}
    )

    Application.put_env(:memba, Postmark, from: "messages@mail.memba.io")

    assert {:error, {:postmark_delivery_exception, ArgumentError, "missing Postmark API client"}} =
             Postmark.deliver(email_delivery_request())

    refute_received {:failing_swoosh_adapter_deliver, %Swoosh.Email{}}
  end

  defp email_delivery_request(overrides \\ []) do
    %EmailDeliveryRequest{
      message_id: Keyword.get_lazy(overrides, :message_id, fn -> Memba.ID.generate(:message) end),
      club_id: Keyword.get_lazy(overrides, :club_id, fn -> Memba.ID.generate(:club) end),
      delivery_id:
        Keyword.get_lazy(overrides, :delivery_id, fn -> Memba.ID.generate(:delivery) end),
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
      conversation_url: Keyword.get(overrides, :conversation_url),
      reply_to_sender_name: Keyword.get(overrides, :reply_to_sender_name),
      reply_to_body: Keyword.get(overrides, :reply_to_body),
      channel: Keyword.get(overrides, :channel, :email),
      subject: Keyword.get(overrides, :subject, "Trip planning night"),
      body: Keyword.get(overrides, :body, "Bring route ideas.")
    }
  end

  defp restore_env(key, nil), do: Application.delete_env(:memba, key)
  defp restore_env(key, value), do: Application.put_env(:memba, key, value)
end
