defmodule Memba.Messaging.LegacyConversationFollowReconciliation do
  @moduledoc """
  Bounded, restartable reconciliation of effective legacy follows at one fence.

  The fence is an event, candidate enumeration waits for the legacy projector,
  and every authority decision is reconstructed from canonical histories no
  later than the fence. Person-stream commands serialize the result with live
  follows, unfollows, and revocations.
  """

  import Ecto.Query

  alias Commanded.Commands.ExecutionResult
  alias Memba.ID
  alias Memba.Membership
  alias Memba.Membership.Club
  alias Memba.Messaging.App, as: MessagingApp
  alias Memba.Messaging.Commands.AdvanceConversationSubscriptionCutoverCheckpoint
  alias Memba.Messaging.Commands.ReconcileLegacyConversationFollow
  alias Memba.Messaging.Commands.RecordConversationSubscriptionCutoverFence
  alias Memba.Messaging.ConversationSubscriptionCutover
  alias Memba.Messaging.Events.LegacyConversationFollowReconciled
  alias Memba.Messaging.LegacyConversationFollowDryRunCursor
  alias Memba.Messaging.Message
  alias Memba.Messaging.PersonConversationSubscriptions
  alias Memba.Messaging.Projections.ConversationFollow
  alias Memba.Messaging.Projectors.ConversationFollow, as: ConversationFollowProjector
  alias Memba.ProjectionBarrier
  alias Memba.Repo

  @namespace "legacy-conversation-follow-reconciliation/v1"
  @default_batch_size 100
  @max_batch_size 500

  def namespace, do: @namespace
  def cutover_acknowledgement, do: ConversationSubscriptionCutover.acknowledgement()

  def run(opts \\ []) when is_list(opts) do
    with {:ok, config} <- validate_options(opts),
         {:ok, cutover} <- ensure_fence(config),
         fence = cutover.fence,
         durable_cursor = checkpoint_cursor(cutover.checkpoint),
         {:ok, start_cursor} <- resolve_start_cursor(config, durable_cursor, fence),
         :ok <- ensure_legacy_source_unchanged(fence.event_store_position),
         :ok <- await_legacy_projector(fence.event_store_position, config.projector_timeout) do
      config = Map.put(config, :durable_cursor, durable_cursor)
      keys = candidate_keys(start_cursor, config.batch_size + 1)
      items = Enum.take(keys, config.batch_size)
      incomplete? = length(keys) > config.batch_size

      initial = %{
        mode: config.mode,
        namespace: @namespace,
        fence_position: fence.event_store_position,
        batch_size: config.batch_size,
        attempted: 0,
        granted: 0,
        no_authority: 0,
        already_reconciled: 0,
        next_cursor: initial_report_cursor(config, start_cursor, durable_cursor, fence),
        outcomes: []
      }

      if config.mode == :record_fence do
        {:ok,
         %{mode: :record_fence, namespace: @namespace, fence_position: fence.event_store_position}}
      else
        case process_items(items, initial, config, fence) do
          {:ok, report} when incomplete? ->
            {:error, %{reason: :incomplete_batch, resumable: true, report: report}}

          result ->
            result
        end
      end
    end
  end

  def run!(opts \\ []) do
    case run(opts) do
      {:ok, report} -> report
      {:error, reason} -> raise RuntimeError, inspect(reason, pretty: true)
    end
  end

  defp ensure_fence(%{mode: :record_fence} = config) do
    messaging_schema = event_store_schema(Memba.Messaging.EventStore)
    membership_schema = event_store_schema(Memba.EventStore)

    if messaging_schema != membership_schema do
      {:error, :event_stores_do_not_share_global_position}
    else
      record_fence(config, messaging_schema)
    end
  end

  defp ensure_fence(_config), do: fetch_fence()

  defp record_fence(config, schema) do
    position = ProjectionBarrier.current_checkpoint()

    command = %RecordConversationSubscriptionCutoverFence{
      cutover_id: ConversationSubscriptionCutover.cutover_id(),
      namespace: @namespace,
      event_store_schema: schema,
      event_store_position: position,
      writers_stopped_acknowledgement: config.acknowledgement
    }

    case MessagingApp.dispatch(command) do
      :ok -> fetch_fence()
      {:ok, _result} -> fetch_fence()
      {:error, reason} -> {:error, reason}
    end
  end

  defp fetch_fence do
    case MessagingApp.aggregate_state(
           ConversationSubscriptionCutover,
           ConversationSubscriptionCutover.cutover_id()
         ) do
      %{fence: %{namespace: @namespace}} = cutover -> {:ok, cutover}
      %{fence: nil} -> {:error, :cutover_fence_not_recorded}
      _different -> {:error, :cutover_fence_conflict}
    end
  end

  defp await_legacy_projector(position, timeout) do
    case ProjectionBarrier.await([ConversationFollowProjector],
           checkpoint: position,
           timeout: timeout
         ) do
      {:ok, _result} -> :ok
      {:error, :timeout, result} -> {:error, {:legacy_projector_lag, result}}
    end
  end

  defp ensure_legacy_source_unchanged(position) do
    schema = event_store_schema(Memba.Messaging.EventStore)

    %{rows: [[count]]} =
      Repo.query!(
        """
        SELECT count(*)
        FROM #{quote_identifier(schema)}.events AS event
        JOIN #{quote_identifier(schema)}.stream_events AS all_event
          ON all_event.event_id = event.event_id
        JOIN #{quote_identifier(schema)}.streams AS all_stream
          ON all_stream.stream_id = all_event.stream_id AND all_stream.stream_uuid = '$all'
        WHERE all_event.stream_version > $1
          AND (
            event.event_type IN (
              'Elixir.Memba.Messaging.Events.ConversationFollowed',
              'Elixir.Memba.Messaging.Events.ConversationUnfollowed'
            )
            OR (
              event.event_type = 'Elixir.Memba.Messaging.Events.MessageSent'
              AND COALESCE(
                (convert_from(event.data, 'UTF8')::jsonb ->> 'sender_follows_conversation')::boolean,
                TRUE
              )
            )
          )
        """,
        [position]
      )

    if count == 0, do: :ok, else: {:error, :legacy_follow_source_changed}
  end

  defp process_items(items, initial, config, fence) do
    initial_state = {:ok, initial, %{}}

    result =
      Enum.reduce_while(items, initial_state, fn key, {:ok, report, club_cache} ->
        case reconcile_key(key, config.mode, fence, report, club_cache) do
          {:ok, outcome, club_cache} ->
            report =
              report
              |> Map.update!(:attempted, &(&1 + 1))
              |> Map.update!(outcome.status, &(&1 + 1))
              |> Map.put(
                :next_cursor,
                report_cursor(config.mode, key, config.durable_cursor, fence)
              )
              |> Map.update!(:outcomes, &[%{key: serialize_cursor(key), outcome: outcome} | &1])

            {:cont, {:ok, report, club_cache}}

          {:error, reason, club_cache} ->
            {:halt,
             {:error,
              %{reason: reason, key: serialize_cursor(key), resumable: true, report: report},
              club_cache}}
        end
      end)

    case result do
      {:ok, report, _cache} -> {:ok, report}
      {:error, error, _cache} -> {:error, error}
    end
  end

  defp reconcile_key({person_id, conversation_id} = key, mode, fence, report, club_cache) do
    {message, _conversation_stream_version} =
      fold_stream_with_version(MessagingApp, conversation_id, Message, fence.event_store_position)

    if message.message_id == nil do
      {:error, :canonical_conversation_not_found_at_fence, club_cache}
    else
      with {:ok, club_state, club_cache} <-
             cached_club_at_fence(club_cache, message.club_id, fence.event_store_position),
           {:ok, descriptor} <-
             Memba.Messaging.issue_fenced_conversation_authority_descriptor(
               person_id,
               conversation_id,
               reconciliation_key(person_id, conversation_id, fence),
               fence
             ) do
        reconcile_with_descriptor(
          key,
          descriptor,
          club_state,
          mode,
          fence,
          report,
          club_cache
        )
      else
        {:error, reason} -> {:error, reason, club_cache}
      end
    end
  end

  defp reconcile_with_descriptor(
         {person_id, conversation_id},
         descriptor,
         %Memba.Membership.FencedClubAuthorityState{} = club_state,
         :dry_run,
         fence,
         _report,
         club_cache
       ) do
    authority = authority_at_fence(club_state.club, descriptor)

    status =
      preview_status(
        person_id,
        conversation_id,
        authority,
        club_state.stream_version,
        fence
      )

    {:ok, %{status: status}, club_cache}
  end

  defp reconcile_with_descriptor(
         {person_id, conversation_id} = key,
         descriptor,
         club_state,
         :apply,
         fence,
         report,
         club_cache
       ) do
    authority_decision_id = authority_decision_id(person_id, conversation_id, fence)

    opts = [
      authority_request_id: authority_request_id(person_id, conversation_id, fence),
      authority_decision_id: authority_decision_id,
      club_at_fence: club_state
    ]

    with {:ok, decision} <-
           Membership.decide_fenced_conversation_subscription_authority(descriptor, opts),
         command <- reconciliation_command(person_id, conversation_id, decision, fence),
         :ok <- run_hook(:legacy_follow_reconciliation_before_person_dispatch_hook, key),
         {:ok, outcome} <- decide_or_dispatch(command, :apply),
         :ok <- run_hook(:legacy_follow_reconciliation_after_person_before_checkpoint_hook, key),
         :ok <- advance_checkpoint(report.next_cursor, key, command.reconciliation_key) do
      {:ok, outcome, club_cache}
    else
      {:error, reason} -> {:error, reason, club_cache}
    end
  end

  defp cached_club_at_fence(cache, club_id, position) do
    case Map.fetch(cache, club_id) do
      {:ok, club_state} ->
        {:ok, club_state, cache}

      :error ->
        case Membership.conversation_subscription_club_at_fence(club_id, position) do
          {:ok, club_state} ->
            {:ok, club_state, Map.put(cache, club_id, club_state)}

          {:error, reason} ->
            {:error, reason}
        end
    end
  end

  defp authority_at_fence(club, descriptor) do
    case Club.resolve_conversation_subscription_authority(club, descriptor) do
      {:ok, membership_id, groups, systems} ->
        %{
          club_id: club.club_id,
          club_membership_id: membership_id,
          custom: groups,
          system: systems
        }

      {:error, :conversation_subscription_not_authorized} ->
        %{club_id: club.club_id, club_membership_id: nil, custom: [], system: []}
    end
  end

  defp preview_status(person_id, conversation_id, authority, club_version, fence) do
    subscriptions = MessagingApp.aggregate_state(PersonConversationSubscriptions, person_id)
    key = reconciliation_key(person_id, conversation_id, fence)

    cond do
      Map.has_key?(subscriptions.reconciliations, key) ->
        :already_reconciled

      Enum.any?(subscriptions.unfollows, fn {_id, unfollow} ->
        unfollow.conversation_id == conversation_id
      end) ->
        :no_authority

      true ->
        custom =
          Enum.reject(
            authority.custom,
            &Map.has_key?(subscriptions.revoked_group_memberships, &1)
          )

        system =
          Enum.filter(authority.system, fn kind ->
            case Map.get(
                   subscriptions.revoked_system_authorities,
                   {authority.club_id, authority.club_membership_id, kind}
                 ) do
              %{authority_through_club_stream_version: cutoff} -> club_version > cutoff
              nil -> true
            end
          end)

        if custom != [] or system != [], do: :granted, else: :no_authority
    end
  end

  defp reconciliation_command(person_id, conversation_id, decision, fence) do
    key = reconciliation_key(person_id, conversation_id, fence)

    %ReconcileLegacyConversationFollow{
      person_id: person_id,
      conversation_id: conversation_id,
      club_id: decision.club_id,
      subscription_id:
        PersonConversationSubscriptions.subscription_id(person_id, conversation_id),
      reconciliation_key: key,
      subscription_intent_id: key,
      authority_decision_id: decision.authority_decision_id,
      authority_decision: decision,
      fence_position: fence.event_store_position,
      conversation_group_ids: decision.conversation_group_ids,
      club_membership_id: decision.club_membership_id,
      club_stream_version: decision.club_stream_version,
      group_membership_ids: decision.group_membership_ids,
      system_authority_kinds: decision.system_authority_kinds
    }
  end

  defp decide_or_dispatch(command, :apply) do
    command
    |> MessagingApp.dispatch(returning: :execution_result, retry_attempts: 10)
    |> classify(command)
  end

  defp advance_checkpoint(previous_cursor, {person_id, conversation_id}, reconciliation_key) do
    command = %AdvanceConversationSubscriptionCutoverCheckpoint{
      cutover_id: ConversationSubscriptionCutover.cutover_id(),
      namespace: @namespace,
      expected_cursor: normalize_cursor(previous_cursor),
      person_id: person_id,
      conversation_id: conversation_id,
      reconciliation_key: reconciliation_key
    }

    case MessagingApp.dispatch(command, retry_attempts: 10) do
      :ok -> :ok
      {:ok, _result} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp reconciliation_key(person_id, conversation_id, fence) do
    PersonConversationSubscriptions.reconciliation_key(
      person_id,
      conversation_id,
      fence.event_store_position
    )
  end

  defp authority_decision_id(person_id, conversation_id, fence) do
    ID.deterministic(:authority_decision, [
      @namespace,
      person_id,
      conversation_id,
      Integer.to_string(fence.event_store_position)
    ])
  end

  defp authority_request_id(person_id, conversation_id, fence) do
    ID.deterministic(:authority_decision, [
      @namespace,
      "request",
      person_id,
      conversation_id,
      Integer.to_string(fence.event_store_position)
    ])
    |> String.replace_prefix("ath_", "")
  end

  defp run_hook(name, key) do
    case Application.get_env(:memba, name) do
      hook when is_function(hook, 1) -> hook.(key)
      _no_hook -> :ok
    end
  end

  defp classify({:ok, %ExecutionResult{events: events}}, command), do: classify(events, command)
  defp classify(:ok, command), do: {:ok, %{status: expected_status(command)}}
  defp classify([], _command), do: {:ok, %{status: :already_reconciled}}

  defp classify(events, _command) when is_list(events) do
    case Enum.find(events, &match?(%LegacyConversationFollowReconciled{}, &1)) do
      %LegacyConversationFollowReconciled{outcome: "granted"} ->
        {:ok, %{status: :granted}}

      %LegacyConversationFollowReconciled{outcome: "no_authority"} ->
        {:ok, %{status: :no_authority}}

      nil ->
        {:error, {:missing_terminal_marker, events}}
    end
  end

  defp classify({:error, reason}, _command), do: {:error, reason}
  defp classify(other, _command), do: {:error, {:unexpected_decision, other}}

  defp expected_status(%{group_membership_ids: [], system_authority_kinds: []}), do: :no_authority
  defp expected_status(_command), do: :granted

  defp fold_stream_with_version(app, stream_id, module, position) do
    event_store =
      if app == MessagingApp, do: Memba.Messaging.EventStore, else: Memba.EventStore

    Memba.EventStoreHistory.stream_forward_at_global_position(
      app,
      event_store,
      stream_id,
      position
    )
    |> Enum.reduce({struct(module), 0}, fn recorded, {aggregate, _version} ->
      {module.apply(aggregate, recorded.data), recorded.stream_version}
    end)
  end

  defp candidate_keys(after_key, limit) do
    {after_person_id, after_conversation_id} = after_key || {"", ""}

    ConversationFollow
    |> where([follow], follow.following == true)
    |> where(
      [follow],
      ^is_nil(after_key) or
        fragment(
          "(?, ?) > (?, ?)",
          follow.member_id,
          follow.conversation_id,
          ^after_person_id,
          ^after_conversation_id
        )
    )
    |> order_by([follow], asc: follow.member_id, asc: follow.conversation_id)
    |> select([follow], {follow.member_id, follow.conversation_id})
    |> limit(^limit)
    |> Repo.all()
  end

  defp validate_options(opts) do
    mode = Keyword.get(opts, :mode, :dry_run)
    batch_size = Keyword.get(opts, :batch_size, @default_batch_size)
    after_value = Keyword.get(opts, :after)
    normalized_after = normalize_after(mode, after_value)
    timeout = Keyword.get(opts, :projector_timeout, 60_000)
    acknowledgement = Keyword.get(opts, :cutover_acknowledgement)

    cond do
      mode not in [:record_fence, :dry_run, :apply] ->
        {:error, :invalid_mode}

      not is_integer(batch_size) or batch_size < 1 or batch_size > @max_batch_size ->
        {:error, :invalid_batch_size}

      normalized_after == :error ->
        {:error, :invalid_cursor}

      not is_integer(timeout) or timeout < 0 ->
        {:error, :invalid_projector_timeout}

      mode in [:record_fence, :apply] and acknowledgement != cutover_acknowledgement() ->
        {:error, :writers_stopped_acknowledgement_required}

      true ->
        {:ok,
         %{
           mode: mode,
           batch_size: batch_size,
           after_key: normalized_after,
           projector_timeout: timeout,
           acknowledgement: acknowledgement
         }}
    end
  end

  defp resolve_start_cursor(%{mode: :record_fence, after_key: nil}, durable, _fence),
    do: {:ok, durable}

  defp resolve_start_cursor(%{mode: :apply, after_key: nil}, durable, _fence),
    do: {:ok, durable}

  defp resolve_start_cursor(%{mode: :apply, after_key: durable}, durable, _fence),
    do: {:ok, durable}

  defp resolve_start_cursor(%{mode: :apply}, _durable, _fence),
    do: {:error, :reconciliation_cursor_conflict}

  defp resolve_start_cursor(%{mode: :dry_run, after_key: nil}, durable, _fence),
    do: {:ok, durable}

  defp resolve_start_cursor(%{mode: :dry_run, after_key: token}, durable, fence) do
    LegacyConversationFollowDryRunCursor.verify(token, durable, fence, @namespace)
  end

  defp initial_report_cursor(%{mode: :dry_run, after_key: token}, _start, _durable, _fence)
       when is_binary(token),
       do: token

  defp initial_report_cursor(%{mode: :dry_run}, nil, _durable, _fence), do: nil

  defp initial_report_cursor(%{mode: :dry_run}, start, durable, fence),
    do: LegacyConversationFollowDryRunCursor.issue(start, durable, fence, @namespace)

  defp initial_report_cursor(_config, start, _durable, _fence), do: serialize_cursor(start)

  defp report_cursor(:dry_run, key, durable, fence),
    do: LegacyConversationFollowDryRunCursor.issue(key, durable, fence, @namespace)

  defp report_cursor(_mode, key, _durable, _fence), do: serialize_cursor(key)

  defp checkpoint_cursor(nil), do: nil
  defp checkpoint_cursor(checkpoint), do: {checkpoint.person_id, checkpoint.conversation_id}

  defp normalize_after(:dry_run, nil), do: nil
  defp normalize_after(:dry_run, token) when is_binary(token), do: token
  defp normalize_after(:record_fence, nil), do: nil
  defp normalize_after(:apply, value), do: normalize_apply_cursor(value)
  defp normalize_after(_mode, _value), do: :error

  defp normalize_apply_cursor(nil), do: nil

  defp normalize_apply_cursor([person_id, conversation_id]),
    do: normalize_apply_cursor({person_id, conversation_id})

  defp normalize_apply_cursor({person_id, conversation_id} = cursor) do
    if ID.valid?(:person, person_id) and ID.valid?(:message, conversation_id),
      do: cursor,
      else: :error
  end

  defp normalize_apply_cursor(_cursor), do: :error

  defp normalize_cursor(nil), do: nil
  defp normalize_cursor([person_id, conversation_id]), do: {person_id, conversation_id}
  defp normalize_cursor({person_id, conversation_id}), do: {person_id, conversation_id}

  defp serialize_cursor(nil), do: nil
  defp serialize_cursor(cursor), do: Tuple.to_list(cursor)

  defp event_store_schema(event_store) do
    event_store.config() |> Keyword.fetch!(:schema) |> to_string()
  end

  defp quote_identifier(identifier) do
    escaped = identifier |> to_string() |> String.replace(~s("), ~s(""))
    ~s("#{escaped}")
  end
end
