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
  alias Memba.Messaging.ConversationStopFollowToken

  @kmc_everyone_address "everyone@kmc.clubs.memba.io"

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

  step "{word} sent the message {string} to Kootenay Mountaineering Club members",
       %{args: [sender_name, subject]} = context do
    Fake.reset()

    context
    |> send_message_to_club_members(sender_name, subject, "Kootenay Mountaineering Club")
    |> dispatch_and_clear_background_message_deliveries()
  end

  step "{word} sent the message {string} to Nelson Paddling Club members",
       %{args: [sender_name, subject]} = context do
    Fake.reset()

    context
    |> send_message_to_club_members(sender_name, subject, "Nelson Paddling Club")
    |> dispatch_and_clear_background_message_deliveries()
  end

  step "{word} replies {string} to {string}", %{args: [sender_name, body, subject]} = context do
    post_reply_to_message(context, sender_name, subject, body)
  end

  step "{word} replies by email to {string} with:",
       %{args: [sender_name, subject]} = context do
    receive_inbound_reply_email(context, sender_name, subject, Map.fetch!(context, :docstring))
  end

  step ~r/^(\w+) replies by email to "([^"]+)" through ([^\s]+)$/,
       %{args: [sender_name, subject, to_address]} = context do
    receive_inbound_reply_email(context, sender_name, subject, "#{subject} details.",
      to_address: to_address
    )
  end

  step ~r/^(\w+) emails "([^"]+)" to ([^\s]+) with reply headers from "([^"]+)"$/,
       %{args: [sender_name, subject, to_address, referenced_subject]} = context do
    referenced_outbound_message_id =
      outbound_message_id_for_subject!(context, referenced_subject, sender_name)

    receive_inbound_club_email(context, sender_name, subject, to_address,
      in_reply_to_message_ids: [referenced_outbound_message_id]
    )
  end

  step "{word} follows the conversation for {string}",
       %{args: [member_name, subject]} = context do
    follow_conversation(context, member_name, subject)
  end

  step "{word} stops following the conversation for {string}",
       %{args: [member_name, subject]} = context do
    unfollow_conversation(context, member_name, subject)
  end

  step "{word} is no longer a member of Kootenay Mountaineering Club",
       %{args: [member_name]} = context do
    remove_member_from_club(context, member_name, "Kootenay Mountaineering Club")
  end

  step ~r/^the conversation for "([^"]+)" should show (\w+)'s reply "([^"]+)"$/,
       %{args: [subject, sender_name, body]} = context do
    assert_conversation_shows_reply(context, subject, sender_name, body)
  end

  step ~r/^the conversation for "([^"]+)" should show (\w+)'s reply$/,
       %{args: [subject, sender_name]} = context do
    %{body: body} = latest_reply_for!(context, subject, sender_name)
    assert_conversation_shows_reply(context, subject, sender_name, body)
  end

  step ~r/^(\w+) should see (\w+)'s reply in the conversation for "([^"]+)"$/,
       %{args: [viewer_name, sender_name, subject]} = context do
    assert_active_member!(context, viewer_name, "Kootenay Mountaineering Club")

    %{body: body} = latest_reply_for!(context, subject, sender_name)
    assert_conversation_shows_reply(context, subject, sender_name, body)
  end

  step "the conversation for {string} should show {string} before {string}",
       %{args: [subject, earlier_body, later_body]} = context do
    assert_conversation_order(context, subject, earlier_body, later_body)
  end

  step ~r/^the conversation for "([^"]+)" should not show (\w+)'s reply "([^"]+)"$/,
       %{args: [subject, sender_name, body]} = context do
    assert_conversation_does_not_show_reply(context, subject, sender_name, body)
  end

  step ~r/^(.+) should(?: each)? receive (\w+)'s reply by email from (.+) via Memba$/,
       %{args: [recipient_names_text, sender_name, club_name]} = context do
    assert_reply_email_delivered_to_members(
      context,
      "Trip planning night",
      sender_name,
      parse_person_list(recipient_names_text),
      club_name
    )
  end

  step ~r/^(.+) should not receive (\w+)'s reply by email$/,
       %{args: [recipient_names_text, sender_name]} = context do
    assert_reply_email_not_delivered_to_members(
      context,
      "Trip planning night",
      sender_name,
      parse_person_list(recipient_names_text)
    )
  end

  step "{word} should not receive his own reply by email", %{args: [sender_name]} = context do
    assert_reply_email_not_delivered_to_author(context, sender_name)
  end

  step "{word} should be following the conversation for {string}",
       %{args: [member_name, subject]} = context do
    assert_conversation_follow_state(context, member_name, subject, true)
  end

  step "{word} should not be following the conversation for {string}",
       %{args: [member_name, subject]} = context do
    assert_conversation_follow_state(context, member_name, subject, false)
  end

  step ~r/^(\w+) follows the stop-follow link from (\w+)'s reply email$/,
       %{args: [recipient_name, sender_name]} = context do
    follow_stop_follow_link_from_reply_email(context, recipient_name, sender_name)
  end

  step "{word} follows a tampered stop-follow link for {string}",
       %{args: [recipient_name, subject]} = context do
    follow_tampered_stop_follow_link(context, recipient_name, subject)
  end

  step "{word} should be told the stop-follow link is not valid",
       %{args: [_recipient_name]} = context do
    assert {:error, :invalid_stop_follow_token} =
             Map.fetch!(context, :last_stop_follow_link_result)

    context
  end

  step "{word} should not be able to reply to {string}",
       %{args: [sender_name, subject]} = context do
    assert_cannot_reply_to_message(context, sender_name, subject)
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

  step ~r/^(\w+) emails "([^"]+)" to ([^\s]+)$/,
       %{args: [sender_name, subject, to_address]} = context do
    receive_inbound_club_email(context, sender_name, subject, to_address)
  end

  step ~r/^(\w+) emails "([^"]+)" to ([^\s]+) from "([^"]+)"$/,
       %{args: [sender_name, subject, to_address, from_address]} = context do
    receive_inbound_club_email(context, sender_name, subject, to_address,
      from_address: from_address
    )
  end

  step ~r/^(\w+) emails "([^"]+)" to ([^\s]+) with an attachment$/,
       %{args: [sender_name, subject, to_address]} = context do
    receive_inbound_club_email(context, sender_name, subject, to_address,
      attachments: [
        %{filename: "route.gpx", content_type: "application/gpx+xml", size: 1234}
      ]
    )
  end

  step ~r/^(\w+) emails "([^"]+)" to ([^\s]+) with only an HTML body$/,
       %{args: [sender_name, subject, to_address]} = context do
    receive_inbound_club_email(context, sender_name, subject, to_address,
      text_body: nil,
      html_body: "<p>#{subject} details.</p>"
    )
  end

  step ~r/^(\w+) emails "([^"]+)" to ([^\s]+) with the body:$/,
       %{args: [sender_name, subject, to_address]} = context do
    receive_inbound_club_email(context, sender_name, subject, to_address,
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

  step ~r/^(\w+)'s club home should list one conversation for "([^"]+)"$/,
       %{args: [viewer_name, subject]} = context do
    conversations =
      club_home_conversations_for!(context, viewer_name, "Kootenay Mountaineering Club")

    message = fetch_from_context!(context, :messages, subject)

    matching_conversations = Enum.filter(conversations, &(&1.subject == subject))
    message_id = message.message_id

    assert length(matching_conversations) == 1

    assert [%{message_id: ^message_id, conversation_id: ^message_id}] = matching_conversations

    Map.put(context, :current_club_home_conversations, conversations)
  end

  step ~r/^the "([^"]+)" conversation should show (\d+) replies$/,
       %{args: [subject, expected_reply_count]} = context do
    conversation = club_home_conversation_for!(context, subject)

    assert conversation.reply_count == String.to_integer(expected_reply_count)

    context
  end

  step "the {string} conversation should show the latest reply is from {word}",
       %{args: [subject, replier_name]} = context do
    conversation = club_home_conversation_for!(context, subject)
    replier_id = person_id_from_context!(context, replier_name)

    assert conversation.latest_replier_id == replier_id
    assert conversation.latest_replier_name == replier_name

    context
  end

  step "the {string} conversation should show no replies yet",
       %{args: [subject]} = context do
    conversation = club_home_conversation_for!(context, subject)

    assert conversation.reply_count == 0
    assert conversation.latest_replier_id == nil
    assert conversation.latest_replier_name == nil

    context
  end

  step "the {string} conversation should show no participant avatars",
       %{args: [subject]} = context do
    conversation = club_home_conversation_for!(context, subject)

    assert Map.get(conversation, :participant_ids, []) == []

    context
  end

  step ~r/^the "([^"]+)" conversation participant avatar-stack should show (.+?)(?:, plus (\d+) more)?$/,
       %{args: args} = context do
    [subject, participant_names_text | additional_count_args] = args
    expected_participant_ids = participant_ids_from_text(context, participant_names_text)
    conversation = club_home_conversation_for!(context, subject)
    participant_ids = Map.get(conversation, :participant_ids, [])
    expected_additional_count = additional_count_arg(additional_count_args)

    assert Enum.take(participant_ids, 3) == expected_participant_ids
    assert max(length(participant_ids) - 3, 0) == expected_additional_count

    context
  end

  step ~r/^(\w+)'s club home should list "([^"]+)" before "([^"]+)"$/,
       %{args: [viewer_name, earlier_subject, later_subject]} = context do
    conversations =
      club_home_conversations_for!(context, viewer_name, "Kootenay Mountaineering Club")

    subjects = Enum.map(conversations, & &1.subject)

    earlier_index = Enum.find_index(subjects, &(&1 == earlier_subject))
    later_index = Enum.find_index(subjects, &(&1 == later_subject))

    assert is_integer(earlier_index),
           "Expected club home conversations to include #{inspect(earlier_subject)}; saw #{inspect(subjects)}"

    assert is_integer(later_index),
           "Expected club home conversations to include #{inspect(later_subject)}; saw #{inspect(subjects)}"

    assert earlier_index < later_index

    context
    |> Map.put(:current_club_home_conversations, conversations)
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

  step "{word} should receive a rejection email from {string}",
       %{args: [sender_name, expected_from_name]} = context do
    context = assert_rejection_email(context, sender_name, "wasn't posted")
    email = fetch_from_context!(context, :rejection_emails, sender_name)

    assert email_from(email) =~ expected_from_name

    context
  end

  step "the rejection email should use the standard Memba footer", context do
    {_sender_name, email} =
      context
      |> Map.fetch!(:rejection_emails)
      |> Enum.at(-1)

    html_body = email.html_body || ""

    assert html_body =~ ~r/Delivered (?:by|for) /
    assert html_body =~ ~s(href="https://memba.io")
    assert html_body =~ "This is an automatic delivery notice."

    assert html_body =~
             ~r/Need a hand\? (?:Contact Memba support|Reply to this email or write to)/

    context
  end

  step "the message body should be:", context do
    message = fetch_from_context!(context, :messages, Map.fetch!(context, :last_message_subject))
    assert message.body == String.trim(Map.fetch!(context, :docstring))
    context
  end

  defp send_message_to_kootenay_members(context, sender_name, subject) do
    send_message_to_club_members(context, sender_name, subject, "Kootenay Mountaineering Club")
  end

  defp send_message_to_club_members(context, sender_name, subject, club_name) do
    message_id = Memba.ID.generate(:message)
    club_id = fetch_from_context!(context, :clubs, club_name)
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

  defp dispatch_and_clear_background_message_deliveries(context) do
    dispatch_pending_email_deliveries()
    Fake.reset()
    context
  end

  defp post_reply_to_message(context, sender_name, subject, body) do
    reply_message_id = Memba.ID.generate(:message)
    root_message = fetch_from_context!(context, :messages, subject)
    sender_id = person_id_from_context!(context, sender_name)

    assert :ok =
             Messaging.post_message_reply(
               %{
                 message_id: reply_message_id,
                 conversation_id: root_message.message_id,
                 sender_id: sender_id,
                 body: body
               },
               consistency: :strong
             )

    assert reply = Messaging.get_message(reply_message_id)

    reply_context = %{
      body: reply.body,
      club_id: reply.club_id,
      conversation_id: reply.conversation_id,
      message_id: reply.message_id,
      sender_id: reply.sender_id,
      sender_name: sender_name,
      subject: subject
    }

    context
    |> Map.put(:last_reply, reply_context)
    |> update_context_map({:replies, subject}, {sender_name, body}, reply_context)
  end

  defp follow_conversation(context, member_name, subject) do
    root_message = fetch_from_context!(context, :messages, subject)
    member_id = person_id_from_context!(context, member_name)

    assert :ok =
             Messaging.follow_conversation_as_current_member(
               %{
                 club_id: root_message.club_id,
                 conversation_id: root_message.message_id,
                 member_id: member_id
               },
               consistency: :strong
             )

    context
  end

  defp unfollow_conversation(context, member_name, subject) do
    root_message = fetch_from_context!(context, :messages, subject)
    member_id = person_id_from_context!(context, member_name)

    assert :ok =
             Messaging.unfollow_conversation_as_current_member(
               %{
                 club_id: root_message.club_id,
                 conversation_id: root_message.message_id,
                 member_id: member_id
               },
               consistency: :strong
             )

    context
  end

  defp remove_member_from_club(context, member_name, club_name) do
    membership_id = fetch_from_context!(context, :memberships, {club_name, member_name})

    assert :ok = Membership.remove_member(%{membership_id: membership_id}, consistency: :strong)

    memberships =
      context
      |> Map.get(:memberships, %{})
      |> Map.delete({club_name, member_name})

    Map.put(context, :memberships, memberships)
  end

  defp assert_conversation_follow_state(context, member_name, subject, expected_following) do
    root_message = fetch_from_context!(context, :messages, subject)
    member_id = person_id_from_context!(context, member_name)

    assert Messaging.following_conversation?(root_message.message_id, member_id) ==
             expected_following

    context
  end

  defp assert_conversation_shows_reply(context, subject, sender_name, body) do
    root_message = fetch_from_context!(context, :messages, subject)
    sender_id = person_id_from_context!(context, sender_name)

    assert Enum.any?(Messaging.list_conversation_messages(root_message.message_id), fn message ->
             message.sender_id == sender_id and message.body == body
           end)

    context
  end

  defp assert_conversation_does_not_show_reply(context, subject, sender_name, body) do
    root_message = fetch_from_context!(context, :messages, subject)
    sender_id = person_id_from_context!(context, sender_name)

    refute Enum.any?(Messaging.list_conversation_messages(root_message.message_id), fn message ->
             message.sender_id == sender_id and message.body == body and
               is_binary(message.reply_to_message_id)
           end)

    context
  end

  defp assert_conversation_order(context, subject, earlier_body, later_body) do
    root_message = fetch_from_context!(context, :messages, subject)
    bodies = Enum.map(Messaging.list_conversation_messages(root_message.message_id), & &1.body)

    earlier_index = Enum.find_index(bodies, &(&1 == earlier_body))
    later_index = Enum.find_index(bodies, &(&1 == later_body))

    assert is_integer(earlier_index),
           "Expected conversation for #{inspect(subject)} to include #{inspect(earlier_body)}"

    assert is_integer(later_index),
           "Expected conversation for #{inspect(subject)} to include #{inspect(later_body)}"

    assert earlier_index < later_index

    context
  end

  defp club_home_conversations_for!(context, viewer_name, club_name) do
    assert_active_member!(context, viewer_name, club_name)

    club_name
    |> then(&fetch_from_context!(context, :clubs, &1))
    |> Messaging.list_conversations_for_club()
  end

  defp club_home_conversation_for!(context, subject) do
    conversations =
      Map.get_lazy(context, :current_club_home_conversations, fn ->
        club_id = fetch_from_context!(context, :clubs, "Kootenay Mountaineering Club")
        Messaging.list_conversations_for_club(club_id)
      end)

    Enum.find(conversations, &(&1.subject == subject)) ||
      flunk("Expected club home conversations to include #{inspect(subject)}")
  end

  defp assert_reply_email_delivered_to_members(
         context,
         subject,
         sender_name,
         expected_recipient_names,
         expected_from_group_name
       ) do
    reply = latest_reply_for!(context, subject, sender_name)
    dispatch_pending_email_deliveries()

    member_deliveries = Messaging.list_member_email_deliverys(reply.message_id)
    assert Enum.map(member_deliveries, & &1.recipient_name) == expected_recipient_names

    provider_deliveries =
      Enum.filter(Fake.deliveries(), fn %EmailDeliveryRequest{} = request ->
        request.message_id == reply.message_id
      end)

    assert length(provider_deliveries) == length(expected_recipient_names)

    Enum.zip(expected_recipient_names, provider_deliveries)
    |> Enum.each(fn {recipient_name, %EmailDeliveryRequest{} = request} ->
      assert request.message_id == reply.message_id
      assert request.conversation_id == reply.conversation_id
      assert request.subject == subject
      assert request.body == reply.body
      assert request.sender_name == sender_name
      assert request.recipient_name == recipient_name

      assert MemberMessageEmail.from_display_name(request) ==
               "#{expected_from_group_name} via Memba"
    end)

    context
  end

  defp assert_reply_email_not_delivered_to_members(
         context,
         subject,
         sender_name,
         excluded_recipient_names
       ) do
    reply = latest_reply_for!(context, subject, sender_name)
    dispatch_pending_email_deliveries()

    member_deliveries = Messaging.list_member_email_deliverys(reply.message_id)
    provider_deliveries = Fake.deliveries()

    Enum.each(excluded_recipient_names, fn recipient_name ->
      recipient_id = person_id_from_context!(context, recipient_name)

      refute Enum.any?(member_deliveries, fn receipt ->
               receipt.recipient_id == recipient_id
             end)

      refute Enum.any?(provider_deliveries, fn %EmailDeliveryRequest{} = request ->
               request.message_id == reply.message_id and request.recipient_id == recipient_id
             end)
    end)

    context
  end

  defp assert_reply_email_not_delivered_to_author(context, sender_name) do
    reply = Map.fetch!(context, :last_reply)
    sender_id = person_id_from_context!(context, sender_name)

    refute Enum.any?(Messaging.list_member_email_deliverys(reply.message_id), fn receipt ->
             receipt.recipient_id == sender_id
           end)

    refute Enum.any?(Fake.deliveries(), fn %EmailDeliveryRequest{} = request ->
             request.message_id == reply.message_id and request.recipient_id == sender_id
           end)

    context
  end

  defp follow_stop_follow_link_from_reply_email(context, recipient_name, _sender_name) do
    reply = Map.fetch!(context, :last_reply)
    recipient_id = person_id_from_context!(context, recipient_name)

    dispatch_pending_email_deliveries()

    request =
      Fake.deliveries()
      |> Enum.find(fn %EmailDeliveryRequest{} = request ->
        request.message_id == reply.message_id and request.recipient_id == recipient_id
      end)

    assert %EmailDeliveryRequest{stop_follow_url: stop_follow_url} = request
    assert is_binary(stop_follow_url) and stop_follow_url != ""

    token = stop_follow_url |> String.split("/") |> List.last()

    result = Messaging.stop_following_conversation_from_email_token(token, consistency: :strong)

    assert {:ok, _scope} = result

    Map.put(context, :last_stop_follow_link_result, result)
  end

  defp follow_tampered_stop_follow_link(context, recipient_name, subject) do
    root_message = fetch_from_context!(context, :messages, subject)
    recipient_id = person_id_from_context!(context, recipient_name)

    assert {:ok, token} =
             ConversationStopFollowToken.sign(%{
               club_id: root_message.club_id,
               conversation_id: root_message.message_id,
               member_id: recipient_id
             })

    result =
      Messaging.stop_following_conversation_from_email_token(token <> "tampered",
        consistency: :strong
      )

    Map.put(context, :last_stop_follow_link_result, result)
  end

  defp assert_cannot_reply_to_message(context, sender_name, subject) do
    reply_message_id = Memba.ID.generate(:message)
    root_message = fetch_from_context!(context, :messages, subject)
    sender_id = person_id_from_context!(context, sender_name)

    assert {:error, :not_current_member} =
             Messaging.post_message_reply(
               %{
                 message_id: reply_message_id,
                 conversation_id: root_message.message_id,
                 sender_id: sender_id,
                 body: "I should not be able to post this."
               },
               consistency: :strong
             )

    refute Messaging.get_message(reply_message_id)

    context
  end

  defp latest_reply_for!(context, subject, sender_name) do
    context
    |> Map.get({:replies, subject}, %{})
    |> Enum.map(fn {{reply_sender_name, _body}, reply} -> {reply_sender_name, reply} end)
    |> Enum.filter(fn {reply_sender_name, _reply} -> reply_sender_name == sender_name end)
    |> List.last()
    |> case do
      {_reply_sender_name, reply} ->
        reply

      nil ->
        flunk("Expected #{sender_name} to have replied to #{inspect(subject)}")
    end
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
    in_reply_to_message_ids = Keyword.get(opts, :in_reply_to_message_ids, [])
    references_message_ids = Keyword.get(opts, :references_message_ids, [])

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
          in_reply_to_message_ids: in_reply_to_message_ids,
          references_message_ids: references_message_ids,
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

        if is_binary(message.reply_to_message_id) do
          record_inbound_reply_context(context, message, sender_name)
        else
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
        end

      {:error, reason} ->
        flunk("Expected inbound email not to error; got #{inspect(reason)}")
    end
  end

  defp receive_inbound_reply_email(context, sender_name, subject, body, opts \\ []) do
    outbound_message_id = outbound_message_id_for_subject!(context, subject, sender_name)
    to_address = Keyword.get(opts, :to_address, @kmc_everyone_address)

    receive_inbound_club_email(context, sender_name, "Re: #{subject}", to_address,
      text_body: body,
      in_reply_to_message_ids: [outbound_message_id]
    )
  end

  defp record_inbound_reply_context(context, message, sender_name) do
    reply_context = %{
      body: message.body,
      club_id: message.club_id,
      conversation_id: message.conversation_id,
      message_id: message.message_id,
      sender_id: message.sender_id,
      sender_name: sender_name,
      subject: message.subject
    }

    context
    |> Map.put(:last_reply, reply_context)
    |> update_context_map({:replies, message.subject}, {sender_name, message.body}, reply_context)
  end

  defp outbound_message_id_for_subject!(context, subject, preferred_recipient_name) do
    message = fetch_from_context!(context, :messages, subject)

    preferred_recipient_id =
      if Map.has_key?(Map.get(context, :people, %{}), preferred_recipient_name) do
        person_id_from_context!(context, preferred_recipient_name)
      end

    deliveries = Messaging.list_recipient_deliveries(message.message_id)

    delivery =
      (preferred_recipient_id &&
         Enum.find(deliveries, &(&1.recipient_id == preferred_recipient_id))) ||
        List.first(deliveries)

    case delivery do
      %{outbound_message_id: outbound_message_id}
      when is_binary(outbound_message_id) and outbound_message_id != "" ->
        outbound_message_id

      _missing ->
        flunk("Expected outbound Message-ID for #{inspect(subject)}")
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

  defp email_from(%Swoosh.Email{from: {name, address}}), do: "#{name} <#{address}>"
  defp email_from(%Swoosh.Email{from: from}) when is_binary(from), do: from
  defp email_from(%Swoosh.Email{from: from}), do: inspect(from)

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

  defp participant_ids_from_text(context, participant_names_text) do
    participant_names_text
    |> parse_person_list()
    |> Enum.map(&person_id_from_context!(context, &1))
  end

  defp additional_count_arg([]), do: 0
  defp additional_count_arg([nil]), do: 0
  defp additional_count_arg([count]), do: String.to_integer(count)

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

  defp parse_person_list(text) do
    text
    |> String.replace(~r/,?\s+and\s+/, ", ")
    |> String.split(~r/\s*,\s*/, trim: true)
    |> Enum.map(&String.trim/1)
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
