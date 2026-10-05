defmodule Memba.Messaging do
  @moduledoc """
  Public application service API for the Messaging bounded context.
  """

  alias Commanded.Commands.ExecutionResult
  alias Memba.ID
  alias Memba.Membership
  alias Memba.Membership.SystemGroups
  alias Memba.Messaging.App
  alias Memba.Messaging.AuthorizationCheckpoint
  alias Memba.Messaging.CommandDispatch
  alias Memba.Messaging.SendClubMessage
  alias Memba.Messaging.PostMemberMessageReply
  alias Memba.Messaging.ReplyCommand
  alias Memba.Messaging.Commands.AcceptInboundClubEmail
  alias Memba.Messaging.Commands.FollowConversation
  alias Memba.Messaging.Commands.PostMessageReply
  alias Memba.Messaging.Commands.RejectInboundClubEmail
  alias Memba.Messaging.Commands.ReceiveInboundEmail
  alias Memba.Messaging.Commands.RequestGroupAccess
  alias Memba.Messaging.Commands.SendMessage
  alias Memba.Messaging.Commands.UnfollowConversation
  alias Memba.Messaging.ConversationAccess
  alias Memba.Messaging.ConversationGroupAccess
  alias Memba.Messaging.ConversationAudience
  alias Memba.Messaging.ConversationFollowQueries
  alias Memba.Messaging.ConversationGroupAccessQueries
  alias Memba.Messaging.ConversationListing
  alias Memba.Messaging.ConversationStopFollowToken
  alias Memba.Messaging.CurrentMemberConversationFollow
  alias Memba.Messaging.EmailDeliveryReport
  alias Memba.Messaging.EveryoneConversationAccessBackfillQueries
  alias Memba.Messaging.DeliveryQueries
  alias Memba.Messaging.Events.InboundClubEmailRejected
  alias Memba.Messaging.GroupEmailPostingPolicy
  alias Memba.Messaging.InboundClubEmailPreparation
  alias Memba.Messaging.InboundClubDestination
  alias Memba.Messaging.InboundClubRejectionEmail
  alias Memba.Messaging.InboundClubSender
  alias Memba.Messaging.InboundEmail
  alias Memba.Messaging.InboundEmailBody
  alias Memba.Messaging.InboundEmailReceipt
  alias Memba.Messaging.Message
  alias Memba.Messaging.MessageQueries
  alias Memba.Messaging.OutboundMessageID

  alias Memba.Messaging.Projectors.ConversationGroupAccess,
    as: ConversationGroupAccessProjector

  alias Memba.Messaging.Projectors.ConversationFollow,
    as: ConversationFollowProjector

  alias Memba.Messaging.Projections.InboundEmailSource, as: InboundEmailSourceProjection
  alias Memba.Messaging.Projections.Message, as: MessageProjection
  alias Memba.Messaging.Projections.EmailDelivery, as: EmailDeliveryProjection
  alias Memba.Messaging.Recipient
  alias Memba.Repo
  alias MembaWeb.ClubSite

  import Ecto.Query

  @doc """
  Send a message to the active members of a club conversation group.

  The service resolves recipients through Membership's public query API, builds
  a `SendMessage` command containing those resolved recipients, and dispatches it
  to the Messaging Commanded application. The audience defaults to the club's
  Everyone group when `:audience_group_id` is omitted. The audience must resolve
  to a group owned by the supplied club before recipients are loaded or a command
  is built. Provider delivery happens asynchronously from projected
  `EmailDelivery` records.
  """
  def send_club_message(attrs, dispatch_opts \\ [])
      when is_map(attrs) and is_list(dispatch_opts) do
    with {:ok, command} <- send_club_message_command(attrs),
         {:ok, dispatch_result} <- dispatch_command(command, dispatch_opts) do
      dispatch_result
    end
  end

  @doc """
  Ask the club's Admin group to add an active member to a custom group.

  The caller supplies only a stable `:message_id`, authenticated `:club_id` and
  `:requester_person_id`, and target `:group_id`. At a stable authorization
  checkpoint, Membership authoritatively resolves the current requester, club,
  target, participation, and current Admin recipients. Messaging then derives
  the fixed subject, body, club-hosted targeted-add URL, and Admin destination
  before dispatching the existing `SendMessage` constituent command.

  The request itself is not routed or persisted. Provider delivery remains
  asynchronous, and a successful result confirms only ordinary message
  acceptance.
  """
  def request_group_access(attrs, dispatch_opts \\ [])
      when is_map(attrs) and is_list(dispatch_opts) do
    with {:ok, request} <- request_group_access_command(attrs),
         {:ok, command} <-
           authorize_at_stable_checkpoint(fn ->
             request_group_access_send_command(request)
           end),
         {:ok, dispatch_result} <- dispatch_command(command, dispatch_opts) do
      dispatch_result
    end
  end

  @doc """
  Send a club message from an in-app current-member surface.

  Unlike inbound email posting, browser composition requires the sender to
  retain active membership in the selected audience group. The Membership
  aggregate is rechecked at a stable event-store checkpoint before dispatch, so
  a committed departure cannot be accepted through stale projections. That
  successful stable check is the action's membership-ordering point: a departure
  committed before it is observed and denies the action; one committed after it
  races with an action already authorized for dispatch.
  """
  def send_club_message_as_current_member(attrs, dispatch_opts \\ [])
      when is_map(attrs) and is_list(dispatch_opts) do
    with {:ok, command} <- SendClubMessage.prepare_current_member(attrs),
         {:ok, dispatch_result} <- CommandDispatch.dispatch(command, dispatch_opts) do
      dispatch_result
    end
  end

  @doc """
  Post a reply to an existing club-message conversation.

  The caller supplies the reply `:message_id`, root `:conversation_id`, replying
  `:sender_id`, and non-blank `:body`. The reply inherits the root message's
  club and subject. Reply authorization requires the sender to hold active
  membership in a group that has write access to the root conversation. The
  successful stable authorization check is the membership-ordering point, with
  a later concurrent departure racing an action already authorized for dispatch.
  """
  def post_message_reply(attrs, dispatch_opts \\ [])
      when is_map(attrs) and is_list(dispatch_opts) do
    with {:ok, command} <- PostMemberMessageReply.prepare(attrs),
         {:ok, dispatch_result} <- CommandDispatch.dispatch(command, dispatch_opts) do
      dispatch_result
    end
  end

  @doc """
  Grant a club-scoped group read or write access to an existing root conversation.

  This API is intended for system/backfill use. It waits specifically for the
  conversation-access projector so callers can query the grant immediately after
  the function returns without waiting for unrelated strong handlers.
  """
  def grant_conversation_access_to_group(attrs, dispatch_opts \\ [])
      when is_map(attrs) and is_list(dispatch_opts) do
    dispatch_opts =
      Keyword.put_new(dispatch_opts, :consistency, [ConversationGroupAccessProjector])

    with {:ok, command} <- ConversationGroupAccess.prepare_grant(attrs),
         {:ok, dispatch_result} <- dispatch_command(command, dispatch_opts) do
      dispatch_result
    end
  end

  @doc """
  Grant the first group access to a legacy root conversation only when none exists.

  Unlike the general grant API, the aggregate treats this as a no-op whenever
  any group already has access. This makes legacy backfill safe even when its
  read-model scan races projection of a newly created private conversation.
  """
  def grant_initial_conversation_access_to_group(attrs, dispatch_opts \\ [])
      when is_map(attrs) and is_list(dispatch_opts) do
    dispatch_opts =
      Keyword.put_new(dispatch_opts, :consistency, [ConversationGroupAccessProjector])

    with {:ok, command} <- ConversationGroupAccess.prepare_initial_grant(attrs),
         {:ok, dispatch_result} <- dispatch_command(command, dispatch_opts) do
      dispatch_result
    end
  end

  @doc """
  Revoke a club-scoped group's access to an existing root conversation.

  The operation is idempotent and waits specifically for the conversation-access
  projector unless the caller explicitly supplies another consistency option.
  """
  def revoke_conversation_access_from_group(attrs, dispatch_opts \\ [])
      when is_map(attrs) and is_list(dispatch_opts) do
    dispatch_opts =
      Keyword.put_new(dispatch_opts, :consistency, [ConversationGroupAccessProjector])

    with {:ok, command} <- ConversationGroupAccess.prepare_revoke(attrs),
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
  so only people with effective read access through an active group membership
  can opt in through the app.
  """
  def follow_conversation_as_current_member(attrs, dispatch_opts \\ [])
      when is_map(attrs) and is_list(dispatch_opts) do
    with {:ok, command} <- CurrentMemberConversationFollow.prepare_follow(attrs),
         {:ok, dispatch_result} <- CommandDispatch.dispatch(command, dispatch_opts) do
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
  limited to people with effective read access through an active group
  membership.
  """
  def unfollow_conversation_as_current_member(attrs, dispatch_opts \\ [])
      when is_map(attrs) and is_list(dispatch_opts) do
    with {:ok, command} <- CurrentMemberConversationFollow.prepare_unfollow(attrs),
         {:ok, dispatch_result} <- CommandDispatch.dispatch(command, dispatch_opts) do
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
      if completed_duplicate_inbound_email_receipt?(receive_result) do
        duplicate_inbound_email_response(receive_command, receive_result)
      else
        recover_or_post_first_inbound_club_email(receive_command, dispatch_opts)
      end
    end
  end

  def receive_inbound_club_email(_attrs, _dispatch_opts), do: {:error, :invalid_inbound_email}

  @doc """
  Resolve an inbound club-message email's recipient addresses to a destination group.

  Supports `<group-email-slug>@<club-slug>.<configured inbound domain>`, returning
  a resolved destination with club and group identity plus the normalized
  to-address, or a typed rejection reason for unsupported recipient addresses
  and unknown club slugs. Unknown group slugs retain the existing unsupported
  recipient outcome and inbound rejection path.
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

  Applies the fixed, named `:club_members_only` group-email posting policy. Known
  people who belong only to another club or whose destination-club membership is
  inactive receive a typed rejection reason for later rejection-email handling.
  Custom-group roots additionally require current participation in that group;
  system-group posting retains its existing club-wide semantics.
  """
  def authorize_inbound_club_email_sender(sender, destination),
    do: InboundClubEmailPreparation.authorize(sender, destination)

  @doc """
  Report that a email delivery was accepted by the recipient server.
  """
  def report_email_delivery_delivered(attrs, dispatch_opts \\ [])
      when is_map(attrs) and is_list(dispatch_opts) do
    with {:ok, command} <- EmailDeliveryReport.delivered(attrs),
         {:ok, dispatch_result} <- CommandDispatch.dispatch(command, dispatch_opts) do
      dispatch_result
    end
  end

  @doc """
  Report that a email delivery was temporarily delayed.
  """
  def report_email_delivery_delayed(attrs, dispatch_opts \\ [])
      when is_map(attrs) and is_list(dispatch_opts) do
    with {:ok, command} <- EmailDeliveryReport.delayed(attrs),
         {:ok, dispatch_result} <- CommandDispatch.dispatch(command, dispatch_opts) do
      dispatch_result
    end
  end

  @doc """
  Report that a email delivery bounced.
  """
  def report_email_delivery_bounced(attrs, dispatch_opts \\ [])
      when is_map(attrs) and is_list(dispatch_opts) do
    with {:ok, command} <- EmailDeliveryReport.bounced(attrs),
         {:ok, dispatch_result} <- CommandDispatch.dispatch(command, dispatch_opts) do
      dispatch_result
    end
  end

  @doc """
  Report that a recipient marked a delivery as spam.
  """
  def report_email_delivery_spam_complaint(attrs, dispatch_opts \\ [])
      when is_map(attrs) and is_list(dispatch_opts) do
    with {:ok, command} <- EmailDeliveryReport.spam_complaint(attrs),
         {:ok, dispatch_result} <- CommandDispatch.dispatch(command, dispatch_opts) do
      dispatch_result
    end
  end

  @doc """
  Fetch a projected message read model by caller-generated UUID.

  Returns `nil` when the ID is absent or is not a valid UUID.
  """
  def get_message(message_id), do: MessageQueries.get_message(message_id)

  @doc """
  List projected messages sent to a club.

  Invalid or missing club IDs return an empty list. Results are ordered by
  insertion time and ID for stable browser/test output.
  """
  def list_messages_for_club(club_id), do: MessageQueries.list_messages_for_club(club_id)

  @doc """
  List projected root conversations sent to a club.

  Invalid or missing club IDs return an empty list. Results include one row per
  conversation root, a count of projected replies in that conversation, and the
  latest projected replier when replies exist. Conversations are ordered by the
  original root message insertion time, newest first, so newer replies do not
  reorder the overview.
  """
  def list_conversations_for_club(club_id), do: ConversationListing.list_for_club(club_id)

  @doc """
  List projected root conversations readable through a group's access grants.

  Both read and write grants permit reading. Invalid or missing group IDs return
  an empty list. Results have the same overview shape and stable ordering as
  `list_conversations_for_club/1`.

  This query establishes access through the supplied group. Callers remain
  responsible for deciding whether a person may act through that group.
  """
  def list_conversations_for_group(group_id), do: ConversationListing.list_for_group(group_id)

  @doc """
  List the projected conversation containing a message.

  The argument may be the root message ID or any reply message ID. Invalid,
  missing, or orphaned projections return an empty list. Results are ordered with
  the original root message first, followed by replies in projected posted order.
  """
  def list_conversation_messages(message_id),
    do: MessageQueries.list_conversation_messages(message_id)

  @doc """
  List the projected conversation readable through a group's access grant.

  The message argument may identify the root or any reply; access is always
  checked against the root conversation. Both read and write grants permit
  reading. Invalid IDs, missing or orphaned messages, and conversations without
  a matching same-club grant return an empty list.

  This query establishes access through the supplied group. Callers remain
  responsible for deciding whether a person may act through that group.
  """
  def list_conversation_messages_for_group(message_id, group_id),
    do: MessageQueries.list_conversation_messages_for_group(message_id, group_id)

  @doc """
  Return a projected follow state for a member in a conversation.

  Invalid IDs or missing follow rows return `nil`.
  """
  def get_conversation_follow(conversation_id, member_id),
    do: ConversationFollowQueries.get_conversation_follow(conversation_id, member_id)

  @doc """
  Return whether a member currently follows a conversation.
  """
  def following_conversation?(conversation_id, member_id),
    do: ConversationFollowQueries.following_conversation?(conversation_id, member_id)

  @doc """
  Return whether a group has the requested access to a projected conversation.

  The `access_level` may be `:read`, `:write`, `"read"`, or `"write"`. A stored
  `"write"` grant satisfies both read and write checks; a stored `"read"` grant
  satisfies only read checks. Invalid IDs or access levels return `false`.
  """
  def group_has_conversation_access?(conversation_id, group_id, access_level),
    do:
      ConversationGroupAccessQueries.group_has_conversation_access?(
        conversation_id,
        group_id,
        access_level
      )

  @doc """
  Resolve a conversation's one current group audience from its root aggregate.

  Association projections may be used to find candidates, but authorization and
  dispatch use this event-sourced decision. Missing and multi-group audiences
  fail closed.
  """
  def resolve_conversation_audience(conversation_id),
    do: ConversationGroupAccessQueries.resolve_conversation_audience(conversation_id)

  @doc """
  Return whether a person has the requested access to a projected conversation.

  The message argument may identify the root or any reply; access is always
  checked against the same-club root conversation. The person's active groups
  are resolved through Membership's public query API and intersected with the
  root's group grants. A write grant satisfies a read request, while a read
  grant does not satisfy a write request.

  Invalid IDs or access levels, missing or orphaned messages, club mismatches,
  inactive memberships, and conversations without a qualifying grant return
  `false`.
  """
  def member_has_conversation_access?(message_id, club_id, person_id, access_level),
    do:
      ConversationGroupAccessQueries.member_has_conversation_access?(
        message_id,
        club_id,
        person_id,
        access_level
      )

  @doc """
  Return one keyset page of legacy root conversations with no group access.

  The page scans projected root messages in ascending `message_id` order and
  returns plain maps only for conversations with no projected access grant. Such
  conversations predate explicit audiences and therefore need an Everyone write
  grant. A conversation that already has Admin or any other audience must never
  be widened to Everyone. `cursor` is the last scanned `message_id` from a
  previous page; callers keep it in process only and may safely restart from
  `nil`.
  """
  def list_everyone_conversation_access_backfill_page(cursor \\ nil, limit \\ 1_000),
    do:
      EveryoneConversationAccessBackfillQueries.list_everyone_conversation_access_backfill_page(
        cursor,
        limit
      )

  @doc """
  List current projected followers for a conversation.

  This is the raw Messaging follow state. Delivery eligibility that depends on
  current participation in the conversation's group is applied when a reply is
  posted.
  """
  def list_conversation_followers(conversation_id),
    do: ConversationFollowQueries.list_conversation_followers(conversation_id)

  @doc """
  List projected messages for the Memba staff operations Messages index.

  Results include club and sender context where the Membership read models can
  provide it. Messaging enriches rows through Membership's public query API so
  it does not depend on Membership projection storage details.
  """
  def list_operator_messages(), do: MessageQueries.list_operator_messages()

  @doc """
  Fetch a projected email delivery read model by caller-generated UUID.

  Returns `nil` when the ID is absent or is not a valid UUID.
  """
  def get_email_delivery(delivery_id), do: DeliveryQueries.get_email_delivery(delivery_id)

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
  Manual retries are disabled. Handoff recovery is owned by the dispatcher;
  a person must not create another provider handoff.
  """
  def retry_failed_email_delivery(delivery_id) do
    with {:ok, _valid_id} <- ID.cast(:delivery, delivery_id) do
      {:error, :manual_retry_disabled}
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
  def list_recipient_deliveries(message_id),
    do: DeliveryQueries.list_recipient_deliveries(message_id)

  @doc """
  Fetch a member-facing email delivery read model by delivery UUID.

  Returns `nil` when the ID is absent or is not a valid UUID.
  """
  def get_member_email_delivery(delivery_id),
    do: DeliveryQueries.get_member_email_delivery(delivery_id)

  @doc """
  Fetch a member-facing email delivery for a recipient on a message.

  Invalid or missing IDs return `nil`. The status uses the simplified
  member vocabulary: sent, delivered, or delivery problem.
  """
  def get_member_email_delivery(message_id, recipient_id),
    do: DeliveryQueries.get_member_email_delivery(message_id, recipient_id)

  @doc """
  List member-facing email email deliveries for a projected message.

  Invalid or missing message IDs return an empty list. Results are ordered by
  recipient name and ID to provide deterministic assertions for acceptance
  plumbing.
  """
  def list_member_email_deliverys(message_id),
    do: DeliveryQueries.list_member_email_deliverys(message_id)

  @doc """
  Fetch an Memba staff email delivery read model by delivery UUID.

  Returns `nil` when the ID is absent or is not a valid UUID.
  """
  def get_memba_staff_email_delivery(delivery_id),
    do: DeliveryQueries.get_memba_staff_email_delivery(delivery_id)

  @doc """
  Fetch an Memba staff email email delivery for a recipient on a message.

  Invalid or missing IDs return `nil`. This view keeps detailed delivery status
  and reason text for delayed, bounced, and spam complaint reports.
  """
  def get_memba_staff_email_delivery(message_id, recipient_id),
    do: DeliveryQueries.get_memba_staff_email_delivery(message_id, recipient_id)

  @doc """
  List Memba-staff-facing email deliveries for the deliveries overview.

  Results include message subject and event timestamp fields populated from the
  messaging projections and are ordered newest event first. Pass
  `message_id: message_id` to narrow the overview to one projected message.
  Invalid options return an empty list.
  """
  def list_operator_deliveries(opts \\ []), do: DeliveryQueries.list_operator_deliveries(opts)

  @doc """
  List Memba staff email email deliveries for a projected message.

  Invalid or missing message IDs return an empty list. Results are ordered by
  recipient name and ID to provide deterministic assertions for acceptance
  plumbing.
  """
  def list_operator_email_deliveries(message_id),
    do: DeliveryQueries.list_operator_email_deliveries(message_id)

  defp normalize_inbound_source_lookup(value) do
    value
    |> String.trim()
    |> String.downcase()
  end

  defp dispatch_command(command, dispatch_opts),
    do: CommandDispatch.dispatch(command, dispatch_opts)

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

  defp completed_duplicate_inbound_email_receipt?(%ExecutionResult{
         events: [],
         aggregate_state: %InboundEmailReceipt{status: status}
       })
       when status in [:accepted, :rejected],
       do: true

  defp completed_duplicate_inbound_email_receipt?(%ExecutionResult{}), do: false

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

  defp recover_or_post_first_inbound_club_email(receive_command, dispatch_opts) do
    message_id = inbound_message_id(receive_command)

    case App.aggregate_state(Message, message_id) do
      %Message{message_id: ^message_id} = message ->
        recover_committed_inbound_message(
          message,
          receive_command,
          dispatch_opts
        )

      _missing_message ->
        post_first_inbound_club_email(receive_command, dispatch_opts)
    end
  end

  defp post_first_inbound_club_email(receive_command, dispatch_opts) do
    case InboundClubEmailPreparation.prepare(receive_command.inbound_email) do
      {:ok, destination, sender} ->
        post_authorized_first_inbound_club_email(
          receive_command,
          destination,
          sender,
          dispatch_opts
        )

      {:reject, to_address, reason, opts} ->
        reject_first_inbound_club_email(receive_command, to_address, reason, dispatch_opts, opts)

      {:error, _reason} = error ->
        error
    end
  end

  defp recover_committed_inbound_message(
         %Message{} = message,
         receive_command,
         dispatch_opts
       ) do
    with :ok <- confirm_matching_committed_inbound_message_content(message, receive_command),
         {:ok, %InboundClubDestination{} = destination} <-
           resolve_inbound_club_email_destination(receive_command.inbound_email),
         {:ok, %InboundClubSender{} = sender} <-
           resolve_inbound_club_email_sender(receive_command.inbound_email),
         :ok <-
           confirm_matching_committed_inbound_message_context(
             message,
             receive_command,
             destination,
             sender
           ),
         :ok <-
           record_inbound_club_email_accepted(
             receive_command.inbound_email,
             destination,
             sender,
             message.message_id,
             dispatch_opts
           ) do
      {:ok,
       accepted_inbound_email_response(
         receive_command,
         destination,
         sender,
         message
       )}
    end
  end

  defp confirm_matching_committed_inbound_message_content(%Message{} = message, receive_command) do
    with {:ok, body} <- InboundEmailBody.normalize_text_body(receive_command.inbound_email),
         true <- message.message_id == inbound_message_id(receive_command),
         true <-
           committed_inbound_message_subject_matches?(message, receive_command.inbound_email),
         true <- message.body == body do
      :ok
    else
      _mismatch -> {:error, :inbound_message_mismatch}
    end
  end

  defp confirm_matching_committed_inbound_message_context(
         %Message{} = message,
         receive_command,
         destination,
         sender
       ) do
    with true <- message.club_id == destination.club_id,
         true <- message.sender_id == sender.person_id,
         true <-
           committed_inbound_message_destination_matches?(
             message,
             receive_command,
             destination
           ) do
      :ok
    else
      _mismatch -> {:error, :inbound_message_mismatch}
    end
  end

  defp committed_inbound_message_subject_matches?(
         %Message{
           message_id: message_id,
           conversation_id: message_id,
           subject: subject
         },
         %InboundEmail{subject: subject}
       ),
       do: true

  defp committed_inbound_message_subject_matches?(
         %Message{message_id: message_id, conversation_id: conversation_id, subject: subject},
         %InboundEmail{}
       )
       when message_id != conversation_id do
    case App.aggregate_state(Message, conversation_id) do
      %Message{
        message_id: ^conversation_id,
        conversation_id: ^conversation_id,
        subject: ^subject
      } ->
        true

      _missing_or_different_root ->
        false
    end
  end

  defp committed_inbound_message_subject_matches?(%Message{}, %InboundEmail{}), do: false

  defp committed_inbound_message_destination_matches?(
         %Message{
           message_id: message_id,
           conversation_id: message_id,
           group_access: group_access
         },
         _receive_command,
         destination
       ) do
    Map.get(group_access, destination.group_id) == "write"
  end

  defp committed_inbound_message_destination_matches?(
         %Message{conversation_id: conversation_id},
         receive_command,
         destination
       ) do
    case resolve_inbound_reply_reference(receive_command.inbound_email, destination) do
      %{conversation_id: ^conversation_id} -> true
      _missing_or_different_reference -> false
    end
  end

  defp accepted_inbound_email_response(receive_command, destination, sender, message) do
    response = %{
      inbound_email_id: receive_command.inbound_email_id,
      message_id: message.message_id,
      club_id: destination.club_id,
      sender_id: sender.person_id,
      from_address: sender.from_address,
      to_address: destination.to_address
    }

    if message.conversation_id == message.message_id do
      response
    else
      Map.put(response, :conversation_id, message.conversation_id)
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
    message_id = inbound_message_id(receive_command)

    case post_inbound_club_message_reply(
           conversation_id,
           sender,
           message_id,
           body,
           dispatch_opts
         ) do
      :ok ->
        with :ok <-
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

      {:error, :not_current_member} ->
        reject_first_inbound_club_email(
          receive_command,
          destination.to_address,
          "not_current_member",
          dispatch_opts,
          club_name: destination.club_name
        )

      {:error, _reason} = error ->
        error
    end
  end

  defp accept_first_inbound_club_email(
         receive_command,
         %InboundClubDestination{} = destination,
         %InboundClubSender{} = sender,
         body,
         dispatch_opts
       ) do
    message_id = inbound_message_id(receive_command)

    case send_inbound_club_message(
           receive_command.inbound_email,
           destination,
           sender,
           message_id,
           body,
           dispatch_opts
         ) do
      :ok ->
        with :ok <-
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

      {:error, :sender_not_active_member, _details} ->
        reject_first_inbound_club_email(
          receive_command,
          destination.to_address,
          "sender_not_active_member",
          dispatch_opts,
          club_name: destination.club_name
        )

      {:error, _reason} = error ->
        error
    end
  end

  defp reject_first_inbound_club_email(
         receive_command,
         to_address,
         rejection_reason,
         dispatch_opts,
         opts
       ) do
    rejection_email_delivery_reference = ID.generate(:delivery)

    case record_inbound_club_email_rejected(
           receive_command.inbound_email,
           to_address,
           rejection_reason,
           rejection_email_delivery_reference,
           dispatch_opts
         ) do
      {:ok, :recorded} ->
        with :ok <-
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

      {:ok, {:duplicate, %ExecutionResult{} = result}} ->
        duplicate_inbound_email_response(receive_command, result)

      {:error, _reason} = error ->
        error
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
    attrs = %{
      message_id: message_id,
      club_id: destination.club_id,
      sender_id: sender.person_id,
      audience_group_id: destination.group_id,
      subject: inbound_email.subject,
      body: body
    }

    with {:ok, command} <-
           authorize_at_stable_checkpoint(fn ->
             with :ok <- GroupEmailPostingPolicy.authorize(sender, destination),
                  {:ok, command} <- send_club_message_command(attrs) do
               {:ok, command}
             end
           end) do
      dispatch_inbound_message_once(command, dispatch_opts)
    end
  end

  defp post_inbound_club_message_reply(
         conversation_id,
         %InboundClubSender{} = sender,
         message_id,
         body,
         dispatch_opts
       ) do
    attrs = %{
      message_id: message_id,
      conversation_id: conversation_id,
      sender_id: sender.person_id,
      body: body
    }

    with {:ok, command} <-
           authorize_at_stable_checkpoint(
             fn ->
               with {:ok, command} <- post_message_reply_command(attrs),
                    :ok <- authorize_reply_sender(command) do
                 {:ok, command}
               end
             end,
             projections: [ConversationFollowProjector]
           ) do
      dispatch_inbound_message_once(command, dispatch_opts)
    end
  end

  defp inbound_message_id(%ReceiveInboundEmail{inbound_email_id: inbound_email_id}) do
    ID.deterministic(:message, [inbound_email_id])
  end

  defp dispatch_inbound_message_once(command, dispatch_opts) do
    case dispatch_ok(command, dispatch_opts) do
      :ok -> :ok
      {:error, :already_sent} -> confirm_matching_inbound_message(command)
      {:error, _reason} = error -> error
    end
  end

  defp confirm_matching_inbound_message(%SendMessage{} = command) do
    case App.aggregate_state(Message, command.message_id) do
      %Message{
        message_id: message_id,
        club_id: club_id,
        sender_id: sender_id,
        conversation_id: message_id,
        group_access: group_access
      }
      when message_id == command.message_id and club_id == command.club_id and
             sender_id == command.sender_id ->
        if Map.get(group_access, command.audience_group_id) == "write" do
          :ok
        else
          {:error, :already_sent}
        end

      _missing_or_different_message ->
        {:error, :already_sent}
    end
  end

  defp confirm_matching_inbound_message(%PostMessageReply{} = command) do
    case App.aggregate_state(Message, command.message_id) do
      %Message{
        message_id: message_id,
        club_id: club_id,
        sender_id: sender_id,
        conversation_id: conversation_id,
        reply_to_message_id: reply_to_message_id
      }
      when message_id == command.message_id and club_id == command.club_id and
             sender_id == command.sender_id and conversation_id == command.conversation_id and
             reply_to_message_id == command.reply_to_message_id ->
        :ok

      _missing_or_different_message ->
        {:error, :already_sent}
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
    command = %RejectInboundClubEmail{
      inbound_email_id: InboundEmail.identity(inbound_email),
      inbound_email: inbound_email,
      to_address: to_address,
      rejection_reason: rejection_reason,
      rejection_email_delivery_reference: rejection_email_delivery_reference
    }

    dispatch_opts = Keyword.put(dispatch_opts, :returning, :execution_result)

    case dispatch_command(command, dispatch_opts) do
      {:ok, {:ok, %ExecutionResult{events: [%InboundClubEmailRejected{} | _events]}}} ->
        {:ok, :recorded}

      {:ok,
       {:ok,
        %ExecutionResult{
          events: [],
          aggregate_state: %InboundEmailReceipt{status: :rejected}
        } = result}} ->
        {:ok, {:duplicate, result}}

      {:error, _reason} = error ->
        error
    end
  end

  defp send_club_message_command(attrs), do: SendClubMessage.prepare(attrs)

  defp request_group_access_command(attrs) do
    with {:ok, message_id} <- fetch_required_id(attrs, :message_id, :message),
         {:ok, club_id} <- fetch_required_id(attrs, :club_id, :club),
         {:ok, requester_person_id} <-
           fetch_required_id(attrs, :requester_person_id, :person),
         {:ok, group_id} <- fetch_required_id(attrs, :group_id, :group) do
      {:ok,
       %RequestGroupAccess{
         operation_intent: Map.get(attrs, "operation_intent"),
         message_id: message_id,
         club_id: club_id,
         requester_person_id: requester_person_id,
         group_id: group_id
       }}
    end
  end

  defp request_group_access_send_command(%RequestGroupAccess{} = request) do
    with {:ok, target} <-
           Membership.resolve_custom_group_target_authoritatively(
             request.club_id,
             request.requester_person_id,
             request.group_id
           ),
         :ok <- reject_current_group_member(target) do
      admin_group_id = SystemGroups.admin_group_id(target.club.club_id)

      {:ok,
       %SendMessage{
         operation_intent: request.operation_intent,
         message_id: request.message_id,
         club_id: target.club.club_id,
         sender_id: target.person.person_id,
         audience_group_id: admin_group_id,
         subject: "Access request: #{target.group.name}",
         body: request_group_access_body(target),
         recipients: resolve_group_recipients(target.club.club_id, admin_group_id)
       }}
    end
  end

  defp reject_current_group_member(%{active_group_member?: false}), do: :ok
  defp reject_current_group_member(%{active_group_member?: true}), do: {:error, :already_member}

  defp request_group_access_body(target) do
    add_url =
      ClubSite.url(
        target.club,
        "/groups/#{target.group.group_id}/members/add/#{target.person.person_id}"
      )

    """
    #{target.person.name} would like to join #{target.group.name}.

    #{target.person.name} asked from #{target.group.name}'s page in #{target.club.name}.

    Add #{target.person.name} to #{target.group.name}:
    #{add_url}

    You'll confirm on the website before #{target.person.name} is added.
    """
  end

  defp post_message_reply_command(attrs) do
    ReplyCommand.prepare(attrs, fn club_id, conversation_id, group_id, sender_id ->
      resolve_reply_recipients(club_id, conversation_id, group_id, except_person_id: sender_id)
    end)
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

  defp fetch_required(attrs, key) do
    string_key = Atom.to_string(key)

    case attrs do
      %{^key => value} -> {:ok, value}
      %{^string_key => value} -> {:ok, value}
      _attrs -> {:error, {:missing_required_attribute, key}}
    end
  end

  defp fetch_required_id(attrs, key, type) do
    with {:ok, value} <- fetch_required(attrs, key) do
      case ID.cast(type, value) do
        {:ok, ^value} -> {:ok, value}
        :error -> {:error, invalid_id_reason(key)}
      end
    end
  end

  defp invalid_id_reason(:conversation_id), do: :invalid_conversation_id
  defp invalid_id_reason(:message_id), do: :invalid_message_id
  defp invalid_id_reason(:club_id), do: :invalid_club_id
  defp invalid_id_reason(:group_id), do: :invalid_group_id
  defp invalid_id_reason(:requester_person_id), do: :invalid_person_id

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

  defp authorize_reply_sender(%PostMessageReply{} = command) do
    case member_has_authoritative_conversation_access?(
           command.conversation_id,
           command.club_id,
           command.sender_id,
           :write
         ) do
      true -> :ok
      false -> {:error, :not_current_member}
    end
  end

  defp authorize_at_stable_checkpoint(authorization, opts \\ []),
    do: AuthorizationCheckpoint.run(authorization, opts)

  defp member_has_authoritative_conversation_access?(
         conversation_id,
         club_id,
         person_id,
         access_level
       ) do
    with {:ok, conversation_id} <- ID.cast(:message, conversation_id),
         {:ok, club_id} <- ID.cast(:club, club_id),
         {:ok, person_id} <- ID.cast(:person, person_id),
         {:ok, access_level} <- ConversationAccess.normalize_access_level(access_level),
         %Message{
           message_id: ^conversation_id,
           club_id: ^club_id,
           group_access: group_access
         } <- App.aggregate_state(Message, conversation_id),
         {:ok, group_id, granted_access_level} <-
           ConversationAudience.canonical_group_access(group_access) do
      grant_levels = ConversationAccess.grant_levels_including(access_level)

      granted_access_level in grant_levels and
        Membership.active_member_of_group_authoritatively?(club_id, group_id, person_id)
    else
      _invalid_missing_or_inaccessible -> false
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

  defp resolve_group_recipients(club_id, group_id, opts \\ []) do
    except_person_id = Keyword.get(opts, :except_person_id)

    club_id
    |> Membership.list_active_members_of_group_authoritatively(group_id)
    |> Enum.reject(&(&1.id == except_person_id))
    |> Enum.map(&resolved_recipient/1)
  end

  defp resolve_reply_recipients(club_id, conversation_id, group_id, opts) do
    except_person_id = Keyword.get(opts, :except_person_id)
    follower_ids = current_follower_ids(club_id, conversation_id)

    club_id
    |> Membership.list_active_members_of_group_authoritatively(group_id)
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
