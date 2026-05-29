defmodule Memba.Cucumber.MessagingSteps do
  use Cucumber.StepDefinition

  import ExUnit.Assertions

  alias Memba.Messaging
  alias Memba.Messaging.DeliveryProviders.Fake
  alias Memba.Messaging.DeliveryRequest
  alias Memba.Messaging.Projections.RecipientDelivery

  step "{word} sends the message {string} to Kootenay Mountaineering Club members",
       %{args: [sender_name, subject]} = context do
    Fake.reset()

    message_id = Ecto.UUID.generate()
    club_id = fetch_from_context!(context, :clubs, "Kootenay Mountaineering Club")
    sender_id = fetch_from_context!(context, :people, sender_name)
    body = "#{subject} details."

    assert :ok =
             Messaging.send_club_message(
               %{
                 message_id: message_id,
                 club_id: club_id,
                 sender_id: sender_id,
                 subject: subject,
                 body: body
               },
               consistency: :strong
             )

    assert Messaging.get_message(message_id)

    context
    |> Map.put(:sent_message, %{
      message_id: message_id,
      club_id: club_id,
      sender_id: sender_id,
      subject: subject,
      body: body
    })
    |> Map.put(:last_message_id, message_id)
  end

  step "the message should be addressed to Alice, Bob, and Carol", context do
    expected_names = ["Alice", "Bob", "Carol"]
    deliveries = deliveries_for_last_message!(context)

    assert Enum.map(deliveries, & &1.recipient_name) == expected_names

    expected_recipient_ids =
      Enum.map(expected_names, &fetch_from_context!(context, :people, &1))

    assert Enum.map(deliveries, & &1.recipient_id) == expected_recipient_ids

    context
    |> Map.put(:addressed_member_names, expected_names)
    |> Map.put(:addressed_member_ids, expected_recipient_ids)
  end

  step "the message should not be addressed to {word}", %{args: [person_name]} = context do
    excluded_person_id = fetch_from_context!(context, :people, person_name)
    deliveries = deliveries_for_last_message!(context)

    refute person_name in Enum.map(deliveries, & &1.recipient_name)
    refute excluded_person_id in Enum.map(deliveries, & &1.recipient_id)

    context
  end

  step "each addressed member should have a separate delivery record", context do
    deliveries = deliveries_for_last_message!(context)
    addressed_member_ids = Map.fetch!(context, :addressed_member_ids)

    assert length(deliveries) == length(addressed_member_ids)
    assert Enum.map(deliveries, & &1.recipient_id) == addressed_member_ids
    assert_unique(Enum.map(deliveries, & &1.delivery_id))
    assert_unique(Enum.map(deliveries, & &1.recipient_id))

    assert Enum.all?(deliveries, fn %RecipientDelivery{} = delivery ->
             delivery.channel == "email" and delivery.status == "sent"
           end)

    Map.put(context, :addressed_delivery_ids, Enum.map(deliveries, & &1.delivery_id))
  end

  step "each delivery should be sent through the email provider", context do
    deliveries = deliveries_for_last_message!(context)
    provider_deliveries = Fake.deliveries()
    expected_delivery_ids = Enum.map(deliveries, & &1.delivery_id)

    assert length(provider_deliveries) == length(deliveries)
    assert Enum.map(provider_deliveries, & &1.delivery_id) == expected_delivery_ids
    assert_unique(Enum.map(provider_deliveries, & &1.delivery_id))

    Enum.zip(deliveries, provider_deliveries)
    |> Enum.each(fn {%RecipientDelivery{} = delivery, %DeliveryRequest{} = request} ->
      assert request.message_id == delivery.message_id
      assert request.delivery_id == delivery.delivery_id
      assert request.recipient_id == delivery.recipient_id
      assert request.recipient_name == delivery.recipient_name
      assert request.recipient_address == delivery.recipient_address
      assert request.channel == :email
      assert request.subject == context.sent_message.subject
      assert request.body == context.sent_message.body
    end)

    context
  end

  defp deliveries_for_last_message!(context) do
    context
    |> Map.fetch!(:last_message_id)
    |> Messaging.list_recipient_deliveries()
  end

  defp fetch_from_context!(context, collection_key, item_key) do
    context
    |> Map.get(collection_key, %{})
    |> Map.fetch(item_key)
    |> case do
      {:ok, value} ->
        value

      :error ->
        flunk("Expected #{inspect(item_key)} to be present in #{inspect(collection_key)}")
    end
  end

  defp assert_unique(values) do
    assert Enum.uniq(values) == values
  end
end
