defmodule Memba.Messaging.DeliveryProviderTest do
  use ExUnit.Case, async: false

  alias Memba.Messaging.DeliveryProvider
  alias Memba.Messaging.DeliveryProviders.Fake
  alias Memba.Messaging.DeliveryProviders.Postmark
  alias Memba.Messaging.DeliveryRequest

  setup do
    original_provider = Application.get_env(:memba, :messaging_delivery_provider)
    original_mailer_config = Application.get_env(:memba, Memba.Mailer)
    original_postmark_config = Application.get_env(:memba, Postmark)

    Fake.reset()

    on_exit(fn ->
      if is_nil(original_provider) do
        Application.delete_env(:memba, :messaging_delivery_provider)
      else
        Application.put_env(:memba, :messaging_delivery_provider, original_provider)
      end

      restore_env(Memba.Mailer, original_mailer_config)
      restore_env(Postmark, original_postmark_config)
      Fake.reset()
    end)

    :ok
  end

  test "defaults to the fake provider for deterministic tests and local development" do
    Application.delete_env(:memba, :messaging_delivery_provider)

    request = delivery_request()

    assert :ok = DeliveryProvider.deliver(request)
    assert Fake.deliveries() == [request]
  end

  test "uses the explicitly configured Postmark provider instead of silently using fake" do
    Application.put_env(:memba, :messaging_delivery_provider, Postmark)

    request = delivery_request()

    assert {:error, {:postmark_configuration_error, message}} = DeliveryProvider.deliver(request)
    assert message =~ "Postmark delivery provider is enabled"
    assert message =~ "MEMBA_POSTMARK_SERVER_TOKEN"
    assert message =~ "MEMBA_POSTMARK_FROM_ADDRESS"
    assert Fake.deliveries() == []
  end

  test "validates required Postmark config before later email delivery work" do
    Application.put_env(:memba, :messaging_delivery_provider, Postmark)

    Application.put_env(:memba, Memba.Mailer,
      adapter: Swoosh.Adapters.Postmark,
      api_key: "server-token"
    )

    Application.put_env(:memba, Postmark, from: "messages@mail.memba.io")

    assert {:error, :postmark_delivery_not_implemented} =
             DeliveryProvider.deliver(delivery_request())

    assert Fake.deliveries() == []
  end

  defp delivery_request do
    %DeliveryRequest{
      message_id: Ecto.UUID.generate(),
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
