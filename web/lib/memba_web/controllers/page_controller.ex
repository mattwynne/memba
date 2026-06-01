defmodule MembaWeb.PageController do
  use MembaWeb, :controller

  alias Memba.Membership
  alias MembaWeb.UserAuth

  def home(%{assigns: %{current_identity: identity}} = conn, %{"club_id" => club_id})
      when not is_nil(identity) do
    Phoenix.LiveView.Controller.live_render(conn, MembaWeb.MemberDashboardLive,
      session: %{
        "club_id" => club_id,
        UserAuth.identity_session_key() => identity.email
      }
    )
  end

  def home(conn, %{"club_id" => club_id}) do
    case Membership.get_club(club_id) do
      nil ->
        not_found(conn)

      _club ->
        Phoenix.LiveView.Controller.live_render(conn, MembaWeb.ClubMarketingLive,
          session: %{"club_id" => club_id}
        )
    end
  end

  def home(conn, _params) do
    page_title =
      if conn.assigns.current_identity do
        "My clubs"
      else
        "Membership made calm"
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

  defp not_found(conn) do
    conn
    |> put_status(:not_found)
    |> put_view(html: MembaWeb.ErrorHTML)
    |> render(:"404")
  end
end
