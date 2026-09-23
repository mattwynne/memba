defmodule Memba.Messaging do
  @moduledoc """
  Public application service API for the Messaging bounded context.
  """

  alias Commanded.Commands.ExecutionResult
  alias Memba.ID
  alias Memba.Membership
  alias Memba.Membership.SystemGroups
  alias Memba.Messaging.App
  alias Memba.Messaging.Commands.AcceptInboundClubEmail
  alias Memba.Messaging.Commands.AuthorizePersonConversationSubscriptionIntent
  alias Memba.Messaging.Commands.CancelPersonConversationSubscriptionIntent
  alias Memba.Messaging.Commands.EndPersonConversationSubscription
  alias Memba.Messaging.Commands.GrantConversationAccessToGroup
  alias Memba.Messaging.Commands.GrantInitialConversationAccessToGroup
  alias Memba.Messaging.Commands.PostMessageReply
  alias Memba.Messaging.Commands.RejectInboundClubEmail
  alias Memba.Messaging.Commands.ReportEmailDeliveryBounced
  alias Memba.Messaging.Commands.RevokeConversationAccessFromGroup
  alias Memba.Messaging.Commands.ReportEmailDeliveryDelayed
  alias Memba.Messaging.Commands.ReportEmailDeliveryDelivered
  alias Memba.Messaging.Commands.ReportEmailDeliverySpamComplaint
  alias Memba.Messaging.Commands.ReceiveInboundEmail
  alias Memba.Messaging.Commands.SendMessage
  alias Memba.Messaging.Commands.StartPersonConversationSubscriptionIntent
  alias Memba.Messaging.ConversationAccess
  alias Memba.Messaging.ConversationAuthorityDescriptor
  alias Memba.Messaging.ConversationReference
  alias Memba.Messaging.ConversationFollowers
  alias Memba.Messaging.ConversationStopFollowToken
  alias Memba.Messaging.EmailDeliveryDispatcher
  alias Memba.Messaging.Events.GroupMembershipSubscriptionRevocationCompleted
  alias Memba.Messaging.Events.InboundClubEmailRejected
  alias Memba.Messaging.GroupEmailPostingPolicy
  alias Memba.Messaging.InboundClubDestination
  alias Memba.Messaging.InboundClubRejectionEmail
  alias Memba.Messaging.InboundClubSender
  alias Memba.Messaging.InboundEmail
  alias Memba.Messaging.InboundEmailBody
  alias Memba.Messaging.InboundEmailReceipt
  alias Memba.Messaging.Message
  alias Memba.Messaging.PersonConversationSubscriptions
  alias Memba.Messaging.OutboundMessageID

  alias Memba.Messaging.Projectors.ConversationGroupAccess,
    as: ConversationGroupAccessProjector

  alias Memba.Messaging.Projectors.PersonConversationSubscriptionsV1,
    as: PersonConversationSubscriptionsProjector

  alias Memba.Messaging.Projections.ConversationGroupAccess, as: ConversationGroupAccessProjection
  alias Memba.Messaging.Projections.ConversationFollow, as: ConversationFollowProjection
  alias Memba.Messaging.Projections.ConversationSubscriptionAuthorization
  alias Memba.Messaging.Projections.GroupMembershipSubscriptionRevocationReceipt
  alias Memba.Messaging.Projections.PersonConversationSubscription
  alias Memba.Messaging.Projections.SystemAuthoritySubscriptionRevocationReceipt
  alias Memba.Messaging.Projections.InboundEmailSource, as: InboundEmailSourceProjection
  alias Memba.Messaging.Projections.MemberEmailDelivery, as: MemberEmailDeliveryProjection
  alias Memba.Messaging.Projections.Message, as: MessageProjection
  alias Memba.Messaging.Projections.MembaStaffEmailDelivery, as: MembaStaffEmailDeliveryProjection
  alias Memba.Messaging.Projections.EmailDelivery, as: EmailDeliveryProjection
  alias Memba.Messaging.Recipient
  alias Memba.ProjectionBarrier
  alias Memba.Repo

  import Ecto.Query

  @default_authorization_stability_timeout 5_000

  @doc """
  Begin and authorize a person-owned conversation subscription.

  This is the product-facing boundary for the new model. It accepts no club,
  membership, GroupMembership, decision, authorization, or subscription IDs.
  Messaging reads canonical conversation access from the root Message aggregate;
  Membership then issues and signs the exact canonical authority decision.
  """
  def begin_person_conversation_subscription(attrs, dispatch_opts \\ [])
      when is_map(attrs) and is_list(dispatch_opts) do
    with :ok <- reject_subscription_provenance(attrs),
         {:ok, person_id} <- fetch_and_cast(attrs, :person_id, :person),
         {:ok, conversation_id} <- fetch_and_cast(attrs, :conversation_id, :message),
         {:ok, subscription_intent_id} <-
           fetch_and_cast(attrs, :subscription_intent_id, :subscription_intent),
         {:ok, source} <- subscription_source(attrs),
         {:ok, decision} <-
           resolve_subscription_authority_decision(
             person_id,
             conversation_id,
             subscription_intent_id,
             source
           ),
         :ok <- run_subscription_authority_issued_hook(decision),
         :ok <- start_and_authorize_subscription(decision, dispatch_opts) do
      :ok
    else
      {:error, _reason} = error -> error
    end
  end

  @doc false
  def valid_conversation_authority_descriptor?(%ConversationAuthorityDescriptor{} = descriptor) do
    expected = conversation_authority_descriptor_signature(descriptor)

    is_binary(descriptor.signature) and
      byte_size(descriptor.signature) == byte_size(expected) and
      Plug.Crypto.secure_compare(descriptor.signature, expected)
  end

  def valid_conversation_authority_descriptor?(_descriptor), do: false

  @doc false
  def issue_fenced_conversation_authority_descriptor(
        person_id,
        conversation_id,
        subscription_intent_id,
        %{cutover_id: cutover_id, event_store_position: position, event_store_schema: schema}
      ) do
    with {:ok, person_id} <- ID.cast(:person, person_id),
         {:ok, conversation_id} <- ID.cast(:message, conversation_id),
         {:ok, subscription_intent_id} <- ID.cast(:subscription_intent, subscription_intent_id),
         true <- is_integer(position) and position >= 0,
         true <- is_binary(schema) and schema != "" do
      {message, stream_version} =
        Memba.EventStoreHistory.stream_forward_at_global_position(
          Memba.Messaging.App,
          Memba.Messaging.EventStore,
          conversation_id,
          position
        )
        |> Enum.reduce({%Memba.Messaging.Message{}, 0}, fn recorded, {message, _version} ->
          {Memba.Messaging.Message.apply(message, recorded.data), recorded.stream_version}
        end)

      if message.message_id == conversation_id and stream_version > 0 do
        descriptor = %ConversationAuthorityDescriptor{
          club_id: message.club_id,
          person_id: person_id,
          subscription_intent_id: subscription_intent_id,
          source: :legacy_reconciliation,
          conversation_id: conversation_id,
          conversation_group_ids: message.group_access |> Map.keys() |> Enum.sort(),
          conversation_stream_version: stream_version,
          reconciliation_fence_id: cutover_id,
          reconciliation_fence_position: position,
          reconciliation_event_store_schema: schema,
          signature: ""
        }

        {:ok, %{descriptor | signature: conversation_authority_descriptor_signature(descriptor)}}
      else
        {:error, :conversation_not_found_at_fence}
      end
    else
      _invalid -> {:error, :invalid_fenced_conversation_authority_request}
    end
  end

  @doc "Return the canonical subscription for one person and conversation."
  def get_person_conversation_subscription(person_id, conversation_id) do
    with {:ok, person_id} <- ID.cast(:person, person_id),
         {:ok, conversation_id} <- ID.cast(:message, conversation_id) do
      Repo.get_by(PersonConversationSubscription,
        person_id: person_id,
        conversation_id: conversation_id
      )
    else
      :error -> nil
    end
  end

  @doc "List a person's effective canonical conversation subscriptions."
  def list_effective_person_conversation_subscriptions(person_id) do
    with {:ok, person_id} <- ID.cast(:person, person_id) do
      PersonConversationSubscription
      |> where([subscription], subscription.person_id == ^person_id and subscription.effective)
      |> order_by([subscription], asc: subscription.conversation_id)
      |> Repo.all()
    else
      :error -> []
    end
  end

  @doc "List canonical grants for a person's conversation subscription."
  def list_person_conversation_subscription_grants(person_id, conversation_id) do
    with {:ok, person_id} <- ID.cast(:person, person_id),
         {:ok, conversation_id} <- ID.cast(:message, conversation_id) do
      ConversationSubscriptionAuthorization
      |> where(
        [authorization],
        authorization.person_id == ^person_id and
          authorization.conversation_id == ^conversation_id
      )
      |> order_by([authorization], asc: authorization.authorization_id)
      |> Repo.all()
    else
      :error -> []
    end
  end

  @doc false
  def group_membership_subscription_revocation_completed?(
        person_id,
        group_membership_id,
        revocation_id
      ) do
    with {:ok, person_id} <- ID.cast(:person, person_id),
         {:ok, group_membership_id} <- ID.cast(:group_membership, group_membership_id),
         {:ok, revocation_id} <- ID.cast(:subscription_revocation, revocation_id) do
      stream_id = PersonConversationSubscriptions.stream_id(person_id)

      case Commanded.EventStore.stream_forward(App, stream_id) do
        {:error, _reason} ->
          false

        stream ->
          Enum.any?(stream, fn
            %{
              data: %GroupMembershipSubscriptionRevocationCompleted{
                person_id: ^person_id,
                group_membership_id: ^group_membership_id,
                revocation_id: ^revocation_id
              }
            } ->
              true

            _recorded_event ->
              false
          end)
      end
    else
      :error -> false
    end
  end

  @doc "Return a durable GroupMembership subscription-revocation receipt."
  def get_group_membership_subscription_revocation_receipt(revocation_id) do
    with {:ok, revocation_id} <- ID.cast(:subscription_revocation, revocation_id) do
      Repo.get(GroupMembershipSubscriptionRevocationReceipt, revocation_id)
    else
      :error -> nil
    end
  end

  @doc false
  def get_system_authority_subscription_revocation_receipt(revocation_id) do
    with {:ok, revocation_id} <- Ecto.UUID.cast(revocation_id) do
      Repo.get(SystemAuthoritySubscriptionRevocationReceipt, revocation_id)
    else
      :error -> nil
    end
  end

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
    with {:ok, command} <- send_club_message_command(attrs) do
      send_root_and_follow(command, dispatch_opts)
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
    with {:ok, command} <-
           authorize_at_stable_checkpoint(fn ->
             with {:ok, command} <- send_club_message_command(attrs),
                  :ok <- authorize_message_sender(command) do
               {:ok, command}
             end
           end) do
      send_root_and_follow(command, dispatch_opts)
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
    with {:ok, command} <-
           authorize_at_stable_checkpoint(fn ->
             with {:ok, command} <- post_message_reply_command(attrs),
                  :ok <- authorize_reply_sender(command) do
               {:ok, command}
             end
           end) do
      send_reply_and_follow(command, dispatch_opts)
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

    with {:ok, command} <- grant_conversation_access_to_group_command(attrs),
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

    with {:ok, command} <- grant_initial_conversation_access_to_group_command(attrs),
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

    with {:ok, command} <- revoke_conversation_access_from_group_command(attrs),
         {:ok, dispatch_result} <- dispatch_command(command, dispatch_opts) do
      dispatch_result
    end
  end

  @doc "Begin and authorize a manual conversation subscription."
  def follow_conversation(attrs, dispatch_opts \\ [])
      when is_map(attrs) and is_list(dispatch_opts) do
    begin_person_conversation_subscription(attrs, dispatch_opts)
  end

  @doc "Follow a conversation from an in-app current-member surface."
  def follow_conversation_as_current_member(attrs, dispatch_opts \\ [])
      when is_map(attrs) and is_list(dispatch_opts) do
    follow_conversation(attrs, dispatch_opts)
  end

  @doc "End every earlier subscription intent and grant for a conversation."
  def unfollow_conversation(attrs, dispatch_opts \\ [])
      when is_map(attrs) and is_list(dispatch_opts) do
    with :ok <- reject_unfollow_provenance(attrs),
         {:ok, person_id} <- fetch_and_cast(attrs, :person_id, :person),
         {:ok, conversation_id} <- fetch_and_cast(attrs, :conversation_id, :message),
         {:ok, unfollow_id} <- fetch_uuid(attrs, :unfollow_id),
         {:ok, dispatch_result} <-
           dispatch_command(
             %EndPersonConversationSubscription{
               person_id: person_id,
               conversation_id: conversation_id,
               unfollow_id: unfollow_id
             },
             dispatch_opts
           ) do
      dispatch_result
    end
  end

  @doc "Stop following from an in-app current-member surface."
  def unfollow_conversation_as_current_member(attrs, dispatch_opts \\ [])
      when is_map(attrs) and is_list(dispatch_opts) do
    with {:ok, person_id} <- fetch_and_cast(attrs, :person_id, :person),
         {:ok, conversation_id} <- fetch_and_cast(attrs, :conversation_id, :message),
         {:ok, club_id} <- canonical_conversation_club_id(conversation_id),
         true <-
           member_has_authoritative_conversation_access?(
             conversation_id,
             club_id,
             person_id,
             :read
           ) do
      unfollow_conversation(attrs, dispatch_opts)
    else
      false -> {:error, :not_current_member}
      {:error, _reason} = error -> error
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
         :ok <- ensure_stop_follow_scope(root_message, scope) do
      case unfollow_conversation(
             %{
               person_id: scope.member_id,
               conversation_id: scope.conversation_id,
               unfollow_id: stable_unfollow_id(scope)
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
  Membership of the addressed group is not required to start a conversation.
  """
  def authorize_inbound_club_email_sender(sender, destination) do
    case authorize_at_stable_checkpoint(fn ->
           case GroupEmailPostingPolicy.authorize(sender, destination) do
             :ok -> {:ok, :authorized}
             {:error, _reason, _details} = error -> error
           end
         end) do
      {:ok, :authorized} -> :ok
      {:error, _reason, _details} = error -> error
      {:error, _reason} = error -> error
    end
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
  List projected root conversations readable through a group's access grants.

  Both read and write grants permit reading. Invalid or missing group IDs return
  an empty list. Results have the same overview shape and stable ordering as
  `list_conversations_for_club/1`.

  This query establishes access through the supplied group. Callers remain
  responsible for deciding whether a person may act through that group.
  """
  def list_conversations_for_group(group_id) do
    with {:ok, group_id} <- ID.cast(:group, group_id) do
      group_id
      |> conversations_for_group_query()
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
         %MessageProjection{} = root <- fetch_conversation_root_projection(conversation_id) do
      list_projected_conversation_messages(conversation_id, root.club_id)
    else
      _invalid_or_missing -> []
    end
  end

  @doc """
  List the projected conversation readable through a group's access grant.

  The message argument may identify the root or any reply; access is always
  checked against the root conversation. Both read and write grants permit
  reading. Invalid IDs, missing or orphaned messages, and conversations without
  a matching same-club grant return an empty list.

  This query establishes access through the supplied group. Callers remain
  responsible for deciding whether a person may act through that group.
  """
  def list_conversation_messages_for_group(message_id, group_id) do
    with {:ok, message_id} <- ID.cast(:message, message_id),
         {:ok, group_id} <- ID.cast(:group, group_id),
         %MessageProjection{} = message <- Repo.get(MessageProjection, message_id),
         {:ok, conversation_id} <- conversation_id_for_message(message),
         %MessageProjection{} = root <- fetch_conversation_root_projection(conversation_id),
         true <- conversation_readable_through_group?(root, group_id) do
      list_projected_conversation_messages(conversation_id, root.club_id)
    else
      _invalid_missing_or_inaccessible -> []
    end
  end

  @doc """
  Return effective follow state during the staged subscription cutover.

  Any canonical person/conversation marker, including an unfollow tombstone,
  wins. Only pairs with no canonical marker fall back to the legacy projection.
  """
  def get_conversation_follow(conversation_id, member_id) do
    with {:ok, conversation_id} <- ID.cast(:message, conversation_id),
         {:ok, member_id} <- ID.cast(:person, member_id) do
      case canonical_subscription_state(member_id, conversation_id) do
        {:canonical, effective?} ->
          canonical_follow_projection(member_id, conversation_id, effective?)

        :no_canonical_marker ->
          Repo.get(
            ConversationFollowProjection,
            ConversationFollowers.follow_id(conversation_id, member_id)
          )
      end
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
  Return whether a group has the requested access to a projected conversation.

  The `access_level` may be `:read`, `:write`, `"read"`, or `"write"`. A stored
  `"write"` grant satisfies both read and write checks; a stored `"read"` grant
  satisfies only read checks. Invalid IDs or access levels return `false`.
  """
  def group_has_conversation_access?(conversation_id, group_id, access_level) do
    with {:ok, conversation_id} <- ID.cast(:message, conversation_id),
         {:ok, group_id} <- ID.cast(:group, group_id),
         {:ok, access_level} <- ConversationAccess.normalize_access_level(access_level) do
      grant_levels = ConversationAccess.grant_levels_including(access_level)

      ConversationGroupAccessProjection
      |> where(
        [access],
        access.conversation_id == ^conversation_id and access.group_id == ^group_id and
          access.access_level in ^grant_levels
      )
      |> Repo.exists?()
    else
      _invalid -> false
    end
  end

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
  def member_has_conversation_access?(message_id, club_id, person_id, access_level) do
    with {:ok, message_id} <- ID.cast(:message, message_id),
         {:ok, club_id} <- ID.cast(:club, club_id),
         {:ok, person_id} <- ID.cast(:person, person_id),
         {:ok, access_level} <- ConversationAccess.normalize_access_level(access_level),
         %MessageProjection{club_id: ^club_id} = message <-
           Repo.get(MessageProjection, message_id),
         {:ok, conversation_id} <- conversation_id_for_message(message),
         %MessageProjection{club_id: ^club_id} <-
           fetch_conversation_root_projection(conversation_id),
         active_group_ids when active_group_ids != [] <-
           active_group_ids_for_member(club_id, person_id) do
      grant_levels = ConversationAccess.grant_levels_including(access_level)

      ConversationGroupAccessProjection
      |> where(
        [access],
        access.conversation_id == ^conversation_id and access.club_id == ^club_id and
          access.group_id in ^active_group_ids and access.access_level in ^grant_levels
      )
      |> Repo.exists?()
    else
      _invalid_missing_or_inaccessible -> false
    end
  end

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
  def list_everyone_conversation_access_backfill_page(cursor \\ nil, limit \\ 1_000) do
    root_conversations =
      MessageProjection
      |> where([message], message.message_id == message.conversation_id)
      |> after_backfill_cursor(:message_id, cursor)
      |> order_by([message], asc: message.message_id)
      |> limit(^normalize_backfill_page_size(limit))
      |> select([message], %{
        conversation_id: message.message_id,
        club_id: message.club_id
      })
      |> Repo.all()

    entries =
      root_conversations
      |> Enum.map(fn root ->
        Map.put(root, :group_id, SystemGroups.everyone_group_id(root.club_id))
      end)
      |> reject_conversations_with_access()

    %{
      entries: entries,
      next_cursor: backfill_next_cursor(root_conversations, :conversation_id),
      source_count: length(root_conversations)
    }
  end

  @doc false
  def delivery_subscription_authorization_effective?(%EmailDeliveryProjection{
        subscription_authorization_id: nil
      }),
      do: true

  def delivery_subscription_authorization_effective?(%EmailDeliveryProjection{} = delivery) do
    subscriptions =
      App.aggregate_state(
        PersonConversationSubscriptions,
        PersonConversationSubscriptions.stream_id(delivery.recipient_id)
      )

    case Map.get(subscriptions.grants, delivery.subscription_authorization_id) do
      %{active: true} = grant ->
        grant.authority_decision_id == delivery.authority_decision_id and
          grant.authority_kind == delivery.authority_kind and
          grant.club_id == delivery.authority_club_id and
          grant.club_membership_id == delivery.authority_club_membership_id and
          grant.group_membership_id == delivery.authority_group_membership_id and
          grant.club_stream_version == delivery.authority_club_stream_version

      _missing_or_revoked ->
        false
    end
  end

  @doc "List effective canonical-or-legacy followers for a conversation."
  def list_conversation_followers(conversation_id) do
    with {:ok, conversation_id} <- ID.cast(:message, conversation_id) do
      conversation_id
      |> effective_follow_candidates()
      |> Enum.map(& &1.follow)
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

  defp canonical_subscription_state(person_id, conversation_id) do
    {state, _grant} = canonical_subscription_evaluation(person_id, conversation_id)
    state
  end

  defp canonical_subscription_evaluation(person_id, conversation_id) do
    subscriptions =
      App.aggregate_state(
        PersonConversationSubscriptions,
        PersonConversationSubscriptions.stream_id(person_id)
      )

    marker? =
      Enum.any?(subscriptions.intents, fn {_id, intent} ->
        intent.conversation_id == conversation_id
      end) or
        Enum.any?(subscriptions.unfollows, fn {_id, unfollow} ->
          unfollow.conversation_id == conversation_id
        end) or
        Enum.any?(subscriptions.grants, fn {_id, grant} ->
          grant.conversation_id == conversation_id
        end)

    if marker? do
      active_grant =
        subscriptions.grants
        |> Map.values()
        |> Enum.filter(&(&1.conversation_id == conversation_id and &1.active))
        |> Enum.sort_by(& &1.authorization_id)
        |> List.first()

      {{:canonical, not is_nil(active_grant)}, active_grant}
    else
      {:no_canonical_marker, nil}
    end
  end

  defp effective_follow_candidates(conversation_id) do
    checkpoint = ProjectionBarrier.current_checkpoint()

    ProjectionBarrier.await!(
      [PersonConversationSubscriptionsProjector, Memba.Messaging.Projectors.ConversationFollow],
      checkpoint: checkpoint,
      timeout: @default_authorization_stability_timeout
    )

    conversation_id
    |> follow_candidate_person_ids()
    |> Enum.map(fn person_id ->
      {state, grant} = canonical_subscription_evaluation(person_id, conversation_id)
      {person_id, state, grant}
    end)
    |> Enum.filter(fn {person_id, state, _grant} ->
      case state do
        {:canonical, effective?} -> effective?
        :no_canonical_marker -> legacy_following?(conversation_id, person_id)
      end
    end)
    |> Enum.map(fn {person_id, _state, grant} ->
      %{follow: canonical_follow_projection(person_id, conversation_id, true), grant: grant}
    end)
    |> Enum.sort_by(& &1.follow.member_id)
  end

  defp follow_candidate_person_ids(conversation_id) do
    legacy_ids =
      ConversationFollowProjection
      |> where([follow], follow.conversation_id == ^conversation_id)
      |> select([follow], follow.member_id)
      |> Repo.all()

    canonical_ids =
      PersonConversationSubscription
      |> where([subscription], subscription.conversation_id == ^conversation_id)
      |> select([subscription], subscription.person_id)
      |> Repo.all()

    Enum.uniq(canonical_ids ++ legacy_ids)
  end

  defp legacy_following?(conversation_id, person_id) do
    case Repo.get_by(ConversationFollowProjection,
           conversation_id: conversation_id,
           member_id: person_id
         ) do
      %ConversationFollowProjection{following: following?} -> following?
      nil -> false
    end
  end

  defp canonical_follow_projection(person_id, conversation_id, effective?) do
    club_id =
      case App.aggregate_state(Message, conversation_id) do
        %Message{club_id: club_id} -> club_id
        _missing -> nil
      end

    %ConversationFollowProjection{
      follow_id: ConversationFollowers.follow_id(conversation_id, person_id),
      club_id: club_id,
      conversation_id: conversation_id,
      member_id: person_id,
      following: effective?
    }
  end

  defp normalize_member_email_delivery(nil), do: nil

  defp normalize_member_email_delivery(%MemberEmailDeliveryProjection{} = receipt), do: receipt

  defp normalize_memba_staff_email_delivery(nil), do: nil

  defp normalize_memba_staff_email_delivery(%MembaStaffEmailDeliveryProjection{} = delivery) do
    delivery
  end

  defp conversations_for_club_query(club_id) do
    {:club, club_id}
    |> conversations_query()
  end

  defp conversations_for_group_query(group_id) do
    {:group, group_id}
    |> conversations_query()
  end

  defp conversations_query(scope) do
    reply_counts_query =
      MessageProjection
      |> where([reply], reply.message_id != reply.conversation_id)
      |> scope_conversation_entries_query(scope)
      |> group_by([reply, ...], [reply.club_id, reply.conversation_id])
      |> select([reply, ...], %{
        club_id: reply.club_id,
        conversation_id: reply.conversation_id,
        reply_count: count(reply.message_id)
      })

    latest_replies_query =
      MessageProjection
      |> where([reply], reply.message_id != reply.conversation_id)
      |> scope_conversation_entries_query(scope)
      |> distinct([reply, ...], asc: reply.club_id, asc: reply.conversation_id)
      |> order_by([reply, ...],
        asc: reply.club_id,
        asc: reply.conversation_id,
        desc: reply.inserted_at,
        desc: reply.message_id
      )
      |> select([reply, ...], %{
        club_id: reply.club_id,
        conversation_id: reply.conversation_id,
        latest_replier_id: reply.sender_id
      })

    participant_first_replies_query =
      MessageProjection
      |> join(:inner, [reply], root in MessageProjection,
        on:
          root.club_id == reply.club_id and
            root.message_id == reply.conversation_id and
            root.message_id == root.conversation_id
      )
      |> where(
        [reply, root],
        reply.message_id != reply.conversation_id and reply.sender_id != root.sender_id
      )
      |> scope_conversation_entries_query(scope)
      |> group_by([reply, ...], [reply.club_id, reply.conversation_id, reply.sender_id])
      |> select([reply, ...], %{
        club_id: reply.club_id,
        conversation_id: reply.conversation_id,
        sender_id: reply.sender_id,
        first_replied_at: min(reply.inserted_at)
      })

    participants_query =
      from participant in subquery(participant_first_replies_query),
        group_by: [participant.club_id, participant.conversation_id],
        select: %{
          club_id: participant.club_id,
          conversation_id: participant.conversation_id,
          participant_ids:
            fragment(
              "array_agg(? ORDER BY ?, ?)",
              participant.sender_id,
              participant.first_replied_at,
              participant.sender_id
            )
        }

    query =
      from root in MessageProjection,
        left_join: reply_counts in subquery(reply_counts_query),
        on:
          reply_counts.club_id == root.club_id and
            reply_counts.conversation_id == root.message_id,
        left_join: latest_reply in subquery(latest_replies_query),
        on:
          latest_reply.club_id == root.club_id and
            latest_reply.conversation_id == root.message_id,
        left_join: participants in subquery(participants_query),
        on:
          participants.club_id == root.club_id and
            participants.conversation_id == root.message_id,
        where: root.message_id == root.conversation_id,
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

    scope_conversation_roots_query(query, scope)
  end

  defp scope_conversation_entries_query(query, {:club, club_id}) do
    where(query, [entry, ...], entry.club_id == ^club_id)
  end

  defp scope_conversation_entries_query(query, {:group, group_id}) do
    read_grant_levels = ConversationAccess.grant_levels_including("read")

    from [entry, ...] in query,
      join: access in ConversationGroupAccessProjection,
      on:
        access.conversation_id == entry.conversation_id and
          access.club_id == entry.club_id,
      where: access.group_id == ^group_id and access.access_level in ^read_grant_levels
  end

  defp scope_conversation_roots_query(query, {:club, club_id}) do
    where(query, [root, _reply_counts, _latest_reply, _participants], root.club_id == ^club_id)
  end

  defp scope_conversation_roots_query(query, {:group, group_id}) do
    read_grant_levels = ConversationAccess.grant_levels_including("read")

    from [root, _reply_counts, _latest_reply, _participants] in query,
      join: access in ConversationGroupAccessProjection,
      on:
        access.conversation_id == root.message_id and
          access.club_id == root.club_id,
      where: access.group_id == ^group_id and access.access_level in ^read_grant_levels
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

  defp conversation_readable_through_group?(
         %MessageProjection{
           message_id: conversation_id,
           conversation_id: conversation_id,
           club_id: club_id
         },
         group_id
       ) do
    read_grant_levels = ConversationAccess.grant_levels_including("read")

    ConversationGroupAccessProjection
    |> where(
      [access],
      access.conversation_id == ^conversation_id and access.club_id == ^club_id and
        access.group_id == ^group_id and access.access_level in ^read_grant_levels
    )
    |> Repo.exists?()
  end

  defp active_group_ids_for_member(club_id, person_id) do
    club_id
    |> Membership.list_active_groups_for_member(person_id)
    |> Enum.map(& &1.group_id)
  end

  defp list_projected_conversation_messages(conversation_id, club_id) do
    MessageProjection
    |> where(
      [message],
      message.conversation_id == ^conversation_id and message.club_id == ^club_id
    )
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

  defp reject_conversations_with_access([]), do: []

  defp reject_conversations_with_access(entries) do
    conversation_ids = Enum.map(entries, & &1.conversation_id)

    conversations_with_access =
      ConversationGroupAccessProjection
      |> where([access], access.conversation_id in ^conversation_ids)
      |> select([access], access.conversation_id)
      |> Repo.all()
      |> MapSet.new()

    Enum.reject(entries, &MapSet.member?(conversations_with_access, &1.conversation_id))
  end

  defp after_backfill_cursor(query, _field, nil), do: query
  defp after_backfill_cursor(query, _field, ""), do: query

  defp after_backfill_cursor(query, field, cursor) when is_binary(cursor) do
    where(query, [row], field(row, ^field) > ^cursor)
  end

  defp normalize_backfill_page_size(limit) when is_integer(limit) and limit > 0, do: limit
  defp normalize_backfill_page_size(_limit), do: 1_000

  defp backfill_next_cursor([], _field), do: nil

  defp backfill_next_cursor(rows, field) do
    rows
    |> List.last()
    |> Map.fetch!(field)
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
    authorize_and_post_first_inbound_club_email(
      receive_command,
      destination,
      sender,
      dispatch_opts
    )
  end

  defp authorize_and_post_first_inbound_club_email(
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
         :ok <- finalize_committed_inbound_auto_follow(message, dispatch_opts),
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
         opts \\ []
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
      command
      |> send_root_and_follow(dispatch_opts)
      |> normalize_dispatch_ok()
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
           authorize_at_stable_checkpoint(fn ->
             with {:ok, command} <- post_message_reply_command(attrs),
                  :ok <- authorize_reply_sender(command) do
               {:ok, command}
             end
           end) do
      command
      |> send_reply_and_follow(dispatch_opts)
      |> normalize_dispatch_ok()
    end
  end

  defp inbound_message_id(%ReceiveInboundEmail{inbound_email_id: inbound_email_id}) do
    ID.deterministic(:message, [inbound_email_id])
  end

  defp finalize_committed_inbound_auto_follow(%Message{} = message, dispatch_opts) do
    root? = message.message_id == message.conversation_id

    if root? do
      start_and_finalize_root_auto_follow(
        message.root_subscription_authority_decision,
        dispatch_opts
      )
    else
      intent_id = auto_follow_intent_id(:reply, message.message_id, message.sender_id)

      case Membership.conversation_subscription_authority_decision_for_intent(
             message.club_id,
             intent_id
           ) do
        {:ok, decision} -> finalize_auto_follow(decision, dispatch_opts)
        {:error, :authority_decision_not_found} -> :ok
        {:error, _reason} = error -> error
      end
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

  defp rejection_reason(reason) when is_atom(reason), do: Atom.to_string(reason)
  defp rejection_reason(reason) when is_binary(reason), do: reason

  defp grant_conversation_access_to_group_command(attrs) do
    with {:ok, conversation_id} <- fetch_required_id(attrs, :conversation_id, :message),
         {:ok, club_id} <- fetch_required_id(attrs, :club_id, :club),
         {:ok, group_id} <- fetch_required_id(attrs, :group_id, :group),
         {:ok, access_level} <- fetch_required(attrs, :access_level),
         {:ok, access_level} <- ConversationAccess.normalize_access_level(access_level) do
      {:ok,
       %GrantConversationAccessToGroup{
         conversation_id: conversation_id,
         club_id: club_id,
         group_id: group_id,
         access_level: access_level
       }}
    end
  end

  defp grant_initial_conversation_access_to_group_command(attrs) do
    with {:ok, conversation_id} <- fetch_required_id(attrs, :conversation_id, :message),
         {:ok, club_id} <- fetch_required_id(attrs, :club_id, :club),
         {:ok, group_id} <- fetch_required_id(attrs, :group_id, :group),
         {:ok, access_level} <- fetch_required(attrs, :access_level),
         {:ok, access_level} <- ConversationAccess.normalize_access_level(access_level) do
      {:ok,
       %GrantInitialConversationAccessToGroup{
         conversation_id: conversation_id,
         club_id: club_id,
         group_id: group_id,
         access_level: access_level
       }}
    end
  end

  defp revoke_conversation_access_from_group_command(attrs) do
    with {:ok, conversation_id} <- fetch_required_id(attrs, :conversation_id, :message),
         {:ok, club_id} <- fetch_required_id(attrs, :club_id, :club),
         {:ok, group_id} <- fetch_required_id(attrs, :group_id, :group) do
      {:ok,
       %RevokeConversationAccessFromGroup{
         conversation_id: conversation_id,
         club_id: club_id,
         group_id: group_id
       }}
    end
  end

  defp send_club_message_command(attrs) do
    with {:ok, message_id} <- fetch_required(attrs, :message_id),
         {:ok, club_id} <- fetch_required_id(attrs, :club_id, :club),
         {:ok, sender_id} <- fetch_required(attrs, :sender_id),
         {:ok, subject} <- fetch_required(attrs, :subject),
         {:ok, body} <- fetch_required(attrs, :body),
         {:ok, audience_group} <- resolve_audience_group(attrs, club_id) do
      audience_group_id = audience_group.group_id

      {:ok,
       %SendMessage{
         message_id: message_id,
         club_id: club_id,
         sender_id: sender_id,
         audience_group_id: audience_group_id,
         subject: subject,
         body: body,
         recipients: resolve_group_recipients(club_id, audience_group_id)
       }}
    end
  end

  defp resolve_audience_group(attrs, club_id) do
    audience_group_id =
      optional_audience_group_id(attrs, SystemGroups.everyone_group_id(club_id))

    with {:ok, audience_group_id} <- ID.cast(:group, audience_group_id) do
      case Membership.get_group(audience_group_id) do
        %{club_id: ^club_id} = audience_group -> {:ok, audience_group}
        _missing_or_foreign_group -> {:error, :audience_group_not_found}
      end
    else
      :error -> {:error, :invalid_audience_group_id}
    end
  end

  defp optional_audience_group_id(attrs, default_group_id) do
    case fetch_required(attrs, :audience_group_id) do
      {:ok, audience_group_id} -> audience_group_id
      {:error, {:missing_required_attribute, :audience_group_id}} -> default_group_id
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

  defp send_root_and_follow(command, dispatch_opts) do
    intent_id = auto_follow_intent_id(:root, command.message_id, command.sender_id)

    with :ok <- validate_unsent_root(command),
         {:ok, decision} <-
           prepare_root_subscription_authority(command, intent_id)
           |> optional_authorized_decision() do
      command = bind_root_subscription_authority(command, decision, intent_id)

      case dispatch_message_for_auto_follow(command, dispatch_opts) do
        {:ok, dispatch_result} ->
          with :ok <- run_auto_follow_send_succeeded_hook(command, decision),
               :ok <- start_and_finalize_root_auto_follow(decision, dispatch_opts) do
            dispatch_result
          end

        {:error, _reason} = error ->
          error
      end
    end
  end

  defp send_reply_and_follow(command, dispatch_opts) do
    intent_id = auto_follow_intent_id(:reply, command.message_id, command.sender_id)

    with {:ok, decision} <-
           resolve_subscription_authority_decision(
             command.sender_id,
             command.conversation_id,
             intent_id,
             :reply
           )
           |> optional_authorized_decision(),
         :ok <- prepare_auto_follow_intent(decision, dispatch_opts) do
      dispatch_send_then_finalize_follow(command, decision, dispatch_opts)
    end
  end

  defp dispatch_send_then_finalize_follow(command, decision, dispatch_opts) do
    case dispatch_message_for_auto_follow(command, dispatch_opts) do
      {:ok, dispatch_result} ->
        with :ok <- run_auto_follow_send_succeeded_hook(command, decision),
             :ok <- finalize_auto_follow(decision, dispatch_opts) do
          dispatch_result
        end

      {:error, _reason} = error ->
        _ = cancel_failed_auto_follow(decision, dispatch_opts)
        error
    end
  end

  defp dispatch_message_for_auto_follow(command, dispatch_opts) do
    case dispatch_command(command, dispatch_opts) do
      {:error, :already_sent} ->
        if matching_committed_message?(command),
          do: {:ok, :ok},
          else: {:error, :already_sent}

      result ->
        result
    end
  end

  defp matching_committed_message?(command) do
    case App.aggregate_state(Message, command.message_id) do
      %Message{} = message ->
        expected_conversation_id = Map.get(command, :conversation_id) || command.message_id

        message.message_id == command.message_id and
          message.club_id == command.club_id and
          message.sender_id == command.sender_id and
          message.conversation_id == expected_conversation_id and
          message.subscription_intent_id == Map.get(command, :subscription_intent_id) and
          message.authority_request_id == Map.get(command, :authority_request_id) and
          message.authority_decision_id == Map.get(command, :authority_decision_id) and
          message.subject == String.trim(command.subject) and
          message.body == String.trim(command.body)

      _missing ->
        false
    end
  end

  defp validate_unsent_root(command) do
    case Message.execute(%Message{}, command) do
      events when is_list(events) -> :ok
      {:error, _reason} = error -> error
    end
  end

  defp bind_root_subscription_authority(command, nil, _intent_id), do: command

  defp bind_root_subscription_authority(command, decision, intent_id) do
    %{
      command
      | subscription_intent_id: intent_id,
        authority_request_id: decision.authority_request_id,
        authority_decision_id: decision.authority_decision_id,
        root_subscription_authority_decision: decision
    }
  end

  defp prepare_root_subscription_authority(command, intent_id) do
    descriptor = %ConversationAuthorityDescriptor{
      club_id: command.club_id,
      person_id: command.sender_id,
      subscription_intent_id: intent_id,
      source: :root,
      conversation_id: command.message_id,
      conversation_group_ids: [command.audience_group_id],
      conversation_stream_version: 2 + length(command.recipients),
      signature: ""
    }

    descriptor = %{
      descriptor
      | signature: conversation_authority_descriptor_signature(descriptor)
    }

    case App.aggregate_state(Message, command.message_id) do
      %Message{root_subscription_authority_decision: decision} when not is_nil(decision) ->
        validate_recorded_subscription_authority_decision(
          decision,
          command.sender_id,
          command.message_id,
          :root
        )

      %Message{message_id: message_id} when not is_nil(message_id) ->
        {:ok, nil}

      _unsent ->
        Membership.issue_unrecorded_conversation_subscription_authority(
          descriptor,
          authority_request_id: stable_uuid(["root-authority", command.message_id]),
          authority_decision_id:
            ID.deterministic(:authority_decision, ["root", command.message_id])
        )
    end
  end

  defp optional_authorized_decision({:ok, decision}), do: {:ok, decision}

  defp optional_authorized_decision({:error, :conversation_subscription_not_authorized}),
    do: {:ok, nil}

  defp optional_authorized_decision({:error, _reason} = error), do: error

  defp start_and_finalize_root_auto_follow(nil, _dispatch_opts), do: :ok

  defp start_and_finalize_root_auto_follow(decision, dispatch_opts) do
    case start_and_authorize_subscription(decision, dispatch_opts) do
      {:error, reason}
      when reason in [
             :subscription_intent_cancelled,
             :conversation_subscription_authority_ended,
             :authority_no_longer_current
           ] ->
        :ok

      result ->
        result
    end
  end

  defp prepare_auto_follow_intent(nil, _dispatch_opts), do: :ok

  defp prepare_auto_follow_intent(decision, dispatch_opts) do
    start_subscription_intent(decision, dispatch_opts)
  end

  defp finalize_auto_follow(nil, _dispatch_opts), do: :ok

  defp finalize_auto_follow(decision, dispatch_opts) do
    case authorize_subscription_intent(
           decision.person_id,
           decision.subscription_intent_id,
           decision,
           dispatch_opts
         ) do
      :ok ->
        :ok

      {:error, reason}
      when reason in [
             :subscription_intent_cancelled,
             :conversation_subscription_authority_ended,
             :authority_no_longer_current
           ] ->
        :ok

      {:error, _reason} = error ->
        error
    end
  end

  defp cancel_failed_auto_follow(nil, _dispatch_opts), do: :ok

  defp cancel_failed_auto_follow(decision, dispatch_opts) do
    App.dispatch(
      %CancelPersonConversationSubscriptionIntent{
        person_id: decision.person_id,
        subscription_intent_id: decision.subscription_intent_id,
        cancellation_id: stable_uuid(["send-failed", decision.subscription_intent_id]),
        reason: "send_failed"
      },
      Keyword.put(dispatch_opts, :retry_attempts, 0)
    )
    |> normalize_dispatch_ok()
  end

  defp run_auto_follow_send_succeeded_hook(command, decision) do
    case Application.get_env(:memba, :auto_follow_send_succeeded_hook) do
      hook when is_function(hook, 2) -> hook.(command, decision)
      _no_hook -> :ok
    end
  end

  defp auto_follow_intent_id(source, message_id, person_id) do
    ID.deterministic(:subscription_intent, [Atom.to_string(source), message_id, person_id])
  end

  defp start_and_authorize_subscription(decision, dispatch_opts) do
    with :ok <- start_subscription_intent(decision, dispatch_opts) do
      authorize_subscription_intent(
        decision.person_id,
        decision.subscription_intent_id,
        decision,
        dispatch_opts
      )
    end
  end

  defp start_subscription_intent(decision, dispatch_opts) do
    dispatch_subscription_with_revalidation(
      %StartPersonConversationSubscriptionIntent{
        person_id: decision.person_id,
        club_id: decision.club_id,
        conversation_id: decision.conversation_id,
        conversation_group_ids: decision.conversation_group_ids,
        conversation_stream_version: decision.conversation_stream_version,
        subscription_id:
          PersonConversationSubscriptions.subscription_id(
            decision.person_id,
            decision.conversation_id
          ),
        subscription_intent_id: decision.subscription_intent_id,
        authority_decision_id: decision.authority_decision_id,
        source: decision.source,
        club_membership_id: decision.club_membership_id,
        club_stream_version: decision.club_stream_version,
        group_membership_ids: decision.group_membership_ids,
        system_authority_kinds: decision.system_authority_kinds,
        authority_decision: decision
      },
      decision,
      dispatch_opts
    )
  end

  defp run_subscription_authority_issued_hook(decision) do
    case Application.get_env(:memba, :conversation_subscription_authority_issued_hook) do
      hook when is_function(hook, 1) -> hook.(decision)
      _no_hook -> :ok
    end
  end

  defp resolve_subscription_authority_decision(person_id, conversation_id, intent_id, source) do
    with {:ok, club_id} <- canonical_conversation_club_id(conversation_id) do
      case Membership.conversation_subscription_authority_decision_for_intent(club_id, intent_id) do
        {:ok, decision} ->
          validate_recorded_subscription_authority_decision(
            decision,
            person_id,
            conversation_id,
            source
          )

        {:error, :authority_decision_not_found} ->
          with {:ok, descriptor} <-
                 canonical_conversation_authority_descriptor(
                   conversation_id,
                   person_id,
                   intent_id,
                   source
                 ),
               :ok <- run_conversation_authority_descriptor_issued_hook(descriptor) do
            Membership.decide_conversation_subscription_authority(descriptor)
          end
      end
    end
  end

  defp canonical_conversation_club_id(conversation_id) do
    case App.aggregate_state(Message, conversation_id) do
      %Message{message_id: ^conversation_id, club_id: club_id} when is_binary(club_id) ->
        {:ok, club_id}

      _missing_conversation ->
        {:error, :conversation_not_found}
    end
  end

  defp validate_recorded_subscription_authority_decision(
         decision,
         person_id,
         conversation_id,
         source
       ) do
    if decision.person_id == person_id and decision.conversation_id == conversation_id and
         decision.source == source do
      {:ok, decision}
    else
      {:error, :subscription_intent_id_conflict}
    end
  end

  defp run_conversation_authority_descriptor_issued_hook(descriptor) do
    case Application.get_env(:memba, :conversation_authority_descriptor_issued_hook) do
      hook when is_function(hook, 1) -> hook.(descriptor)
      _no_hook -> :ok
    end
  end

  defp canonical_conversation_authority_descriptor(
         conversation_id,
         person_id,
         intent_id,
         source
       ) do
    with {:ok, before_version} <- conversation_stream_version(conversation_id),
         %Message{club_id: club_id, group_access: group_access} <-
           App.aggregate_state(Message, conversation_id),
         {:ok, after_version} <- conversation_stream_version(conversation_id),
         true <- before_version == after_version,
         conversation_group_ids when conversation_group_ids != [] <-
           canonical_subscription_group_ids(group_access) do
      descriptor = %ConversationAuthorityDescriptor{
        club_id: club_id,
        person_id: person_id,
        subscription_intent_id: intent_id,
        source: source,
        conversation_id: conversation_id,
        conversation_group_ids: conversation_group_ids,
        conversation_stream_version: after_version,
        signature: ""
      }

      {:ok, %{descriptor | signature: conversation_authority_descriptor_signature(descriptor)}}
    else
      [] ->
        {:error, :conversation_has_no_subscription_groups}

      false ->
        canonical_conversation_authority_descriptor(
          conversation_id,
          person_id,
          intent_id,
          source
        )

      _missing ->
        {:error, :conversation_not_found}
    end
  end

  defp conversation_stream_version(conversation_id) do
    version =
      Memba.Messaging.App
      |> Commanded.EventStore.stream_forward(conversation_id)
      |> Enum.reduce(0, fn event, _version -> event.stream_version end)

    if version > 0, do: {:ok, version}, else: {:error, :conversation_not_found}
  end

  defp conversation_authority_descriptor_signature(descriptor) do
    fields = [
      descriptor.club_id,
      descriptor.person_id,
      descriptor.subscription_intent_id,
      descriptor.source,
      descriptor.conversation_id,
      descriptor.conversation_group_ids,
      descriptor.conversation_stream_version
    ]

    fields =
      if descriptor.source in [:legacy_reconciliation, "legacy_reconciliation"] do
        fields ++
          [
            descriptor.reconciliation_fence_id,
            descriptor.reconciliation_fence_position,
            descriptor.reconciliation_event_store_schema
          ]
      else
        fields
      end

    payload = :erlang.term_to_binary(fields)

    :crypto.mac(:hmac, :sha256, conversation_authority_descriptor_signing_key(), payload)
  end

  defp conversation_authority_descriptor_signing_key do
    :memba
    |> Application.fetch_env!(MembaWeb.Endpoint)
    |> Keyword.fetch!(:secret_key_base)
    |> then(&:crypto.mac(:hmac, :sha256, &1, "messaging-conversation-authority"))
  end

  defp reject_unfollow_provenance(attrs) do
    allowed = MapSet.new([:person_id, :conversation_id, :unfollow_id])
    reject_untrusted_attributes(attrs, allowed)
  end

  defp reject_subscription_provenance(attrs) do
    allowed = MapSet.new([:person_id, :conversation_id, :subscription_intent_id, :source])

    supplied =
      attrs
      |> Map.keys()
      |> Enum.map(fn key -> if is_binary(key), do: key, else: Atom.to_string(key) end)
      |> Enum.map(&String.to_existing_atom/1)
      |> MapSet.new()

    if MapSet.subset?(supplied, allowed),
      do: :ok,
      else: {:error, :trusted_subscription_provenance_not_accepted}
  rescue
    ArgumentError -> {:error, :unknown_subscription_attribute}
  end

  defp reject_untrusted_attributes(attrs, allowed) do
    supplied =
      attrs
      |> Map.keys()
      |> Enum.map(fn key -> if is_binary(key), do: key, else: Atom.to_string(key) end)
      |> Enum.map(&String.to_existing_atom/1)
      |> MapSet.new()

    if MapSet.subset?(supplied, allowed),
      do: :ok,
      else: {:error, :trusted_subscription_provenance_not_accepted}
  rescue
    ArgumentError -> {:error, :unknown_subscription_attribute}
  end

  defp fetch_uuid(attrs, key) do
    with {:ok, value} <- fetch_required(attrs, key),
         {:ok, ^value} <- Ecto.UUID.cast(value) do
      {:ok, value}
    else
      :error -> {:error, :invalid_unfollow_id}
      {:error, _reason} = error -> error
    end
  end

  defp fetch_and_cast(attrs, key, type) do
    with {:ok, value} <- fetch_required(attrs, key),
         {:ok, ^value} <- ID.cast(type, value) do
      {:ok, value}
    else
      :error -> {:error, subscription_id_error(key)}
      {:error, _reason} = error -> error
    end
  end

  defp subscription_id_error(:person_id), do: :invalid_person_id
  defp subscription_id_error(:conversation_id), do: :invalid_conversation_id
  defp subscription_id_error(:subscription_intent_id), do: :invalid_subscription_intent_id

  defp subscription_source(attrs) do
    with {:ok, source} <- fetch_required(attrs, :source) do
      case source do
        :manual -> {:ok, :manual}
        :root -> {:ok, :root}
        :reply -> {:ok, :reply}
        "manual" -> {:ok, :manual}
        "root" -> {:ok, :root}
        "reply" -> {:ok, :reply}
        _invalid -> {:error, :invalid_subscription_source}
      end
    end
  end

  defp canonical_subscription_group_ids(group_access) do
    group_access
    |> Enum.filter(fn {_group_id, access_level} -> access_level in ["read", "write"] end)
    |> Enum.map(fn {group_id, _access_level} -> group_id end)
    |> Enum.sort()
  end

  defp authorize_subscription_intent(person_id, intent_id, decision, dispatch_opts) do
    command = %AuthorizePersonConversationSubscriptionIntent{
      person_id: person_id,
      subscription_intent_id: intent_id,
      authority_decision_id: decision.authority_decision_id,
      current_group_membership_ids: decision.group_membership_ids,
      current_system_authority_kinds: decision.system_authority_kinds,
      authority_decision: decision
    }

    case dispatch_subscription_with_revalidation(command, decision, dispatch_opts) do
      :ok ->
        :ok

      {:error, :conversation_subscription_authority_ended} = error ->
        _ =
          App.dispatch(
            %CancelPersonConversationSubscriptionIntent{
              person_id: person_id,
              subscription_intent_id: intent_id,
              cancellation_id: Ecto.UUID.generate(),
              reason: "authority_ended"
            },
            Keyword.put(dispatch_opts, :retry_attempts, 0)
          )

        error

      {:error, _reason} = error ->
        error
    end
  end

  defp dispatch_subscription_with_revalidation(command, decision, dispatch_opts, attempts \\ 1) do
    dispatch_opts = Keyword.put(dispatch_opts, :retry_attempts, 0)

    case App.dispatch(command, dispatch_opts) do
      :ok ->
        :ok

      {:ok, _dispatch_result} ->
        :ok

      {:error, :too_many_attempts} when attempts > 0 ->
        with :ok <- Membership.revalidate_conversation_subscription_authority(decision) do
          dispatch_subscription_with_revalidation(command, decision, dispatch_opts, attempts - 1)
        end

      {:error, _reason} = error ->
        error
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
  defp invalid_id_reason(:club_id), do: :invalid_club_id
  defp invalid_id_reason(:group_id), do: :invalid_group_id

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

  defp authorize_message_sender(%SendMessage{} = command) do
    if Membership.active_member_of_group_authoritatively?(
         command.club_id,
         command.audience_group_id,
         command.sender_id
       ) do
      :ok
    else
      {:error, :not_current_member}
    end
  end

  defp authorize_at_stable_checkpoint(authorization) when is_function(authorization, 0) do
    authorize_at_stable_checkpoint(authorization, [])
  end

  defp authorize_at_stable_checkpoint(authorization, opts)
       when is_function(authorization, 0) and is_list(opts) do
    deadline =
      System.monotonic_time(:millisecond) + authorization_stability_timeout()

    authorize_at_stable_checkpoint(
      authorization,
      Keyword.get(opts, :projections, []),
      deadline
    )
  end

  defp authorize_at_stable_checkpoint(authorization, projections, deadline) do
    if System.monotonic_time(:millisecond) >= deadline do
      {:error, :authorization_stability_timeout}
    else
      checkpoint = ProjectionBarrier.current_checkpoint()

      with :ok <- await_authorization_projections(projections, checkpoint, deadline),
           {:ok, authorized} <- authorization.() do
        if ProjectionBarrier.current_checkpoint() == checkpoint do
          {:ok, authorized}
        else
          authorize_at_stable_checkpoint(authorization, projections, deadline)
        end
      end
    end
  end

  defp await_authorization_projections([], _checkpoint, _deadline), do: :ok

  defp await_authorization_projections(projections, checkpoint, deadline) do
    timeout = max(deadline - System.monotonic_time(:millisecond), 0)

    case ProjectionBarrier.await(projections, checkpoint: checkpoint, timeout: timeout) do
      {:ok, _result} -> :ok
      {:error, :timeout, _result} -> {:error, :authorization_stability_timeout}
    end
  end

  defp authorization_stability_timeout do
    case Application.get_env(
           :memba,
           :authorization_stability_timeout,
           @default_authorization_stability_timeout
         ) do
      timeout when is_integer(timeout) and timeout >= 0 -> timeout
      _invalid -> @default_authorization_stability_timeout
    end
  end

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
         } <- App.aggregate_state(Message, conversation_id) do
      grant_levels = ConversationAccess.grant_levels_including(access_level)

      Enum.any?(group_access, fn {group_id, granted_access_level} ->
        granted_access_level in grant_levels and
          Membership.active_member_of_group_authoritatively?(
            club_id,
            group_id,
            person_id
          )
      end)
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

  defp stable_unfollow_id(scope) do
    stable_uuid([scope.club_id, scope.conversation_id, scope.member_id, "email-unfollow"])
  end

  defp stable_uuid(parts) do
    parts
    |> Enum.join(<<0>>)
    |> then(&:crypto.hash(:md5, &1))
    |> Ecto.UUID.load!()
  end

  defp normalize_dispatch_ok(:ok), do: :ok
  defp normalize_dispatch_ok({:ok, _result}), do: :ok
  defp normalize_dispatch_ok({:error, _reason} = error), do: error

  defp resolve_group_recipients(club_id, group_id, opts \\ []) do
    except_person_id = Keyword.get(opts, :except_person_id)

    group_id
    |> Membership.list_active_members_of_group()
    |> Enum.reject(&(&1.id == except_person_id))
    |> Enum.filter(&Membership.active_member_of_group_authoritatively?(club_id, group_id, &1.id))
    |> Enum.map(&resolved_recipient/1)
  end

  defp resolve_reply_recipients(club_id, conversation_id, opts) do
    except_person_id = Keyword.get(opts, :except_person_id)

    candidates =
      conversation_id
      |> effective_follow_candidates()
      |> Enum.reject(&(&1.follow.member_id == except_person_id))
      |> Enum.filter(
        &member_has_authoritative_conversation_access?(
          conversation_id,
          club_id,
          &1.follow.member_id,
          :read
        )
      )

    contacts =
      candidates
      |> Enum.map(& &1.follow.member_id)
      |> Membership.list_person_contact_summaries()

    candidates
    |> Enum.flat_map(fn candidate ->
      case Map.get(contacts, candidate.follow.member_id) do
        nil -> []
        contact -> [resolved_reply_recipient(contact, candidate.grant)]
      end
    end)
    |> Enum.sort_by(&{&1.name, &1.person_id})
  end

  defp resolved_reply_recipient(contact, nil) do
    resolved_recipient(%{
      id: contact.person_id,
      name: contact.name,
      email: contact.primary_email
    })
  end

  defp resolved_reply_recipient(contact, grant) do
    %{
      resolved_recipient(%{
        id: contact.person_id,
        name: contact.name,
        email: contact.primary_email
      })
      | subscription_authorization_id: grant.authorization_id,
        authority_decision_id: grant.authority_decision_id,
        authority_kind: grant.authority_kind,
        authority_club_id: grant.club_id,
        authority_club_membership_id: grant.club_membership_id,
        authority_group_membership_id: grant.group_membership_id,
        authority_club_stream_version: grant.club_stream_version
    }
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
