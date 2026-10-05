defmodule MembaWeb.LiveQuery.ReadModelContractViolationError do
  @moduledoc """
  Raised when a recognized read-model publisher violates its event contract.

  The exception records only the projector, source-event module, and stable
  reason. It deliberately excludes the event payload.
  """

  @enforce_keys [:projector, :source_event, :reason]
  defexception [:projector, :source_event, :reason]

  @type t :: %__MODULE__{
          projector: module(),
          source_event: module() | :unstructured,
          reason: term()
        }

  @impl Exception
  def message(%__MODULE__{} = exception) do
    "read-model contract violation for projector #{inspect(exception.projector)}, " <>
      "source event #{inspect(exception.source_event)}: #{inspect(exception.reason)}"
  end
end
