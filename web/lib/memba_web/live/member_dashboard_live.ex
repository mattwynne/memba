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
  def mount(params, session, socket) do
    club_id = Map.get(session, "club_id")
    selected_group_id = Map.get(params, "group_id")
    current_identity = current_identity_from_session(session)
    current_identity_clubs = identity_clubs(current_identity)

    socket = assign_current_identity(socket, current_identity, current_identity_clubs)

    case MemberDashboardPresentation.load(
           club_id,
           current_identity,
           current_identity_clubs,
           selected_group_id
         ) do
      {:ok, dashboard_assigns} ->
        if connected?(socket) do
          Phoenix.PubSub.subscribe(Memba.PubSub, ReadModelChanges.topic())
        end

        {:ok,
         socket
         |> assign(:club_id_source, Map.get(session, "club_id_source", "host"))
         |> assign(:selected_group_route_id, selected_group_id)
         |> assign(:active_section, "conversations")
         |> assign(dashboard_assigns)}

      {:error, :forbidden} ->
        forbidden!()

      {:error, :not_found} ->
        not_found!(socket)
    end
  end

  @impl Phoenix.LiveView
  def handle_params(params, _uri, socket) do
    selected_group_id = Map.get(params, "group_id")

    socket =
      if socket.assigns.selected_group_route_id == selected_group_id do
        socket
      else
        refresh_dashboard(socket, socket.assigns.selected_club.club_id, selected_group_id)
      end

    {:noreply, assign(socket, :active_section, active_section(socket.assigns.live_action))}
  end

  @impl Phoenix.LiveView
  def handle_event(
        "restore_remembered_group",
        %{"group_id" => remembered_group_id},
        %{assigns: %{selected_group_route_id: nil}} = socket
      )
      when is_binary(remembered_group_id) and remembered_group_id != "" do
    case MemberDashboardPresentation.load(
           socket.assigns.selected_club.club_id,
           socket.assigns.current_identity,
           socket.assigns.current_identity_clubs,
           remembered_group_id
         ) do
      {:ok, dashboard_assigns} ->
        selected_group_id = dashboard_assigns.selected_group.group_id

        socket =
          socket
          |> assign(:selected_group_route_id, selected_group_id)
          |> assign(dashboard_assigns)
          |> push_patch(to: remembered_group_path(socket.assigns.live_action, selected_group_id))

        {:reply, %{selected_group_id: selected_group_id}, socket}

      {:error, :not_found} ->
        reply_with_selected_group(socket)

      {:error, :forbidden} ->
        forbidden!()
    end
  end

  def handle_event("restore_remembered_group", _params, socket) do
    reply_with_selected_group(socket)
  end

  @impl Phoenix.LiveView
  def handle_info(
        {:read_model_changed, %{projector: Memba.Messaging.Projectors.MemberEmailDelivery}},
        %{assigns: %{selected_club: selected_club}} = socket
      ) do
    {:noreply,
     refresh_dashboard(socket, selected_club.club_id, socket.assigns.selected_group_route_id)}
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  @impl Phoenix.LiveView
  def render(%{selected_club: _selected_club} = assigns) do
    MembaWeb.PageHTML.club(assigns)
  end

  defp active_section(:members), do: "members"
  defp active_section(_live_action), do: "conversations"

  defp remembered_group_path(:members, group_id), do: ~p"/groups/#{group_id}/members"
  defp remembered_group_path(_live_action, group_id), do: ~p"/groups/#{group_id}"

  defp reply_with_selected_group(socket) do
    {:reply, %{selected_group_id: socket.assigns.selected_group.group_id}, socket}
  end

  defp refresh_dashboard(socket, club_id, selected_group_id) do
    case MemberDashboardPresentation.load(
           club_id,
           socket.assigns.current_identity,
           socket.assigns.current_identity_clubs,
           selected_group_id
         ) do
      {:ok, dashboard_assigns} ->
        socket
        |> assign(:selected_group_route_id, selected_group_id)
        |> assign(dashboard_assigns)

      {:error, :forbidden} ->
        forbidden!()

      {:error, :not_found} ->
        not_found!(socket)
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

  defp not_found!(socket) do
    case socket.private[:connect_info] do
      %Plug.Conn{} = conn ->
        raise Phoenix.Router.NoRouteError, conn: conn, router: MembaWeb.Router

      _connect_info ->
        raise "member dashboard not found"
    end
  end
end
