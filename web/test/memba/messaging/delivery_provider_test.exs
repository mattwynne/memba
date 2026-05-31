defmodule Memba.Messaging.DeliveryProviderTest do
  use ExUnit.Case, async: false

  alias Memba.Messaging.DeliveryProvider
  alias Memba.Messaging.DeliveryProviders.Fake
  alias Memba.Messaging.DeliveryProviders.Postmark
  alias Memba.Messaging.DeliveryRequest

  setup do
    original_provider = Application.get_env(:memba, :messaging_delivery_provider)

    Fake.reset()

    on_exit(fn ->
      if is_nil(original_provider) do
        Application.delete_env(:memba, :messaging_delivery_provider)
      else
        Application.put_env(:memba, :messaging_delivery_provider, original_provider)
      end

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

    assert {:error, :postmark_delivery_not_configured} = DeliveryProvider.deliver(request)
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
end
