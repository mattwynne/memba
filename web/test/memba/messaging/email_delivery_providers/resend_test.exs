defmodule Memba.Messaging.EmailDeliveryProviders.ResendTest do
  use ExUnit.Case, async: false

  import Swoosh.TestAssertions

  alias Memba.Messaging.EmailDeliveryProviders.Resend
  alias Memba.Messaging.EmailDeliveryRequest

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

    request = email_delivery_request(body: "Hello <Alice> & Bob\nBring route ideas.")

    assert :ok = Resend.deliver(request)

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

  test "omits reply-to when no reply-to address is configured" do
    Application.put_env(:memba, Resend, from: "messages@mail.memba.io")

    assert :ok = Resend.deliver(email_delivery_request())

    assert_received {:email, %Swoosh.Email{reply_to: nil}}
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
    %EmailDeliveryRequest{
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
