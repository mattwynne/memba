defmodule MembaWeb.Plugs.ClubSiteMemberRoute do
  @moduledoc """
  Resolves private member routes from the configured club subdomain host.
  """

  import Plug.Conn
  import Phoenix.Controller, only: [put_view: 2, render: 2]

  alias Memba.Membership
  alias MembaWeb.ClubSite

  def init(opts), do: opts

  def live_session(conn) do
    case conn.private do
      %{memba_club_id_source: :host, memba_host_selected_club: %{club_id: club_id}} ->
        %{"club_id_source" => "host", "club_id" => club_id}

      %{memba_club_id_source: :host} ->
        %{"club_id_source" => "host"}

      _private ->
        %{}
    end
  end

  def call(conn, _opts) do
    case ClubSite.slug_from_host(conn.host) do
      {:ok, slug} -> put_host_selected_club(conn, slug)
      :error -> conn
    end
  end

  defp put_host_selected_club(conn, slug) do
    case Membership.get_club_by_slug(slug) do
      nil ->
        not_found(conn)

      club ->
        conn = fetch_query_params(conn)
        query_params = Map.put(conn.query_params, "club_id", club.club_id)
        params = Map.merge(conn.params, query_params)

        %{conn | query_params: query_params, params: params}
        |> put_private(:memba_club_id_source, :host)
        |> put_private(:memba_host_selected_club, club)
    end
  end

  defp not_found(conn) do
    conn
    |> put_status(:not_found)
    |> put_view(html: MembaWeb.ErrorHTML)
    |> render(:"404")
    |> halt()
  end
end
