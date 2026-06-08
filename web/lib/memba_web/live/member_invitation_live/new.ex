defmodule MembaWeb.MemberInvitationLive.New do
  @moduledoc """
  LiveView entry point for member-facing club member invitations.

  The router references this module as `MemberInvitationLive.New` from the
  `scope "/", MembaWeb` block, matching the existing member LiveView route
  namespace without duplicating the `MembaWeb` prefix.
  """
  use MembaWeb, :live_view

  alias Memba.Membership
  alias Memba.Membership.Permissions

  @impl Phoenix.LiveView
  def mount(params, session, socket) when is_map(params) do
    params = put_session_club_id(params, session) |> put_club_id_source(session)
    socket = ensure_identity_assigns(socket)

    case params do
      %{"club_id" => club_id} ->
        case invitation_context(
               club_id,
               socket.assigns.current_identity,
               socket.assigns.current_identity_clubs
             ) do
          {:ok, invitation_assigns} ->
            {:ok,
             socket
             |> assign(:route_params, params)
             |> assign(invitation_assigns)}

          {:error, :forbidden} ->
            forbidden!(socket)
        end

      _params ->
        {:ok,
         socket
         |> assign(:route_params, params)
         |> assign_empty_invitation_context()}
    end
  end

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> ensure_identity_assigns()
     |> assign(:route_params, %{})
     |> assign_empty_invitation_context()}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.club_site
      flash={@flash}
      club_name={selected_club_name(@selected_club)}
      current_identity={@current_identity}
    >
      <div
        id="member-club-invitation-new"
        data-live-view="member-club-invitation-new"
        data-live-action={@live_action}
        data-club-id={selected_club_id(@selected_club, @route_params)}
        data-club-id-source={club_id_source(@route_params)}
        class="space-y-8"
      >
        <section class="mx-auto max-w-3xl overflow-hidden rounded-3xl border border-[var(--club-site-line)] bg-[var(--club-site-paper)] p-6 shadow-sm sm:p-8">
          <.link
            id="member-invitation-club-home-link"
            href={club_home_path(@selected_club, @route_params)}
            class="inline-flex w-fit items-center gap-2 text-sm font-semibold text-[var(--club-site-muted)] transition duration-200 hover:text-[var(--club-site-ink)]"
          >
            <.icon name="hero-arrow-left" class="size-4" /> Club home
          </.link>

          <p class="mt-5 text-xs font-semibold uppercase tracking-[0.18em] text-[var(--club-site-muted)]">
            Member invitations
          </p>

          <h1 class="mt-2 text-4xl font-semibold tracking-tight text-[var(--club-site-ink)]">
            Invite a member
          </h1>

          <p
            id="member-invitation-selected-club"
            data-club-id={selected_club_id(@selected_club, @route_params)}
            class="mt-3 text-sm font-semibold uppercase tracking-[0.18em] text-[var(--club-site-accent)]"
          >
            {selected_club_name(@selected_club)}
          </p>

          <p class="mt-6 max-w-2xl text-base leading-7 text-[var(--club-site-muted)]">
            Send a one-use invitation link for {selected_club_name(@selected_club)}. The invitee
            will control the invited email address before membership starts.
          </p>
        </section>
      </div>
    </Layouts.club_site>
    """
  end

  defp invitation_context(club_id, current_identity, current_identity_clubs) do
    with selected_club when not is_nil(selected_club) <-
           selected_club(current_identity_clubs, club_id),
         current_person when not is_nil(current_person) <-
           current_person_for_identity(current_identity),
         true <-
           Membership.person_has_club_permission?(
             selected_club.club_id,
             current_person.person_id,
             Permissions.club_manage_members()
           ) do
      {:ok, %{selected_club: selected_club}}
    else
      _not_authorized -> {:error, :forbidden}
    end
  end

  defp selected_club(current_identity_clubs, club_id) do
    Enum.find(current_identity_clubs, fn club -> club.club_id == club_id end)
  end

  defp current_person_for_identity(nil), do: nil
  defp current_person_for_identity(identity), do: Membership.get_person_by_email(identity.email)

  defp assign_empty_invitation_context(socket) do
    assign(socket, :selected_club, nil)
  end

  defp ensure_identity_assigns(socket) do
    socket
    |> assign_new(:current_identity, fn -> nil end)
    |> assign_new(:current_identity_clubs, fn -> [] end)
  end

  defp put_session_club_id(params, session) do
    case {Map.get(params, "club_id"), Map.get(session, "club_id")} do
      {nil, club_id} when is_binary(club_id) -> Map.put(params, "club_id", club_id)
      _club_id_present_or_missing -> params
    end
  end

  defp put_club_id_source(params, session) do
    case Map.get(session, "club_id_source") do
      "host" -> Map.put(params, "club_id_source", "host")
      _source -> params
    end
  end

  defp selected_club_name(nil), do: "Club"
  defp selected_club_name(selected_club), do: selected_club.name

  defp selected_club_id(nil, route_params), do: Map.get(route_params, "club_id")
  defp selected_club_id(selected_club, _route_params), do: selected_club.club_id

  defp club_id_source(%{"club_id_source" => "host"}), do: "host"
  defp club_id_source(_route_params), do: "query"

  defp club_home_path(nil, route_params) do
    case Map.get(route_params, "club_id") do
      nil -> ~p"/"
      club_id -> ~p"/?club_id=#{club_id}"
    end
  end

  defp club_home_path(_selected_club, %{"club_id_source" => "host"}), do: ~p"/"
  defp club_home_path(selected_club, _route_params), do: ~p"/?club_id=#{selected_club.club_id}"

  defp forbidden!(_socket), do: raise(MembaWeb.ForbiddenError)
end
