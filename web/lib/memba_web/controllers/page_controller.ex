defmodule MembaWeb.PageController do
  use MembaWeb, :controller

  alias Memba.Membership
  alias MembaWeb.IdentityAuth

  @public_club_host_suffix ".clubs.memba.io"

  def home(conn, params) do
    case public_club_slug_from_host(conn.host) do
      {:ok, slug} -> home_for_public_club_slug(conn, slug)
      :error -> home_for_params(conn, params)
    end
  end

  defp home_for_params(
         %{assigns: %{current_identity: identity}} = conn,
         %{"club_id" => club_id}
       )
       when not is_nil(identity) do
    cond do
      is_nil(Membership.get_club(club_id)) ->
        not_found(conn)

      Membership.active_member_of_club_by_email?(club_id, identity.email) ->
        Phoenix.LiveView.Controller.live_render(conn, MembaWeb.MemberDashboardLive,
          session: %{
            "club_id" => club_id,
            IdentityAuth.identity_session_key() => identity.email
          }
        )

      true ->
        render_public_club_page(conn, club_id)
    end
  end

  defp home_for_params(conn, %{"club_id" => club_id}) do
    case Membership.get_club(club_id) do
      nil -> not_found(conn)
      _club -> render_public_club_page(conn, club_id)
    end
  end

  defp home_for_params(conn, _params) do
    page_title =
      if conn.assigns.current_identity do
        "Your clubs"
      else
        "Volunteering shouldn’t feel like work"
      end

    conn
    |> assign(:page_title, page_title)
    |> render(:home)
  end

  defp home_for_public_club_slug(conn, slug) do
    case Membership.get_club_by_slug(slug) do
      nil -> not_found(conn)
      club -> render_public_club_page(conn, club.club_id)
    end
  end

  defp public_club_slug_from_host(host) when is_binary(host) do
    host = host |> String.downcase() |> String.trim_trailing(".")

    if String.ends_with?(host, @public_club_host_suffix) do
      host
      |> String.trim_trailing(@public_club_host_suffix)
      |> String.split(".", parts: 2)
      |> case do
        [slug | _rest] when slug != "" -> {:ok, slug}
        _no_slug -> :error
      end
    else
      :error
    end
  end

  def about(conn, _params) do
    conn
    |> assign(:page_title, "About")
    |> render(:about)
  end

  def get_started(conn, _params) do
    conn
    |> assign(:page_title, "Get started")
    |> render(:get_started)
  end

  def terms(conn, _params) do
    conn
    |> assign(:page_title, "Terms of Service")
    |> render(:terms)
  end

  def privacy(conn, _params) do
    conn
    |> assign(:page_title, "Privacy Policy")
    |> render(:privacy)
  end

  defp render_public_club_page(conn, club_id) do
    Phoenix.LiveView.Controller.live_render(conn, MembaWeb.PublicClubPageLive,
      session: %{"club_id" => club_id}
    )
  end

  defp not_found(conn) do
    conn
    |> put_status(:not_found)
    |> put_view(html: MembaWeb.ErrorHTML)
    |> render(:"404")
  end
end
