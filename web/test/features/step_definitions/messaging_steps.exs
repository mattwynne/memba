defmodule Memba.Cucumber.MessagingSteps do
  use Cucumber.StepDefinition

  import ExUnit.Assertions

  alias Memba.Messaging
  alias Memba.Messaging.App
  alias Memba.Messaging.Commands.ReportDeliveryBounced
  alias Memba.Messaging.Commands.ReportDeliveryDelayed
  alias Memba.Messaging.Commands.ReportDeliveryDelivered
  alias Memba.Messaging.Commands.ReportDeliveryOpened
  alias Memba.Messaging.Commands.ReportDeliverySpamComplaint
  alias Memba.Messaging.DeliveryProviders.Fake
  alias Memba.Messaging.DeliveryRequest
  alias Memba.Messaging.Projections.RecipientDelivery

  step "{word} sends the message {string} to Kootenay Mountaineering Club members",
       %{args: [sender_name, subject]} = context do
    Fake.reset()

    send_message_to_kootenay_members(context, sender_name, subject)
  end

  step "{word} has sent the message {string} to Kootenay Mountaineering Club members",
       %{args: [sender_name, subject]} = context do
    Fake.reset()

    send_message_to_kootenay_members(context, sender_name, subject)
  end

  step "{word} email for {string} is reported as delivered",
       %{args: [recipient_name, subject]} = context do
    report_delivery_status(context, recipient_name, subject, :delivered)
  end

  step "{word} email for {string} has been reported as delivered",
       %{args: [recipient_name, subject]} = context do
    report_delivery_status(context, recipient_name, subject, :delivered)
  end

  step "{word} email for {string} is reported as delayed because {string}",
       %{args: [recipient_name, subject, reason]} = context do
    report_delivery_status(context, recipient_name, subject, :delayed, reason)
  end

  step "{word} email for {string} is reported as bounced because {string}",
       %{args: [recipient_name, subject, reason]} = context do
    report_delivery_status(context, recipient_name, subject, :bounced, reason)
  end

  step "{word} email for {string} is reported as a spam complaint because {string}",
       %{args: [recipient_name, subject, reason]} = context do
    report_delivery_status(context, recipient_name, subject, :spam_complaint, reason)
  end

  step "{word} opens the email for {string}", %{args: [recipient_name, subject]} = context do
    report_delivery_status(context, recipient_name, subject, :opened)
  end

  step "{word} receipt status for {string} should be {string}",
       %{args: [recipient_name, subject, expected_status]} = context do
    receipt = member_receipt_for!(context, recipient_name, subject)

    assert receipt.receipt_status == expected_status

    context
  end

  step "{word} operator deliverability status should be {string}",
       %{args: [recipient_name, expected_status]} = context do
    deliverability = operator_deliverability_for!(context, recipient_name)

    assert deliverability.status == expected_status

    context
  end

  step "{word} operator deliverability reason should be {string}",
       %{args: [recipient_name, expected_reason]} = context do
    deliverability = operator_deliverability_for!(context, recipient_name)

    assert deliverability.reason == expected_reason

    context
  end

  step "operators should see {word} delivery for {string} as {string}",
       %{args: [recipient_name, subject, expected_status]} = context do
    deliverability = operator_deliverability_for!(context, recipient_name, subject)

    assert deliverability.status == expected_status

    Map.put(context, :current_operator_deliverability, deliverability)
  end

  step "operators should see {word} delivery reason {string}",
       %{args: [recipient_name, expected_reason]} = context do
    deliverability =
      Map.get_lazy(context, :current_operator_deliverability, fn ->
        operator_deliverability_for!(context, recipient_name)
      end)

    assert deliverability.reason == expected_reason

    context
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
      assert request.club_id == context.sent_message.club_id
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

  defp send_message_to_kootenay_members(context, sender_name, subject) do
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
    |> update_context_map(:messages, subject, %{
      message_id: message_id,
      club_id: club_id,
      sender_id: sender_id,
      subject: subject,
      body: body
    })
  end

  defp report_delivery_status(context, recipient_name, subject, status, reason \\ nil) do
    recipient_name = normalize_person_name(recipient_name)
    message = fetch_from_context!(context, :messages, subject)
    delivery = delivery_for!(context, recipient_name, subject)

    command =
      case status do
        :delivered ->
          %ReportDeliveryDelivered{
            message_id: message.message_id,
            delivery_id: delivery.delivery_id
          }

        :delayed ->
          %ReportDeliveryDelayed{
            message_id: message.message_id,
            delivery_id: delivery.delivery_id,
            reason: reason
          }

        :bounced ->
          %ReportDeliveryBounced{
            message_id: message.message_id,
            delivery_id: delivery.delivery_id,
            reason: reason
          }

        :spam_complaint ->
          %ReportDeliverySpamComplaint{
            message_id: message.message_id,
            delivery_id: delivery.delivery_id,
            reason: reason
          }

        :opened ->
          %ReportDeliveryOpened{
            message_id: message.message_id,
            delivery_id: delivery.delivery_id
          }
      end

    assert :ok = App.dispatch(command, consistency: :strong)

    context
  end

  defp member_receipt_for!(context, recipient_name, subject) do
    recipient_name = normalize_person_name(recipient_name)
    message = fetch_from_context!(context, :messages, subject)
    recipient_id = fetch_from_context!(context, :people, recipient_name)

    Messaging.get_member_receipt(message.message_id, recipient_id) ||
      flunk("Expected a member receipt for #{recipient_name} and #{inspect(subject)}")
  end

  defp operator_deliverability_for!(context, recipient_name) do
    operator_deliverability_for!(context, recipient_name, context.sent_message.subject)
  end

  defp operator_deliverability_for!(context, recipient_name, subject) do
    recipient_name = normalize_person_name(recipient_name)
    message = fetch_from_context!(context, :messages, subject)
    recipient_id = fetch_from_context!(context, :people, recipient_name)

    Messaging.get_operator_deliverability(message.message_id, recipient_id) ||
      flunk("Expected operator deliverability for #{recipient_name} and #{inspect(subject)}")
  end

  defp delivery_for!(context, recipient_name, subject) do
    message = fetch_from_context!(context, :messages, subject)
    recipient_id = fetch_from_context!(context, :people, recipient_name)

    message.message_id
    |> Messaging.list_recipient_deliveries()
    |> Enum.find(&(&1.recipient_id == recipient_id))
    |> case do
      %RecipientDelivery{} = delivery ->
        delivery

      nil ->
        flunk("Expected a delivery for #{recipient_name} and #{inspect(subject)}")
    end
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

  defp update_context_map(context, collection_key, item_key, value) do
    collection =
      context
      |> Map.get(collection_key, %{})
      |> Map.put(item_key, value)

    Map.put(context, collection_key, collection)
  end

  defp normalize_person_name(name) do
    String.replace_suffix(name, "'s", "")
  end

  defp assert_unique(values) do
    assert Enum.uniq(values) == values
  end
end
