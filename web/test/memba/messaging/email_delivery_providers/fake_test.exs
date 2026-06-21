defmodule Memba.Messaging.EmailDeliveryProviders.FakeTest do
  use ExUnit.Case, async: false

  alias Memba.Messaging.EmailDeliveryProvider
  alias Memba.Messaging.EmailDeliveryProviders.Fake
  alias Memba.Messaging.EmailDeliveryRequest
  alias Memba.Messaging.OutboundMessageID

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
    message_id = Memba.ID.generate(:message)
    delivery_id = Memba.ID.generate(:delivery)

    %EmailDeliveryRequest{
      message_id: message_id,
      club_id: Memba.ID.generate(:club),
      delivery_id: delivery_id,
      outbound_message_id: OutboundMessageID.for_delivery(delivery_id, message_id),
      recipient_id: Memba.ID.generate(:person),
      recipient_name: name,
      recipient_address: String.downcase(name) <> "@example.com",
      sender_name: "Bob",
      sender_address: "bob@example.com",
      channel: :email,
      subject: "Trail day",
      body: "Meet at 9am."
    }
  end
end
