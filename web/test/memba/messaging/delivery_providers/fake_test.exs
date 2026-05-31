defmodule Memba.Messaging.DeliveryProviders.FakeTest do
  use ExUnit.Case, async: false

  alias Memba.Messaging.DeliveryProvider
  alias Memba.Messaging.DeliveryProviders.Fake
  alias Memba.Messaging.DeliveryRequest

  setup do
    Fake.reset()
    :ok
  end

  test "records provider delivery requests in call order" do
    first_request = delivery_request("Alice")
    second_request = delivery_request("Bob")

    assert :ok = DeliveryProvider.deliver(first_request)
    assert :ok = DeliveryProvider.deliver(second_request)

    assert Fake.deliveries() == [first_request, second_request]
  end

  defp delivery_request(name) do
    %DeliveryRequest{
      message_id: Ecto.UUID.generate(),
      club_id: Ecto.UUID.generate(),
      delivery_id: Ecto.UUID.generate(),
      recipient_id: Ecto.UUID.generate(),
      recipient_name: name,
      recipient_address: String.downcase(name) <> "@example.com",
      channel: :email,
      subject: "Trail day",
      body: "Meet at 9am."
    }
  end
end
