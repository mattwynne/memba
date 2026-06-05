defmodule MembaWeb.ResendReceivedEmail do
  @moduledoc """
  Retrieves full Resend received-email content when webhook payloads contain only metadata.

  Resend's `email.received` webhook intentionally omits body, headers, and full
  attachment details. The webhook includes `data.email_id`; callers can use the
  Received emails API to retrieve the text/html bodies before handing the payload
  to Memba's provider-neutral inbound email parser.
  """

  @api_base_url "https://api.resend.com"

  def enrich_payload(payload) when is_map(payload) do
    with {:ok, data} <- fetch_data(payload),
         false <- has_body?(data),
         {:ok, email_id} <- email_id(data),
         {:ok, received_email} <- client().get_received_email(email_id) do
      {:ok, put_data(payload, Map.merge(data, received_email))}
    else
      true -> {:ok, payload}
      {:error, _reason} = error -> error
    end
  end

  def enrich_payload(_payload), do: {:error, :invalid_payload}

  def get_received_email(email_id) when is_binary(email_id) do
    with {:ok, api_key} <- api_key() do
      @api_base_url
      |> URI.merge("/emails/receiving/#{URI.encode(email_id)}")
      |> Req.get(
        headers: [
          {"authorization", "Bearer #{api_key}"},
          {"accept", "application/json"}
        ]
      )
      |> case do
        {:ok, %Req.Response{status: status, body: body}} when status in 200..299 ->
          normalize_received_email(body)

        {:ok, %Req.Response{status: status, body: body}} ->
          {:error, {:resend_received_email_api_error, status, body}}

        {:error, reason} ->
          {:error, {:resend_received_email_api_error, reason}}
      end
    end
  end

  def get_received_email(_email_id), do: {:error, :invalid_provider_message_id}

  defp fetch_data(payload) do
    case value(payload, [:data, "data"]) do
      data when is_map(data) -> {:ok, data}
      _other -> {:error, {:missing_required_attribute, "data"}}
    end
  end

  defp has_body?(data) do
    present_binary?(value(data, [:text, "text"])) or present_binary?(value(data, [:html, "html"]))
  end

  defp email_id(data) do
    data
    |> value([:email_id, "email_id", :id, "id"])
    |> case do
      value when is_binary(value) ->
        case String.trim(value) do
          "" -> {:error, {:missing_required_attribute, "data.email_id"}}
          email_id -> {:ok, email_id}
        end

      nil ->
        {:error, {:missing_required_attribute, "data.email_id"}}

      _other ->
        {:error, :invalid_provider_message_id}
    end
  end

  defp put_data(payload, data) do
    cond do
      Map.has_key?(payload, "data") -> Map.put(payload, "data", data)
      Map.has_key?(payload, :data) -> Map.put(payload, :data, data)
      true -> Map.put(payload, "data", data)
    end
  end

  defp normalize_received_email(body) when is_map(body) do
    {:ok,
     %{
       "text" => value(body, [:text, "text"]),
       "html" => value(body, [:html, "html"]),
       "headers" => value(body, [:headers, "headers"]),
       "attachments" => value(body, [:attachments, "attachments"])
     }
     |> Enum.reject(fn {_key, value} -> is_nil(value) end)
     |> Map.new()}
  end

  defp normalize_received_email(_body), do: {:error, :invalid_resend_received_email_response}

  defp api_key do
    case configured_api_key() do
      nil -> {:error, :missing_resend_api_key}
      api_key -> {:ok, api_key}
    end
  end

  defp configured_api_key do
    :memba
    |> Application.get_env(__MODULE__, [])
    |> Keyword.get(:api_key)
    |> present_or_else(fn -> System.get_env("MEMBA_RESEND_API_KEY") end)
    |> present_or_else(fn -> System.get_env("RESEND_API_KEY") end)
    |> present_or_else(fn -> System.get_env("RESEND_ADMIN_API_KEY") end)
  end

  defp client do
    :memba
    |> Application.get_env(__MODULE__, [])
    |> Keyword.get(:client, __MODULE__)
  end

  defp value(map, keys) when is_map(map) do
    Enum.find_value(keys, fn key ->
      if Map.has_key?(map, key), do: Map.get(map, key)
    end)
  end

  defp value(_map, _keys), do: nil

  defp present_binary?(value) when is_binary(value), do: String.trim(value) != ""
  defp present_binary?(_value), do: false

  defp present_or_else(value, fallback) when is_function(fallback, 0) do
    if present_binary?(value), do: value, else: fallback.()
  end
end
