defmodule Memba.Messaging.EmailDeliveryProviderConfig do
  @moduledoc """
  Runtime configuration helpers for selecting the messaging email delivery provider.

  Real email email delivery providers are selected only when a deployment explicitly opts in.
  Leaving the environment variable unset preserves the application default, which
  is the fake provider in local development and tests.
  """

  alias Memba.Messaging.EmailDeliveryProviders.Fake
  alias Memba.Messaging.EmailDeliveryProviders.Postmark

  @provider_env "MEMBA_MESSAGING_DELIVERY_PROVIDER"
  @providers %{
    "fake" => Fake,
    "postmark" => Postmark
  }

  @doc """
  Resolve an optional delivery-provider environment value.

  Returns `:default` when no explicit provider was configured, so existing
  application configuration remains in force.
  """
  def provider_override(nil), do: :default

  def provider_override(value) when is_binary(value) do
    provider_name = value |> String.trim() |> String.downcase()

    case provider_name do
      "" ->
        :default

      provider_name ->
        case Map.fetch(@providers, provider_name) do
          {:ok, provider} -> {:ok, provider}
          :error -> {:error, unsupported_provider_message(value)}
        end
    end
  end

  @doc """
  Resolve an optional delivery-provider environment value or raise clearly.
  """
  def provider_override!(value) do
    case provider_override(value) do
      :default -> :default
      {:ok, provider} -> provider
      {:error, message} -> raise ArgumentError, message
    end
  end

  defp unsupported_provider_message(value) do
    supported = @providers |> Map.keys() |> Enum.sort() |> Enum.join(", ")

    "Unsupported #{@provider_env}=#{inspect(value)}. " <>
      "Supported values are: #{supported}."
  end
end
