defmodule MembaWeb.ClubMemberInvitationsLive.New do
  @moduledoc """
  Member-facing club-scoped entry point for inviting club members.

  The route is mounted inside the existing club member live session so the
  selected club can come from either the `club_id` query parameter or the club
  site host session, matching the member message routes.
  """
  use MembaWeb, :live_view

  alias Memba.Accounts
  alias Memba.Membership
  alias Memba.Membership.Permissions

  @impl Phoenix.LiveView
  def mount(params, session, socket) when is_map(params) do
    params = params |> put_session_club_id(session) |> put_club_id_source(session)
    socket = ensure_identity_assigns(socket)

    with %{"club_id" => club_id} <- params,
         {:ok, invitation_assigns} <-
           invitation_context(
             club_id,
             socket.assigns.current_identity,
             socket.assigns.current_identity_clubs
           ) do
      {:ok,
       socket
       |> assign(:route_params, params)
       |> assign(invitation_assigns)}
    else
      _missing_or_unauthorized -> forbidden!(socket)
    end
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
        id="member-club-member-invitation-new"
        data-live-view="member-club-member-invitation-new"
        data-club-id={selected_club_id(@selected_club, @route_params)}
        data-current-member-id={current_member_id(@current_member)}
        data-active-member-count={@active_member_count}
        class="mx-auto max-w-3xl space-y-8"
      >
        <section
          id="member-invitation-page-header"
          class="border-b border-[var(--club-site-line)] pb-8"
        >
          <.link
            id="member-invitation-club-home-link"
            href={club_home_path(@selected_club, @route_params)}
            class="inline-flex w-fit items-center gap-2 text-sm font-semibold text-[var(--club-site-muted)] transition duration-200 hover:text-[var(--club-site-ink)]"
          >
            <.icon name="hero-arrow-left" class="size-4" /> Club home
          </.link>

          <p
            id="member-invitation-eyebrow"
            class="mt-5 text-xs font-semibold uppercase tracking-[0.18em] text-[var(--club-site-muted)]"
          >
            Member invitations
          </p>

          <h1 class="mt-2 text-4xl font-semibold tracking-tight text-[var(--club-site-ink)]">
            Invite a member
          </h1>

          <p class="mt-3 max-w-2xl text-base leading-7 text-[var(--club-site-muted)]">
            Send a club-scoped invitation for {selected_club_name(@selected_club)}. Invitees
            verify control of their email address before membership starts.
          </p>
        </section>

        <section
          id="member-invitation-selected-club"
          data-club-id={selected_club_id(@selected_club, @route_params)}
          class="rounded-3xl border border-[var(--club-site-line)] bg-[var(--club-site-paper)] p-6 shadow-sm"
        >
          <p class="text-xs font-semibold uppercase tracking-[0.18em] text-[var(--club-site-muted)]">
            Current club
          </p>
          <h2 class="mt-2 text-2xl font-semibold tracking-tight text-[var(--club-site-ink)]">
            {selected_club_name(@selected_club)}
          </h2>
          <p
            id="member-invitation-member-count"
            data-active-member-count={@active_member_count}
            class="mt-2 text-sm leading-6 text-[var(--club-site-muted)]"
          >
            Invitations from this page are scoped to this club and affect only its member list.
          </p>
        </section>
      </div>
    </Layouts.club_site>
    """
  end

  defp ensure_identity_assigns(socket) do
    socket
    |> assign_new(:current_identity, fn -> nil end)
    |> assign_new(:current_identity_clubs, fn -> [] end)
  end

  defp invitation_context(club_id, current_identity, current_identity_clubs) do
    with selected_club when not is_nil(selected_club) <-
           selected_club(current_identity_clubs, club_id),
         members <- Membership.list_active_members_of_club(club_id),
         current_member when not is_nil(current_member) <-
           current_member_for_identity(members, current_identity),
         true <- can_manage_members?(club_id, current_member) do
      {:ok,
       %{
         selected_club: selected_club,
         current_member: current_member,
         active_member_count: Enum.count(members)
       }}
    else
      _not_authorized -> {:error, :forbidden}
    end
  end

  defp selected_club(current_identity_clubs, club_id) do
    Enum.find(current_identity_clubs, fn club -> club.club_id == club_id end)
  end

  defp current_member_for_identity(_members, nil), do: nil

  defp current_member_for_identity(members, identity) do
    identity_email = Accounts.normalize_email(identity.email)

    Enum.find(members, fn member -> Accounts.normalize_email(member.email) == identity_email end)
  end

  defp can_manage_members?(club_id, %{id: person_id}) do
    Membership.person_has_club_permission?(club_id, person_id, Permissions.club_manage_members())
  end

  defp can_manage_members?(_club_id, _current_member), do: false

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

  defp current_member_id(nil), do: nil
  defp current_member_id(current_member), do: current_member.id

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
