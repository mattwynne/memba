defmodule MembaWeb.StaffMCP.Auth do
  @moduledoc false

  import Plug.Conn

  alias Memba.Accounts
  alias MembaWeb.{ClubSite, Endpoint}

  def init(opts), do: opts

  def call(conn, _opts) do
    cond do
      ClubSite.club_host?(conn.host) -> conn |> send_resp(:not_found, "") |> halt()
      allowed_origin?(conn) -> authenticate(conn)
      true -> conn |> send_resp(:forbidden, "") |> halt()
    end
  end

  def credentials_from_env!(nil), do: []

  def credentials_from_env!(json) do
    case Jason.decode(json) do
      {:ok, entries} when is_map(entries) ->
        credentials = Enum.map(entries, &credential!/1)

        if Enum.uniq_by(credentials, &elem(&1, 1)) != credentials do
          raise ArgumentError, "Staff MCP credential hashes must be unique"
        end

        credentials

      _ ->
        raise ArgumentError, "MEMBA_STAFF_MCP_CREDENTIALS must be a JSON object"
    end
  end

  defp credential!({email, digest}) when is_binary(digest) do
    with true <- Accounts.staff_email?(email),
         {:ok, hash} <- Base.decode16(digest, case: :mixed),
         32 <- byte_size(hash) do
      {email |> String.trim() |> String.downcase(), hash}
    else
      _ -> invalid_credential!()
    end
  end

  defp credential!(_entry), do: invalid_credential!()

  defp invalid_credential! do
    raise ArgumentError,
          "Staff MCP credentials must map staff email addresses to SHA-256 hex digests"
  end

  defp allowed_origin?(conn) do
    case get_req_header(conn, "origin") do
      [] -> true
      [origin] -> origin == Endpoint.url()
      _ -> false
    end
  end

  defp authenticate(conn) do
    case get_req_header(conn, "authorization") do
      [<<scheme::binary-size(7), token::binary>>] when byte_size(token) in 32..128 ->
        if String.downcase(scheme, :ascii) == "bearer " do
          assign_operator(conn, :crypto.hash(:sha256, token))
        else
          unauthorized(conn)
        end

      _ ->
        unauthorized(conn)
    end
  end

  defp assign_operator(conn, hash) do
    credentials = Application.get_env(:memba, __MODULE__, [])

    case Enum.find(credentials, fn {_email, expected} ->
           Plug.Crypto.secure_compare(hash, expected)
         end) do
      {email, _digest} -> assign(conn, :staff_mcp_email, email)
      nil -> unauthorized(conn)
    end
  end

  defp unauthorized(conn) do
    conn
    |> put_resp_header("www-authenticate", ~s(Bearer realm="Memba Staff"))
    |> send_resp(:unauthorized, "")
    |> halt()
  end
end
