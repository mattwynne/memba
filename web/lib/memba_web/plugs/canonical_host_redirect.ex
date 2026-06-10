defmodule MembaWeb.Plugs.CanonicalHostRedirect do
  @moduledoc """
  Redirects requests that arrive on a non-canonical hostname to the root domain.
  """

  import Plug.Conn

  alias Memba.Membership
  alias MembaWeb.ClubSite

  @fly_hostname "memba.fly.dev"
  @canonical_url "https://memba.io"

  def init(opts), do: opts

  def call(%Plug.Conn{host: @fly_hostname} = conn, _opts) do
    if club_id_redirect_candidate?(conn) do
      redirect_club_id_query(conn)
    else
      redirect(conn, @canonical_url)
    end
  end

  def call(conn, _opts) do
    cond do
      staff_path?(conn.request_path) and ClubSite.club_host?(conn.host) ->
        redirect(conn, root_domain_url())

      club_id_redirect_candidate?(conn) ->
        redirect_club_id_query(conn)

      true ->
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

  defp club_id_redirect_candidate?(conn) do
    not staff_path?(conn.request_path) and not ClubSite.club_host?(conn.host) and
      String.contains?(conn.query_string, "club_id=")
  end

  defp redirect_club_id_query(conn) do
    query_params = Plug.Conn.Query.decode(conn.query_string)

    case {Map.get(query_params, "club_id"), ClubSite.club_host?(conn.host)} do
      {club_id, false} when is_binary(club_id) ->
        redirect_to_club_url(conn, club_id, Map.delete(query_params, "club_id"))

      _no_club_id_or_already_on_club_host ->
        conn
    end
  end

  defp redirect_to_club_url(conn, club_id, query_params) do
    case Membership.get_club(club_id) do
      nil ->
        conn

      club ->
        conn
        |> put_resp_header("location", club_redirect_url(club, conn.request_path, query_params))
        |> send_resp(:found, "")
        |> halt()
    end
  end

  defp club_redirect_url(club, path, query_params) do
    query_params
    |> Plug.Conn.Query.encode()
    |> case do
      "" -> ClubSite.url(club, path)
      query_string -> ClubSite.url(club, path) <> "?" <> query_string
    end
  end

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
