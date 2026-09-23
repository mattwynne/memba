defmodule MembaWeb.MemberDashboardLive do
  @moduledoc """
  LiveView-backed member dashboard for signed-in club home requests.

  Club subdomains are the canonical URL; the router passes the host-selected
  club into this LiveView session for signed-in active members.
  """
  use MembaWeb, :live_view

  require Logger

  alias Memba.Accounts
  alias Memba.Membership
  alias Memba.Membership.CustomGroupAdmission
  alias Memba.Membership.CustomGroupRemoval
  alias Memba.Membership.GroupWelcomeEmail
  alias Memba.ReadModelChanges
  alias MembaWeb.ClubSite
  alias MembaWeb.IdentityAuth
  alias MembaWeb.MemberDashboardPresentation

  @dashboard_state_projectors [
    Memba.Membership.Projectors.Group,
    Memba.Membership.Projectors.GroupMembership,
    Memba.Membership.Projectors.Membership,
    Memba.Membership.Projectors.Role,
    Memba.Messaging.Projectors.ConversationGroupAccess
  ]

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
         |> assign(:custom_group_member_picker_open?, false)
         |> assign(:custom_group_member_removal, nil)
         |> assign_custom_group_member_picker_query("")
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
      socket
      |> assign(:custom_group_member_picker_open?, false)
      |> assign(:custom_group_member_removal, nil)
      |> assign_custom_group_member_picker_query("")
      |> refresh_dashboard(socket.assigns.selected_club.club_id, selected_group_id)

    {:noreply, assign(socket, :active_section, active_section(socket.assigns.live_action))}
  end

  @impl Phoenix.LiveView
  def handle_event(
        "open_custom_group_member_picker",
        _params,
        %{assigns: %{can_add_custom_group_members?: true}} = socket
      ) do
    {:noreply,
     socket
     |> assign(:custom_group_member_picker_open?, true)
     |> assign_custom_group_member_picker_query("")}
  end

  def handle_event("open_custom_group_member_picker", _params, socket), do: {:noreply, socket}

  def handle_event("close_custom_group_member_picker", _params, socket) do
    {:noreply,
     socket
     |> assign(:custom_group_member_picker_open?, false)
     |> assign_custom_group_member_picker_query("")}
  end

  def handle_event(
        "filter_custom_group_member_candidates",
        %{"member_search" => %{"query" => query}},
        %{assigns: %{custom_group_member_picker_open?: true}} = socket
      )
      when is_binary(query) do
    {:noreply, assign_custom_group_member_picker_query(socket, query)}
  end

  def handle_event("filter_custom_group_member_candidates", _params, socket),
    do: {:noreply, socket}

  def handle_event(
        "add_custom_group_member",
        %{"membership_id" => membership_id, "person_id" => person_id},
        socket
      ) do
    attrs = %{
      club_id: socket.assigns.selected_club.club_id,
      group_id: socket.assigns.selected_group.group_id,
      membership_id: membership_id,
      person_id: person_id,
      actor_person_id: socket.assigns.current_member.id
    }

    case Membership.add_custom_group_member(attrs, consistency: :strong) do
      {:ok, %CustomGroupAdmission{} = admission} ->
        admission
        |> deliver_group_welcome(socket)
        |> log_group_welcome_delivery_failure(admission)

        {:noreply,
         refresh_dashboard(
           socket,
           socket.assigns.selected_club.club_id,
           socket.assigns.selected_group_route_id
         )}

      {:error, _reason} ->
        {:noreply,
         put_flash(socket, :error, "We couldn't add that member. Refresh and try again.")}
    end
  end

  def handle_event("add_custom_group_member", _params, socket) do
    {:noreply, put_flash(socket, :error, "We couldn't add that member. Refresh and try again.")}
  end

  def handle_event(
        "confirm_custom_group_member_removal",
        %{"membership_id" => membership_id, "person_id" => person_id},
        %{assigns: %{can_add_custom_group_members?: true}} = socket
      ) do
    {:noreply,
     assign(socket, :custom_group_member_removal, %{
       action_key: {membership_id, person_id},
       membership_id: membership_id,
       person_id: person_id,
       operation_id: Ecto.UUID.generate(),
       status: :pending
     })}
  end

  def handle_event("confirm_custom_group_member_removal", _params, socket),
    do: {:noreply, socket}

  def handle_event("cancel_custom_group_member_removal", _params, socket) do
    {:noreply, assign(socket, :custom_group_member_removal, nil)}
  end

  def handle_event(
        "remove_custom_group_member",
        %{
          "membership_id" => membership_id,
          "person_id" => person_id,
          "removal_operation_id" => submitted_operation_id
        },
        socket
      ) do
    with {:ok, operation_id} <-
           removal_operation_id(socket, membership_id, person_id, submitted_operation_id) do
      attrs = %{
        club_id: socket.assigns.selected_club.club_id,
        group_id: socket.assigns.selected_group.group_id,
        membership_id: membership_id,
        person_id: person_id,
        actor_person_id: socket.assigns.current_member.id,
        removal_operation_id: operation_id
      }

      case Membership.remove_custom_group_member(attrs, consistency: :strong) do
        {:ok, %CustomGroupRemoval{}} ->
          self_leave? = person_id == socket.assigns.current_member.id

          completed_removal = %{
            action_key: {membership_id, person_id},
            membership_id: membership_id,
            person_id: person_id,
            operation_id: operation_id,
            status: :completed
          }

          refreshed =
            socket
            |> assign(:custom_group_member_removal, completed_removal)
            |> refresh_dashboard(
              socket.assigns.selected_club.club_id,
              socket.assigns.selected_group_route_id
            )

          refreshed =
            if self_leave? do
              put_flash(
                refreshed,
                :info,
                "You're no longer in #{socket.assigns.selected_group.name}. You still belong to #{socket.assigns.selected_club.name}."
              )
            else
              refreshed
            end

          {:noreply, refreshed}

        {:error, _reason} ->
          {:noreply,
           socket
           |> refresh_dashboard(
             socket.assigns.selected_club.club_id,
             socket.assigns.selected_group_route_id
           )
           |> put_flash(:error, "You are not authorized to access that page.")}
      end
    else
      :error ->
        {:noreply, put_flash(socket, :error, "You are not authorized to access that page.")}
    end
  end

  def handle_event("remove_custom_group_member", _params, socket) do
    {:noreply, put_flash(socket, :error, "You are not authorized to access that page.")}
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
    socket =
      refresh_dashboard(
        socket,
        socket.assigns.selected_club.club_id,
        socket.assigns.selected_group_route_id
      )

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

  def handle_info(
        {:read_model_changed, %{projector: projector, source_event: %{club_id: club_id}}},
        %{assigns: %{selected_club: %{club_id: club_id}}} = socket
      )
      when projector in @dashboard_state_projectors do
    {:noreply, refresh_dashboard(socket, club_id, socket.assigns.selected_group_route_id)}
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  @impl Phoenix.LiveView
  def render(%{selected_club: _selected_club} = assigns) do
    MembaWeb.PageHTML.club(assigns)
  end

  defp active_section(:members), do: "members"
  defp active_section(_live_action), do: "conversations"

  defp removal_operation_id(socket, membership_id, person_id, submitted_operation_id) do
    action_key = {membership_id, person_id}

    case socket.assigns[:custom_group_member_removal] do
      %{action_key: ^action_key, operation_id: operation_id}
      when operation_id == submitted_operation_id ->
        {:ok, operation_id}

      %{action_key: ^action_key} ->
        :error

      _reconnected_action ->
        Ecto.UUID.cast(submitted_operation_id)
    end
  end

  defp assign_custom_group_member_picker_query(socket, query) do
    socket
    |> assign(:custom_group_member_picker_query, query)
    |> assign(:custom_group_member_picker_form, to_form(%{"query" => query}, as: :member_search))
  end

  defp remembered_group_path(:members, group_id), do: ~p"/groups/#{group_id}/members"
  defp remembered_group_path(_live_action, group_id), do: ~p"/groups/#{group_id}"

  defp deliver_group_welcome(
         %CustomGroupAdmission{transition: :member_added} = admission,
         socket
       ) do
    recipient = Membership.get_person(admission.person_id)
    added_by = Membership.get_person(admission.actor_person_id)

    GroupWelcomeEmail.deliver(%{
      club: socket.assigns.selected_club,
      group: socket.assigns.selected_group,
      recipient: %{
        person_id: admission.person_id,
        name: person_name(recipient),
        email: Membership.get_person_primary_email(admission.person_id)
      },
      added_by: %{
        person_id: admission.actor_person_id,
        name: person_name(added_by)
      },
      group_url:
        ClubSite.url(
          socket.assigns.selected_club,
          ~p"/groups/#{admission.group_id}"
        )
    })
  end

  defp deliver_group_welcome(
         %CustomGroupAdmission{transition: :already_member},
         _socket
       ),
       do: :ok

  defp log_group_welcome_delivery_failure(:ok, _admission), do: :ok

  defp log_group_welcome_delivery_failure(
         {:error, reason},
         %CustomGroupAdmission{} = admission
       ) do
    Logger.warning(
      "Could not deliver custom-group welcome email: #{inspect(reason)}",
      club_id: admission.club_id,
      group_id: admission.group_id,
      membership_id: admission.membership_id,
      person_id: admission.person_id,
      actor_person_id: admission.actor_person_id
    )
  end

  defp person_name(%{name: name}), do: name
  defp person_name(_person), do: nil

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
