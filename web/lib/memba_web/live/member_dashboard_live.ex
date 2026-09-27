defmodule MembaWeb.MemberDashboardLive do
  @moduledoc """
  LiveView-backed member dashboard for signed-in club home requests.

  Club subdomains are the canonical URL; the router passes the host-selected
  club into this LiveView session for signed-in active members.
  """
  use MembaWeb, :live_view

  require Logger

  alias Commanded.Commands.ExecutionResult
  alias Memba.Accounts
  alias Memba.ID
  alias Memba.Membership
  alias Memba.Membership.CustomGroupAdmission
  alias Memba.Membership.CustomGroupRemoval
  alias Memba.Membership.GroupWelcomeEmail
  alias Memba.Messaging
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
    targeted_person_id = Map.get(params, "person_id")
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
         |> assign(:targeted_person_route_id, targeted_person_id)
         |> assign(:targeted_group_member, nil)
         |> assign(:active_section, "conversations")
         |> assign(:custom_group_member_picker_open?, false)
         |> assign(:custom_group_member_removal, nil)
         |> assign(:group_access_request_state, :idle)
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
    targeted_person_id = Map.get(params, "person_id")

    socket =
      socket
      |> assign(:targeted_person_route_id, targeted_person_id)
      |> assign(:targeted_group_member, nil)
      |> assign(:custom_group_member_picker_open?, false)
      |> assign(:custom_group_member_removal, nil)
      |> assign(:group_access_request_state, :idle)
      |> assign_custom_group_member_picker_query("")
      |> refresh_dashboard(socket.assigns.selected_club.club_id, selected_group_id)

    {:noreply, assign(socket, :active_section, active_section(socket.assigns.live_action))}
  end

  @impl Phoenix.LiveView
  def handle_event(
        "request_group_access",
        _params,
        %{
          assigns: %{
            can_request_group_access?: true,
            group_access_request_state: :idle
          }
        } = socket
      ) do
    socket = assign(socket, :group_access_request_state, :sending)

    result =
      Messaging.request_group_access(
        %{
          message_id: ID.generate(:message),
          club_id: socket.assigns.selected_club.club_id,
          requester_person_id: socket.assigns.current_member.id,
          group_id: socket.assigns.selected_group.group_id
        },
        consistency: :strong
      )

    case result do
      :ok ->
        {:noreply, assign(socket, :group_access_request_state, :sent)}

      {:ok, %ExecutionResult{}} ->
        {:noreply, assign(socket, :group_access_request_state, :sent)}

      {:error, _reason} ->
        {:noreply,
         socket
         |> assign(:group_access_request_state, :idle)
         |> put_flash(:error, "We couldn't send your request. Refresh and try again.")}
    end
  end

  def handle_event("request_group_access", _params, socket), do: {:noreply, socket}

  def handle_event(
        "reset_group_access_request",
        _params,
        %{
          assigns: %{
            can_request_group_access?: true,
            group_access_request_state: :sent
          }
        } = socket
      ) do
    {:noreply, assign(socket, :group_access_request_state, :idle)}
  end

  def handle_event("reset_group_access_request", _params, socket), do: {:noreply, socket}

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

  defp active_section(live_action) when live_action in [:members, :targeted_add], do: "members"
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
        |> assign_targeted_group_member()

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

  defp assign_targeted_group_member(
         %{
           assigns: %{
             live_action: :targeted_add,
             can_add_custom_group_members?: true,
             selected_club: %{club_id: club_id},
             selected_group: %{group_id: group_id},
             targeted_person_route_id: person_id
           }
         } = socket
       ) do
    case Membership.resolve_custom_group_target_authoritatively(club_id, person_id, group_id) do
      {:ok, target} ->
        assign(socket, :targeted_group_member, present_targeted_group_member(target))

      {:error, _invalid_missing_or_unauthorized} ->
        not_found!(socket)
    end
  end

  defp assign_targeted_group_member(%{assigns: %{live_action: :targeted_add}}) do
    forbidden!()
  end

  defp assign_targeted_group_member(socket) do
    assign(socket, :targeted_group_member, nil)
  end

  defp present_targeted_group_member(%{
         membership: %{membership_id: membership_id},
         person: %{person_id: person_id, name: name},
         active_group_member?: active_group_member?
       }) do
    %{
      person_id: person_id,
      membership_id: membership_id,
      name: name,
      initials: person_initials(name),
      active_group_member?: active_group_member?
    }
  end

  defp person_initials(name) when is_binary(name) do
    name
    |> String.split(~r/\s+/, trim: true)
    |> Enum.take(2)
    |> Enum.map_join("", fn <<first::utf8, _rest::binary>> ->
      String.upcase(<<first::utf8>>)
    end)
    |> case do
      "" -> "?"
      initials -> initials
    end
  end

  defp person_initials(_name), do: "?"

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
