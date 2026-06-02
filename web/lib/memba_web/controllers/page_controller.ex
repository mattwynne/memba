defmodule MembaWeb.PageController do
  use MembaWeb, :controller

  alias Memba.Membership
  alias MembaWeb.UserAuth

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
    Phoenix.LiveView.Controller.live_render(conn, MembaWeb.MemberDashboardLive,
      session: %{
        "club_id" => club_id,
        UserAuth.identity_session_key() => identity.email
      }
    )
  end

  defp home_for_params(conn, %{"club_id" => club_id}) do
    case Membership.get_club(club_id) do
      nil ->
        not_found(conn)

      _club ->
        render_public_club_page(conn, club_id)
    end
  end

  defp home_for_params(conn, _params) do
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

  defp render_public_club_page(conn, club_id) do
    Phoenix.LiveView.Controller.live_render(conn, MembaWeb.ClubMarketingLive,
      session: %{"club_id" => club_id}
    )
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
