defmodule MembaWeb.MemberDashboardLive do
  @moduledoc """
  LiveView-backed member dashboard for signed-in club home requests.

  Club subdomains are the canonical URL; the router passes the host-selected
  club into this LiveView session for signed-in active members.
  """
  use MembaWeb, :live_view

  alias Memba.Accounts
  alias Memba.ReadModelChanges
  alias MembaWeb.IdentityAuth
  alias MembaWeb.MemberDashboardPresentation

  @impl Phoenix.LiveView
  def mount(_params, session, socket) do
    club_id = Map.get(session, "club_id")
    current_identity = current_identity_from_session(session)
    current_identity_clubs = identity_clubs(current_identity)

    socket = assign_current_identity(socket, current_identity, current_identity_clubs)

    case MemberDashboardPresentation.load(club_id, current_identity, current_identity_clubs) do
      {:ok, dashboard_assigns} ->
        if connected?(socket) do
          Phoenix.PubSub.subscribe(Memba.PubSub, ReadModelChanges.topic())
        end

        {:ok,
         socket
         |> assign(:club_id_source, Map.get(session, "club_id_source", "host"))
         |> assign(dashboard_assigns)}

      {:error, :forbidden} ->
        forbidden!()
    end
  end

  @impl Phoenix.LiveView
  def handle_info(
        {:read_model_changed, %{projector: Memba.Messaging.Projectors.MemberEmailDelivery}},
        %{assigns: %{selected_club: selected_club}} = socket
      ) do
    {:noreply, refresh_dashboard(socket, selected_club.club_id)}
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  @impl Phoenix.LiveView
  def render(%{selected_club: _selected_club} = assigns) do
    MembaWeb.PageHTML.club(assigns)
  end

  defp refresh_dashboard(socket, club_id) do
    case MemberDashboardPresentation.load(
           club_id,
           socket.assigns.current_identity,
           socket.assigns.current_identity_clubs
         ) do
      {:ok, dashboard_assigns} ->
        assign(socket, dashboard_assigns)

      {:error, :forbidden} ->
        forbidden!()
    end
  end

  defp current_identity_from_session(session) do
    session
    |> Map.get(IdentityAuth.identity_session_key())
    |> Accounts.normalize_email()
    |> case do
      nil ->
        nil

      email ->
        %{
          email: email,
          staff?: Accounts.staff_email?(email),
          active_clubs: Accounts.list_active_clubs_for_email(email)
        }
    end
  end

  defp assign_current_identity(socket, identity, current_identity_clubs) do
    assign(socket,
      current_identity: identity,
      current_identity_email: identity_email(identity),
      current_identity_staff?: identity_staff?(identity),
      current_identity_clubs: current_identity_clubs
    )
  end

  defp identity_email(nil), do: nil
  defp identity_email(identity), do: identity.email

  defp identity_staff?(nil), do: false
  defp identity_staff?(identity), do: identity.staff?

  defp identity_clubs(nil), do: []
  defp identity_clubs(identity), do: identity.active_clubs

  defp forbidden!, do: raise(MembaWeb.ForbiddenError)
end
