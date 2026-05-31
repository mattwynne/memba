defmodule MembaWeb.Plugs.CanonicalHostRedirect do
  @moduledoc """
  Redirects Fly's default hostname to the canonical public hostname.
  """

  import Plug.Conn

  @fly_hostname "memba.fly.dev"
  @canonical_url "https://memba.io"

  def init(opts), do: opts

  def call(%Plug.Conn{host: @fly_hostname} = conn, _opts) do
    conn
    |> put_resp_header("location", redirect_url(conn))
    |> send_resp(:moved_permanently, "")
    |> halt()
  end

  def call(conn, _opts), do: conn

  defp redirect_url(conn) do
    query_string =
      case conn.query_string do
        "" -> ""
        query_string -> "?#{query_string}"
      end

    @canonical_url <> conn.request_path <> query_string
  end
end
