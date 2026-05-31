defmodule Memba.Messaging.DeliveryProviders.PostmarkTest do
  use ExUnit.Case, async: false

  import Swoosh.TestAssertions

  alias Memba.Messaging.DeliveryProviders.Postmark
  alias Memba.Messaging.DeliveryRequest

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

  test "builds and sends a multipart email with Postmark correlation metadata and open tracking" do
    Application.put_env(:memba, Postmark,
      from: "messages@mail.memba.io",
      reply_to: "help@memba.io"
    )

    request = delivery_request(body: "Hello <Alice> & Bob\nBring route ideas.")

    assert :ok = Postmark.deliver(request)

    assert_received {:email, %Swoosh.Email{} = email}

    assert email.from == {"", "messages@mail.memba.io"}
    assert email.reply_to == {"", "help@memba.io"}
    assert email.to == [{"Alice Adams", "alice@example.com"}]
    assert email.subject == "Trip planning night"
    assert email.text_body == "Hello <Alice> & Bob\nBring route ideas."

    assert email.html_body ==
             "<html><body><p>Hello &lt;Alice&gt; &amp; Bob<br>\nBring route ideas.</p></body></html>"

    refute email.html_body =~ "<Alice>"

    assert email.provider_options == %{
             metadata: %{
               "memba_message_id" => request.message_id,
               "memba_delivery_id" => request.delivery_id,
               "memba_club_id" => request.club_id
             },
             track_opens: true
           }
  end

  test "omits reply-to when no reply-to address is configured" do
    Application.put_env(:memba, Postmark, from: "messages@mail.memba.io")

    assert :ok = Postmark.deliver(delivery_request())

    assert_received {:email, %Swoosh.Email{reply_to: nil}}
  end

  test "does not hand an email to Swoosh when required Postmark configuration is missing" do
    Application.put_env(:memba, Memba.Mailer, adapter: Swoosh.Adapters.Test)
    Application.put_env(:memba, Postmark, from: "messages@mail.memba.io")

    assert {:error, {:postmark_configuration_error, message}} =
             Postmark.deliver(delivery_request())

    assert message =~ "Postmark delivery provider is enabled"
    assert message =~ "MEMBA_POSTMARK_SERVER_TOKEN"

    assert_no_email_sent()
  end

  test "does not hand unsupported delivery channels to Swoosh" do
    Application.put_env(:memba, Postmark, from: "messages@mail.memba.io")

    assert {:error, {:unsupported_delivery_channel, :sms}} =
             Postmark.deliver(delivery_request(channel: :sms))

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
             Postmark.deliver(delivery_request())

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
             Postmark.deliver(delivery_request())

    refute_received {:failing_swoosh_adapter_deliver, %Swoosh.Email{}}
  end

  defp delivery_request(overrides \\ []) do
    %DeliveryRequest{
      message_id: Keyword.get_lazy(overrides, :message_id, &Ecto.UUID.generate/0),
      club_id: Keyword.get_lazy(overrides, :club_id, &Ecto.UUID.generate/0),
      delivery_id: Keyword.get_lazy(overrides, :delivery_id, &Ecto.UUID.generate/0),
      recipient_id: Keyword.get_lazy(overrides, :recipient_id, &Ecto.UUID.generate/0),
      recipient_name: Keyword.get(overrides, :recipient_name, "Alice Adams"),
      recipient_address: Keyword.get(overrides, :recipient_address, "alice@example.com"),
      channel: Keyword.get(overrides, :channel, :email),
      subject: Keyword.get(overrides, :subject, "Trip planning night"),
      body: Keyword.get(overrides, :body, "Bring route ideas.")
    }
  end

  defp restore_env(key, nil), do: Application.delete_env(:memba, key)
  defp restore_env(key, value), do: Application.put_env(:memba, key, value)
end
