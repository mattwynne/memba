defmodule Memba.Messaging.EmailDeliveryProviderConfig do
  @moduledoc """
  Runtime configuration helpers for selecting the environment-wide email provider.

  One provider setting configures the shared mailer and the messaging delivery
  provider together. Leaving the environment variable unset preserves the
  application default.
  """

  alias Memba.Messaging.EmailDeliveryProviders.Fake
  alias Memba.Messaging.EmailDeliveryProviders.Local
  alias Memba.Messaging.EmailDeliveryProviders.Postmark
  alias Memba.Messaging.EmailDeliveryProviders.Resend

  @provider_env "MEMBA_EMAIL_PROVIDER"
  @providers %{
    "fake" => Fake,
    "local" => Local,
    "postmark" => Postmark,
    "resend" => Resend
  }

  @doc """
  Resolve an optional environment-wide email provider value.

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
