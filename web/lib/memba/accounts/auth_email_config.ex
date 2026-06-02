defmodule Memba.Accounts.AuthEmailConfig do
  @moduledoc """
  Runtime configuration for shared sign-in-link auth emails.

  Auth email delivery is enabled explicitly with `MEMBA_AUTH_EMAIL_PROVIDER`.
  When Postmark delivery is enabled, the shared Postmark server token, auth
  sender, and dedicated auth message stream must all be configured.
  """

  @enforce_keys [:from, :message_stream]
  defstruct [:server_token, :from, :message_stream]

  @provider_env "MEMBA_AUTH_EMAIL_PROVIDER"
  @server_token_env "MEMBA_POSTMARK_SERVER_TOKEN"
  @from_address_env "MEMBA_AUTH_EMAIL_FROM_ADDRESS"
  @message_stream_env "MEMBA_AUTH_EMAIL_MESSAGE_STREAM"

  @type t :: %__MODULE__{
          server_token: String.t(),
          from: String.t(),
          message_stream: String.t()
        }

  @doc """
  Decide whether auth email delivery has been explicitly enabled.
  """
  def provider_override(value)

  def provider_override(value) when is_binary(value) do
    case value |> String.trim() |> String.downcase() do
      "" -> :default
      "postmark" -> {:ok, :postmark}
      provider -> {:error, unsupported_provider_message(provider)}
    end
  end

  def provider_override(nil), do: :default
  def provider_override(value), do: {:error, unsupported_provider_message(value)}

  @doc """
  Decide whether auth email delivery has been enabled, or raise on bad input.
  """
  def provider_override!(value) do
    case provider_override(value) do
      {:ok, provider} -> provider
      :default -> :default
      {:error, message} -> raise ArgumentError, message
    end
  end

  @doc """
  Read and validate required auth email Postmark settings from environment.
  """
  def from_env(get_env \\ &System.get_env/1) when is_function(get_env, 1) do
    validate(
      %{
        @server_token_env => get_env.(@server_token_env),
        @from_address_env => get_env.(@from_address_env),
        @message_stream_env => get_env.(@message_stream_env)
      },
      required: postmark_config_keys(),
      source: :environment
    )
  end

  @doc """
  Read and validate required auth email Postmark settings from environment or raise.
  """
  def from_env!(get_env \\ &System.get_env/1) when is_function(get_env, 1) do
    case from_env(get_env) do
      {:ok, config} -> config
      {:error, message} -> raise ArgumentError, message
    end
  end

  @doc """
  Read and validate required auth email Postmark settings from application config.
  """
  def from_application_env do
    mailer_config = Application.get_env(:memba, Memba.Mailer, [])
    auth_email_config = Application.get_env(:memba, Memba.Accounts.AuthEmail, [])

    validate(
      %{
        @server_token_env => Keyword.get(mailer_config, :api_key),
        @from_address_env => Keyword.get(auth_email_config, :from),
        @message_stream_env => Keyword.get(auth_email_config, :message_stream)
      },
      required: email_config_keys(),
      source: :application
    )
  end

  @doc """
  Read and validate required auth email Postmark settings from application config or raise.
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

    required_config_keys = Keyword.fetch!(opts, :required)

    missing_required =
      normalized_values
      |> Map.take(required_config_keys)
      |> Enum.filter(fn {_key, value} -> is_nil(value) end)
      |> Enum.map(fn {key, _value} -> key end)
      |> Enum.sort()

    case missing_required do
      [] ->
        {:ok,
         %__MODULE__{
           server_token: Map.get(normalized_values, @server_token_env),
           from: Map.fetch!(normalized_values, @from_address_env),
           message_stream: Map.fetch!(normalized_values, @message_stream_env)
         }}

      missing ->
        {:error, missing_config_message(missing, required_config_keys, opts[:source])}
    end
  end

  defp normalize(value) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      value -> value
    end
  end

  defp normalize(_value), do: nil

  defp postmark_config_keys, do: [@server_token_env | email_config_keys()]
  defp email_config_keys, do: [@from_address_env, @message_stream_env]

  defp missing_config_message(missing, required_config_keys, source) do
    "Auth email Postmark delivery is enabled, but required #{source_label(source)} " <>
      "configuration is missing: #{Enum.join(missing, ", ")}. " <>
      "Set #{Enum.join(required_config_keys, ", ")}, or leave " <>
      "#{@provider_env} unset to skip real auth email delivery."
  end

  defp source_label(:application), do: "application"
  defp source_label(:environment), do: "environment"

  defp unsupported_provider_message(provider) do
    "Unsupported #{@provider_env}=#{inspect(provider)}. Set #{@provider_env}=postmark " <>
      "to enable real auth email delivery, or leave it unset."
  end
end
