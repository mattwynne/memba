defmodule Memba.TestSupport.FailingSwooshAdapter do
  @moduledoc false

  @behaviour Swoosh.Adapter

  @impl Swoosh.Adapter
  def validate_config(config) do
    case Keyword.get(config, :test_validate_config_error) do
      nil -> :ok
      message -> raise ArgumentError, message
    end
  end

  @impl Swoosh.Adapter
  def validate_dependency, do: :ok

  @impl Swoosh.Adapter
  def deliver(email, config) do
    if owner = Keyword.get(config, :test_owner) do
      send(owner, {:failing_swoosh_adapter_deliver, email})
    end

    case Keyword.fetch!(config, :test_delivery_result) do
      {:raise, message} -> raise ArgumentError, message
      result -> result
    end
  end
end
