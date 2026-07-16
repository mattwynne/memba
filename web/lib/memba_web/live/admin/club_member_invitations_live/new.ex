defmodule MembaWeb.Admin.ClubMemberInvitationsLive.New do
  use MembaWeb, :live_view

  alias Memba.Membership
  alias Memba.Membership.ClubMemberInvitationEmail
  alias Memba.Membership.EmailAddresses

  @empty_invitation %{"email" => ""}
  @empty_errors %{email: []}

  @impl Phoenix.LiveView
  def mount(%{"club_id" => club_id}, _session, socket) do
    club = Membership.get_club(club_id)

    {:ok,
     socket
     |> assign(:club_id, club_id)
     |> assign(:club, club)
     |> assign_form(@empty_invitation, @empty_errors)}
  end

  @impl Phoenix.LiveView
  def handle_event("validate_invitation", %{"invitation" => invitation_params}, socket) do
    {:noreply, assign_form(socket, invitation_params, validation_errors(invitation_params))}
  end

  def handle_event("send_invitation", %{"invitation" => invitation_params}, socket) do
    with %{} = club <- socket.assigns.club,
         {:ok, invited_email} <- invitation_email(invitation_params),
         pending? = pending_invitation?(socket.assigns.club_id, invited_email.normalized_email),
         {:ok, invitation} <-
           Membership.invite_club_member(
             %{"club_id" => socket.assigns.club_id, "email" => invited_email.normalized_email},
             consistency: :strong
           ),
         :ok <- deliver_invitation(invitation, invited_email.normalized_email, club) do
      {:noreply,
       socket
       |> put_flash(:info, success_message(invited_email.normalized_email, pending?))
       |> assign_form(@empty_invitation, @empty_errors)}
    else
      nil ->
        {:noreply,
         socket
         |> put_flash(:error, "Club not found")
         |> assign_form(invitation_params, @empty_errors)}

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
    <Layouts.admin flash={@flash} current_identity={@current_identity} active={:clubs}>
      <main
        id="club-member-invitation-new"
        data-admin-page="club-member-invitation-new"
        data-club-id={@club_id}
        class="mx-auto max-w-5xl space-y-6 p-6"
      >
        <%= if @club do %>
          <section
            id="club-member-invitation-page-header"
            class="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between"
          >
            <div class="space-y-2">
              <.link
                id="back-to-club-link"
                navigate={~p"/admin/clubs/#{@club_id}"}
                aria-label="Back to club"
                class="text-sm font-semibold text-[#1f4842] transition duration-200 hover:text-[#15201c]"
              >
                ← Club
              </.link>
              <p class="text-sm font-semibold uppercase tracking-wide text-[#7d877f]">
                Member invitations
              </p>
              <h1 class="text-3xl font-bold tracking-tight text-[#15201c]">Invite a member</h1>
              <p class="max-w-3xl text-[#4b5a55]">
                Send a one-use invitation link for {@club.name}. The invitee controls the email
                address and will enter their own profile details before membership starts.
              </p>
            </div>

            <div
              id="club-member-invitation-context-card"
              class="rounded-2xl border border-[#e6e3dc] bg-white p-4 shadow-sm"
            >
              <p class="text-xs font-semibold uppercase tracking-wide text-[#7d877f]">
                Club context
              </p>
              <p class="mt-2 text-lg font-bold tracking-tight text-[#15201c]">{@club.name}</p>
              <p class="mt-1 break-all font-mono text-xs text-[#7d877f]">{@club.club_id}</p>
            </div>
          </section>

          <section
            id="club-member-invitation-form-card"
            class="overflow-hidden rounded-2xl border border-[#e6e3dc] bg-white shadow-sm"
          >
            <div class="border-b border-[#e6e3dc] p-5">
              <p class="text-xs font-semibold uppercase tracking-wide text-[#7d877f]">
                Invitation details
              </p>
              <h2 class="mt-1 text-lg font-semibold text-[#15201c]">
                Email-only member invitation
              </h2>
              <p class="mt-1 text-sm text-[#7d877f]">
                Staff provide only the email address. Memba will not create a person record or an
                active club membership until the invitee accepts and completes profile details.
              </p>
            </div>

            <.form
              for={@form}
              id="club-member-invitation-form"
              aria-label="Invite member"
              class="space-y-5 p-5"
              phx-change="validate_invitation"
              phx-submit="send_invitation"
            >
              <div class="rounded-2xl border border-[#e6e3dc] bg-[#f7f6f3] p-4">
                <.input
                  name={@form[:email].name}
                  value={@form[:email].value}
                  id="club-member-invitation-email-input"
                  type="email"
                  label="Email address"
                  aria-label="Invitee email address"
                  autocomplete="email"
                  placeholder="robin@example.com"
                  errors={@form_errors.email}
                  required
                />
              </div>

              <div class="flex flex-col gap-3 sm:flex-row sm:items-center">
                <.button
                  id="send-club-member-invitation-button"
                  type="submit"
                  aria-label="Send member invitation"
                >
                  Send invitation
                </.button>

                <.link
                  id="cancel-club-member-invitation-link"
                  navigate={~p"/admin/clubs/#{@club_id}"}
                  aria-label="Cancel member invitation"
                  class="inline-flex items-center justify-center rounded-full border border-[#d6d2c8] bg-white px-4 py-2 text-sm font-semibold text-[#4b5a55] shadow-sm transition duration-200 hover:-translate-y-0.5 hover:border-[#1f4842] hover:text-[#15201c] hover:shadow-md"
                >
                  Cancel
                </.link>
              </div>
            </.form>
          </section>
        <% else %>
          <section class="space-y-4">
            <.link
              id="back-to-clubs-link"
              navigate={~p"/admin/clubs"}
              aria-label="Back to clubs"
              class="text-sm font-semibold text-[#1f4842] transition duration-200 hover:text-[#15201c]"
            >
              ← Clubs
            </.link>
            <div class="rounded-2xl border border-[#e6e3dc] bg-white p-5 shadow-sm">
              <h1 class="text-2xl font-bold text-[#15201c]">Club not found</h1>
              <p class="mt-2 text-[#4b5a55]">No projected club exists for this URL.</p>
            </div>
          </section>
        <% end %>
      </main>
    </Layouts.admin>
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
end
