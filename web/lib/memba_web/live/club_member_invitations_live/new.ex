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
  alias Memba.Membership.EmailAddresses
  alias Memba.Membership.Permissions
  alias MembaWeb.ClubMemberInvitationSender

  @empty_invitation %{"email" => ""}
  @empty_errors %{email: []}

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
       |> assign(invitation_assigns)
       |> assign_form(@empty_invitation, @empty_errors)}
    else
      _missing_or_unauthorized -> forbidden!(socket)
    end
  end

  @impl Phoenix.LiveView
  def handle_event("validate_invitation", %{"invitation" => invitation_params}, socket) do
    {:noreply, assign_form(socket, invitation_params, validation_errors(invitation_params))}
  end

  def handle_event("send_invitation", %{"invitation" => invitation_params}, socket) do
    with {:ok, invitation} <-
           ClubMemberInvitationSender.send_invitation(
             socket.assigns.selected_club,
             Map.get(invitation_params(invitation_params), "email"),
             consistency: :strong
           ) do
      {:noreply,
       socket
       |> put_flash(:info, success_message(invitation.email, invitation.resent?))
       |> assign_form(@empty_invitation, @empty_errors)}
    else
      {:error, :invalid_email} ->
        {:noreply,
         assign_form(socket, invitation_params, %{email: ["Enter a valid email address."]})}

      {:error, reason} ->
        {:noreply,
         socket
         |> put_flash(:error, failure_message(reason))
         |> assign_form(invitation_params, @empty_errors)}
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

        <section
          id="member-invitation-form-card"
          class="rounded-3xl border border-[var(--club-site-line)] bg-[var(--club-site-paper)] p-6 shadow-sm"
        >
          <div class="space-y-2">
            <p class="text-xs font-semibold uppercase tracking-[0.18em] text-[var(--club-site-muted)]">
              Invitation details
            </p>
            <h2 class="text-2xl font-semibold tracking-tight text-[var(--club-site-ink)]">
              Send an email invitation
            </h2>
            <p class="text-sm leading-6 text-[var(--club-site-muted)]">
              Provide the invitee’s email address. Memba sends the same one-use invitation link
              used by Staff invitations, and membership starts only after the invitee accepts.
            </p>
          </div>

          <.form
            for={@form}
            id="member-club-member-invitation-form"
            aria-label="Invite member"
            class="mt-6 space-y-5"
            phx-change="validate_invitation"
            phx-submit="send_invitation"
          >
            <.input
              name={@form[:email].name}
              value={@form[:email].value}
              id="member-club-member-invitation-email-input"
              type="email"
              label="Email address"
              aria-label="Invitee email address"
              autocomplete="email"
              placeholder="dana@example.com"
              errors={@form_errors.email}
              required
            />

            <div class="flex flex-col gap-3 sm:flex-row sm:items-center">
              <.button
                id="send-member-club-member-invitation-button"
                type="submit"
                aria-label="Send member invitation"
                class="inline-flex items-center justify-center rounded-full border border-[var(--club-site-accent)] bg-[var(--club-site-accent)] px-4 py-2 text-sm font-semibold text-white shadow-sm transition duration-200 hover:-translate-y-0.5 hover:shadow-md"
              >
                Send invitation
              </.button>

              <.link
                id="cancel-member-club-member-invitation-link"
                href={club_home_path(@selected_club, @route_params)}
                aria-label="Cancel member invitation"
                class="inline-flex items-center justify-center rounded-full border border-[var(--club-site-line)] bg-white px-4 py-2 text-sm font-semibold text-[var(--club-site-muted)] shadow-sm transition duration-200 hover:-translate-y-0.5 hover:text-[var(--club-site-ink)] hover:shadow-md"
              >
                Cancel
              </.link>
            </div>
          </.form>
        </section>
      </div>
    </Layouts.club_site>
    """
  end

  defp assign_form(socket, params, errors) do
    socket
    |> assign(:invitation_params, invitation_params(params))
    |> assign(:form_errors, Map.merge(@empty_errors, errors))
    |> assign(:form, to_form(invitation_params(params), as: :invitation))
  end

  defp invitation_params(params) when is_map(params) do
    %{"email" => Map.get(params, "email", "")}
  end

  defp invitation_params(_params), do: @empty_invitation

  defp validation_errors(params) do
    case Map.get(invitation_params(params), "email") do
      "" ->
        @empty_errors

      email ->
        if valid_email?(email),
          do: @empty_errors,
          else: %{email: ["Enter a valid email address."]}
    end
  end

  defp valid_email?(email), do: match?({:ok, _email}, EmailAddresses.normalize_email(email))

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

  defp success_message(email, false), do: "Invitation sent to #{email}"
  defp success_message(email, true), do: "Invitation resent to #{email}"

  defp failure_message(:already_active_member),
    do: "That email address is already an active member of this club."

  defp failure_message({:club_member_invitation_email_configuration_error, _message}) do
    "Invitation was created, but Memba could not send the email. Check auth email delivery configuration and try again."
  end

  defp failure_message({:club_member_invitation_email_delivery_error, _reason}) do
    "Invitation was created, but Memba could not send the email. Try again."
  end

  defp failure_message(reason), do: "Could not send invitation: #{inspect(reason)}"

  defp forbidden!(_socket), do: raise(MembaWeb.ForbiddenError)
end
