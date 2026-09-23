defmodule Memba.Membership.LegacyGroupMembershipReconciliation do
  @moduledoc """
  Bounded reconciliation of legacy custom-group relations at durable Club fences.

  Enumeration reads canonical source history. Apply mode records each Club's
  immutable fence through its aggregate before making decisions. Dry-run folds
  the same aggregate and executes the same commands without dispatching them.
  Projection catch-up is deliberately separate.
  """

  alias Commanded.Commands.ExecutionResult
  alias Commanded.EventStore
  alias Memba.ID
  alias Memba.Membership.App
  alias Memba.Membership.Club
  alias Memba.Membership.Commands.ReconcileLegacyGroupMembership
  alias Memba.Membership.Commands.RecordLegacyGroupMembershipReconciliationFence
  alias Memba.Membership.Events.GroupMemberAdded
  alias Memba.Membership.Events.GroupMemberRemoved
  alias Memba.Membership.Events.LegacyGroupMembershipReconciliationFenceRecorded
  alias Memba.Membership.Events.LegacyGroupMembershipReconciled
  alias Memba.Membership.SystemGroups
  alias Memba.Repo

  @namespace "legacy-custom-group-reconciliation/v1"
  @default_batch_size 100
  @max_batch_size 500
  @cutover_acknowledgement "NO_LEGACY_GROUP_WRITERS"

  def namespace, do: @namespace
  def cutover_acknowledgement, do: @cutover_acknowledgement

  def group_membership_id(club_id, group_id, club_membership_id, namespace \\ @namespace) do
    ID.deterministic(:group_membership, [namespace, club_id, group_id, club_membership_id])
  end

  def run(opts \\ []) when is_list(opts) do
    with {:ok, config} <- validate_options(opts) do
      keys = candidate_keys(config.after_key, config.club_ids, config.batch_size + 1)
      items = Enum.take(keys, config.batch_size)
      incomplete? = length(keys) > config.batch_size

      initial = %{
        mode: config.mode,
        namespace: config.namespace,
        batch_size: config.batch_size,
        attempted: 0,
        fence_recorded: 0,
        reconciled: 0,
        already_reconciled: 0,
        already_current: 0,
        ended: 0,
        inactive_at_fence: 0,
        next_cursor: serialize_cursor(config.after_key),
        outcomes: []
      }

      case process_items(items, initial, config) do
        {:ok, report} when incomplete? ->
          {:error, %{reason: :incomplete_batch, resumable: true, report: report}}

        result ->
          result
      end
    end
  end

  def run!(opts \\ []) do
    case run(opts) do
      {:ok, report} -> report
      {:error, reason} -> raise RuntimeError, inspect(reason, pretty: true)
    end
  end

  defp process_items(items, initial, config) do
    Enum.reduce_while(items, {:ok, initial}, fn key, {:ok, report} ->
      case reconcile_key(key, config) do
        {:ok, outcome} ->
          report =
            report
            |> record_outcome(key, outcome)
            |> Map.put(:next_cursor, serialize_cursor(key))

          {:cont, {:ok, report}}

        {:error, reason} ->
          {:halt,
           {:error,
            %{
              reason: reason,
              key: serialize_cursor(key),
              resumable: true,
              report: report
            }}}
      end
    end)
  end

  defp reconcile_key({club_id, _group_id, _club_membership_id}, %{mode: :record_fences} = config) do
    case canonical_fenced_state(club_id, :record_fences, config.namespace) do
      {:ok, _history, _aggregate, fence_version} ->
        {:ok, %{status: :fence_recorded, fence_stream_version: fence_version}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp reconcile_key({club_id, group_id, club_membership_id}, config) do
    with {:ok, history, aggregate, fence_version} <-
           canonical_fenced_state(club_id, config.mode, config.namespace),
         {:ok, relation} <-
           relation_at_fence(history, group_id, club_membership_id, fence_version) do
      case relation do
        nil ->
          {:ok, %{status: :inactive_at_fence}}

        relation ->
          command = %ReconcileLegacyGroupMembership{
            club_id: club_id,
            group_id: group_id,
            group_membership_id:
              group_membership_id(club_id, group_id, club_membership_id, config.namespace),
            club_membership_id: club_membership_id,
            person_id: relation.person_id,
            namespace: config.namespace,
            fence_stream_version: fence_version,
            source_stream_version: relation.source_stream_version
          }

          decide_or_dispatch(aggregate, command, config.mode)
      end
    end
  end

  defp canonical_fenced_state(club_id, mode, namespace) do
    history = stream_history(club_id)

    case fence_from_history(history) do
      {:ok, %{namespace: ^namespace, source_stream_version: fence_version}} ->
        {:ok, history, fold_aggregate(history), fence_version}

      {:ok, _different_fence} ->
        {:error, :reconciliation_fence_conflict}

      :error when mode == :record_fences ->
        record_fence(club_id, namespace, latest_stream_version(history))

      :error ->
        {:error, :reconciliation_fence_not_recorded}
    end
  end

  defp record_fence(club_id, namespace, expected_stream_version) do
    command = %RecordLegacyGroupMembershipReconciliationFence{
      club_id: club_id,
      namespace: namespace,
      expected_stream_version: expected_stream_version
    }

    case App.dispatch(command) do
      :ok -> canonical_fenced_state(club_id, :apply, namespace)
      {:ok, _result} -> canonical_fenced_state(club_id, :apply, namespace)
      {:error, reason} -> {:error, reason}
    end
  end

  defp decide_or_dispatch(aggregate, command, :dry_run) do
    aggregate
    |> Club.execute(command)
    |> classify_decision(command, :dry_run)
  end

  defp decide_or_dispatch(_aggregate, command, :apply) do
    command
    |> App.dispatch(returning: :execution_result)
    |> classify_decision(command, :apply)
  end

  defp classify_decision(
         [%Memba.Membership.Events.GroupMembershipStarted{}, %LegacyGroupMembershipReconciled{}],
         command,
         mode
       ) do
    {:ok,
     %{
       status: :reconciled,
       mode: mode,
       group_membership_id: command.group_membership_id,
       fence_stream_version: command.fence_stream_version,
       source_stream_version: command.source_stream_version
     }}
  end

  defp classify_decision({:ok, %ExecutionResult{events: events}}, command, mode),
    do: classify_decision(events, command, mode)

  defp classify_decision(:ok, command, :apply),
    do:
      {:ok,
       %{status: :reconciled, mode: :apply, group_membership_id: command.group_membership_id}}

  defp classify_decision([], command, mode) do
    {:ok,
     %{
       status: :already_reconciled,
       mode: mode,
       group_membership_id: command.group_membership_id
     }}
  end

  defp classify_decision({:error, :first_class_relation_current}, command, mode) do
    {:ok,
     %{status: :already_current, mode: mode, group_membership_id: command.group_membership_id}}
  end

  defp classify_decision({:error, :first_class_relation_ended}, command, mode) do
    {:ok, %{status: :ended, mode: mode, group_membership_id: command.group_membership_id}}
  end

  defp classify_decision({:error, reason}, _command, _mode), do: {:error, reason}
  defp classify_decision(other, _command, _mode), do: {:error, {:unexpected_decision, other}}

  defp relation_at_fence(history, group_id, membership_id, fence_version) do
    relation =
      history
      |> Enum.take_while(&(&1.stream_version <= fence_version))
      |> Enum.reduce(nil, fn
        %{data: %event_module{} = event, stream_version: version}, relation
        when event_module in [GroupMemberAdded, GroupMemberRemoved] ->
          if event.group_id == group_id and event.membership_id == membership_id do
            %{
              active: event_module == GroupMemberAdded,
              person_id: event.person_id,
              source_stream_version: version
            }
          else
            relation
          end

        _recorded, relation ->
          relation
      end)

    case relation do
      %{active: true} = active -> {:ok, Map.delete(active, :active)}
      _inactive_or_missing -> {:ok, nil}
    end
  end

  defp fence_from_history(history) do
    case Enum.find(
           history,
           &match?(%{data: %LegacyGroupMembershipReconciliationFenceRecorded{}}, &1)
         ) do
      %{data: event} ->
        {:ok, %{namespace: event.namespace, source_stream_version: event.source_stream_version}}

      nil ->
        :error
    end
  end

  defp stream_history(club_id) do
    App |> EventStore.stream_forward(club_id) |> Enum.to_list()
  end

  defp fold_aggregate(history) do
    Enum.reduce(history, %Club{}, fn recorded, aggregate ->
      Club.apply(aggregate, recorded.data)
    end)
  end

  defp latest_stream_version([]), do: 0
  defp latest_stream_version(history), do: List.last(history).stream_version

  defp candidate_keys(after_key, club_ids, limit) do
    {after_club_id, after_group_id, after_membership_id} = after_key || {"", "", ""}

    Repo.query!(
      """
      SELECT DISTINCT
        stream.stream_uuid,
        convert_from(event.data, 'UTF8')::jsonb ->> 'group_id',
        convert_from(event.data, 'UTF8')::jsonb ->> 'membership_id'
      FROM event_store.events AS event
      JOIN event_store.stream_events AS stream_event ON stream_event.event_id = event.event_id
      JOIN event_store.streams AS stream ON stream.stream_id = stream_event.stream_id
      WHERE stream.stream_uuid LIKE 'clb\\_%' ESCAPE '\\'
        AND event.event_type IN (
          'Elixir.Memba.Membership.Events.GroupMemberAdded',
          'Elixir.Memba.Membership.Events.GroupMemberRemoved'
        )
        AND NOT EXISTS (
          SELECT 1
          FROM event_store.events AS group_event
          JOIN event_store.stream_events AS group_stream_event
            ON group_stream_event.event_id = group_event.event_id
          WHERE group_stream_event.stream_id = stream.stream_id
            AND group_event.event_type = 'Elixir.Memba.Membership.Events.GroupCreated'
            AND convert_from(group_event.data, 'UTF8')::jsonb ->> 'group_id' =
              convert_from(event.data, 'UTF8')::jsonb ->> 'group_id'
            AND convert_from(group_event.data, 'UTF8')::jsonb ->> 'group_key' IN ('everyone', 'admin')
        )
        AND ($1::boolean = FALSE OR stream.stream_uuid = ANY($2::text[]))
        AND (
          $3::boolean = FALSE
          OR (
            stream.stream_uuid,
            convert_from(event.data, 'UTF8')::jsonb ->> 'group_id',
            convert_from(event.data, 'UTF8')::jsonb ->> 'membership_id'
          ) > ($4::text, $5::text, $6::text)
        )
      ORDER BY 1, 2, 3
      LIMIT $7
      """,
      [
        not is_nil(club_ids),
        club_ids || [],
        not is_nil(after_key),
        after_club_id,
        after_group_id,
        after_membership_id,
        limit
      ]
    ).rows
    |> Enum.map(&List.to_tuple/1)
    |> Enum.filter(fn {club_id, group_id, _membership_id} ->
      SystemGroups.custom_group?(%{club_id: club_id, group_id: group_id})
    end)
  end

  defp record_outcome(report, key, outcome) do
    report
    |> Map.update!(:attempted, &(&1 + 1))
    |> Map.update!(outcome.status, &(&1 + 1))
    |> Map.update!(:outcomes, &[%{key: serialize_cursor(key), outcome: outcome} | &1])
  end

  defp validate_options(opts) do
    mode = Keyword.get(opts, :mode, :dry_run)
    batch_size = Keyword.get(opts, :batch_size, @default_batch_size)
    after_key = normalize_cursor(Keyword.get(opts, :after))
    club_ids = Keyword.get(opts, :club_ids)
    namespace = Keyword.get(opts, :namespace, @namespace)
    acknowledgement = Keyword.get(opts, :cutover_acknowledgement)

    cond do
      mode not in [:dry_run, :apply, :record_fences] ->
        {:error, :invalid_mode}

      not is_integer(batch_size) or batch_size < 1 or batch_size > @max_batch_size ->
        {:error, :invalid_batch_size}

      after_key == :error ->
        {:error, :invalid_cursor}

      not valid_cursor?(after_key) ->
        {:error, :invalid_cursor}

      not valid_club_ids?(club_ids) ->
        {:error, :invalid_club_ids}

      not is_binary(namespace) or namespace == "" ->
        {:error, :invalid_namespace}

      mode in [:apply, :record_fences] and acknowledgement != @cutover_acknowledgement ->
        {:error, :cutover_acknowledgement_required}

      true ->
        {:ok,
         %{
           mode: mode,
           batch_size: batch_size,
           after_key: after_key,
           club_ids: club_ids,
           namespace: namespace
         }}
    end
  end

  defp normalize_cursor(nil), do: nil

  defp normalize_cursor([club_id, group_id, membership_id]),
    do: {club_id, group_id, membership_id}

  defp normalize_cursor({club_id, group_id, membership_id}),
    do: {club_id, group_id, membership_id}

  defp normalize_cursor(_cursor), do: :error

  defp valid_cursor?(nil), do: true

  defp valid_cursor?({club_id, group_id, membership_id}) do
    ID.valid?(:club, club_id) and ID.valid?(:group, group_id) and
      ID.valid?(:membership, membership_id)
  end

  defp valid_cursor?(_cursor), do: false

  defp valid_club_ids?(nil), do: true

  defp valid_club_ids?(ids) when is_list(ids) and ids != [],
    do: Enum.all?(ids, &ID.valid?(:club, &1))

  defp valid_club_ids?(_ids), do: false

  defp serialize_cursor(nil), do: nil
  defp serialize_cursor(cursor), do: Tuple.to_list(cursor)
end
