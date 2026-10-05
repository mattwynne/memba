defmodule Memba.Messaging do
  @moduledoc """
  Public application service API for the Messaging bounded context.
  """

  alias Memba.ID
  alias Memba.Messaging.CommandDispatch
  alias Memba.Messaging.SendClubMessage
  alias Memba.Messaging.PostMemberMessageReply
  alias Memba.Messaging.Commands.FollowConversation
  alias Memba.Messaging.Commands.UnfollowConversation
  alias Memba.Messaging.ConversationGroupAccess
  alias Memba.Messaging.ConversationFollowQueries
  alias Memba.Messaging.ConversationGroupAccessQueries
  alias Memba.Messaging.ConversationListing
  alias Memba.Messaging.ConversationStopFollowToken
  alias Memba.Messaging.CurrentMemberConversationFollow
  alias Memba.Messaging.EmailDeliveryReport
  alias Memba.Messaging.EveryoneConversationAccessBackfillQueries
  alias Memba.Messaging.DeliveryQueries
  alias Memba.Messaging.InboundClubEmail
  alias Memba.Messaging.InboundClubEmailPreparation
  alias Memba.Messaging.InboundClubDestination
  alias Memba.Messaging.InboundClubSender
  alias Memba.Messaging.MessageQueries
  alias Memba.Messaging.MessageSourceQueries
  alias Memba.Messaging.RequestGroupAccess

  alias Memba.Messaging.Projectors.ConversationGroupAccess,
    as: ConversationGroupAccessProjector

  alias Memba.Messaging.Projections.Message, as: MessageProjection
  alias Memba.Repo

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
    with {:ok, command} <- RequestGroupAccess.prepare(attrs),
         {:ok, dispatch_result} <- CommandDispatch.dispatch(command, dispatch_opts) do
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
  def receive_inbound_club_email_command(attrs), do: InboundClubEmail.command(attrs)

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

  def receive_inbound_club_email(attrs, dispatch_opts),
    do: InboundClubEmail.receive(attrs, dispatch_opts)

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
  def get_outbound_message_reference(rfc_message_id),
    do: MessageSourceQueries.get_outbound_message_reference(rfc_message_id)

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
  def get_inbound_email_source(provider, provider_message_id),
    do: MessageSourceQueries.get_inbound_email_source(provider, provider_message_id)

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

  defp dispatch_command(command, dispatch_opts),
    do: CommandDispatch.dispatch(command, dispatch_opts)

  defp send_club_message_command(attrs), do: SendClubMessage.prepare(attrs)

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
end
