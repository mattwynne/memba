defmodule Memba.Cucumber.MessagingSteps do
  use Cucumber.StepDefinition

  import ExUnit.Assertions

  alias Memba.Membership
  alias Memba.Messaging
  alias Memba.Messaging.App
  alias Memba.Messaging.Commands.ReportEmailDeliveryBounced
  alias Memba.Messaging.Commands.ReportEmailDeliveryDelayed
  alias Memba.Messaging.Commands.ReportEmailDeliveryDelivered
  alias Memba.Messaging.Commands.ReportEmailDeliverySpamComplaint
  alias Memba.Messaging.EmailDeliveryDispatcher
  alias Memba.Messaging.EmailDeliveryProviders.Fake
  alias Memba.Messaging.EmailDeliveryProviders.Unavailable
  alias Memba.Messaging.EmailDeliveryRequest
  alias Memba.Messaging.MemberMessageEmail
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

  step "Alice tries to send a message to Kootenay Mountaineering Club members with subject {string} and no body",
       %{args: [subject]} = context do
    Fake.reset()
    try_send_message_to_kootenay_members(context, "Alice", subject, "")
  end

  step "{word} should be told the message was not sent", %{args: [_viewer_name]} = context do
    assert :ok = Map.fetch!(context, :failed_send_result)

    context
  end

  step "{word} should be told to contact support", %{args: [_viewer_name]} = context do
    assert :ok = Map.fetch!(context, :failed_send_result)

    context
  end

  step "{word} should be told the message body cannot be blank", context do
    assert {:error, :invalid_body} = Map.fetch!(context, :failed_send_result)

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

  step "{word} emails {string} to kmc@clubs.memba.io",
       %{args: [sender_name, subject]} = context do
    receive_inbound_club_email(context, sender_name, subject, "kmc@clubs.memba.io")
  end

  step "{word} emails {string} to kmc@clubs.memba.io from {string}",
       %{args: [sender_name, subject, from_address]} = context do
    receive_inbound_club_email(context, sender_name, subject, "kmc@clubs.memba.io",
      from_address: from_address
    )
  end

  step "{word} emails {string} to kmc@clubs.memba.io with an attachment",
       %{args: [sender_name, subject]} = context do
    receive_inbound_club_email(context, sender_name, subject, "kmc@clubs.memba.io",
      attachments: [
        %{filename: "route.gpx", content_type: "application/gpx+xml", size: 1234}
      ]
    )
  end

  step "{word} emails {string} to kmc@clubs.memba.io with only an HTML body",
       %{args: [sender_name, subject]} = context do
    receive_inbound_club_email(context, sender_name, subject, "kmc@clubs.memba.io",
      text_body: nil,
      html_body: "<p>#{subject} details.</p>"
    )
  end

  step "{word} emails {string} to kmc@clubs.memba.io with the body:",
       %{args: [sender_name, subject]} = context do
    receive_inbound_club_email(context, sender_name, subject, "kmc@clubs.memba.io",
      text_body: Map.fetch!(context, :docstring)
    )
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

    person_id = person_id_from_context!(context, person_name)
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
    excluded_person_id = person_id_from_context!(context, person_name)
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
             delivery.channel == "email" and delivery.status in ["pending", "dispatching", "sent"]
           end)

    Map.put(context, :addressed_delivery_ids, Enum.map(deliveries, & &1.delivery_id))
  end

  step "each delivery should be sent through the email provider", context do
    assert_each_delivery_sent_through_provider(context)
  end

  step "each addressed member should receive an email from Alice via Memba", context do
    assert_each_delivery_sent_through_provider(context, sender_name: "Alice")
  end

  step "each addressed member should receive an email with the subject {string}",
       %{args: [expected_subject]} = context do
    dispatch_pending_email_deliveries()

    provider_deliveries = Fake.deliveries()

    assert length(provider_deliveries) == length(deliveries_for_last_message!(context))

    Enum.each(provider_deliveries, fn %EmailDeliveryRequest{} = request ->
      assert MemberMessageEmail.subject(request) == expected_subject
    end)

    context
  end

  step "no club message named {string} should be created", %{args: [subject]} = context do
    assert_no_club_message(context, "Kootenay Mountaineering Club", subject)
  end

  step "no Kootenay Mountaineering Club message named {string} should be created",
       %{args: [subject]} = context do
    assert_no_club_message(context, "Kootenay Mountaineering Club", subject)
  end

  step "no addressed member should receive an email for {string}", %{args: [subject]} = context do
    refute Enum.any?(Fake.deliveries(), &(&1.subject == subject))

    context
  end

  step "{word} should receive a rejection email explaining the message was not posted",
       %{args: [sender_name]} = context do
    assert_rejection_email(context, sender_name, "wasn't posted")
  end

  step "{word} should receive a rejection email explaining attachments are not supported",
       %{args: [sender_name]} = context do
    assert_rejection_email(context, sender_name, "attachments can't be posted")
  end

  step "{word} should receive a rejection email explaining a plain-text message body is required",
       %{args: [sender_name]} = context do
    assert_rejection_email(context, sender_name, "plain-text message body")
  end

  step "{word} should be told how to contact support", %{args: [sender_name]} = context do
    email = fetch_from_context!(context, :rejection_emails, sender_name)
    assert email.text_body =~ ~r/contact Memba support|reply to this email/i
    context
  end

  step "the message body should be:", context do
    message = fetch_from_context!(context, :messages, Map.fetch!(context, :last_message_subject))
    assert message.body == String.trim(Map.fetch!(context, :docstring))
    context
  end

  defp send_message_to_kootenay_members(context, sender_name, subject) do
    message_id = Memba.ID.generate(:message)
    club_id = fetch_from_context!(context, :clubs, "Kootenay Mountaineering Club")
    sender_id = person_id_from_context!(context, sender_name)
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

  defp try_send_message_to_kootenay_members(context, sender_name, subject, body \\ nil) do
    message_id = Memba.ID.generate(:message)
    club_id = fetch_from_context!(context, :clubs, "Kootenay Mountaineering Club")
    sender_id = person_id_from_context!(context, sender_name)
    body = body || "#{subject} details."

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

  defp receive_inbound_club_email(context, sender_name, subject, to_address, opts \\ []) do
    Fake.reset()

    from_address =
      Keyword.get_lazy(opts, :from_address, fn -> email_address_for(context, sender_name) end)

    text_body = Keyword.get(opts, :text_body, "#{subject} details.")
    html_body = Keyword.get(opts, :html_body)
    attachments = Keyword.get(opts, :attachments, [])

    result =
      Messaging.receive_inbound_club_email(
        %{
          provider: "domain-cucumber",
          provider_message_id: provider_message_id(context, sender_name, subject, from_address),
          from_address: from_address,
          recipient_addresses: [to_address],
          subject: subject,
          text_body: text_body,
          html_body: html_body,
          attachments: attachments
        },
        consistency: :strong
      )

    context =
      context
      |> Map.put(:last_inbound_email_result, result)
      |> Map.put(:last_message_subject, subject)
      |> update_context_map(:inbound_from_addresses, sender_name, from_address)

    case result do
      {:ok, %{status: :rejected, rejection_reason: reason}} ->
        Map.put(context, :last_rejection_reason, reason)

      {:ok, %{message_id: message_id, club_id: club_id, sender_id: sender_id}} ->
        message = Messaging.get_message(message_id)

        context
        |> Map.put(:sent_message, %{
          message_id: message_id,
          club_id: club_id,
          sender_id: sender_id,
          subject: message.subject,
          body: message.body
        })
        |> Map.put(:last_message_id, message_id)
        |> update_context_map(:messages, subject, %{
          message_id: message_id,
          club_id: club_id,
          sender_id: sender_id,
          subject: message.subject,
          body: message.body
        })

      {:error, reason} ->
        flunk("Expected inbound email not to error; got #{inspect(reason)}")
    end
  end

  defp assert_no_club_message(context, club_name, subject) do
    club_id = fetch_from_context!(context, :clubs, club_name)

    refute Enum.any?(Messaging.list_messages_for_club(club_id), &(&1.subject == subject))

    context
  end

  defp assert_rejection_email(context, sender_name, expected_text) do
    assert {:ok, %{status: :rejected}} = Map.fetch!(context, :last_inbound_email_result)

    expected_address =
      context
      |> Map.get(:inbound_from_addresses, %{})
      |> Map.get(sender_name, email_address_for(context, sender_name))

    assert_received {:email, %Swoosh.Email{} = email}

    assert Enum.any?(email.to, fn
             {_name, address} -> address == expected_address
             address when is_binary(address) -> address == expected_address
           end)

    assert email.text_body =~ expected_text

    update_context_map(context, :rejection_emails, sender_name, email)
  end

  defp assert_each_delivery_sent_through_provider(context, opts \\ []) do
    deliveries = deliveries_for_last_message!(context)
    dispatch_pending_email_deliveries()

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

      if sender_name = Keyword.get(opts, :sender_name) do
        assert request.sender_name == sender_name
        assert request.sender_address == primary_email_for(context, sender_name)
      end
    end)

    context
  end

  defp dispatch_pending_email_deliveries do
    _deliveries = EmailDeliveryDispatcher.dispatch_pending_email_deliveries()
    :ok
  end

  defp report_email_delivery_status(context, recipient_name, subject, status, reason \\ nil) do
    recipient_name = normalize_person_name(recipient_name)
    message = fetch_from_context!(context, :messages, subject)
    delivery = delivery_for!(context, recipient_name, subject)

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
      end

    assert :ok = App.dispatch(command, consistency: :strong)

    context
  end

  defp assert_last_message_addressed_to(context, expected_names) do
    deliveries = deliveries_for_last_message!(context)

    assert Enum.map(deliveries, & &1.recipient_name) == expected_names

    expected_recipient_ids =
      Enum.map(expected_names, &person_id_from_context!(context, &1))

    assert Enum.map(deliveries, & &1.recipient_id) == expected_recipient_ids

    context
    |> Map.put(:addressed_member_names, expected_names)
    |> Map.put(:addressed_member_ids, expected_recipient_ids)
  end

  defp member_email_delivery_for!(context, recipient_name, subject) do
    recipient_name = normalize_person_name(recipient_name)
    message = fetch_from_context!(context, :messages, subject)
    recipient_id = person_id_from_context!(context, recipient_name)

    Messaging.get_member_email_delivery(message.message_id, recipient_id) ||
      flunk("Expected a member email delivery for #{recipient_name} and #{inspect(subject)}")
  end

  defp memba_staff_email_delivery_for!(context, recipient_name) do
    memba_staff_email_delivery_for!(context, recipient_name, context.sent_message.subject)
  end

  defp memba_staff_email_delivery_for!(context, recipient_name, subject) do
    recipient_name = normalize_person_name(recipient_name)
    message = fetch_from_context!(context, :messages, subject)
    recipient_id = person_id_from_context!(context, recipient_name)

    Messaging.get_memba_staff_email_delivery(message.message_id, recipient_id) ||
      flunk("Expected Memba staff email delivery for #{recipient_name} and #{inspect(subject)}")
  end

  defp delivery_for!(context, recipient_name, subject) do
    message = fetch_from_context!(context, :messages, subject)
    recipient_id = person_id_from_context!(context, recipient_name)

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
    person_id = person_id_from_context!(context, normalize_person_name(person_name))

    assert Membership.active_member_of_club?(club_id, person_id)
  end

  defp member_email_delivery_status_for_label("Sending"), do: "sent"
  defp member_email_delivery_status_for_label("Delivered"), do: "delivered"
  defp member_email_delivery_status_for_label("Delivery problem"), do: "delivery problem"
  defp member_email_delivery_status_for_label(status), do: status

  defp person_id_from_context!(context, person_name) do
    case fetch_from_context!(context, :people, person_name) do
      %{person_id: person_id} -> person_id
      person_id when is_binary(person_id) -> person_id
    end
  end

  defp primary_email_for(context, person_name) do
    context
    |> person_id_from_context!(person_name)
    |> Membership.get_person_primary_email()
  end

  defp email_address_for(context, person_name) do
    case Map.get(context, :people, %{}) |> Map.get(person_name) do
      %{email: email} -> email
      person_id when is_binary(person_id) -> Membership.get_person_primary_email(person_id)
      nil -> default_email_for(context, person_name)
    end
  end

  defp default_email_for(context, person_name) do
    normalized_name =
      person_name
      |> String.downcase()
      |> String.replace(~r/[^a-z0-9]+/, ".")
      |> String.trim(".")

    "#{normalized_name}-#{scenario_email_suffix(context)}@example.test"
  end

  defp provider_message_id(context, sender_name, subject, from_address) do
    [Map.get(context, :scenario_name), sender_name, subject, from_address]
    |> Enum.join(":")
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end

  defp scenario_email_suffix(context) do
    context
    |> Map.get(:scenario_name, "scenario")
    |> :erlang.phash2(1_000_000)
    |> Integer.to_string(36)
    |> String.downcase()
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

  defp restore_messaging_email_delivery_provider(:missing), do: :ok

  defp restore_messaging_email_delivery_provider(nil),
    do: Application.delete_env(:memba, :messaging_email_delivery_provider)

  defp restore_messaging_email_delivery_provider(provider),
    do: Application.put_env(:memba, :messaging_email_delivery_provider, provider)
end
