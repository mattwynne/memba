defmodule Memba.Messaging.DeliveryProviders.PostmarkConfig do
  @moduledoc """
  Required runtime configuration for the Postmark delivery provider.

  Real Postmark delivery is only enabled when explicitly selected. When it is
  selected, the server token and sender/from address must be present so the
  failure mode is clear instead of silently falling back to fake delivery.
  """

  @enforce_keys [:server_token, :from]
  defstruct [:server_token, :from]

  @server_token_env "MEMBA_POSTMARK_SERVER_TOKEN"
  @from_address_env "MEMBA_POSTMARK_FROM_ADDRESS"

  @type t :: %__MODULE__{
          server_token: String.t(),
          from: String.t()
        }

  @doc """
  Read and validate required Postmark provider settings from environment.
  """
  def from_env(get_env \\ &System.get_env/1) when is_function(get_env, 1) do
    validate(
      %{
        @server_token_env => get_env.(@server_token_env),
        @from_address_env => get_env.(@from_address_env)
      },
      source: :environment
    )
  end

  @doc """
  Read and validate required Postmark provider settings from environment or raise.
  """
  def from_env!(get_env \\ &System.get_env/1) when is_function(get_env, 1) do
    case from_env(get_env) do
      {:ok, config} -> config
      {:error, message} -> raise ArgumentError, message
    end
  end

  @doc """
  Read and validate required Postmark provider settings from application config.
  """
  def from_application_env do
    mailer_config = Application.get_env(:memba, Memba.Mailer, [])
    provider_config = Application.get_env(:memba, Memba.Messaging.DeliveryProviders.Postmark, [])

    validate(
      %{
        @server_token_env => Keyword.get(mailer_config, :api_key),
        @from_address_env => Keyword.get(provider_config, :from)
      },
      source: :application
    )
  end

  @doc """
  Read and validate required Postmark provider settings from application config or raise.
  """
  def from_application_env! do
    case from_application_env() do
      {:ok, config} -> config
      {:error, message} -> raise ArgumentError, message
    end
  end

  defp validate(values, opts) do
    normalized_values =
      Map.new(values, fn {key, value} ->
        {key, normalize(value)}
      end)

    missing =
      normalized_values
      |> Enum.filter(fn {_key, value} -> is_nil(value) end)
      |> Enum.map(fn {key, _value} -> key end)
      |> Enum.sort()

    case missing do
      [] ->
        {:ok,
         %__MODULE__{
           server_token: Map.fetch!(normalized_values, @server_token_env),
           from: Map.fetch!(normalized_values, @from_address_env)
         }}

      missing ->
        {:error, missing_config_message(missing, opts[:source])}
    end
  end

  defp normalize(value) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      value -> value
    end
  end

  defp normalize(_value), do: nil

  defp missing_config_message(missing, source) do
    "Postmark delivery provider is enabled, but required #{source_label(source)} " <>
      "configuration is missing: #{Enum.join(missing, ", ")}. " <>
      "Set #{@server_token_env} and #{@from_address_env}, or leave " <>
      "MEMBA_MESSAGING_DELIVERY_PROVIDER unset to use the fake provider."
  end

  defp source_label(:application), do: "application"
  defp source_label(:environment), do: "environment"
end
