defmodule MembaWeb.MemberGroupLive.New do
  @moduledoc """
  Member-facing entry point for creating a private club group.

  The selected club comes from the canonical club subdomain and the surface is
  available only to an active member with club-management authority. Live
  validation and authoritative creation are layered onto this name-only form
  separately.
  """
  use MembaWeb, :live_view

  alias Memba.Accounts
  alias Memba.Membership
  alias Memba.Membership.Authorization
  alias MembaWeb.ClubSite

  @empty_group %{"name" => ""}

  @impl Phoenix.LiveView
  def mount(params, session, socket) when is_map(params) do
    route_params = params |> put_session_club_id(session) |> put_club_id_source(session)

    with club_id when is_binary(club_id) <- Map.get(route_params, "club_id"),
         {:ok, group_context} <-
           group_context(
             club_id,
             socket.assigns.current_identity,
             socket.assigns.current_identity_clubs
           ) do
      {:ok,
       socket
       |> assign(:route_params, route_params)
       |> assign(group_context)
       |> assign(:form, to_form(@empty_group, as: :group))}
    else
      _missing_or_forbidden_context ->
        forbidden!()
    end
  end

  def mount(_params, _session, _socket), do: forbidden!()

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.club_site
      flash={@flash}
      club_name={@selected_club.name}
      current_identity={@current_identity}
      member_name={@current_member.name}
    >
      <div
        id="member-group-new"
        data-live-view="member-group-new"
        data-club-id={@selected_club.club_id}
        data-current-member-id={@current_member.id}
        class="mx-auto max-w-3xl"
      >
        <.link
          id="member-group-new-back-link"
          navigate={groups_path(@selected_club, @route_params)}
          class="inline-flex w-fit items-center gap-2 text-sm font-semibold text-ink-2 transition duration-200 hover:text-sage-700"
        >
          <.icon name="hero-arrow-left" class="size-4" aria-hidden="true" /> Back to groups
        </.link>

        <header class="mt-5">
          <p class="text-xs font-semibold uppercase tracking-[0.18em] text-sage-700">
            Private group
          </p>
          <h1 class="mt-2 text-4xl font-semibold tracking-tight text-base-content">
            New group
          </h1>
          <p
            id="member-group-new-selected-club"
            data-club-id={@selected_club.club_id}
            class="mt-3 text-sm font-semibold uppercase tracking-[0.18em] text-primary"
          >
            {@selected_club.name}
          </p>
          <p class="mt-5 max-w-2xl text-base leading-7 text-ink-2">
            Everyone in the club will see this group's name. Only its members can read its
            conversations or receive its emails. You'll be its first member.
          </p>
        </header>

        <section
          id="member-group-new-form-card"
          class="mt-8 overflow-hidden rounded-3xl border border-base-300 bg-base-100 shadow-sm"
        >
          <div class="border-b border-base-300 p-5">
            <p class="text-xs font-semibold uppercase tracking-[0.18em] text-ink-2">
              Group details
            </p>
            <h2 class="mt-1 text-lg font-semibold text-base-content">
              Choose a name
            </h2>
            <p class="mt-1 text-sm leading-6 text-ink-2">
              Memba generates the group's email address from this name.
            </p>
          </div>

          <.form
            for={@form}
            id="member-group-new-form"
            aria-label="Create a group"
            class="space-y-5 p-5"
          >
            <.input
              field={@form[:name]}
              id="member-group-name-input"
              type="text"
              label="Group name"
              autocomplete="off"
              placeholder="e.g. Board, Trips committee, Newsletter"
              aria-describedby="member-group-name-hint"
              required
            />
            <p id="member-group-name-hint" class="-mt-4 text-sm leading-6 text-ink-3">
              Use a name that's different from the club's existing groups.
            </p>

            <div
              id="member-group-email-preview-panel"
              class="rounded-2xl border border-base-300 bg-base-200 px-4 py-3"
            >
              <span
                id="member-group-email-preview-label"
                class="text-xs font-semibold uppercase tracking-[0.16em] text-ink-3"
              >
                Group email
              </span>
              <output
                id="member-group-email-preview"
                for="member-group-name-input"
                aria-labelledby="member-group-email-preview-label"
                aria-live="polite"
                class="mt-1 block min-h-6 text-sm italic text-ink-3"
              >
                Appears here as you type the name
              </output>
            </div>

            <div class="flex flex-col gap-3 sm:flex-row sm:items-center">
              <.button
                id="member-group-create-button"
                type="submit"
                variant="primary"
                size="lg"
                disabled
              >
                Create group
              </.button>

              <.button
                id="member-group-new-cancel-link"
                navigate={groups_path(@selected_club, @route_params)}
                variant="secondary"
                size="lg"
              >
                Cancel
              </.button>
            </div>
          </.form>
        </section>
      </div>
    </Layouts.club_site>
    """
  end

  defp group_context(club_id, current_identity, current_identity_clubs) do
    with selected_club when not is_nil(selected_club) <-
           Enum.find(current_identity_clubs, &(&1.club_id == club_id)),
         current_member when not is_nil(current_member) <-
           current_member(club_id, current_identity),
         :ok <- Authorization.authorize_manage_members(club_id, current_member.id) do
      {:ok, %{selected_club: selected_club, current_member: current_member}}
    else
      _missing_or_forbidden_context -> {:error, :forbidden}
    end
  end

  defp current_member(_club_id, nil), do: nil

  defp current_member(club_id, identity) do
    identity_email = Accounts.normalize_email(identity.email)

    club_id
    |> Membership.list_active_members_of_club()
    |> Enum.find(fn member -> Accounts.normalize_email(member.email) == identity_email end)
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

  defp groups_path(_selected_club, %{"club_id_source" => "host"}), do: ~p"/conversations"

  defp groups_path(selected_club, _route_params),
    do: ClubSite.url(selected_club, ~p"/conversations")

  defp forbidden!, do: raise(MembaWeb.ForbiddenError)
end
