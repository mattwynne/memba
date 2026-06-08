defmodule MembaWeb.MemberInvitationLive.New do
  @moduledoc """
  LiveView entry point for member-facing club member invitations.

  The router references this module as `MemberInvitationLive.New` from the
  `scope "/", MembaWeb` block, matching the existing member LiveView route
  namespace without duplicating the `MembaWeb` prefix.
  """
  use MembaWeb, :live_view

  alias Memba.Membership
  alias Memba.Membership.ClubMemberInvitationEmail
  alias Memba.Membership.EmailAddresses
  alias Memba.Membership.Permissions

  @empty_invitation %{"email" => ""}
  @empty_errors %{email: []}

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
             |> assign(invitation_assigns)
             |> assign_form(@empty_invitation, @empty_errors)}

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
  def handle_event("validate_invitation", %{"invitation" => invitation_params}, socket) do
    {:noreply, assign_form(socket, invitation_params, validation_errors(invitation_params))}
  end

  def handle_event("validate_invitation", _params, socket) do
    {:noreply, assign_form(socket, @empty_invitation, @empty_errors)}
  end

  def handle_event("send_invitation", %{"invitation" => invitation_params}, socket) do
    with %{} = club <- socket.assigns.selected_club,
         %{} = current_person <- socket.assigns.current_person,
         {:ok, invited_email} <- invitation_email(invitation_params),
         pending? = pending_invitation?(club.club_id, invited_email.normalized_email),
         {:ok, invitation} <-
           Membership.invite_club_member_as_club_member(
             %{
               "club_id" => club.club_id,
               "actor_person_id" => current_person.person_id,
               "email" => invited_email.normalized_email
             },
             consistency: :strong
           ),
         :ok <- deliver_invitation(invitation, invited_email.normalized_email, club) do
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

      nil ->
        forbidden!(socket)
    end
  end

  def handle_event("send_invitation", _params, socket) do
    handle_event("send_invitation", %{"invitation" => %{}}, socket)
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

        <section
          id="member-invitation-form-card"
          class="mx-auto max-w-3xl overflow-hidden rounded-3xl border border-[var(--club-site-line)] bg-[var(--club-site-paper)] shadow-sm"
        >
          <div class="border-b border-[var(--club-site-line)] p-6 sm:p-8">
            <p class="text-xs font-semibold uppercase tracking-[0.18em] text-[var(--club-site-muted)]">
              Invitation details
            </p>
            <h2 class="mt-2 text-2xl font-semibold tracking-tight text-[var(--club-site-ink)]">
              Email-only member invitation
            </h2>
            <p class="mt-3 text-sm leading-6 text-[var(--club-site-muted)]">
              Enter the email address to invite. The invitee will provide any profile details
              themselves before Memba creates their membership.
            </p>
          </div>

          <.form
            for={@form}
            id="member-invitation-form"
            aria-label="Invite member"
            class="space-y-5 p-6 sm:p-8"
            phx-change="validate_invitation"
            phx-submit="send_invitation"
          >
            <div class="rounded-2xl border border-[var(--club-site-line)] bg-[var(--club-site-bg)] p-4">
              <.input
                name={@form[:email].name}
                value={@form[:email].value}
                id="member-invitation-email-input"
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
                id="send-member-invitation-button"
                type="submit"
                aria-label="Send member invitation"
                class="inline-flex min-h-12 items-center justify-center gap-2 rounded-full bg-[var(--club-site-accent)] px-6 py-3 text-sm font-semibold text-white shadow-sm transition duration-200 hover:-translate-y-0.5 hover:shadow-md"
              >
                <.icon name="hero-paper-airplane" class="size-4" /> Send invitation
              </.button>

              <.link
                id="cancel-member-invitation-link"
                href={club_home_path(@selected_club, @route_params)}
                aria-label="Cancel member invitation"
                class="inline-flex min-h-12 items-center justify-center rounded-full border border-[var(--club-site-line)] bg-[var(--club-site-paper)] px-6 py-3 text-sm font-semibold text-[var(--club-site-muted)] transition duration-200 hover:-translate-y-0.5 hover:bg-white hover:text-[var(--club-site-ink)]"
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
      {:ok, %{selected_club: selected_club, current_person: current_person}}
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
    socket
    |> assign(:selected_club, nil)
    |> assign(:current_person, nil)
    |> assign_form(@empty_invitation, @empty_errors)
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

  defp failure_message(:forbidden), do: "You are not allowed to invite members for this club."
  defp failure_message(reason), do: "Could not send invitation: #{inspect(reason)}"

  defp forbidden!(_socket), do: raise(MembaWeb.ForbiddenError)
end
