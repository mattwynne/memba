defmodule MembaWeb.Plugs.CanonicalHostRedirect do
  @moduledoc """
  Redirects requests that arrive on a non-canonical hostname to the root domain.
  """

  import Plug.Conn

  alias MembaWeb.ClubSite

  @fly_hostname "memba.fly.dev"
  @canonical_url "https://memba.io"

  def init(opts), do: opts

  def call(%Plug.Conn{host: @fly_hostname} = conn, _opts) do
    redirect(conn, @canonical_url)
  end

  def call(conn, _opts) do
    if staff_path?(conn.request_path) and ClubSite.club_host?(conn.host) do
      redirect(conn, root_domain_url())
    else
      conn
    end
  end

  defp redirect(conn, base_url) do
    conn
    |> put_resp_header("location", redirect_url(conn, base_url))
    |> send_resp(:moved_permanently, "")
    |> halt()
  end

  defp staff_path?("/admin"), do: true
  defp staff_path?("/admin/" <> _rest), do: true
  defp staff_path?(_path), do: false

  defp root_domain_url do
    %URI{
      scheme: club_site_scheme(),
      host: root_domain_host(),
      port: root_domain_port()
    }
    |> URI.to_string()
    |> String.trim_trailing("/")
  end

  defp root_domain_host do
    base_domain = ClubSite.base_domain()

    if String.starts_with?(base_domain, "clubs.") do
      String.replace_prefix(base_domain, "clubs.", "")
    else
      base_domain
    end
  end

  defp club_site_scheme do
    :memba
    |> Application.get_env(:club_site, [])
    |> Keyword.get(:scheme, "https")
    |> to_string()
  end

  defp root_domain_port do
    configured_port =
      :memba
      |> Application.get_env(:club_site, [])
      |> Keyword.get(:port)

    case {club_site_scheme(), configured_port} do
      {"http", 80} -> nil
      {"https", 443} -> nil
      {_scheme, nil} -> nil
      {_scheme, port} -> port
    end
  end

  defp redirect_url(conn, base_url) do
    query_string =
      case conn.query_string do
        "" -> ""
        query_string -> "?#{query_string}"
      end

    base_url <> conn.request_path <> query_string
  end
end
