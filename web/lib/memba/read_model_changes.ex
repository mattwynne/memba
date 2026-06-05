defmodule Memba.ReadModelChanges do
  @moduledoc """
  Publishes read-model state changes after projectors commit them.

  Projectors call `publish/4` from their `after_update/3` callback. Subscribers can
  listen on `topic/0` to find out when any read model has changed, or derive a
  narrower topic from the published message if they need domain-specific fan-out.
  """

  @topic "read_model_changes"

  @type message :: %{
          projector: module(),
          source_event: struct(),
          metadata: map(),
          changes: map()
        }

  @doc """
  The PubSub topic for all committed read-model changes.
  """
  @spec topic() :: String.t()
  def topic, do: @topic

  @doc """
  Broadcast a committed read-model change.

  This is intended to be called from `Commanded.Projections.Ecto.after_update/3`,
  which runs only after the projector transaction has committed successfully.
  """
  @spec publish(module(), struct(), map(), map()) :: :ok | {:error, term()}
  def publish(projector, source_event, metadata, changes) when is_atom(projector) do
    Phoenix.PubSub.broadcast(
      Memba.PubSub,
      @topic,
      {:read_model_changed,
       %{
         projector: projector,
         source_event: source_event,
         metadata: metadata,
         changes: changes
       }}
    )
  end
end
