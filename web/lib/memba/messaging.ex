defmodule Memba.Messaging do
  @moduledoc """
  Public application service API for the Messaging bounded context.
  """

  alias Commanded.Commands.ExecutionResult
  alias Memba.ID
  alias Memba.Membership
  alias Memba.Messaging.App
  alias Memba.Messaging.Commands.AcceptInboundClubEmail
  alias Memba.Messaging.Commands.FollowConversation
  alias Memba.Messaging.Commands.PostMessageReply
  alias Memba.Messaging.Commands.RejectInboundClubEmail
  alias Memba.Messaging.Commands.ReportEmailDeliveryBounced
  alias Memba.Messaging.Commands.ReportEmailDeliveryDelayed
  alias Memba.Messaging.Commands.ReportEmailDeliveryDelivered
  alias Memba.Messaging.Commands.ReportEmailDeliverySpamComplaint
  alias Memba.Messaging.Commands.ReceiveInboundEmail
  alias Memba.Messaging.Commands.SendMessage
  alias Memba.Messaging.Commands.UnfollowConversation
  alias Memba.Messaging.ConversationReference
  alias Memba.Messaging.ConversationFollowers
  alias Memba.Messaging.ConversationStopFollowToken
  alias Memba.Messaging.EmailDeliveryDispatcher
  alias Memba.Messaging.InboundClubAuthorization
  alias Memba.Messaging.InboundClubDestination
  alias Memba.Messaging.InboundClubRejectionEmail
  alias Memba.Messaging.InboundClubSender
  alias Memba.Messaging.InboundEmail
  alias Memba.Messaging.InboundEmailBody
  alias Memba.Messaging.InboundEmailReceipt
  alias Memba.Messaging.OutboundMessageID
  alias Memba.Messaging.Projections.ConversationFollow, as: ConversationFollowProjection
  alias Memba.Messaging.Projections.InboundEmailSource, as: InboundEmailSourceProjection
  alias Memba.Messaging.Projections.MemberEmailDelivery, as: MemberEmailDeliveryProjection
  alias Memba.Messaging.Projections.Message, as: MessageProjection
  alias Memba.Messaging.Projections.MembaStaffEmailDelivery, as: MembaStaffEmailDeliveryProjection
  alias Memba.Messaging.Projections.EmailDelivery, as: EmailDeliveryProjection
  alias Memba.Messaging.Recipient
  alias Memba.Repo

  import Ecto.Query

  @doc """
  Send a message to the active members of a club.

  The service resolves recipients through Membership's public query API, builds
  a `SendMessage` command containing those resolved recipients, and dispatches it
  to the Messaging Commanded application. Provider delivery happens
  asynchronously from projected `EmailDelivery` records.
  """
  def send_club_message(attrs, dispatch_opts \\ [])
      when is_map(attrs) and is_list(dispatch_opts) do
    with {:ok, command} <- send_club_message_command(attrs),
         {:ok, dispatch_result} <- dispatch_command(command, dispatch_opts) do
      dispatch_result
    end
  end

  @doc """
  Post a reply to an existing club-message conversation.

  The caller supplies the reply `:message_id`, root `:conversation_id`, replying
  `:sender_id`, and non-blank `:body`. The reply inherits the root message's
  club and subject, and only a current member of that club may reply.
  """
  def post_message_reply(attrs, dispatch_opts \\ [])
      when is_map(attrs) and is_list(dispatch_opts) do
    with {:ok, command} <- post_message_reply_command(attrs),
         :ok <- authorize_reply_sender(command.club_id, command.sender_id),
         {:ok, dispatch_result} <- dispatch_command(command, dispatch_opts) do
      dispatch_result
    end
  end

  @doc """
  Follow a club-message conversation for reply notifications.

  This command records follow state only. Caller-facing authorization, such as
  ensuring a person is a current club member before opting in from the app, is
  applied by the surfaces that expose this capability.
  """
  def follow_conversation(attrs, dispatch_opts \\ [])
      when is_map(attrs) and is_list(dispatch_opts) do
    with {:ok, command} <- follow_conversation_command(attrs),
         {:ok, dispatch_result} <- dispatch_command(command, dispatch_opts) do
      dispatch_result
    end
  end

  @doc """
  Follow a conversation from an in-app current-member surface.

  The raw `follow_conversation/2` command records follow state for system and
  future email-unsubscribe workflows. Browser surfaces should use this wrapper
  so only current club members can opt in through the app.
  """
  def follow_conversation_as_current_member(attrs, dispatch_opts \\ [])
      when is_map(attrs) and is_list(dispatch_opts) do
    with {:ok, command} <- follow_conversation_command(attrs),
         :ok <- authorize_current_member_conversation_action(command),
         {:ok, dispatch_result} <- dispatch_command(command, dispatch_opts) do
      dispatch_result
    end
  end

  @doc """
  Stop following a club-message conversation.
  """
  def unfollow_conversation(attrs, dispatch_opts \\ [])
      when is_map(attrs) and is_list(dispatch_opts) do
    with {:ok, command} <- unfollow_conversation_command(attrs),
         {:ok, dispatch_result} <- dispatch_command(command, dispatch_opts) do
      dispatch_result
    end
  end

  @doc """
  Stop following a conversation from an in-app current-member surface.

  Email stop-follow links intentionally use the raw unfollow command so former
  members can reduce notifications without signing in. In-app unfollow remains
  limited to current club members.
  """
  def unfollow_conversation_as_current_member(attrs, dispatch_opts \\ [])
      when is_map(attrs) and is_list(dispatch_opts) do
    with {:ok, command} <- unfollow_conversation_command(attrs),
         :ok <- authorize_current_member_conversation_action(command),
         {:ok, dispatch_result} <- dispatch_command(command, dispatch_opts) do
      dispatch_result
    end
  end

  @doc """
  Stop following a conversation from a signed reply-email link.

  The token scopes the action to the intended club, conversation, and member.
  This API intentionally does not require current club membership because it only
  reduces notifications and old emails should remain useful.
  """
  def stop_following_conversation_from_email_token(token, dispatch_opts \\ [])
      when is_list(dispatch_opts) do
    with {:ok, scope} <- ConversationStopFollowToken.verify(token),
         {:ok, root_message} <- fetch_conversation_root(scope.conversation_id),
         :ok <- ensure_stop_follow_scope(root_message, scope),
         :ok <- reconcile_projected_follow_before_unfollow(scope, dispatch_opts) do
      case unfollow_conversation(
             %{
               club_id: scope.club_id,
               conversation_id: scope.conversation_id,
               member_id: scope.member_id
             },
             dispatch_opts
           ) do
        {:error, _reason} = error -> error
        dispatch_result -> {:ok, Map.put(scope, :dispatch_result, dispatch_result)}
      end
    else
      {:error, _reason} -> {:error, :invalid_stop_follow_token}
      nil -> {:error, :invalid_stop_follow_token}
    end
  end

  @doc """
  Build a provider-neutral command for an inbound club-message email.

  Provider webhook adapters should translate provider-specific payloads into
  this API's attrs before later inbound-email handling resolves clubs, authorizes
  senders, creates messages, and records idempotency/audit events.
  """
  def receive_inbound_club_email_command(attrs) when is_map(attrs) do
    with {:ok, inbound_email} <- InboundEmail.new(attrs) do
      {:ok,
       %ReceiveInboundEmail{
         inbound_email_id: InboundEmail.identity(inbound_email),
         inbound_email: inbound_email
       }}
    end
  end

  def receive_inbound_club_email_command(_attrs), do: {:error, :invalid_inbound_email}

  @doc """
  Receive and post a provider-neutral inbound club-message email.

  This wraps the same `send_club_message/2` path used by browser-composed club
  messages, so accepted inbound email creates the same message event, recipient
  delivery events, and pending delivery projections for the dispatcher to hand
  off to the provider.

  Reply-by-email uses Topicbox-style routing: recognized `In-Reply-To` or
  `References` Message-ID values are matched only against outbound Memba emails
  for the addressed club. A recognized same-club header posts through the normal
  conversation reply path; missing, unknown, or different-club headers fall back
  to the existing new club-wide message path. Sender authorization and rejection
  behaviour stay the same for both paths.
  """
  def receive_inbound_club_email(attrs, dispatch_opts \\ [])

  def receive_inbound_club_email(attrs, dispatch_opts)
      when is_map(attrs) and is_list(dispatch_opts) do
    with {:ok, receive_command} <- receive_inbound_club_email_command(attrs),
         {:ok, receive_result} <- dispatch_inbound_email_received(receive_command, dispatch_opts) do
      if duplicate_inbound_email_receipt?(receive_result) do
        duplicate_inbound_email_response(receive_command, receive_result)
      else
        post_first_inbound_club_email(receive_command, dispatch_opts)
      end
    end
  end

  def receive_inbound_club_email(_attrs, _dispatch_opts), do: {:error, :invalid_inbound_email}

  @doc """
  Resolve an inbound club-message email's recipient addresses to a destination club.

  Supports the current whole-club address shape
  `everyone@<club-slug>.<configured inbound domain>`, returning a resolved
  destination with club id and normalized to-address, or a typed rejection reason
  for unsupported recipient addresses and unknown club slugs.
  """
  def resolve_inbound_club_email_destination(inbound_email_or_recipient_addresses) do
    InboundClubDestination.resolve(inbound_email_or_recipient_addresses)
  end

  @doc """
  Resolve an inbound club-message email's sender address to a Membership person.

  Supports primary and alternate email addresses through Membership's public
  email lookup API, returning a resolved sender or a typed rejection reason for
  unknown sender addresses.
  """
  def resolve_inbound_club_email_sender(inbound_email_or_from_address) do
    InboundClubSender.resolve(inbound_email_or_from_address)
  end

  @doc """
  Authorize a resolved inbound sender to post to a resolved club destination.

  Only active members of the destination club may post by email. Known people who
  belong only to another club, or whose destination-club membership is inactive,
  receive a typed rejection reason for later rejection-email handling.
  """
  def authorize_inbound_club_email_sender(sender, destination) do
    InboundClubAuthorization.authorize(sender, destination)
  end

  @doc """
  Report that a email delivery was accepted by the recipient server.
  """
  def report_email_delivery_delivered(attrs, dispatch_opts \\ [])
      when is_map(attrs) and is_list(dispatch_opts) do
    with {:ok, command} <- report_email_delivery_delivered_command(attrs),
         {:ok, dispatch_result} <- dispatch_command(command, dispatch_opts) do
      dispatch_result
    end
  end

  @doc """
  Report that a email delivery was temporarily delayed.
  """
  def report_email_delivery_delayed(attrs, dispatch_opts \\ [])
      when is_map(attrs) and is_list(dispatch_opts) do
    with {:ok, command} <- report_email_delivery_delayed_command(attrs),
         {:ok, dispatch_result} <- dispatch_command(command, dispatch_opts) do
      dispatch_result
    end
  end

  @doc """
  Report that a email delivery bounced.
  """
  def report_email_delivery_bounced(attrs, dispatch_opts \\ [])
      when is_map(attrs) and is_list(dispatch_opts) do
    with {:ok, command} <- report_email_delivery_bounced_command(attrs),
         {:ok, dispatch_result} <- dispatch_command(command, dispatch_opts) do
      dispatch_result
    end
  end

  @doc """
  Report that a recipient marked a delivery as spam.
  """
  def report_email_delivery_spam_complaint(attrs, dispatch_opts \\ [])
      when is_map(attrs) and is_list(dispatch_opts) do
    with {:ok, command} <- report_email_delivery_spam_complaint_command(attrs),
         {:ok, dispatch_result} <- dispatch_command(command, dispatch_opts) do
      dispatch_result
    end
  end

  @doc """
  Fetch a projected message read model by caller-generated UUID.

  Returns `nil` when the ID is absent or is not a valid UUID.
  """
  def get_message(message_id) do
    with {:ok, message_id} <- ID.cast(:message, message_id) do
      Repo.get(MessageProjection, message_id)
    else
      :error -> nil
    end
  end

  @doc """
  List projected messages sent to a club.

  Invalid or missing club IDs return an empty list. Results are ordered by
  insertion time and ID for stable browser/test output.
  """
  def list_messages_for_club(club_id) do
    with {:ok, club_id} <- ID.cast(:club, club_id) do
      MessageProjection
      |> where([message], message.club_id == ^club_id)
      |> order_by([message], asc: message.inserted_at, asc: message.message_id)
      |> Repo.all()
    else
      :error -> []
    end
  end

  @doc """
  List projected root conversations sent to a club.

  Invalid or missing club IDs return an empty list. Results include one row per
  conversation root, a count of projected replies in that conversation, and the
  latest projected replier when replies exist. Conversations are ordered by the
  original root message insertion time, newest first, so newer replies do not
  reorder the overview.
  """
  def list_conversations_for_club(club_id) do
    with {:ok, club_id} <- ID.cast(:club, club_id) do
      club_id
      |> conversations_for_club_query()
      |> Repo.all()
      |> add_latest_replier_names()
    else
      :error -> []
    end
  end

  @doc """
  List the projected conversation containing a message.

  The argument may be the root message ID or any reply message ID. Invalid,
  missing, or orphaned projections return an empty list. Results are ordered with
  the original root message first, followed by replies in projected posted order.
  """
  def list_conversation_messages(message_id) do
    with {:ok, message_id} <- ID.cast(:message, message_id),
         %MessageProjection{} = message <- Repo.get(MessageProjection, message_id),
         {:ok, conversation_id} <- conversation_id_for_message(message),
         %MessageProjection{} <- fetch_conversation_root_projection(conversation_id) do
      MessageProjection
      |> where([message], message.conversation_id == ^conversation_id)
      |> order_by([message],
        asc:
          fragment(
            "CASE WHEN ? = ? THEN 0 ELSE 1 END",
            message.message_id,
            ^conversation_id
          ),
        asc: message.inserted_at,
        asc: message.message_id
      )
      |> Repo.all()
    else
      _invalid_or_missing -> []
    end
  end

  @doc """
  Return a projected follow state for a member in a conversation.

  Invalid IDs or missing follow rows return `nil`.
  """
  def get_conversation_follow(conversation_id, member_id) do
    with {:ok, conversation_id} <- ID.cast(:message, conversation_id),
         {:ok, member_id} <- ID.cast(:person, member_id) do
      Repo.get(
        ConversationFollowProjection,
        ConversationFollowers.follow_id(conversation_id, member_id)
      )
    else
      :error -> nil
    end
  end

  @doc """
  Return whether a member currently follows a conversation.
  """
  def following_conversation?(conversation_id, member_id) do
    case get_conversation_follow(conversation_id, member_id) do
      %ConversationFollowProjection{following: true} -> true
      _not_following -> false
    end
  end

  @doc """
  List current projected followers for a conversation.

  This is the raw Messaging follow state. Delivery eligibility that depends on
  current club membership is applied by reply-delivery code.
  """
  def list_conversation_followers(conversation_id) do
    with {:ok, conversation_id} <- ID.cast(:message, conversation_id) do
      ConversationFollowProjection
      |> where([follow], follow.conversation_id == ^conversation_id and follow.following == true)
      |> order_by([follow], asc: follow.member_id)
      |> Repo.all()
    else
      :error -> []
    end
  end

  @doc """
  List projected messages for the Memba staff operations Messages index.

  Results include club and sender context where the Membership read models can
  provide it. Messaging enriches rows through Membership's public query API so
  it does not depend on Membership projection storage details.
  """
  def list_operator_messages() do
    messages =
      MessageProjection
      |> order_by([message], desc: message.inserted_at, desc: message.message_id)
      |> Repo.all()

    club_summaries =
      messages
      |> Enum.map(& &1.club_id)
      |> Membership.list_club_summaries()

    sender_summaries =
      messages
      |> Enum.map(& &1.sender_id)
      |> Membership.list_person_contact_summaries()

    Enum.map(messages, fn message ->
      club = Map.get(club_summaries, message.club_id, %{})
      sender = Map.get(sender_summaries, message.sender_id, %{})

      %{
        message_id: message.message_id,
        subject: message.subject,
        club_id: message.club_id,
        club_name: Map.get(club, :name),
        club_slug: Map.get(club, :slug),
        sender_id: message.sender_id,
        sender_name: Map.get(sender, :name),
        sender_email: Map.get(sender, :primary_email),
        projected_at: message.inserted_at
      }
    end)
  end

  @doc """
  Fetch a projected email delivery read model by caller-generated UUID.

  Returns `nil` when the ID is absent or is not a valid UUID.
  """
  def get_email_delivery(delivery_id) do
    with {:ok, delivery_id} <- ID.cast(:delivery, delivery_id) do
      Repo.get(EmailDeliveryProjection, delivery_id)
    else
      :error -> nil
    end
  end

  @doc """
  Resolve a persisted outbound RFC Message-ID to its Memba message context.

  `messaging_email_deliveries.outbound_message_id` is non-null and unique, so
  this lookup is deterministic across dispatcher retries, projection replay, and
  inbound reply handling.

  Returns `nil` when the Message-ID is blank, malformed for this lookup, unknown,
  or belongs to a delivery whose message projection is absent.
  """
  def get_outbound_message_reference(rfc_message_id) do
    with message_id when is_binary(message_id) <- OutboundMessageID.normalize(rfc_message_id) do
      EmailDeliveryProjection
      |> join(:inner, [delivery], message in MessageProjection,
        on: message.message_id == delivery.message_id
      )
      |> where([delivery, _message], delivery.outbound_message_id == ^message_id)
      |> select([delivery, message], %{
        outbound_message_id: delivery.outbound_message_id,
        delivery_id: delivery.delivery_id,
        message_id: message.message_id,
        conversation_id: message.conversation_id,
        club_id: message.club_id
      })
      |> Repo.one()
    else
      nil -> nil
    end
  end

  @doc """
  Manually retry provider dispatch for one failed email delivery.

  This internal/operator-facing API does not create message or delivery events.
  It delegates to the supervised dispatch boundary, which retries only deliveries
  currently marked `failed` and persists the resulting delivery status and
  diagnostics.
  """
  def retry_failed_email_delivery(delivery_id) do
    with {:ok, delivery_id} <- ID.cast(:delivery, delivery_id) do
      EmailDeliveryDispatcher.retry_failed_delivery(delivery_id)
    else
      :error -> {:error, :invalid_delivery_id}
    end
  end

  @doc """
  Fetch a projected inbound email source/status record by provider identity.

  This is a support/audit read-model query. Inbound idempotency remains owned by
  the event-sourced inbound email aggregate, not this projection.
  """
  def get_inbound_email_source(provider, provider_message_id)
      when is_binary(provider) and is_binary(provider_message_id) do
    provider = normalize_inbound_source_lookup(provider)
    provider_message_id = normalize_inbound_source_lookup(provider_message_id)

    if provider == "" or provider_message_id == "" do
      nil
    else
      Repo.get_by(InboundEmailSourceProjection,
        provider: provider,
        provider_message_id: provider_message_id
      )
    end
  end

  def get_inbound_email_source(_provider, _provider_message_id), do: nil

  @doc """
  List email email deliveries for a projected message.

  Invalid or missing message IDs return an empty list. Results are ordered by
  recipient name and ID to provide deterministic assertions for acceptance
  plumbing.
  """
  def list_recipient_deliveries(message_id) do
    with {:ok, message_id} <- ID.cast(:message, message_id) do
      EmailDeliveryProjection
      |> where([delivery], delivery.message_id == ^message_id)
      |> order_by([delivery], asc: delivery.recipient_name, asc: delivery.recipient_id)
      |> Repo.all()
    else
      :error -> []
    end
  end

  @doc """
  Fetch a member-facing email delivery read model by delivery UUID.

  Returns `nil` when the ID is absent or is not a valid UUID.
  """
  def get_member_email_delivery(delivery_id) do
    with {:ok, delivery_id} <- ID.cast(:delivery, delivery_id) do
      MemberEmailDeliveryProjection
      |> Repo.get(delivery_id)
      |> normalize_member_email_delivery()
    else
      :error -> nil
    end
  end

  @doc """
  Fetch a member-facing email delivery for a recipient on a message.

  Invalid or missing IDs return `nil`. The status uses the simplified
  member vocabulary: sent, delivered, or delivery problem.
  """
  def get_member_email_delivery(message_id, recipient_id) do
    with {:ok, message_id} <- ID.cast(:message, message_id),
         {:ok, recipient_id} <- ID.cast(:person, recipient_id) do
      Repo.get_by(MemberEmailDeliveryProjection,
        message_id: message_id,
        recipient_id: recipient_id
      )
      |> normalize_member_email_delivery()
    else
      :error -> nil
    end
  end

  @doc """
  List member-facing email email deliveries for a projected message.

  Invalid or missing message IDs return an empty list. Results are ordered by
  recipient name and ID to provide deterministic assertions for acceptance
  plumbing.
  """
  def list_member_email_deliverys(message_id) do
    with {:ok, message_id} <- ID.cast(:message, message_id) do
      from(receipt in MemberEmailDeliveryProjection,
        left_join: deliverability in MembaStaffEmailDeliveryProjection,
        on: deliverability.delivery_id == receipt.delivery_id,
        where: receipt.message_id == ^message_id,
        order_by: [asc: receipt.recipient_name, asc: receipt.recipient_id],
        select_merge: %{reason: deliverability.reason}
      )
      |> Repo.all()
      |> Enum.map(&normalize_member_email_delivery/1)
    else
      :error -> []
    end
  end

  @doc """
  Fetch an Memba staff email delivery read model by delivery UUID.

  Returns `nil` when the ID is absent or is not a valid UUID.
  """
  def get_memba_staff_email_delivery(delivery_id) do
    with {:ok, delivery_id} <- ID.cast(:delivery, delivery_id) do
      MembaStaffEmailDeliveryProjection
      |> Repo.get(delivery_id)
      |> normalize_memba_staff_email_delivery()
    else
      :error -> nil
    end
  end

  @doc """
  Fetch an Memba staff email email delivery for a recipient on a message.

  Invalid or missing IDs return `nil`. This view keeps detailed delivery status
  and reason text for delayed, bounced, and spam complaint reports.
  """
  def get_memba_staff_email_delivery(message_id, recipient_id) do
    with {:ok, message_id} <- ID.cast(:message, message_id),
         {:ok, recipient_id} <- ID.cast(:person, recipient_id) do
      Repo.get_by(MembaStaffEmailDeliveryProjection,
        message_id: message_id,
        recipient_id: recipient_id
      )
      |> normalize_memba_staff_email_delivery()
    else
      :error -> nil
    end
  end

  @doc """
  List Memba-staff-facing email deliveries for the deliveries overview.

  Results include message subject and event timestamp fields populated from the
  messaging projections and are ordered newest event first. Pass
  `message_id: message_id` to narrow the overview to one projected message.
  Invalid options return an empty list.
  """
  def list_operator_deliveries(opts \\ []) do
    if is_list(opts) do
      with {:ok, query} <- operator_deliveries_query(opts) do
        Repo.all(query)
        |> Enum.map(&normalize_memba_staff_email_delivery/1)
      else
        :error -> []
      end
    else
      []
    end
  end

  @doc """
  List Memba staff email email deliveries for a projected message.

  Invalid or missing message IDs return an empty list. Results are ordered by
  recipient name and ID to provide deterministic assertions for acceptance
  plumbing.
  """
  def list_operator_email_deliveries(message_id) do
    with {:ok, message_id} <- ID.cast(:message, message_id) do
      MembaStaffEmailDeliveryProjection
      |> where([deliverability], deliverability.message_id == ^message_id)
      |> order_by([deliverability],
        asc: deliverability.recipient_name,
        asc: deliverability.recipient_id
      )
      |> Repo.all()
      |> Enum.map(&normalize_memba_staff_email_delivery/1)
    else
      :error -> []
    end
  end

  defp normalize_member_email_delivery(nil), do: nil

  defp normalize_member_email_delivery(%MemberEmailDeliveryProjection{} = receipt), do: receipt

  defp normalize_memba_staff_email_delivery(nil), do: nil

  defp normalize_memba_staff_email_delivery(%MembaStaffEmailDeliveryProjection{} = delivery) do
    delivery
  end

  defp conversations_for_club_query(club_id) do
    reply_counts_query =
      from reply in MessageProjection,
        where: reply.club_id == ^club_id and reply.message_id != reply.conversation_id,
        group_by: reply.conversation_id,
        select: %{
          conversation_id: reply.conversation_id,
          reply_count: count(reply.message_id)
        }

    latest_replies_query =
      from reply in MessageProjection,
        where: reply.club_id == ^club_id and reply.message_id != reply.conversation_id,
        distinct: [asc: reply.conversation_id],
        order_by: [asc: reply.conversation_id, desc: reply.inserted_at, desc: reply.message_id],
        select: %{
          conversation_id: reply.conversation_id,
          latest_replier_id: reply.sender_id
        }

    participant_first_replies_query =
      from reply in MessageProjection,
        join: root in MessageProjection,
        on:
          root.club_id == reply.club_id and
            root.message_id == reply.conversation_id and
            root.message_id == root.conversation_id,
        where:
          reply.club_id == ^club_id and
            reply.message_id != reply.conversation_id and
            reply.sender_id != root.sender_id,
        group_by: [reply.conversation_id, reply.sender_id],
        select: %{
          conversation_id: reply.conversation_id,
          sender_id: reply.sender_id,
          first_replied_at: min(reply.inserted_at)
        }

    participants_query =
      from participant in subquery(participant_first_replies_query),
        group_by: participant.conversation_id,
        select: %{
          conversation_id: participant.conversation_id,
          participant_ids:
            fragment(
              "array_agg(? ORDER BY ?, ?)",
              participant.sender_id,
              participant.first_replied_at,
              participant.sender_id
            )
        }

    from root in MessageProjection,
      left_join: reply_counts in subquery(reply_counts_query),
      on: reply_counts.conversation_id == root.message_id,
      left_join: latest_reply in subquery(latest_replies_query),
      on: latest_reply.conversation_id == root.message_id,
      left_join: participants in subquery(participants_query),
      on: participants.conversation_id == root.message_id,
      where: root.club_id == ^club_id and root.message_id == root.conversation_id,
      order_by: [desc: root.inserted_at, desc: root.message_id],
      select: %{
        message: root,
        message_id: root.message_id,
        conversation_id: root.conversation_id,
        club_id: root.club_id,
        sender_id: root.sender_id,
        subject: root.subject,
        body: root.body,
        inserted_at: root.inserted_at,
        updated_at: root.updated_at,
        reply_count: fragment("COALESCE(?, 0)", reply_counts.reply_count),
        latest_replier_id: latest_reply.latest_replier_id,
        participant_ids: fragment("COALESCE(?, ARRAY[]::text[])", participants.participant_ids)
      }
  end

  defp add_latest_replier_names(conversation_rows) do
    replier_summaries =
      conversation_rows
      |> Enum.map(& &1.latest_replier_id)
      |> Enum.reject(&is_nil/1)
      |> Membership.list_person_contact_summaries()

    Enum.map(conversation_rows, fn row ->
      latest_replier_name =
        row.latest_replier_id
        |> then(&Map.get(replier_summaries, &1, %{}))
        |> Map.get(:name)

      Map.put(row, :latest_replier_name, latest_replier_name)
    end)
  end

  defp conversation_id_for_message(%MessageProjection{conversation_id: conversation_id}) do
    case ID.cast(:message, conversation_id) do
      {:ok, conversation_id} -> {:ok, conversation_id}
      :error -> :error
    end
  end

  defp fetch_conversation_root_projection(conversation_id) do
    case Repo.get(MessageProjection, conversation_id) do
      %MessageProjection{message_id: ^conversation_id, conversation_id: ^conversation_id} = root ->
        root

      _missing_or_not_root ->
        nil
    end
  end

  defp operator_deliveries_query(opts) do
    query =
      from deliverability in MembaStaffEmailDeliveryProjection,
        left_join: dispatch in EmailDeliveryProjection,
        on: dispatch.delivery_id == deliverability.delivery_id,
        join: message in MessageProjection,
        on: message.message_id == deliverability.message_id,
        order_by: [desc: deliverability.updated_at, desc: deliverability.delivery_id],
        select_merge: %{
          message_subject: message.subject,
          event_at: deliverability.updated_at,
          dispatch_status: dispatch.status,
          dispatch_attempt_count: dispatch.attempt_count,
          dispatch_latest_error: dispatch.latest_error,
          dispatch_latest_detail: dispatch.latest_detail
        }

    case Keyword.fetch(opts, :message_id) do
      {:ok, message_id} ->
        with {:ok, message_id} <- ID.cast(:message, message_id) do
          {:ok,
           where(query, [deliverability, _message], deliverability.message_id == ^message_id)}
        else
          :error -> :error
        end

      :error ->
        {:ok, query}
    end
  end

  defp normalize_inbound_source_lookup(value) do
    value
    |> String.trim()
    |> String.downcase()
  end

  defp dispatch_command(command, dispatch_opts) do
    case App.dispatch(command, dispatch_opts) do
      :ok -> {:ok, :ok}
      {:ok, _result} = ok -> {:ok, ok}
      {:error, _reason} = error -> error
    end
  end

  defp dispatch_ok(command, dispatch_opts) do
    case dispatch_command(command, dispatch_opts) do
      {:ok, _dispatch_result} -> :ok
      {:error, _reason} = error -> error
    end
  end

  defp dispatch_inbound_email_received(receive_command, dispatch_opts) do
    dispatch_opts = Keyword.put(dispatch_opts, :returning, :execution_result)

    case dispatch_command(receive_command, dispatch_opts) do
      {:ok, {:ok, %ExecutionResult{} = result}} -> {:ok, result}
      {:error, _reason} = error -> error
    end
  end

  defp duplicate_inbound_email_receipt?(%ExecutionResult{events: []}), do: true
  defp duplicate_inbound_email_receipt?(%ExecutionResult{}), do: false

  defp duplicate_inbound_email_response(
         receive_command,
         %ExecutionResult{aggregate_state: %InboundEmailReceipt{} = receipt}
       ) do
    {:ok,
     %{
       inbound_email_id: receive_command.inbound_email_id,
       duplicate?: true,
       status: receipt.status,
       message_id: receipt.message_id,
       rejection_reason: receipt.rejection_reason
     }}
  end

  defp post_first_inbound_club_email(receive_command, dispatch_opts) do
    case resolve_inbound_club_email_destination(receive_command.inbound_email) do
      {:ok, %InboundClubDestination{} = destination} ->
        post_first_inbound_club_email_to_destination(receive_command, destination, dispatch_opts)

      {:error, reason, to_address} ->
        reject_first_inbound_club_email(
          receive_command,
          to_address,
          rejection_reason(reason),
          dispatch_opts
        )
    end
  end

  defp post_first_inbound_club_email_to_destination(
         receive_command,
         %InboundClubDestination{} = destination,
         dispatch_opts
       ) do
    case resolve_inbound_club_email_sender(receive_command.inbound_email) do
      {:ok, %InboundClubSender{} = sender} ->
        post_first_inbound_club_email_from_sender(
          receive_command,
          destination,
          sender,
          dispatch_opts
        )

      {:error, reason, _details} ->
        reject_first_inbound_club_email(
          receive_command,
          destination.to_address,
          rejection_reason(reason),
          dispatch_opts,
          club_name: destination.club_name
        )
    end
  end

  defp post_first_inbound_club_email_from_sender(
         receive_command,
         %InboundClubDestination{} = destination,
         %InboundClubSender{} = sender,
         dispatch_opts
       ) do
    case authorize_inbound_club_email_sender(sender, destination) do
      :ok ->
        post_authorized_first_inbound_club_email(
          receive_command,
          destination,
          sender,
          dispatch_opts
        )

      {:error, reason, _details} ->
        reject_first_inbound_club_email(
          receive_command,
          destination.to_address,
          rejection_reason(reason),
          dispatch_opts,
          club_name: destination.club_name
        )
    end
  end

  defp post_authorized_first_inbound_club_email(
         receive_command,
         %InboundClubDestination{} = destination,
         %InboundClubSender{} = sender,
         dispatch_opts
       ) do
    if inbound_email_has_attachments?(receive_command.inbound_email) do
      reject_first_inbound_club_email(
        receive_command,
        destination.to_address,
        "attachments_not_supported",
        dispatch_opts,
        club_name: destination.club_name
      )
    else
      case InboundEmailBody.normalize_text_body(receive_command.inbound_email) do
        {:ok, body} ->
          accept_first_inbound_club_email_or_reply(
            receive_command,
            destination,
            sender,
            body,
            dispatch_opts
          )

        {:error, :plain_text_required} ->
          reject_first_inbound_club_email(
            receive_command,
            destination.to_address,
            "plain_text_required",
            dispatch_opts,
            club_name: destination.club_name
          )
      end
    end
  end

  defp inbound_email_has_attachments?(%InboundEmail{attachments: [_attachment | _attachments]}),
    do: true

  defp inbound_email_has_attachments?(%InboundEmail{}), do: false

  defp accept_first_inbound_club_email_or_reply(
         receive_command,
         %InboundClubDestination{} = destination,
         %InboundClubSender{} = sender,
         body,
         dispatch_opts
       ) do
    case resolve_inbound_reply_reference(receive_command.inbound_email, destination) do
      %{conversation_id: conversation_id} ->
        accept_first_inbound_club_email_reply(
          receive_command,
          destination,
          sender,
          body,
          conversation_id,
          dispatch_opts
        )

      nil ->
        accept_first_inbound_club_email(
          receive_command,
          destination,
          sender,
          body,
          dispatch_opts
        )
    end
  end

  defp accept_first_inbound_club_email_reply(
         receive_command,
         %InboundClubDestination{} = destination,
         %InboundClubSender{} = sender,
         body,
         conversation_id,
         dispatch_opts
       ) do
    message_id = Memba.ID.generate(:message)

    with :ok <-
           post_inbound_club_message_reply(
             conversation_id,
             sender,
             message_id,
             body,
             dispatch_opts
           ),
         :ok <-
           record_inbound_club_email_accepted(
             receive_command.inbound_email,
             destination,
             sender,
             message_id,
             dispatch_opts
           ) do
      {:ok,
       %{
         inbound_email_id: receive_command.inbound_email_id,
         message_id: message_id,
         conversation_id: conversation_id,
         club_id: destination.club_id,
         sender_id: sender.person_id,
         from_address: sender.from_address,
         to_address: destination.to_address
       }}
    end
  end

  defp accept_first_inbound_club_email(
         receive_command,
         %InboundClubDestination{} = destination,
         %InboundClubSender{} = sender,
         body,
         dispatch_opts
       ) do
    message_id = Memba.ID.generate(:message)

    with :ok <-
           send_inbound_club_message(
             receive_command.inbound_email,
             destination,
             sender,
             message_id,
             body,
             dispatch_opts
           ),
         :ok <-
           record_inbound_club_email_accepted(
             receive_command.inbound_email,
             destination,
             sender,
             message_id,
             dispatch_opts
           ) do
      {:ok,
       %{
         inbound_email_id: receive_command.inbound_email_id,
         message_id: message_id,
         club_id: destination.club_id,
         sender_id: sender.person_id,
         from_address: sender.from_address,
         to_address: destination.to_address
       }}
    end
  end

  defp reject_first_inbound_club_email(
         receive_command,
         to_address,
         rejection_reason,
         dispatch_opts,
         opts \\ []
       ) do
    rejection_email_delivery_reference = ID.generate(:delivery)

    with :ok <-
           record_inbound_club_email_rejected(
             receive_command.inbound_email,
             to_address,
             rejection_reason,
             rejection_email_delivery_reference,
             dispatch_opts
           ),
         :ok <-
           InboundClubRejectionEmail.deliver(
             receive_command.inbound_email,
             to_address,
             rejection_reason,
             rejection_email_delivery_reference,
             opts
           ) do
      {:ok,
       %{
         inbound_email_id: receive_command.inbound_email_id,
         status: :rejected,
         rejection_reason: rejection_reason,
         from_address: receive_command.inbound_email.from_address,
         to_address: to_address,
         rejection_email_delivery_reference: rejection_email_delivery_reference
       }}
    end
  end

  defp send_inbound_club_message(
         %InboundEmail{} = inbound_email,
         %InboundClubDestination{} = destination,
         %InboundClubSender{} = sender,
         message_id,
         body,
         dispatch_opts
       ) do
    case send_club_message(
           %{
             message_id: message_id,
             club_id: destination.club_id,
             sender_id: sender.person_id,
             subject: inbound_email.subject,
             body: body
           },
           dispatch_opts
         ) do
      {:error, _reason} = error -> error
      _send_result -> :ok
    end
  end

  defp post_inbound_club_message_reply(
         conversation_id,
         %InboundClubSender{} = sender,
         message_id,
         body,
         dispatch_opts
       ) do
    case post_message_reply(
           %{
             message_id: message_id,
             conversation_id: conversation_id,
             sender_id: sender.person_id,
             body: body
           },
           dispatch_opts
         ) do
      {:error, _reason} = error -> error
      _reply_result -> :ok
    end
  end

  defp resolve_inbound_reply_reference(
         %InboundEmail{} = inbound_email,
         %InboundClubDestination{} = destination
       ) do
    inbound_email
    |> inbound_reply_message_ids()
    |> Enum.find_value(&same_club_outbound_message_reference(&1, destination))
  end

  defp inbound_reply_message_ids(%InboundEmail{} = inbound_email) do
    in_reply_to_message_ids = inbound_email.in_reply_to_message_ids || []
    references_message_ids = inbound_email.references_message_ids || []

    in_reply_to_message_ids ++ Enum.reverse(references_message_ids)
  end

  defp same_club_outbound_message_reference(message_id, %InboundClubDestination{} = destination) do
    case get_outbound_message_reference(message_id) do
      %{club_id: club_id} = reference when club_id == destination.club_id -> reference
      _unknown_or_other_club -> nil
    end
  end

  defp record_inbound_club_email_accepted(
         %InboundEmail{} = inbound_email,
         %InboundClubDestination{} = destination,
         %InboundClubSender{} = sender,
         message_id,
         dispatch_opts
       ) do
    dispatch_ok(
      %AcceptInboundClubEmail{
        inbound_email_id: InboundEmail.identity(inbound_email),
        inbound_email: inbound_email,
        to_address: destination.to_address,
        club_id: destination.club_id,
        sender_id: sender.person_id,
        message_id: message_id
      },
      dispatch_opts
    )
  end

  defp record_inbound_club_email_rejected(
         %InboundEmail{} = inbound_email,
         to_address,
         rejection_reason,
         rejection_email_delivery_reference,
         dispatch_opts
       ) do
    dispatch_ok(
      %RejectInboundClubEmail{
        inbound_email_id: InboundEmail.identity(inbound_email),
        inbound_email: inbound_email,
        to_address: to_address,
        rejection_reason: rejection_reason,
        rejection_email_delivery_reference: rejection_email_delivery_reference
      },
      dispatch_opts
    )
  end

  defp rejection_reason(reason) when is_atom(reason), do: Atom.to_string(reason)
  defp rejection_reason(reason) when is_binary(reason), do: reason

  defp send_club_message_command(attrs) do
    with {:ok, message_id} <- fetch_required(attrs, :message_id),
         {:ok, club_id} <- fetch_required(attrs, :club_id),
         {:ok, sender_id} <- fetch_required(attrs, :sender_id),
         {:ok, subject} <- fetch_required(attrs, :subject),
         {:ok, body} <- fetch_required(attrs, :body) do
      {:ok,
       %SendMessage{
         message_id: message_id,
         club_id: club_id,
         sender_id: sender_id,
         subject: subject,
         body: body,
         recipients: resolve_recipients(club_id)
       }}
    end
  end

  defp post_message_reply_command(attrs) do
    with {:ok, message_id} <- fetch_required(attrs, :message_id),
         {:ok, conversation_id} <- fetch_required(attrs, :conversation_id),
         {:ok, sender_id} <- fetch_required(attrs, :sender_id),
         {:ok, body} <- fetch_required(attrs, :body),
         {:ok, root_message} <- fetch_conversation_root(conversation_id) do
      {:ok,
       %PostMessageReply{
         message_id: message_id,
         club_id: root_message.club_id,
         sender_id: sender_id,
         conversation_id: conversation_id,
         reply_to_message_id: ConversationReference.reply_to_message_id(conversation_id),
         subject: root_message.subject,
         body: body,
         recipients:
           resolve_reply_recipients(root_message.club_id, conversation_id,
             except_person_id: sender_id
           )
       }}
    end
  end

  defp follow_conversation_command(attrs) do
    with {:ok, club_id} <- fetch_required(attrs, :club_id),
         {:ok, conversation_id} <- fetch_required(attrs, :conversation_id),
         {:ok, member_id} <- fetch_required(attrs, :member_id) do
      {:ok,
       %FollowConversation{
         club_id: club_id,
         conversation_id: conversation_id,
         member_id: member_id
       }}
    end
  end

  defp unfollow_conversation_command(attrs) do
    with {:ok, club_id} <- fetch_required(attrs, :club_id),
         {:ok, conversation_id} <- fetch_required(attrs, :conversation_id),
         {:ok, member_id} <- fetch_required(attrs, :member_id) do
      {:ok,
       %UnfollowConversation{
         club_id: club_id,
         conversation_id: conversation_id,
         member_id: member_id
       }}
    end
  end

  defp report_email_delivery_delivered_command(attrs) do
    with {:ok, message_id} <- fetch_required(attrs, :message_id),
         {:ok, delivery_id} <- fetch_required(attrs, :delivery_id) do
      {:ok, %ReportEmailDeliveryDelivered{message_id: message_id, delivery_id: delivery_id}}
    end
  end

  defp report_email_delivery_delayed_command(attrs) do
    with {:ok, message_id} <- fetch_required(attrs, :message_id),
         {:ok, delivery_id} <- fetch_required(attrs, :delivery_id),
         {:ok, reason} <- fetch_required(attrs, :reason) do
      {:ok,
       %ReportEmailDeliveryDelayed{
         message_id: message_id,
         delivery_id: delivery_id,
         reason: reason
       }}
    end
  end

  defp report_email_delivery_bounced_command(attrs) do
    with {:ok, message_id} <- fetch_required(attrs, :message_id),
         {:ok, delivery_id} <- fetch_required(attrs, :delivery_id),
         {:ok, reason} <- fetch_required(attrs, :reason) do
      {:ok,
       %ReportEmailDeliveryBounced{
         message_id: message_id,
         delivery_id: delivery_id,
         reason: reason
       }}
    end
  end

  defp report_email_delivery_spam_complaint_command(attrs) do
    with {:ok, message_id} <- fetch_required(attrs, :message_id),
         {:ok, delivery_id} <- fetch_required(attrs, :delivery_id),
         {:ok, reason} <- fetch_required(attrs, :reason) do
      {:ok,
       %ReportEmailDeliverySpamComplaint{
         message_id: message_id,
         delivery_id: delivery_id,
         reason: reason
       }}
    end
  end

  defp fetch_required(attrs, key) do
    string_key = Atom.to_string(key)

    case attrs do
      %{^key => value} -> {:ok, value}
      %{^string_key => value} -> {:ok, value}
      _attrs -> {:error, {:missing_required_attribute, key}}
    end
  end

  defp fetch_conversation_root(conversation_id) do
    with {:ok, conversation_id} <- ID.cast(:message, conversation_id) do
      case Repo.get(MessageProjection, conversation_id) do
        %MessageProjection{} = message -> {:ok, message}
        nil -> {:error, :conversation_not_found}
      end
    else
      :error -> {:error, :invalid_conversation_id}
    end
  end

  defp authorize_reply_sender(club_id, sender_id) do
    if Membership.active_member_of_club?(club_id, sender_id) do
      :ok
    else
      {:error, :not_current_member}
    end
  end

  defp authorize_current_member_conversation_action(command) do
    with :ok <- authorize_reply_sender(command.club_id, command.member_id),
         {:ok, root_message} <- fetch_conversation_root(command.conversation_id) do
      if root_message.club_id == command.club_id do
        :ok
      else
        {:error, :conversation_not_found}
      end
    end
  end

  defp ensure_stop_follow_scope(
         %MessageProjection{club_id: club_id, message_id: conversation_id},
         %{
           club_id: club_id,
           conversation_id: conversation_id
         }
       ) do
    :ok
  end

  defp ensure_stop_follow_scope(%MessageProjection{}, _scope), do: {:error, :wrong_scope}

  defp reconcile_projected_follow_before_unfollow(scope, dispatch_opts) do
    if following_conversation?(scope.conversation_id, scope.member_id) do
      case follow_conversation(
             %{
               club_id: scope.club_id,
               conversation_id: scope.conversation_id,
               member_id: scope.member_id
             },
             dispatch_opts
           ) do
        {:error, _reason} = error -> error
        _dispatch_result -> :ok
      end
    else
      :ok
    end
  end

  defp resolve_recipients(club_id, opts \\ []) do
    except_person_id = Keyword.get(opts, :except_person_id)

    club_id
    |> Membership.list_active_members_of_club()
    |> Enum.reject(&(&1.id == except_person_id))
    |> Enum.map(&resolved_recipient/1)
  end

  defp resolve_reply_recipients(club_id, conversation_id, opts) do
    except_person_id = Keyword.get(opts, :except_person_id)
    follower_ids = current_follower_ids(club_id, conversation_id)

    club_id
    |> Membership.list_active_members_of_club()
    |> Enum.filter(&MapSet.member?(follower_ids, &1.id))
    |> Enum.reject(&(&1.id == except_person_id))
    |> Enum.map(&resolved_recipient/1)
  end

  defp current_follower_ids(club_id, conversation_id) do
    conversation_id
    |> list_conversation_followers()
    |> Enum.filter(&(&1.club_id == club_id))
    |> Enum.map(& &1.member_id)
    |> MapSet.new()
  end

  defp resolved_recipient(%{id: person_id, name: name, email: email}) do
    %Recipient{
      delivery_id: Memba.ID.generate(:delivery),
      person_id: person_id,
      name: name,
      email: email
    }
  end
end
