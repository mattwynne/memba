defmodule Memba.Messaging.DeliveryProviders.Fake do
  @moduledoc """
  Fake delivery provider used by the messaging skeleton and tests.

  Calls are stored in process state so tests and acceptance step definitions can
  assert exactly which recipient deliveries were handed to the provider.
  """

  use Agent

  alias Memba.Messaging.DeliveryProvider
  alias Memba.Messaging.DeliveryRequest

  @behaviour DeliveryProvider

  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)

    Agent.start_link(fn -> [] end, name: name)
  end

  @impl DeliveryProvider
  def deliver(%DeliveryRequest{} = request) do
    Agent.update(__MODULE__, fn requests -> [request | requests] end)
    :ok
  end

  @doc """
  Return delivery requests in the order they were handed to the provider.
  """
  def deliveries do
    Agent.get(__MODULE__, &Enum.reverse/1)
  end

  @doc """
  Clear recorded delivery requests.
  """
  def reset do
    Agent.update(__MODULE__, fn _requests -> [] end)
  end
end
