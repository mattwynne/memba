defmodule Memba.Messaging.EmailDeliveryProviderTest do
  use ExUnit.Case, async: false

  alias Memba.Messaging.EmailDeliveryProvider
  alias Memba.Messaging.EmailDeliveryProviders.Fake
  alias Memba.Messaging.EmailDeliveryProviders.Postmark
  alias Memba.Messaging.EmailDeliveryRequest

  setup do
    original_provider = Application.get_env(:memba, :messaging_email_delivery_provider)
    original_mailer_config = Application.get_env(:memba, Memba.Mailer)
    original_postmark_config = Application.get_env(:memba, Postmark)

    Fake.reset()

    on_exit(fn ->
      if is_nil(original_provider) do
        Application.delete_env(:memba, :messaging_email_delivery_provider)
      else
        Application.put_env(:memba, :messaging_email_delivery_provider, original_provider)
      end

      restore_env(Memba.Mailer, original_mailer_config)
      restore_env(Postmark, original_postmark_config)
      Fake.reset()
    end)

    :ok
  end

  test "defaults to the fake provider for deterministic tests and local development" do
    Application.delete_env(:memba, :messaging_email_delivery_provider)

    request = email_delivery_request()

    assert :ok = EmailDeliveryProvider.deliver(request)
    assert Fake.deliveries() == [request]
  end

  test "uses the explicitly configured Postmark provider instead of silently using fake" do
    Application.put_env(:memba, :messaging_email_delivery_provider, Postmark)

    request = email_delivery_request()

    assert {:error, {:postmark_configuration_error, message}} =
             EmailDeliveryProvider.deliver(request)

    assert message =~ "Postmark email delivery provider is enabled"
    assert message =~ "MEMBA_POSTMARK_SERVER_TOKEN"
    assert message =~ "MEMBA_POSTMARK_FROM_ADDRESS"
    assert Fake.deliveries() == []
  end

  test "validates required Postmark config before later email delivery work" do
    Application.put_env(:memba, :messaging_email_delivery_provider, Postmark)

    Application.put_env(:memba, Memba.Mailer,
      adapter: Swoosh.Adapters.Test,
      api_key: "server-token"
    )

    Application.put_env(:memba, Postmark, from: "messages@mail.memba.io")

    assert :ok = EmailDeliveryProvider.deliver(email_delivery_request())
    assert_received {:email, %Swoosh.Email{}}

    assert Fake.deliveries() == []
  end

  defp email_delivery_request do
    %EmailDeliveryRequest{
      message_id: Ecto.UUID.generate(),
      club_id: Ecto.UUID.generate(),
      delivery_id: Ecto.UUID.generate(),
      recipient_id: Ecto.UUID.generate(),
      recipient_name: "Alice",
      recipient_address: "alice@example.com",
      channel: :email,
      subject: "Trail day",
      body: "Meet at 9am."
    }
  end

  defp restore_env(key, nil), do: Application.delete_env(:memba, key)
  defp restore_env(key, value), do: Application.put_env(:memba, key, value)
end
