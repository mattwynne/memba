defmodule Memba.Messaging.EmailDeliveryProviders.FakeTest do
  use ExUnit.Case, async: false

  alias Memba.Messaging.EmailDeliveryProvider
  alias Memba.Messaging.EmailDeliveryProviders.Fake
  alias Memba.Messaging.EmailDeliveryRequest

  setup do
    Fake.reset()
    :ok
  end

  test "records provider delivery requests in call order" do
    first_request = email_delivery_request("Alice")
    second_request = email_delivery_request("Bob")

    assert :ok = EmailDeliveryProvider.deliver(first_request)
    assert :ok = EmailDeliveryProvider.deliver(second_request)

    assert Fake.deliveries() == [first_request, second_request]
  end

  defp email_delivery_request(name) do
    %EmailDeliveryRequest{
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
