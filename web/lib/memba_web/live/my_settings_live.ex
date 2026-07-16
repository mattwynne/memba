defmodule MembaWeb.MySettingsLive do
  @moduledoc """
  Global personal settings surface for signed-in club members.

  The page is mounted from the authenticated club-member LiveView session so it
  can reuse the club-site shell while keeping the selected settings tab in the
  URL via LiveView patches.
  """
  use MembaWeb, :live_view

  alias Memba.Membership
  alias Memba.Membership.Events.PersonEmailAddressAdded
  alias Memba.Membership.Events.PersonEmailAddressRemoved
  alias Memba.Membership.Events.PersonEmailAddressVerified
  alias Memba.Membership.Events.PersonEmailAddressesReplaced
  alias Memba.Membership.Events.PersonPrimaryEmailAddressChanged
  alias Memba.Membership.PersonEmailAddressVerificationEmail
  alias Memba.ReadModelChanges

  @impl Phoenix.LiveView
  def mount(_params, session, socket) do
    with {:ok, selected_club} <- selected_club(session),
         {:ok, current_person} <- current_person(socket.assigns[:current_identity]) do
      if connected?(socket) do
        Phoenix.PubSub.subscribe(Memba.PubSub, ReadModelChanges.topic())
      end

      {:ok,
       assign(socket,
         page_title: "Account settings",
         selected_club: selected_club,
         current_person: current_person,
         current_person_clubs:
           Membership.list_active_club_memberships_for_person(current_person.person_id),
         current_person_email_addresses:
           Membership.list_person_email_addresses(current_person.person_id),
         add_email_form: to_form(%{"email" => ""}, as: :email_address),
         add_email_error: nil,
         active_tab: :profile
       )}
    else
      _missing_context -> forbidden!()
    end
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _uri, socket) do
    {:noreply, assign(socket, :active_tab, active_tab(socket.assigns.live_action))}
  end

  @impl Phoenix.LiveView
  def handle_info(
        {:read_model_changed,
         %{projector: Memba.Membership.Projectors.Person, source_event: event}},
        %{assigns: %{current_person: current_person}} = socket
      ) do
    if person_email_address_change_for_person?(event, current_person.person_id) do
      {:noreply, refresh_person_email_addresses(socket)}
    else
      {:noreply, socket}
    end
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  @impl Phoenix.LiveView
  def handle_event(
        "add_email_address",
        %{"email_address" => %{"email" => email}},
        %{assigns: %{current_person: current_person}} = socket
      ) do
    attrs = %{person_id: current_person.person_id, email: email}

    case add_pending_email_address_and_deliver_verification(socket, attrs) do
      :ok ->
        {:noreply,
         socket
         |> put_flash(:info, verification_email_sent_message())
         |> assign(:add_email_error, nil)
         |> assign(:add_email_form, to_form(%{"email" => ""}, as: :email_address))
         |> refresh_person_email_addresses()}

      {:error, reason} ->
        {:noreply,
         socket
         |> put_flash(:error, add_email_error_message(reason))
         |> assign(:add_email_error, add_email_error_message(reason))
         |> assign(:add_email_form, to_form(%{"email" => email}, as: :email_address))}
    end
  end

  def handle_event("resend_verification", %{"email" => email}, socket) do
    case deliver_person_email_address_verification(socket, email) do
      :ok ->
        {:noreply, put_flash(socket, :info, verification_email_sent_message())}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, email_action_error_message(reason))}
    end
  end

  def handle_event("make_primary", %{"email" => email}, socket) do
    attrs = %{person_id: socket.assigns.current_person.person_id, email: email}

    case Membership.make_person_email_address_primary(attrs, consistency: :strong) do
      :ok ->
        {:noreply, refresh_person_email_addresses(socket)}

      {:ok, _result} ->
        {:noreply, refresh_person_email_addresses(socket)}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, email_action_error_message(reason))}
    end
  end

  def handle_event("remove_email", %{"email" => email}, socket) do
    attrs = %{person_id: socket.assigns.current_person.person_id, email: email}

    case Membership.remove_person_email_address(attrs, consistency: :strong) do
      :ok ->
        {:noreply, refresh_person_email_addresses(socket)}

      {:ok, _result} ->
        {:noreply, refresh_person_email_addresses(socket)}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, email_action_error_message(reason))}
    end
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.club_site
      flash={@flash}
      club_name={@selected_club.name}
      current_identity={@current_identity}
      member_name={@current_person.name}
    >
      <main id="my-settings-main" class="px-6 py-7 sm:px-8 sm:py-10">
        <div
          id="my-settings"
          data-live-view="my-settings"
          data-active-tab={@active_tab}
          class="mx-auto grid max-w-[860px] gap-5"
        >
          <section class="grid gap-1">
            <.link
              id="my-settings-back-to-club"
              navigate={~p"/conversations"}
              class="inline-flex items-center gap-1 text-sm font-semibold text-ink-3 transition hover:text-sage-700"
            >
              ‹ Back to club
            </.link>
            <h1
              id="my-settings-title"
              class="text-[30px] font-bold leading-tight tracking-[-0.03em] text-ink"
            >
              Account settings
            </h1>
          </section>

          <div
            id="my-settings-layout"
            class="settings-layout flex flex-col gap-5 md:flex-row md:gap-7"
          >
            <nav
              id="my-settings-tabs-list"
              class="settings-tabs flex shrink-0 flex-row gap-1 overflow-x-auto md:w-44 md:flex-col md:overflow-visible"
              role="tablist"
              aria-orientation="vertical"
              aria-label="Account settings sections"
            >
              <.link
                id="my-settings-tab-profile"
                patch={settings_tab_path(:profile)}
                class={settings_tab_class(@active_tab, :profile)}
                data-tab="profile"
                role="tab"
                aria-selected={settings_tab_selected?(@active_tab, :profile)}
                aria-controls="my-settings-panel-profile"
              >
                Profile
              </.link>
              <.link
                id="my-settings-tab-clubs"
                patch={settings_tab_path(:clubs)}
                class={settings_tab_class(@active_tab, :clubs)}
                data-tab="clubs"
                role="tab"
                aria-selected={settings_tab_selected?(@active_tab, :clubs)}
                aria-controls="my-settings-panel-clubs"
              >
                Clubs
              </.link>
              <.link
                id="my-settings-tab-emails"
                patch={settings_tab_path(:emails)}
                class={settings_tab_class(@active_tab, :emails)}
                data-tab="emails"
                role="tab"
                aria-selected={settings_tab_selected?(@active_tab, :emails)}
                aria-controls="my-settings-panel-emails"
              >
                Emails
              </.link>
            </nav>

            <div id="my-settings-panels" class="min-w-0 flex-1">
              <section
                id="my-settings-panel-profile"
                role="tabpanel"
                aria-labelledby="my-settings-tab-profile"
                hidden={@active_tab != :profile}
                class="settings-panel"
              >
                <div id="my-settings-profile-card" class="settings-card">
                  <div class="settings-card__head">
                    <h2 class="settings-card__title">Profile</h2>
                  </div>
                  <div class="settings-card__body">
                    <div class="flex items-center gap-3">
                      <div
                        id="my-settings-profile-avatar"
                        class="grid size-10 shrink-0 place-items-center rounded-full bg-sage-400 text-sm font-bold text-white"
                      >
                        {person_initials(@current_person.name)}
                      </div>
                      <p id="my-settings-profile-name" class="text-xl font-bold text-ink">
                        {@current_person.name}
                      </p>
                    </div>
                  </div>
                </div>
              </section>

              <section
                id="my-settings-panel-clubs"
                role="tabpanel"
                aria-labelledby="my-settings-tab-clubs"
                hidden={@active_tab != :clubs}
                class="settings-panel"
              >
                <div id="my-settings-clubs-card" class="settings-card">
                  <div class="settings-card__head">
                    <h2 class="settings-card__title">Current clubs</h2>
                  </div>
                  <div class="settings-card__body">
                    <div id="my-settings-club-chip-list" class="flex flex-wrap gap-2">
                      <span
                        :for={club <- @current_person_clubs}
                        id={"my-settings-club-chip-#{club.club_id}"}
                        class="inline-flex items-center gap-2 rounded-full border border-base-300 bg-base-200 py-1.5 pr-3 pl-1.5"
                      >
                        <span class="grid size-[22px] place-items-center rounded-full bg-sage-200 text-[10px] font-bold text-sage-800">
                          {club_initials(club.club_name)}
                        </span>
                        <span>
                          <span class="text-sm font-semibold text-ink">{club.club_name}</span>
                          <br />
                          <span class="text-xs text-ink-3">
                            Member since {format_month_year(club.member_since)}
                          </span>
                        </span>
                      </span>
                    </div>
                  </div>
                </div>
              </section>

              <section
                id="my-settings-panel-emails"
                role="tabpanel"
                aria-labelledby="my-settings-tab-emails"
                hidden={@active_tab != :emails}
                class="settings-panel"
              >
                <div id="my-settings-email-addresses-card" class="settings-card">
                  <div class="settings-card__head">
                    <h2 class="settings-card__title">Email addresses</h2>
                    <p class="mt-1 text-sm leading-5 text-ink-3">
                      Your primary address is the one we'll send emails to. We'll accept incoming
                      emails from your other verified addresses.
                    </p>
                  </div>
                  <div class="settings-card__body">
                    <div id="my-settings-email-list" class="email-list">
                      <div
                        :for={email_address <- @current_person_email_addresses}
                        id={"my-settings-email-row-#{email_dom_id(email_address)}"}
                        class="email-row"
                        data-testid="person-email-row"
                        data-state={email_state(email_address)}
                      >
                        <div class="email-row__top">
                          <div class="email-row__address-line">
                            <span class="email-row__address">
                              {email_address.email}
                            </span>
                            <span
                              :if={email_address.primary?}
                              class="my-settings-primary-badge badge badge-primary badge-soft"
                            >
                              Primary
                            </span>
                          </div>
                          <.verified_badge :if={verified_email_address?(email_address)} />
                          <.pending_badge :if={!verified_email_address?(email_address)} />
                        </div>

                        <div
                          :if={!email_address.primary?}
                          class="email-row__actions-cell"
                        >
                          <.button
                            :if={verified_email_address?(email_address)}
                            id={"my-settings-make-primary-#{email_dom_id(email_address)}"}
                            type="button"
                            phx-click="make_primary"
                            phx-value-email={email_address.email}
                            variant="secondary"
                          >
                            Make primary
                          </.button>
                          <.button
                            :if={!verified_email_address?(email_address)}
                            id={"my-settings-resend-verification-#{email_dom_id(email_address)}"}
                            type="button"
                            phx-click="resend_verification"
                            phx-value-email={email_address.email}
                            variant="secondary"
                          >
                            Resend verification
                          </.button>
                          <.button
                            id={"my-settings-remove-email-#{email_dom_id(email_address)}"}
                            type="button"
                            phx-click="remove_email"
                            phx-value-email={email_address.email}
                            variant="ghost"
                          >
                            Remove
                          </.button>
                        </div>
                      </div>
                    </div>

                    <.form
                      for={@add_email_form}
                      id="my-settings-add-email-form"
                      class="mt-4 flex flex-wrap items-end gap-3"
                      phx-submit="add_email_address"
                    >
                      <div class="min-w-60 flex-1">
                        <.input
                          id="settings-add-email-input"
                          field={@add_email_form[:email]}
                          type="email"
                          label="Add an email address"
                          placeholder="dana@example.com"
                        />
                      </div>
                      <div class="mb-1">
                        <.button id="my-settings-add-email-button" type="submit">
                          Add email address
                        </.button>
                      </div>
                    </.form>

                    <p
                      :if={@add_email_error}
                      id="my-settings-add-email-error"
                      class="mt-2 text-sm font-semibold text-error"
                    >
                      {@add_email_error}
                    </p>
                  </div>
                </div>
              </section>
            </div>
          </div>
        </div>
      </main>
    </Layouts.club_site>
    """
  end

  attr :rest, :global

  defp verified_badge(assigns) do
    ~H"""
    <span class="my-settings-verified-badge badge badge-success badge-soft gap-1.5" {@rest}>
      <.icon name="hero-check" class="size-3 shrink-0" />Verified
    </span>
    """
  end

  attr :rest, :global

  defp pending_badge(assigns) do
    ~H"""
    <span class="my-settings-pending-badge badge badge-warning badge-soft gap-1.5" {@rest}>
      <span class="dot size-1.5 rounded-full bg-current"></span>Pending verification
    </span>
    """
  end

  defp selected_club(session) when is_map(session) do
    case Membership.get_club(Map.get(session, "club_id")) do
      nil -> {:error, :forbidden}
      club -> {:ok, club}
    end
  end

  defp selected_club(_session), do: {:error, :forbidden}

  defp current_person(%{email: email}) when is_binary(email) do
    case Membership.get_person_by_email(email) do
      nil -> {:error, :forbidden}
      person -> {:ok, person}
    end
  end

  defp current_person(_identity), do: {:error, :forbidden}

  defp refresh_person_email_addresses(socket) do
    assign(
      socket,
      :current_person_email_addresses,
      Membership.list_person_email_addresses(socket.assigns.current_person.person_id)
    )
  end

  defp add_pending_email_address_and_deliver_verification(socket, attrs) do
    with :ok <-
           normalize_context_result(
             Membership.add_person_email_address(attrs, consistency: :strong)
           ),
         :ok <- deliver_person_email_address_verification(socket, attrs.email) do
      :ok
    end
  end

  defp deliver_person_email_address_verification(socket, email) do
    attrs = %{person_id: socket.assigns.current_person.person_id, email: email}

    with {:ok, %{issuer_result: %{token: token}}} <-
           Membership.resend_person_email_address_verification(attrs),
         :ok <-
           PersonEmailAddressVerificationEmail.deliver(%{
             person_id: attrs.person_id,
             email: email,
             verification_url: url(~p"/my/settings/email-verifications/#{token}")
           }) do
      :ok
    end
  end

  defp normalize_context_result(:ok), do: :ok
  defp normalize_context_result({:ok, _result}), do: :ok
  defp normalize_context_result({:error, _reason} = error), do: error

  defp verification_email_sent_message,
    do:
      "You've been sent a verification email. Click the link in your email to verify this address"

  defp add_email_error_message(:email_address_taken),
    do: "That email address is already in use by another Memba user."

  defp add_email_error_message({:error, reason}), do: add_email_error_message(reason)

  defp add_email_error_message(_reason),
    do: "We could not add that email address. Please check it and try again."

  defp email_action_error_message({:error, reason}), do: email_action_error_message(reason)

  defp email_action_error_message(_reason),
    do: "We could not update that email address. Please try again."

  defp person_email_address_change_for_person?(
         %PersonEmailAddressAdded{person_id: person_id},
         person_id
       ),
       do: true

  defp person_email_address_change_for_person?(
         %PersonEmailAddressVerified{person_id: person_id},
         person_id
       ),
       do: true

  defp person_email_address_change_for_person?(
         %PersonPrimaryEmailAddressChanged{person_id: person_id},
         person_id
       ),
       do: true

  defp person_email_address_change_for_person?(
         %PersonEmailAddressRemoved{person_id: person_id},
         person_id
       ),
       do: true

  defp person_email_address_change_for_person?(
         %PersonEmailAddressesReplaced{person_id: person_id},
         person_id
       ),
       do: true

  defp person_email_address_change_for_person?(_event, _person_id), do: false

  defp active_tab(:clubs), do: :clubs
  defp active_tab(:emails), do: :emails
  defp active_tab(_live_action), do: :profile

  defp settings_tab_path(:profile), do: ~p"/my/settings/profile"
  defp settings_tab_path(:clubs), do: ~p"/my/settings/clubs"
  defp settings_tab_path(:emails), do: ~p"/my/settings/emails"

  defp settings_tab_class(active_tab, tab) do
    if active_tab == tab do
      [
        "settings-tab is-active rounded-lg bg-sage-50 px-3 py-2.5 text-left text-sm font-semibold text-sage-700 transition"
      ]
    else
      [
        "settings-tab rounded-lg px-3 py-2.5 text-left text-sm font-semibold text-ink-2 transition hover:bg-base-200 hover:text-ink"
      ]
    end
  end

  defp settings_tab_selected?(active_tab, tab), do: to_string(active_tab == tab)

  defp person_initials(name), do: initials(name)

  defp club_initials(name), do: initials(name)

  defp initials(name) when is_binary(name) do
    name
    |> String.split(~r/\s+/, trim: true)
    |> Enum.take(2)
    |> Enum.map_join("", fn word -> String.first(word) || "" end)
    |> String.upcase()
    |> case do
      "" -> "?"
      initials -> initials
    end
  end

  defp initials(_name), do: "?"

  defp format_month_year(%DateTime{} = date_time), do: Calendar.strftime(date_time, "%b %Y")
  defp format_month_year(_date_time), do: "joining"

  defp email_state(%{primary?: true}), do: "primary"

  defp email_state(email_address),
    do: if(verified_email_address?(email_address), do: "verified", else: "pending")

  defp verified_email_address?(%{verified_at: nil}), do: false
  defp verified_email_address?(%{verified_at: _verified_at}), do: true

  defp email_dom_id(%{normalized_email: normalized_email}) when is_binary(normalized_email) do
    Regex.replace(~r/[^a-zA-Z0-9_-]+/, normalized_email, "-")
    |> String.trim("-")
  end

  defp email_dom_id(_email_address), do: "unknown"

  defp forbidden!, do: raise(MembaWeb.ForbiddenError)
end
