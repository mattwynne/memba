defmodule LiveQuery.Source do
  @moduledoc """
  Defines the injected source boundary for live-query notifications.

  A source subscribes the owning connected LiveView process, classifies raw
  notifications into opaque invalidations, and decides whether an invalidation
  matches an opaque query interest. Applications retain ownership of the
  interest and invalidation vocabulary.
  """

  @enforce_keys [:subscribe, :classify, :matches?]
  defstruct [:subscribe, :classify, :matches?]

  @type t :: %__MODULE__{
          subscribe: (-> :ok | {:error, term()}),
          classify: (term() -> :ignore | {:ok, [term()]}),
          matches?: (term(), term() -> boolean())
        }

  @doc """
  Builds a source from subscription, classification, and matching functions.
  """
  @spec new!(keyword()) :: t()
  def new!(options) when is_list(options) do
    subscribe = Keyword.fetch!(options, :subscribe)
    classify = Keyword.fetch!(options, :classify)
    matches? = Keyword.fetch!(options, :matches?)

    unless is_function(subscribe, 0) do
      raise ArgumentError, "live query source subscribe must be a zero-argument function"
    end

    unless is_function(classify, 1) do
      raise ArgumentError, "live query source classify must be a one-argument function"
    end

    unless is_function(matches?, 2) do
      raise ArgumentError, "live query source matches? must be a two-argument function"
    end

    %__MODULE__{subscribe: subscribe, classify: classify, matches?: matches?}
  end

  @doc false
  @spec subscribe(t()) :: :ok | {:error, term()}
  def subscribe(%__MODULE__{subscribe: subscribe}), do: subscribe.()

  @doc false
  @spec classify(t(), term()) :: :ignore | {:ok, [term()]}
  def classify(%__MODULE__{classify: classify}, notification), do: classify.(notification)

  @doc false
  @spec matches?(t(), term(), term()) :: boolean()
  def matches?(%__MODULE__{matches?: matches?}, interest, invalidation),
    do: matches?.(interest, invalidation)
end
