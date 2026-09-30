defmodule MembaWeb.LiveQuery.Query do
  @moduledoc """
  Provisional, app-private description of one LiveView-owned query.

  A query has a stable identity, owns exactly one public socket assign, and
  reads one coherent result from its current inputs. Its interests are opaque
  to the query and binding; only the injected source knows how to match them.

  This contract is intentionally local to Memba while the iteration proves it
  against real consumers. It is not the frozen API of the future package.
  """

  @enforce_keys [:id, :assign, :load]
  defstruct [:id, :assign, :load]

  @type success :: {:ok, result :: term(), interests :: [term()]}
  @type access_error :: {:error, reason :: term()}
  @type loader :: (inputs :: term() -> success() | access_error())

  @type t :: %__MODULE__{
          id: term(),
          assign: atom(),
          load: loader()
        }

  @doc """
  Builds a provisional query description.
  """
  @spec new!(keyword()) :: t()
  def new!(options) when is_list(options) do
    id = Keyword.fetch!(options, :id)
    assign = Keyword.fetch!(options, :assign)
    load = Keyword.fetch!(options, :load)

    unless is_atom(assign) do
      raise ArgumentError, "live query assign must be an atom, got: #{inspect(assign)}"
    end

    unless is_function(load, 1) do
      raise ArgumentError, "live query load must be a one-argument function"
    end

    %__MODULE__{id: id, assign: assign, load: load}
  end

  @doc false
  @spec load(t(), term()) :: success() | access_error()
  def load(%__MODULE__{load: load}, inputs), do: load.(inputs)
end
