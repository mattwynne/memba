defmodule Memba.Messaging.EmailDeliveryProviders.SelectiveFailure do
  @moduledoc """
  Test email delivery provider that records every request and fails configured recipients.
  """

  use Agent

  alias Memba.Messaging.EmailDeliveryProvider
  alias Memba.Messaging.EmailDeliveryRequest

  @behaviour EmailDeliveryProvider

  def start_link(_opts) do
    Agent.start_link(fn -> %{requests: [], failing_addresses: MapSet.new()} end, name: __MODULE__)
  end

  @impl EmailDeliveryProvider
  def deliver(%EmailDeliveryRequest{} = request) do
    Agent.get_and_update(__MODULE__, fn state ->
      state = update_in(state.requests, &[request | &1])

      result =
        if MapSet.member?(state.failing_addresses, request.recipient_address) do
          {:error, {:selective_failure, request.recipient_address}}
        else
          :ok
        end

      {result, state}
    end)
  end

  def fail_addresses(addresses) when is_list(addresses) do
    Agent.update(__MODULE__, fn state ->
      %{state | failing_addresses: MapSet.new(addresses)}
    end)
  end

  def deliveries do
    Agent.get(__MODULE__, fn state -> Enum.reverse(state.requests) end)
  end

  def reset do
    Agent.update(__MODULE__, fn _state -> %{requests: [], failing_addresses: MapSet.new()} end)
  end
end
