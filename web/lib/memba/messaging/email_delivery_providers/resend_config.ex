defmodule Memba.Messaging.EmailDeliveryProviders.ResendConfig do
  @moduledoc """
  Required runtime configuration for the Resend email delivery provider.

  Real Resend delivery is only enabled when explicitly selected. When it is
  selected, the API key and sender/from address must be present so the failure
  mode is clear instead of silently falling back to fake delivery. A monitored
  reply-to address is optional but used when configured.
  """

  @enforce_keys [:api_key, :from]
  defstruct [:api_key, :from, :reply_to]

  @api_key_env "MEMBA_RESEND_API_KEY"
  @from_address_env "MEMBA_RESEND_FROM_ADDRESS"
  @reply_to_address_env "MEMBA_RESEND_REPLY_TO_ADDRESS"

  @type t :: %__MODULE__{
          api_key: String.t(),
          from: String.t(),
          reply_to: String.t() | nil
        }

  @doc """
  Read and validate required Resend provider settings from environment.
  """
  def from_env(get_env \\ &System.get_env/1) when is_function(get_env, 1) do
    validate(
      %{
        @api_key_env => get_env.(@api_key_env),
        @from_address_env => get_env.(@from_address_env),
        @reply_to_address_env => get_env.(@reply_to_address_env)
      },
      source: :environment
    )
  end

  @doc """
  Read and validate required Resend provider settings from environment or raise.
  """
  def from_env!(get_env \\ &System.get_env/1) when is_function(get_env, 1) do
    case from_env(get_env) do
      {:ok, config} -> config
      {:error, message} -> raise ArgumentError, message
    end
  end

  @doc """
  Read and validate required Resend provider settings from application config.
  """
  def from_application_env do
    mailer_config = Application.get_env(:memba, Memba.Mailer, [])

    provider_config =
      Application.get_env(:memba, Memba.Messaging.EmailDeliveryProviders.Resend, [])

    validate(
      %{
        @api_key_env => Keyword.get(mailer_config, :api_key),
        @from_address_env => Keyword.get(provider_config, :from),
        @reply_to_address_env => Keyword.get(provider_config, :reply_to)
      },
      source: :application
    )
  end

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

    missing_required =
      normalized_values
      |> Map.take(required_config_keys())
      |> Enum.filter(fn {_key, value} -> is_nil(value) end)
      |> Enum.map(fn {key, _value} -> key end)
      |> Enum.sort()

    case missing_required do
      [] ->
        {:ok,
         %__MODULE__{
           api_key: Map.fetch!(normalized_values, @api_key_env),
           from: Map.fetch!(normalized_values, @from_address_env),
           reply_to: Map.fetch!(normalized_values, @reply_to_address_env)
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

  defp required_config_keys, do: [@api_key_env, @from_address_env]

  defp missing_config_message(missing, source) do
    "Resend email delivery provider is enabled, but required #{source_label(source)} " <>
      "configuration is missing: #{Enum.join(missing, ", ")}. " <>
      "Set #{@api_key_env} and #{@from_address_env}, or leave " <>
      "MEMBA_MESSAGING_DELIVERY_PROVIDER unset to use the fake provider."
  end

  defp source_label(:application), do: "application"
  defp source_label(:environment), do: "environment"
end
