defmodule MembaWeb.MemberInvitationLive.New do
  @moduledoc """
  Member-facing club invitation entry point.

  The route is scoped to the selected club through the canonical club subdomain,
  which carries the host-selected club in the LiveView session.
  """
  use MembaWeb, :live_view

  alias Memba.Accounts
  alias Memba.Membership
  alias Memba.Membership.Authorization
  alias Memba.Membership.ClubMemberInvitationEmail
  alias Memba.Membership.EmailAddresses
  alias MembaWeb.ClubSite

  @empty_invitation %{"email" => ""}
  @empty_errors %{email: []}

  @impl Phoenix.LiveView
  def mount(params, session, socket) when is_map(params) do
    params = put_session_club_id(params, session) |> put_club_id_source(session)
    socket = ensure_identity_assigns(socket)

    with club_id when is_binary(club_id) <- Map.get(params, "club_id"),
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
      _missing_or_forbidden_context ->
        forbidden!(socket)
    end
  end

  def mount(_params, _session, socket), do: forbidden!(socket)

  @impl Phoenix.LiveView
  def handle_event("validate_invitation", %{"invitation" => invitation_params}, socket) do
    {:noreply, assign_form(socket, invitation_params, validation_errors(invitation_params))}
  end

  def handle_event("send_invitation", %{"invitation" => invitation_params}, socket) do
    with {:ok, invited_email} <- invitation_email(invitation_params),
         club_id <- selected_club_id(socket.assigns.selected_club, socket.assigns.route_params),
         pending? = pending_invitation?(club_id, invited_email.normalized_email),
         {:ok, invitation} <-
           Membership.invite_club_member(
             %{"club_id" => club_id, "email" => invited_email.normalized_email},
             consistency: :strong
           ),
         :ok <-
           deliver_invitation(
             invitation,
             invited_email.normalized_email,
             socket.assigns.selected_club
           ) do
      {:noreply,
       socket
       |> put_flash(:info, success_message(invited_email.normalized_email, pending?))
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
      member_name={@current_member && @current_member.name}
    >
      <div
        id="member-club-invitation-new"
        data-live-view="member-club-invitation-new"
        data-club-id={selected_club_id(@selected_club, @route_params)}
        data-current-member-id={current_member_id(@current_member)}
        data-active-member-count={@active_member_count}
        class="mx-auto max-w-3xl space-y-8"
      >
        <section class="overflow-hidden rounded-3xl border border-base-300 bg-base-100 p-6 shadow-sm sm:p-8">
          <.link
            id="member-club-invitation-club-home-link"
            href={club_home_path(@selected_club, @route_params)}
            class="inline-flex w-fit items-center gap-2 text-sm font-semibold text-ink-2 transition duration-200 hover:text-base-content"
          >
            <.icon name="hero-arrow-left" class="size-4" /> Club home
          </.link>

          <p class="mt-5 text-xs font-semibold uppercase tracking-[0.18em] text-ink-2">
            Member invitations
          </p>

          <h1 class="mt-2 text-4xl font-semibold tracking-tight text-base-content">
            Invite a member
          </h1>

          <p
            id="member-club-invitation-selected-club"
            data-club-id={selected_club_id(@selected_club, @route_params)}
            class="mt-3 text-sm font-semibold uppercase tracking-[0.18em] text-primary"
          >
            {selected_club_name(@selected_club)}
          </p>

          <p class="mt-5 text-base leading-7 text-ink-2">
            Send a one-use invitation link for {selected_club_name(@selected_club)}. The
            invitation stays scoped to this club, and invited people will become ordinary
            members after they accept.
          </p>

          <div
            id="member-club-invitation-current-member"
            data-current-member-id={current_member_id(@current_member)}
            class="mt-6 flex items-center gap-3 rounded-2xl border border-base-300 bg-base-200 px-4 py-3"
          >
            <.avatar
              id="member-club-invitation-current-member-avatar"
              data-testid="member-club-invitation-current-member-avatar"
              initials={member_initials(current_member_name(@current_member))}
              size={:md}
              class="shrink-0"
              title={current_member_name(@current_member)}
            />
            <span class="min-w-0">
              <strong class="block truncate text-sm font-semibold text-base-content">
                {current_member_name(@current_member)}
              </strong>
              <span class="block text-xs text-ink-2">
                Inviting from this club membership
              </span>
            </span>
          </div>
        </section>

        <section
          id="member-club-invitation-form-card"
          class="overflow-hidden rounded-3xl border border-base-300 bg-base-100 shadow-sm"
        >
          <div class="border-b border-base-300 p-5">
            <p class="text-xs font-semibold uppercase tracking-[0.18em] text-ink-2">
              Invitation details
            </p>
            <h2 class="mt-1 text-lg font-semibold text-base-content">
              Email-only member invitation
            </h2>
            <p class="mt-1 text-sm text-ink-2">
              Enter the invitee's email address. Memba sends a one-use link so the
              invited person controls that email before membership starts.
            </p>
          </div>

          <.form
            for={@form}
            id="member-club-invitation-form"
            aria-label="Invite member"
            class="space-y-5 p-5"
            phx-change="validate_invitation"
            phx-submit="send_invitation"
          >
            <div class="rounded-2xl border border-base-300 bg-base-200 p-4">
              <.input
                name={@form[:email].name}
                value={@form[:email].value}
                id="member-club-invitation-email-input"
                type="email"
                label="Email address"
                aria-label="Invitee email address"
                autocomplete="email"
                placeholder="dana@example.com"
                errors={@form_errors.email}
                required
              />
            </div>

            <div class="flex flex-col gap-3 sm:flex-row sm:items-center">
              <.button
                id="send-member-club-invitation-button"
                type="submit"
                aria-label="Send member invitation"
                variant="primary"
                size="lg"
              >
                Send invitation
              </.button>

              <.button
                id="cancel-member-club-invitation-link"
                href={club_home_path(@selected_club, @route_params)}
                aria-label="Cancel member invitation"
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

  defp invitation_email(params) do
    params
    |> invitation_params()
    |> Map.get("email")
    |> EmailAddresses.normalize_email()
  end

  defp valid_email?(email), do: match?({:ok, _email}, EmailAddresses.normalize_email(email))

  defp pending_invitation?(club_id, email) do
    not is_nil(Membership.get_pending_club_member_invitation_by_email(club_id, email))
  end

  defp deliver_invitation(invitation, email, club) do
    ClubMemberInvitationEmail.deliver(%{
      email: email,
      club: club,
      invitation_id: invitation.invitation_id,
      invitation_url: invitation_url(invitation.invitation_token)
    })
  end

  defp invitation_url(invitation_token) do
    MembaWeb.Endpoint.url() <>
      "/invitations/club-members/" <> URI.encode(invitation_token, &URI.char_unreserved?/1)
  end

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
         :ok <- Authorization.authorize_manage_members(club_id, current_member.id) do
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

  defp current_member_name(nil), do: "Current member"
  defp current_member_name(current_member), do: current_member.name

  defp club_home_path(_selected_club, %{"club_id_source" => "host"}), do: ~p"/conversations"

  defp club_home_path(selected_club, _route_params),
    do: ClubSite.url(selected_club, "/conversations")

  defp member_initials(nil), do: "ME"

  defp member_initials(name) do
    name
    |> String.split(~r/\s+/, trim: true)
    |> Enum.take(2)
    |> Enum.map(&String.first/1)
    |> Enum.join()
    |> String.upcase()
    |> case do
      "" -> "ME"
      initials -> initials
    end
  end

  defp forbidden!(_socket), do: raise(MembaWeb.ForbiddenError)
end
