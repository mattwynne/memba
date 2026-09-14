defmodule Memba.Cucumber.CustomGroupConversationSteps do
  use Cucumber.StepDefinition

  import ExUnit.Assertions

  alias Memba.ClubInboundEmailAddress
  alias Memba.Membership
  alias Memba.Membership.App, as: MembershipApp
  alias Memba.Membership.Commands.AddGroupMember
  alias Memba.Membership.Commands.CreateGroup
  alias Memba.Membership.SystemGroups
  alias Memba.Messaging
  alias Memba.Messaging.EmailDeliveryDispatcher
  alias Memba.Messaging.EmailDeliveryProviders.Fake

  @club_name "Kootenay Mountaineering Club"
  @board_name "Board"
  @board_address "board@kmc.clubs.memba.io"

  step "Bob, Carol, and Eve are its ordinary active club members", context do
    Enum.reduce(["Bob", "Carol", "Eve"], context, &ensure_active_member(&2, @club_name, &1))
  end

  step "Alice, Bob, and Carol are the only members of its custom group Board", context do
    context = ensure_custom_group(context, @club_name, @board_name, "board")

    Enum.reduce(["Alice", "Bob", "Carol"], context, fn person_name, context ->
      add_group_member(context, @club_name, @board_name, person_name)
    end)
  end

  step "Board's email address is {string}", %{args: [expected_address]} = context do
    club = Membership.get_club(club_id!(context, @club_name))
    group = group!(context, @club_name, @board_name)

    assert ClubInboundEmailAddress.address(club, group.email_slug) == expected_address
    context
  end

  step ~r/^(\w+) sends "([^"]+)" to Board on the website$/,
       %{args: [sender_name, subject]} = context do
    send_board_conversation(context, sender_name, subject, :current_member)
  end

  step ~r/^"([^"]+)" should be a Board conversation$/,
       %{args: [subject]} = context do
    assert_board_conversation(context, subject)
  end

  step ~r/^(.+) should be able to read it$/,
       %{args: [person_names]} = context do
    Enum.each(parse_person_list(person_names), fn person_name ->
      assert_member_access(context, person_name, last_subject!(context), :read, true)
    end)

    context
  end

  step ~r/^(.+) should each receive its initial email$/,
       %{args: [person_names]} = context do
    assert_initial_recipients(context, last_subject!(context), parse_person_list(person_names))
  end

  step ~r/^(.+) should neither be able to read it nor receive its email$/,
       %{args: [person_names]} = context do
    subject = last_subject!(context)

    Enum.each(parse_person_list(person_names), fn person_name ->
      assert_member_access(context, person_name, subject, :read, false)
      refute_recipient(context, subject, person_name)
    end)

    context
  end

  step "it should not appear among Everyone's conversations", context do
    subject = last_subject!(context)
    everyone_group_id = SystemGroups.everyone_group_id(club_id!(context, @club_name))

    refute Enum.any?(
             Messaging.list_conversations_for_group(everyone_group_id),
             &(&1.subject == subject)
           )

    context
  end

  step ~r/^Board should have the conversation "([^"]+)"$/,
       %{args: [subject]} = context do
    assert_board_conversation(context, subject)
  end

  step ~r/^(\w+) should not receive its initial email or become its follower$/,
       %{args: [person_name]} = context do
    subject = last_subject!(context)
    message = message!(context, subject)

    refute_recipient(context, subject, person_name)
    refute Messaging.following_conversation?(message.message_id, person_id!(context, person_name))
    context
  end

  step ~r/^(\w+) should neither belong to Board nor gain permission to read or reply to the conversation$/,
       %{args: [person_name]} = context do
    board_id = group_id!(context, @club_name, @board_name)
    person_id = person_id!(context, person_name)
    subject = last_subject!(context)

    refute Membership.active_member_of_group?(board_id, person_id)
    assert_member_access(context, person_name, subject, :read, false)
    assert_member_access(context, person_name, subject, :write, false)
    context
  end

  step ~r/^(\w+) should be following "([^"]+)"$/,
       %{args: [person_name, subject]} = context do
    assert Messaging.following_conversation?(
             message!(context, subject).message_id,
             person_id!(context, person_name)
           )

    context
  end

  step "Pat belongs to Nelson Paddling Club but not KMC", context do
    context
    |> ensure_club("Nelson Paddling Club", "nelson")
    |> ensure_active_member("Nelson Paddling Club", "Pat")
  end

  step "Robin has no club membership", context do
    ensure_person(context, "Robin")
  end

  step "Eve is no longer an active member of KMC", context do
    membership_id = membership_id!(context, @club_name, "Eve")
    assert :ok = Membership.remove_member(%{membership_id: membership_id}, consistency: :strong)

    update_context(context, :memberships, fn memberships ->
      Map.delete(memberships, {@club_name, "Eve"})
    end)
  end

  step ~r/^no Board conversation named "([^"]+)" should be created$/,
       %{args: [subject]} = context do
    board_id = group_id!(context, @club_name, @board_name)

    refute Enum.any?(
             Messaging.list_conversations_for_group(board_id),
             &(&1.subject == subject)
           )

    context
  end

  step ~r/^(\w+) should receive the existing message-not-posted rejection email$/,
       %{args: [person_name]} = context do
    assert {:ok, %{status: :rejected}} = Map.fetch!(context, :last_inbound_email_result)

    expected_address =
      get_in(context, [:inbound_from_addresses, person_name]) ||
        person_email!(context, person_name)

    assert_received {:email, %Swoosh.Email{} = email}

    assert Enum.any?(email.to, &email_address?(&1, expected_address)),
           "Expected rejection email to #{expected_address}; got #{inspect(email.to)}"

    assert email.text_body =~ "wasn't posted"
    context
  end

  step ~r/^(\w+) tries to reply "([^"]+)" to that conversation (on the website|by email)$/,
       %{args: [person_name, body, channel]} = context do
    subject = last_subject!(context)
    message = message!(context, subject)
    message_count_before = length(Messaging.list_conversation_messages(message.message_id))

    {result, context} =
      case channel do
        "on the website" ->
          result =
            Messaging.post_message_reply(
              %{
                message_id: Memba.ID.generate(:message),
                conversation_id: message.message_id,
                sender_id: person_id!(context, person_name),
                body: body
              },
              consistency: :strong
            )

          {result, context}

        "by email" ->
          dispatch_pending_email_deliveries()
          outbound_message_id = outbound_message_id!(message.message_id)

          receive_inbound_email(context, person_name, "Re: #{subject}", @board_address,
            text_body: body,
            in_reply_to_message_ids: [outbound_message_id]
          )
      end

    Map.put(context, :reply_attempt, %{
      body: body,
      channel: channel,
      conversation_id: message.message_id,
      message_count_before: message_count_before,
      person_name: person_name,
      result: result
    })
  end

  step ~r/^"([^"]+)" should not be added to that conversation$/,
       %{args: [body]} = context do
    attempt = Map.fetch!(context, :reply_attempt)
    messages = Messaging.list_conversation_messages(attempt.conversation_id)

    assert length(messages) == attempt.message_count_before
    refute Enum.any?(messages, &(&1.body == body))
    context
  end

  step ~r/^(\w+) should not gain access to that conversation$/,
       %{args: [person_name]} = context do
    subject = last_subject!(context)
    assert_member_access(context, person_name, subject, :read, false)
    assert_member_access(context, person_name, subject, :write, false)
    context
  end

  step ~r/^(\w+) replies by email "([^"]+)" to "([^"]+)"$/,
       %{args: [person_name, body, subject]} = context do
    message = message!(context, subject)
    dispatch_pending_email_deliveries()
    Fake.reset()

    {result, context} =
      receive_inbound_email(context, person_name, "Re: #{subject}", @board_address,
        text_body: body,
        in_reply_to_message_ids: [outbound_message_id!(message.message_id)]
      )

    assert {:ok, %{message_id: reply_id, conversation_id: conversation_id}} = result
    assert conversation_id == message.message_id
    reply = Messaging.get_message(reply_id)

    context
    |> Map.put(:last_reply, reply_context(reply, person_name, subject))
    |> put_reply_context(subject, person_name, body, reply_context(reply, person_name, subject))
  end

  step ~r/^"([^"]+)" should be a reply in Board's "([^"]+)" conversation$/,
       %{args: [body, subject]} = context do
    board_id = group_id!(context, @club_name, @board_name)
    root = message!(context, subject)

    assert Enum.any?(
             Messaging.list_conversation_messages_for_group(root.message_id, board_id),
             &(is_binary(&1.reply_to_message_id) and &1.body == body)
           )

    context
  end

  step ~r/^(\w+) should be following that conversation$/,
       %{args: [person_name]} = context do
    message = message!(context, last_subject!(context))
    assert Messaging.following_conversation?(message.message_id, person_id!(context, person_name))
    context
  end

  step ~r/^(\w+) should receive (\w+)'s reply by email$/,
       %{args: [recipient_name, sender_name]} = context do
    assert_reply_recipients(context, sender_name, [recipient_name])
  end

  step ~r/^(.+) should not receive it$/,
       %{args: [person_names]} = context do
    reply = Map.fetch!(context, :last_reply)
    refute_reply_recipients(context, reply, parse_person_list(person_names))
  end

  step ~r/^(\w+) started Board's conversation "([^"]+)"$/,
       %{args: [person_name, subject]} = context do
    context
    |> send_board_conversation(person_name, subject, :fixture)
    |> clear_initial_deliveries()
  end

  step ~r/^(\w+) follows "([^"]+)"$/,
       %{args: [person_name, subject]} = context do
    set_following(context, person_name, subject, true)
  end

  step ~r/^(\w+) does not follow "([^"]+)"$/,
       %{args: [person_name, subject]} = context do
    set_following(context, person_name, subject, false)
  end

  step ~r/^(\w+) has stopped following "([^"]+)"$/,
       %{args: [person_name, subject]} = context do
    set_following(context, person_name, subject, false)
  end

  step ~r/^(\w+) replies "([^"]+)" to "([^"]+)" on the website$/,
       %{args: [person_name, body, subject]} = context do
    post_reply(context, person_name, subject, body)
  end

  step ~r/^(\w+) should still be able to read the whole conversation$/,
       %{args: [person_name]} = context do
    subject = last_subject!(context)
    message = message!(context, subject)
    board_id = group_id!(context, @club_name, @board_name)

    assert_member_access(context, person_name, subject, :read, true)
    assert length(Messaging.list_conversation_messages_for_group(message.message_id, board_id)) >= 2
    context
  end

  defp ensure_club(context, club_name, slug) do
    case get_in(context, [:clubs, club_name]) do
      club_id when is_binary(club_id) ->
        context

      nil ->
        club_id = Memba.ID.generate(:club)

        assert :ok =
                 Membership.create_club(
                   %{club_id: club_id, name: club_name, slug: slug},
                   consistency: :strong
                 )

        put_context(context, :clubs, club_name, club_id)
    end
  end

  defp ensure_active_member(context, club_name, person_name) do
    context = ensure_person(context, person_name)
    key = {club_name, person_name}

    case get_in(context, [:memberships, key]) do
      membership_id when is_binary(membership_id) ->
        context

      nil ->
        membership_id = Memba.ID.generate(:membership)

        assert :ok =
                 Membership.add_member(
                   %{
                     club_id: club_id!(context, club_name),
                     membership_id: membership_id,
                     person_id: person_id!(context, person_name)
                   },
                   consistency: :strong
                 )

        put_context(context, :memberships, key, membership_id)
    end
  end

  defp ensure_person(context, person_name) do
    case get_in(context, [:people, person_name]) do
      %{person_id: person_id} when is_binary(person_id) ->
        context

      nil ->
        person_id = Memba.ID.generate(:person)
        email = "#{String.downcase(person_name)}-#{scenario_suffix(context)}@example.test"

        assert :ok =
                 Membership.create_person(
                   %{
                     person_id: person_id,
                     name: person_name,
                     email_addresses: [%{email: email, is_primary: true}]
                   },
                   consistency: :strong
                 )

        put_context(context, :people, person_name, %{
          email: email,
          name: person_name,
          person_id: person_id
        })
    end
  end

  defp ensure_custom_group(context, club_name, group_name, email_slug) do
    group_id = Memba.ID.generate(:group)

    assert :ok =
             MembershipApp.dispatch(
               %CreateGroup{
                 club_id: club_id!(context, club_name),
                 group_id: group_id,
                 group_key: nil,
                 email_slug: email_slug,
                 name: group_name
               },
               consistency: :strong
             )

    put_context(context, :groups, {club_name, group_name}, group_id)
  end

  defp add_group_member(context, club_name, group_name, person_name) do
    assert :ok =
             MembershipApp.dispatch(
               %AddGroupMember{
                 club_id: club_id!(context, club_name),
                 group_id: group_id!(context, club_name, group_name),
                 membership_id: membership_id!(context, club_name, person_name),
                 person_id: person_id!(context, person_name)
               },
               consistency: :strong
             )

    context
  end

  defp send_board_conversation(context, sender_name, subject, mode) do
    Fake.reset()
    message_id = Memba.ID.generate(:message)

    attrs = %{
      message_id: message_id,
      club_id: club_id!(context, @club_name),
      sender_id: person_id!(context, sender_name),
      audience_group_id: group_id!(context, @club_name, @board_name),
      subject: subject,
      body: "#{subject} details."
    }

    result =
      case mode do
        :current_member -> Messaging.send_club_message_as_current_member(attrs, consistency: :strong)
        :fixture -> Messaging.send_club_message(attrs, consistency: :strong)
      end

    assert :ok = result
    message = Messaging.get_message(message_id)

    context
    |> Map.put(:last_message_id, message_id)
    |> Map.put(:last_message_subject, subject)
    |> Map.put(:sent_message, message)
    |> put_context(:messages, subject, message)
  end

  defp assert_board_conversation(context, subject) do
    message = ensure_recorded_message(context, subject)
    board_id = group_id!(context, @club_name, @board_name)

    assert Enum.any?(
             Messaging.list_conversations_for_group(board_id),
             &(&1.message_id == message.message_id and &1.subject == subject)
           )

    context
    |> Map.put(:last_message_subject, subject)
    |> put_context(:messages, subject, message)
  end

  defp ensure_recorded_message(context, subject) do
    case get_in(context, [:messages, subject]) do
      nil ->
        group_id = group_id!(context, @club_name, @board_name)

        Messaging.list_conversations_for_group(group_id)
        |> Enum.find(&(&1.subject == subject))
        |> case do
          nil -> flunk("Expected Board conversation #{inspect(subject)}")
          message -> message
        end

      message ->
        message
    end
  end

  defp assert_initial_recipients(context, subject, expected_names) do
    message = message!(context, subject)
    deliveries = Messaging.list_recipient_deliveries(message.message_id)

    assert Enum.sort(Enum.map(deliveries, & &1.recipient_name)) == Enum.sort(expected_names)
    dispatch_pending_email_deliveries()

    provider_names =
      Fake.deliveries()
      |> Enum.filter(&(&1.message_id == message.message_id))
      |> Enum.map(& &1.recipient_name)

    assert Enum.sort(provider_names) == Enum.sort(expected_names)
    context
  end

  defp refute_recipient(context, subject, person_name) do
    message = message!(context, subject)
    person_id = person_id!(context, person_name)

    refute Enum.any?(
             Messaging.list_recipient_deliveries(message.message_id),
             &(&1.recipient_id == person_id)
           )

    dispatch_pending_email_deliveries()

    refute Enum.any?(
             Fake.deliveries(),
             &(&1.message_id == message.message_id and &1.recipient_id == person_id)
           )
  end

  defp assert_member_access(context, person_name, subject, access_level, expected) do
    message = message!(context, subject)

    assert Messaging.member_has_conversation_access?(
             message.message_id,
             message.club_id,
             person_id!(context, person_name),
             access_level
           ) == expected
  end

  defp receive_inbound_email(context, sender_name, subject, to_address, opts) do
    result =
      Messaging.receive_inbound_club_email(
        %{
          provider: "domain-custom-group-conversations",
          provider_message_id:
            "custom-group-#{Memba.ID.generate(:message)}-#{String.downcase(sender_name)}",
          from_address: person_email!(context, sender_name),
          recipient_addresses: [to_address],
          subject: subject,
          text_body: Keyword.fetch!(opts, :text_body),
          html_body: nil,
          in_reply_to_message_ids: Keyword.get(opts, :in_reply_to_message_ids, []),
          references_message_ids: [],
          attachments: []
        },
        consistency: :strong
      )

    {result, Map.put(context, :last_inbound_email_result, result)}
  end

  defp outbound_message_id!(message_id) do
    Messaging.list_recipient_deliveries(message_id)
    |> Enum.find_value(& &1.outbound_message_id)
    |> case do
      nil -> flunk("Expected an outbound Message-ID for #{message_id}")
      outbound_message_id -> outbound_message_id
    end
  end

  defp post_reply(context, person_name, subject, body) do
    Fake.reset()
    root = message!(context, subject)
    reply_id = Memba.ID.generate(:message)

    assert :ok =
             Messaging.post_message_reply(
               %{
                 message_id: reply_id,
                 conversation_id: root.message_id,
                 sender_id: person_id!(context, person_name),
                 body: body
               },
               consistency: :strong
             )

    reply = Messaging.get_message(reply_id)
    reply = reply_context(reply, person_name, subject)

    context
    |> Map.put(:last_reply, reply)
    |> put_reply_context(subject, person_name, body, reply)
  end

  defp set_following(context, person_name, subject, true) do
    message = message!(context, subject)

    assert :ok =
             Messaging.follow_conversation_as_current_member(
               %{
                 club_id: message.club_id,
                 conversation_id: message.message_id,
                 member_id: person_id!(context, person_name)
               },
               consistency: :strong
             )

    context
  end

  defp set_following(context, person_name, subject, false) do
    message = message!(context, subject)
    person_id = person_id!(context, person_name)

    if Messaging.following_conversation?(message.message_id, person_id) do
      assert :ok =
               Messaging.unfollow_conversation_as_current_member(
                 %{
                   club_id: message.club_id,
                   conversation_id: message.message_id,
                   member_id: person_id
                 },
                 consistency: :strong
               )
    end

    context
  end

  defp assert_reply_recipients(context, sender_name, included_names) do
    reply = Map.fetch!(context, :last_reply)
    assert reply.sender_name == sender_name
    dispatch_pending_email_deliveries()

    recipient_names =
      Fake.deliveries()
      |> Enum.filter(&(&1.message_id == reply.message_id))
      |> Enum.map(& &1.recipient_name)

    Enum.each(included_names, &assert(&1 in recipient_names))
    context
  end

  defp refute_reply_recipients(context, reply, excluded_names) do
    dispatch_pending_email_deliveries()

    recipient_names =
      Fake.deliveries()
      |> Enum.filter(&(&1.message_id == reply.message_id))
      |> Enum.map(& &1.recipient_name)

    Enum.each(excluded_names, &refute(&1 in recipient_names))
    context
  end

  defp clear_initial_deliveries(context) do
    dispatch_pending_email_deliveries()
    Fake.reset()
    context
  end

  defp dispatch_pending_email_deliveries do
    _deliveries = EmailDeliveryDispatcher.dispatch_pending_email_deliveries()
    :ok
  end

  defp group!(context, club_name, group_name) do
    context
    |> group_id!(club_name, group_name)
    |> then(&Membership.get_group/1)
    |> case do
      %{group_id: group_id} = group when is_binary(group_id) -> group
      nil -> flunk("Expected #{group_name} in #{club_name}")
    end
  end

  defp group_id!(context, club_name, group_name) do
    context
    |> Map.fetch!(:groups)
    |> Map.fetch!({club_name, group_name})
  end

  defp club_id!(context, club_name), do: fetch_context!(context, :clubs, club_name)

  defp person_id!(context, person_name) do
    context
    |> fetch_context!(:people, person_name)
    |> Map.fetch!(:person_id)
  end

  defp person_email!(context, person_name) do
    context
    |> fetch_context!(:people, person_name)
    |> Map.fetch!(:email)
  end

  defp membership_id!(context, club_name, person_name) do
    fetch_context!(context, :memberships, {club_name, person_name})
  end

  defp message!(context, subject), do: fetch_context!(context, :messages, subject)

  defp last_subject!(context) do
    Map.get(context, :last_message_subject) ||
      Map.fetch!(context, :sent_message).subject
  end

  defp fetch_context!(context, collection_key, item_key) do
    context
    |> Map.fetch!(collection_key)
    |> Map.fetch!(item_key)
  end

  defp put_context(context, collection_key, item_key, value) do
    update_context(context, collection_key, &Map.put(&1, item_key, value))
  end

  defp put_reply_context(context, subject, person_name, body, reply) do
    update_context(context, {:replies, subject}, fn replies ->
      Map.put(replies, {person_name, body}, reply)
    end)
  end

  defp update_context(context, collection_key, fun) do
    Map.update(context, collection_key, fun.(%{}), fun)
  end

  defp reply_context(reply, person_name, subject) do
    %{
      body: reply.body,
      club_id: reply.club_id,
      conversation_id: reply.conversation_id,
      message_id: reply.message_id,
      sender_id: reply.sender_id,
      sender_name: person_name,
      subject: subject
    }
  end

  defp email_address?({_name, address}, expected), do: same_email?(address, expected)
  defp email_address?(address, expected) when is_binary(address), do: same_email?(address, expected)

  defp same_email?(left, right), do: String.downcase(left) == String.downcase(right)

  defp parse_person_list(text) do
    text
    |> String.replace(~r/,?\s+and\s+/, ", ")
    |> String.split(~r/\s*,\s*/, trim: true)
  end

  defp scenario_suffix(context) do
    context
    |> Map.get(:scenario_name, "scenario")
    |> :erlang.phash2(1_000_000)
    |> Integer.to_string(36)
  end
end
