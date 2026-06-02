defmodule MembaWeb.PageController do
  use MembaWeb, :controller

  alias Memba.Membership
  alias MembaWeb.IdentityAuth

  def home(%{assigns: %{current_identity: identity}} = conn, %{"club_id" => club_id})
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

  def home(conn, %{"club_id" => club_id}) do
    case Membership.get_club(club_id) do
      nil -> not_found(conn)
      _club -> render_public_club_page(conn, club_id)
    end
  end

  def home(conn, _params) do
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
