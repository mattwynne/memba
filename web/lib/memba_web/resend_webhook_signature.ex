defmodule MembaWeb.ResendWebhookSignature do
  @moduledoc false

  @signing_secret_env_var "MEMBA_RESEND_WEBHOOK_SIGNING_SECRET"
  @max_timestamp_age_seconds 5 * 60

  def signing_secret_from_env!(env, env_fun \\ &System.get_env/1) when is_function(env_fun, 1) do
    case env_fun.(@signing_secret_env_var) |> normalize_config_value() do
      nil when env == :prod ->
        raise """
        environment variable #{@signing_secret_env_var} is missing.
        Production Resend inbound webhooks must be verified with a Svix signing secret.
        """

      nil ->
        nil

      signing_secret ->
        signing_secret
    end
  end

  def verify(conn, secret \\ configured_secret()) do
    with {:ok, secret} <- normalize_secret(secret),
         {:ok, body} <- raw_body(conn),
         {:ok, svix_id} <- header(conn, "svix-id"),
         {:ok, svix_timestamp} <- header(conn, "svix-timestamp"),
         :ok <- verify_timestamp(svix_timestamp),
         {:ok, signatures} <- signatures(conn),
         expected_signature <- sign(secret, svix_id, svix_timestamp, body),
         true <- signed?(signatures, expected_signature) do
      :ok
    else
      false -> {:error, :invalid_signature}
      {:error, _reason} = error -> error
    end
  end

  def configured? do
    case configured_secret() do
      secret when is_binary(secret) -> String.trim(secret) != ""
      _other -> false
    end
  end

  defp normalize_config_value(value) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      trimmed -> trimmed
    end
  end

  defp normalize_config_value(_value), do: nil

  defp configured_secret do
    Application.get_env(:memba, __MODULE__, [])
    |> Keyword.get(:signing_secret)
  end

  defp normalize_secret(secret) when is_binary(secret) do
    case String.trim(secret) do
      "" -> {:error, :missing_signing_secret}
      "whsec_" <> encoded_secret -> Base.decode64(encoded_secret)
      encoded_secret -> Base.decode64(encoded_secret)
    end
  end

  defp normalize_secret(_secret), do: {:error, :missing_signing_secret}

  defp raw_body(%Plug.Conn{assigns: %{raw_body: body}}) when is_binary(body), do: {:ok, body}
  defp raw_body(_conn), do: {:error, :missing_raw_body}

  defp header(conn, header_name) do
    case Plug.Conn.get_req_header(conn, header_name) do
      [value | _rest] when is_binary(value) and value != "" -> {:ok, value}
      _missing -> {:error, {:missing_header, header_name}}
    end
  end

  defp verify_timestamp(timestamp) do
    case Integer.parse(timestamp) do
      {timestamp_seconds, ""} ->
        if abs(System.system_time(:second) - timestamp_seconds) <= @max_timestamp_age_seconds do
          :ok
        else
          {:error, :stale_timestamp}
        end

      _invalid ->
        {:error, :invalid_timestamp}
    end
  end

  defp signatures(conn) do
    conn
    |> Plug.Conn.get_req_header("svix-signature")
    |> Enum.flat_map(&String.split(&1, " ", trim: true))
    |> Enum.map(&String.trim/1)
    |> Enum.filter(&(&1 != ""))
    |> case do
      [] -> {:error, {:missing_header, "svix-signature"}}
      signatures -> {:ok, signatures}
    end
  end

  defp sign(secret, svix_id, svix_timestamp, body) do
    signed_content = [svix_id, svix_timestamp, body] |> Enum.join(".")

    digest = :crypto.mac(:hmac, :sha256, secret, signed_content)
    "v1," <> Base.encode64(digest)
  end

  defp signed?(signatures, expected_signature) do
    Enum.any?(signatures, fn signature ->
      byte_size(signature) == byte_size(expected_signature) and
        Plug.Crypto.secure_compare(signature, expected_signature)
    end)
  end
end
