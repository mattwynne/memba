defmodule Memba.Cucumber.MessagingSteps do
  use Cucumber.StepDefinition

  import ExUnit.Assertions

  alias Memba.Membership
  alias Memba.Messaging
  alias Memba.Messaging.App
  alias Memba.Messaging.Commands.ReportEmailDeliveryBounced
  alias Memba.Messaging.Commands.ReportEmailDeliveryDelayed
  alias Memba.Messaging.Commands.ReportEmailDeliveryDelivered
  alias Memba.Messaging.Commands.ReportEmailDeliveryOpened
  alias Memba.Messaging.Commands.ReportEmailDeliverySpamComplaint
  alias Memba.Messaging.EmailDeliveryProviders.Fake
  alias Memba.Messaging.EmailDeliveryProviders.Unavailable
  alias Memba.Messaging.EmailDeliveryRequest
  alias Memba.Messaging.Projections.EmailDelivery

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

  step "club message sending is unavailable", context do
    original_provider = Application.get_env(:memba, :messaging_email_delivery_provider)
    Application.put_env(:memba, :messaging_email_delivery_provider, Unavailable)

    Map.put(context, :messaging_email_delivery_provider_before_unavailable, original_provider)
  end

  step "{word} tries to send the message {string} to Kootenay Mountaineering Club members",
       %{args: [sender_name, subject]} = context do
    try_send_message_to_kootenay_members(context, sender_name, subject)
  end

  step "{word} should be told the message was not sent", %{args: [_viewer_name]} = context do
    assert {:error, :unavailable} = Map.fetch!(context, :failed_send_result)

    context
  end

  step "{word} should be told to contact support", %{args: [_viewer_name]} = context do
    assert {:error, :unavailable} = Map.fetch!(context, :failed_send_result)

    context
  end

  step "{word} email for {string} is reported as delivered",
       %{args: [recipient_name, subject]} = context do
    report_email_delivery_status(context, recipient_name, subject, :delivered)
  end

  step "{word} email for {string} has been reported as delivered",
       %{args: [recipient_name, subject]} = context do
    report_email_delivery_status(context, recipient_name, subject, :delivered)
  end

  step "{word} has opened the email for {string}", %{args: [recipient_name, subject]} = context do
    report_email_delivery_status(context, recipient_name, subject, :opened)
  end

  step "{word} email for {string} is reported as delayed because {string}",
       %{args: [recipient_name, subject, reason]} = context do
    report_email_delivery_status(context, recipient_name, subject, :delayed, reason)
  end

  step "{word} email for {string} has been reported as delayed because {string}",
       %{args: [recipient_name, subject, reason]} = context do
    report_email_delivery_status(context, recipient_name, subject, :delayed, reason)
  end

  step "{word} email for {string} is reported as bounced because {string}",
       %{args: [recipient_name, subject, reason]} = context do
    report_email_delivery_status(context, recipient_name, subject, :bounced, reason)
  end

  step "{word} email for {string} has been reported as bounced because {string}",
       %{args: [recipient_name, subject, reason]} = context do
    report_email_delivery_status(context, recipient_name, subject, :bounced, reason)
  end

  step "{word} email for {string} is reported as a spam complaint because {string}",
       %{args: [recipient_name, subject, reason]} = context do
    report_email_delivery_status(context, recipient_name, subject, :spam_complaint, reason)
  end

  step "{word} opens the email for {string}", %{args: [recipient_name, subject]} = context do
    report_email_delivery_status(context, recipient_name, subject, :opened)
  end

  step "{word} status for {string} should be {string}",
       %{args: [recipient_name, subject, expected_status]} = context do
    receipt = member_email_delivery_for!(context, recipient_name, subject)

    assert receipt.status == expected_status

    context
  end

  step "{word} should see the message {string} in Kootenay Mountaineering Club",
       %{args: [viewer_name, subject]} = context do
    assert_active_member!(context, viewer_name, "Kootenay Mountaineering Club")
    message = fetch_from_context!(context, :messages, subject)
    club_id = fetch_from_context!(context, :clubs, "Kootenay Mountaineering Club")

    assert message.club_id == club_id

    context
  end

  step "{word} should see the message was addressed to Alice, Bob, Carol, and Dana",
       %{args: [viewer_name]} = context do
    assert_active_member!(context, viewer_name, "Kootenay Mountaineering Club")
    assert_last_message_addressed_to(context, ["Alice", "Bob", "Carol", "Dana"])
  end

  step "{word} should not see {word} in the addressed members",
       %{args: [viewer_name, person_name]} = context do
    assert_active_member!(context, viewer_name, "Kootenay Mountaineering Club")

    person_id = fetch_from_context!(context, :people, person_name)
    deliveries = deliveries_for_last_message!(context)

    refute person_name in Enum.map(deliveries, & &1.recipient_name)
    refute person_id in Enum.map(deliveries, & &1.recipient_id)

    context
  end

  step "{word} should see every addressed member's status as {string}",
       %{args: [viewer_name, expected_status_label]} = context do
    assert_active_member!(context, viewer_name, "Kootenay Mountaineering Club")
    expected_status = member_email_delivery_status_for_label(expected_status_label)

    context
    |> Map.fetch!(:addressed_member_names)
    |> Enum.each(fn recipient_name ->
      receipt = member_email_delivery_for!(context, recipient_name, context.sent_message.subject)
      assert receipt.status == expected_status
    end)

    context
  end

  step "{word} views the message {string}", %{args: [viewer_name, subject]} = context do
    assert_active_member!(context, viewer_name, "Kootenay Mountaineering Club")
    message = fetch_from_context!(context, :messages, subject)
    club_id = fetch_from_context!(context, :clubs, "Kootenay Mountaineering Club")

    assert message.club_id == club_id

    Map.put(context, :viewed_message_subject, subject)
  end

  step "{word} should see {word} status for {string} as {string}",
       %{args: [viewer_name, recipient_name, subject, expected_status_label]} = context do
    assert_active_member!(context, viewer_name, "Kootenay Mountaineering Club")

    receipt = member_email_delivery_for!(context, recipient_name, subject)
    assert receipt.status == member_email_delivery_status_for_label(expected_status_label)

    context
  end

  step "{word} Memba staff email delivery status should be {string}",
       %{args: [recipient_name, expected_status]} = context do
    deliverability = memba_staff_email_delivery_for!(context, recipient_name)

    assert deliverability.status == expected_status

    context
  end

  step "{word} Memba staff email delivery reason should be {string}",
       %{args: [recipient_name, expected_reason]} = context do
    deliverability = memba_staff_email_delivery_for!(context, recipient_name)

    assert deliverability.reason == expected_reason

    context
  end

  step "Memba staff should see {word} delivery for {string} as {string}",
       %{args: [recipient_name, subject, expected_status]} = context do
    deliverability = memba_staff_email_delivery_for!(context, recipient_name, subject)

    assert deliverability.status == expected_status

    Map.put(context, :current_memba_staff_email_delivery, deliverability)
  end

  step "Memba staff should see {word} delivery reason {string}",
       %{args: [recipient_name, expected_reason]} = context do
    deliverability =
      Map.get_lazy(context, :current_memba_staff_email_delivery, fn ->
        memba_staff_email_delivery_for!(context, recipient_name)
      end)

    assert deliverability.reason == expected_reason

    context
  end

  step "the message should be addressed to Alice, Bob, and Carol", context do
    assert_last_message_addressed_to(context, ["Alice", "Bob", "Carol"])
  end

  step "the message should not be addressed to {word}", %{args: [person_name]} = context do
    excluded_person_id = fetch_from_context!(context, :people, person_name)
    deliveries = deliveries_for_last_message!(context)

    refute person_name in Enum.map(deliveries, & &1.recipient_name)
    refute excluded_person_id in Enum.map(deliveries, & &1.recipient_id)

    context
  end

  step "each addressed member should have a separate email delivery", context do
    deliveries = deliveries_for_last_message!(context)
    addressed_member_ids = Map.fetch!(context, :addressed_member_ids)

    assert length(deliveries) == length(addressed_member_ids)
    assert Enum.map(deliveries, & &1.recipient_id) == addressed_member_ids
    assert_unique(Enum.map(deliveries, & &1.delivery_id))
    assert_unique(Enum.map(deliveries, & &1.recipient_id))

    assert Enum.all?(deliveries, fn %EmailDelivery{} = delivery ->
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
    |> Enum.each(fn {%EmailDelivery{} = delivery, %EmailDeliveryRequest{} = request} ->
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

  defp try_send_message_to_kootenay_members(context, sender_name, subject) do
    message_id = Ecto.UUID.generate()
    club_id = fetch_from_context!(context, :clubs, "Kootenay Mountaineering Club")
    sender_id = fetch_from_context!(context, :people, sender_name)
    body = "#{subject} details."

    result =
      try do
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
      after
        context
        |> Map.get(:messaging_email_delivery_provider_before_unavailable, :missing)
        |> restore_messaging_email_delivery_provider()
      end

    context
    |> Map.put(:failed_send_result, result)
    |> Map.put(:failed_send_message, %{
      message_id: message_id,
      club_id: club_id,
      sender_id: sender_id,
      subject: subject,
      body: body
    })
  end

  defp report_email_delivery_status(context, recipient_name, subject, status, reason \\ nil) do
    recipient_name = normalize_person_name(recipient_name)
    message = fetch_from_context!(context, :messages, subject)
    delivery = delivery_for!(context, recipient_name, subject)

    if status == :opened && delivery.status == "sent" do
      assert :ok =
               App.dispatch(
                 %ReportEmailDeliveryDelivered{
                   message_id: message.message_id,
                   delivery_id: delivery.delivery_id
                 },
                 consistency: :strong
               )
    end

    command =
      case status do
        :delivered ->
          %ReportEmailDeliveryDelivered{
            message_id: message.message_id,
            delivery_id: delivery.delivery_id
          }

        :delayed ->
          %ReportEmailDeliveryDelayed{
            message_id: message.message_id,
            delivery_id: delivery.delivery_id,
            reason: reason
          }

        :bounced ->
          %ReportEmailDeliveryBounced{
            message_id: message.message_id,
            delivery_id: delivery.delivery_id,
            reason: reason
          }

        :spam_complaint ->
          %ReportEmailDeliverySpamComplaint{
            message_id: message.message_id,
            delivery_id: delivery.delivery_id,
            reason: reason
          }

        :opened ->
          %ReportEmailDeliveryOpened{
            message_id: message.message_id,
            delivery_id: delivery.delivery_id
          }
      end

    assert :ok = App.dispatch(command, consistency: :strong)

    context
  end

  defp assert_last_message_addressed_to(context, expected_names) do
    deliveries = deliveries_for_last_message!(context)

    assert Enum.map(deliveries, & &1.recipient_name) == expected_names

    expected_recipient_ids =
      Enum.map(expected_names, &fetch_from_context!(context, :people, &1))

    assert Enum.map(deliveries, & &1.recipient_id) == expected_recipient_ids

    context
    |> Map.put(:addressed_member_names, expected_names)
    |> Map.put(:addressed_member_ids, expected_recipient_ids)
  end

  defp member_email_delivery_for!(context, recipient_name, subject) do
    recipient_name = normalize_person_name(recipient_name)
    message = fetch_from_context!(context, :messages, subject)
    recipient_id = fetch_from_context!(context, :people, recipient_name)

    Messaging.get_member_email_delivery(message.message_id, recipient_id) ||
      flunk("Expected a member email delivery for #{recipient_name} and #{inspect(subject)}")
  end

  defp memba_staff_email_delivery_for!(context, recipient_name) do
    memba_staff_email_delivery_for!(context, recipient_name, context.sent_message.subject)
  end

  defp memba_staff_email_delivery_for!(context, recipient_name, subject) do
    recipient_name = normalize_person_name(recipient_name)
    message = fetch_from_context!(context, :messages, subject)
    recipient_id = fetch_from_context!(context, :people, recipient_name)

    Messaging.get_memba_staff_email_delivery(message.message_id, recipient_id) ||
      flunk("Expected Memba staff email delivery for #{recipient_name} and #{inspect(subject)}")
  end

  defp delivery_for!(context, recipient_name, subject) do
    message = fetch_from_context!(context, :messages, subject)
    recipient_id = fetch_from_context!(context, :people, recipient_name)

    message.message_id
    |> Messaging.list_recipient_deliveries()
    |> Enum.find(&(&1.recipient_id == recipient_id))
    |> case do
      %EmailDelivery{} = delivery ->
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

  defp assert_active_member!(context, person_name, club_name) do
    club_id = fetch_from_context!(context, :clubs, club_name)
    person_id = fetch_from_context!(context, :people, normalize_person_name(person_name))

    assert Membership.active_member_of_club?(club_id, person_id)
  end

  defp member_email_delivery_status_for_label("Sending"), do: "sent"
  defp member_email_delivery_status_for_label("Delivered"), do: "delivered"
  defp member_email_delivery_status_for_label("Delivery problem"), do: "delivery problem"
  defp member_email_delivery_status_for_label("Opened"), do: "opened"
  defp member_email_delivery_status_for_label(status), do: status

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

  defp restore_messaging_email_delivery_provider(:missing), do: :ok

  defp restore_messaging_email_delivery_provider(nil),
    do: Application.delete_env(:memba, :messaging_email_delivery_provider)

  defp restore_messaging_email_delivery_provider(provider),
    do: Application.put_env(:memba, :messaging_email_delivery_provider, provider)
end
