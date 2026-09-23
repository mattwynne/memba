defmodule Memba.Messaging.ConversationSubscriptionCutover do
  @moduledoc "Singleton aggregate owning the immutable legacy-follow cutover fence."

  alias Memba.Messaging.Commands.AdvanceConversationSubscriptionCutoverCheckpoint
  alias Memba.Messaging.Commands.RecordConversationSubscriptionCutoverFence
  alias Memba.Messaging.Events.ConversationSubscriptionCutoverCheckpointAdvanced
  alias Memba.Messaging.Events.ConversationSubscriptionCutoverFenceRecorded

  @cutover_id "conversation-subscription-cutover-v1"
  @acknowledgement "NO_LEGACY_CONVERSATION_FOLLOW_WRITERS"

  defstruct fence: nil, checkpoint: nil

  def cutover_id, do: @cutover_id
  def acknowledgement, do: @acknowledgement

  @doc false
  def verify_terminal_marker_before_checkpoint(%__MODULE__{} = cutover, %{command: command}) do
    stream_id = Memba.Messaging.PersonConversationSubscriptions.stream_id(command.person_id)

    marker =
      case Commanded.EventStore.stream_forward(Memba.Messaging.App, stream_id) do
        {:error, :stream_not_found} ->
          nil

        events ->
          Enum.find(events, fn
            %{data: %Memba.Messaging.Events.LegacyConversationFollowReconciled{} = event} ->
              event.reconciliation_key == command.reconciliation_key and
                event.person_id == command.person_id and
                event.conversation_id == command.conversation_id and
                event.fence_position == cutover.fence.event_store_position

            _other ->
              false
          end)
      end

    if marker, do: :ok, else: {:error, :terminal_reconciliation_marker_not_recorded}
  end

  def execute(%__MODULE__{fence: nil}, %RecordConversationSubscriptionCutoverFence{} = command) do
    cond do
      command.cutover_id != @cutover_id ->
        {:error, :invalid_cutover_id}

      command.writers_stopped_acknowledgement != @acknowledgement ->
        {:error, :writers_stopped_acknowledgement_required}

      not is_binary(command.namespace) or command.namespace == "" ->
        {:error, :invalid_reconciliation_namespace}

      not is_binary(command.event_store_schema) or command.event_store_schema == "" ->
        {:error, :invalid_event_store_schema}

      not is_integer(command.event_store_position) or command.event_store_position < 0 ->
        {:error, :invalid_event_store_position}

      true ->
        struct(ConversationSubscriptionCutoverFenceRecorded, Map.from_struct(command))
    end
  end

  def execute(
        %__MODULE__{fence: %{namespace: namespace, event_store_schema: schema}},
        %RecordConversationSubscriptionCutoverFence{
          namespace: namespace,
          event_store_schema: schema,
          writers_stopped_acknowledgement: @acknowledgement
        }
      ),
      do: []

  def execute(%__MODULE__{}, %RecordConversationSubscriptionCutoverFence{}),
    do: {:error, :cutover_fence_conflict}

  def execute(%__MODULE__{fence: nil}, %AdvanceConversationSubscriptionCutoverCheckpoint{}),
    do: {:error, :cutover_fence_not_recorded}

  def execute(
        %__MODULE__{} = cutover,
        %AdvanceConversationSubscriptionCutoverCheckpoint{} = command
      ) do
    current_cursor = checkpoint_cursor(cutover.checkpoint)
    next_cursor = {command.person_id, command.conversation_id}

    cond do
      command.cutover_id != @cutover_id or command.namespace != cutover.fence.namespace ->
        {:error, :cutover_fence_conflict}

      command.expected_cursor != current_cursor ->
        {:error, :reconciliation_checkpoint_conflict}

      current_cursor != nil and next_cursor <= current_cursor ->
        {:error, :reconciliation_checkpoint_not_monotonic}

      not Memba.ID.valid?(:person, command.person_id) or
          not Memba.ID.valid?(:message, command.conversation_id) ->
        {:error, :invalid_reconciliation_checkpoint}

      command.reconciliation_key !=
          Memba.Messaging.PersonConversationSubscriptions.reconciliation_key(
            command.person_id,
            command.conversation_id,
            cutover.fence.event_store_position
          ) ->
        {:error, :reconciliation_key_mismatch}

      true ->
        %ConversationSubscriptionCutoverCheckpointAdvanced{
          cutover_id: command.cutover_id,
          namespace: command.namespace,
          previous_cursor: serialize_cursor(current_cursor),
          person_id: command.person_id,
          conversation_id: command.conversation_id,
          reconciliation_key: command.reconciliation_key
        }
    end
  end

  def apply(%__MODULE__{} = cutover, %ConversationSubscriptionCutoverFenceRecorded{} = event) do
    %{cutover | fence: Map.from_struct(event)}
  end

  def apply(%__MODULE__{} = cutover, %ConversationSubscriptionCutoverCheckpointAdvanced{} = event) do
    %{cutover | checkpoint: Map.from_struct(event)}
  end

  def apply(%__MODULE__{} = cutover, _event), do: cutover

  defp checkpoint_cursor(nil), do: nil
  defp checkpoint_cursor(checkpoint), do: {checkpoint.person_id, checkpoint.conversation_id}

  defp serialize_cursor(nil), do: nil
  defp serialize_cursor(cursor), do: Tuple.to_list(cursor)
end
