defmodule Memba.Messaging.MemberSubmission do
  @moduledoc """
  One open-form attempt to submit a member message. The message ID is the operation
  ID. An immutable digest of the intended action is recorded in MessageSent, so
  a duplicate ID is accepted only when the write-side event matches this intent.
  Acceptance does not imply provider delivery.
  """

  alias Commanded.EventStore
  alias Memba.ID
  alias Memba.Messaging.App
  alias Memba.Messaging.Events.MessageSent

  defstruct [:message_id, :intent, :kind, :attrs]

  def new(kind, attrs) when kind in [:club_message, :reply, :group_access] and is_map(attrs) do
    message_id = ID.generate(:message)
    attrs = Map.new(attrs, fn {key, value} -> {to_string(key), value} end)
    # A length-delimited Erlang term representation avoids ambiguous concatenation.
    canonical = Enum.sort(Map.to_list(attrs))

    intent =
      :crypto.hash(:sha256, :erlang.term_to_binary({kind, canonical}))
      |> Base.encode16(case: :lower)

    %__MODULE__{message_id: message_id, intent: intent, kind: kind, attrs: attrs}
  end

  @doc """
  Returns {:accepted, id}, {:rejected, reason}, or {:uncertain, reason}.
  An unrecognized dispatch error (including a lost acknowledgement) cannot prove
  that the command did not commit. Reconciliation reads the event stream, never a
  lagging message projection.
  """
  def submit(%__MODULE__{} = operation, dispatch) when is_function(dispatch, 1) do
    case reconcile(operation) do
      :accepted -> {:accepted, operation.message_id}
      :conflict -> {:rejected, :operation_id_conflict}
      :missing -> dispatch_once(operation, dispatch)
      :unavailable -> {:uncertain, :reconciliation_unavailable}
    end
  end

  def same_intent?(%__MODULE__{kind: original_kind, attrs: original_attrs}, kind, attrs) do
    original_kind == kind and
      original_attrs == Map.new(attrs, fn {key, value} -> {to_string(key), value} end)
  end

  defp dispatch_once(operation, dispatch) do
    attrs =
      Map.merge(operation.attrs, %{
        "message_id" => operation.message_id,
        "operation_intent" => operation.intent
      })

    result =
      try do
        dispatch.(attrs)
      catch
        :exit, reason -> {:error, {:dispatch_exit, reason}}
      end

    case result do
      :ok -> {:accepted, operation.message_id}
      {:ok, _} -> {:accepted, operation.message_id}
      {:error, reason} -> resolve_error(operation, reason)
    end
  end

  defp resolve_error(operation, reason) do
    case reconcile(operation) do
      :accepted ->
        {:accepted, operation.message_id}

      :conflict ->
        {:rejected, :operation_id_conflict}

      :unavailable ->
        {:uncertain, reason}

      :missing ->
        if definite_rejection?(reason),
          do: {:rejected, reason},
          else: {:uncertain, reason}
    end
  end

  # Only failures known to occur before dispatch are definite. Other errors may
  # include projection timeouts after the event-store append.
  defp definite_rejection?(reason) do
    reason in [
      :forbidden,
      :not_current_member,
      :already_member,
      :audience_group_not_found,
      :invalid_body,
      :invalid_subject,
      :invalid_message_id,
      :invalid_audience_group_id,
      :invalid_conversation_reference,
      :reply_to_message_required
    ] or
      match?({:missing_required_attribute, _}, reason)
  end

  defp reconcile(operation) do
    try do
      case EventStore.stream_forward(App, operation.message_id) do
        {:error, :stream_not_found} ->
          :missing

        {:error, _} ->
          :unavailable

        events ->
          case Enum.find(events, fn %{data: data} -> match?(%MessageSent{}, data) end) do
            %{data: %MessageSent{operation_intent: intent}} when intent == operation.intent ->
              :accepted

            %{data: %MessageSent{}} ->
              :conflict

            _ ->
              :unavailable
          end
      end
    rescue
      _ -> :unavailable
    catch
      :exit, _ -> :unavailable
    end
  end
end
