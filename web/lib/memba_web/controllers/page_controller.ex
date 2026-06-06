defmodule MembaWeb.PageController do
  use MembaWeb, :controller

  alias Memba.Membership
  alias Memba.Onboarding
  alias MembaWeb.ClubSite
  alias MembaWeb.IdentityAuth

  @publicly_hidden_club_slugs MapSet.new(["test"])

  def home(conn, params) do
    case ClubSite.slug_from_host(conn.host) do
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
        render_member_dashboard(conn, club_id, "query")

      true ->
        club_id
        |> Membership.get_club()
        |> then(&render_public_club_page_or_not_found(conn, &1))
    end
  end

  defp home_for_params(conn, %{"club_id" => club_id}) do
    case Membership.get_club(club_id) do
      nil -> not_found(conn)
      club -> render_public_club_page_or_not_found(conn, club)
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
      nil ->
        not_found(conn)

      club ->
        if signed_in_active_member?(conn, club.club_id) do
          render_member_dashboard(conn, club.club_id, "host")
        else
          render_public_club_page_or_not_found(conn, club)
        end
    end
  end

  defp signed_in_active_member?(%{assigns: %{current_identity: nil}}, _club_id), do: false

  defp signed_in_active_member?(%{assigns: %{current_identity: identity}}, club_id) do
    Membership.active_member_of_club_by_email?(club_id, identity.email)
  end

  def about(conn, _params) do
    conn
    |> assign(:page_title, "About")
    |> render(:about)
  end

  def get_started(conn, params) do
    conn
    |> assign(:request_submitted?, Map.get(params, "submitted") == "true")
    |> render_get_started(Onboarding.change_request(%{}))
  end

  def submit_get_started(conn, params) do
    request_params = Map.get(params, "request", %{})

    case Onboarding.create_request(request_params) do
      {:ok, _request} ->
        redirect(conn, to: ~p"/get-started?submitted=true")

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> assign(:request_submitted?, false)
        |> render_get_started(changeset)
    end
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

  defp render_get_started(conn, changeset) do
    conn
    |> assign(:page_title, "Get started")
    |> assign(:request_form, Phoenix.Component.to_form(changeset, as: :request))
    |> render(:get_started)
  end

  defp render_member_dashboard(conn, club_id, club_id_source) do
    Phoenix.LiveView.Controller.live_render(conn, MembaWeb.MemberDashboardLive,
      session: %{
        "club_id" => club_id,
        "club_id_source" => club_id_source,
        IdentityAuth.identity_session_key() => conn.assigns.current_identity.email
      }
    )
  end

  defp render_public_club_page_or_not_found(conn, nil), do: not_found(conn)

  defp render_public_club_page_or_not_found(conn, club) do
    if public_club_page_visible?(club) do
      render_public_club_page(conn, club.club_id)
    else
      not_found(conn)
    end
  end

  defp public_club_page_visible?(club) do
    not MapSet.member?(@publicly_hidden_club_slugs, club.slug)
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
