defmodule MembaWeb.MySettingsLive do
  @moduledoc """
  Global personal settings surface for signed-in club members.

  The page is mounted from the authenticated club-member LiveView session so it
  can reuse the club-site shell while keeping the selected settings tab in the
  URL via LiveView patches.
  """
  use MembaWeb, :live_view

  alias Memba.Membership

  @impl Phoenix.LiveView
  def mount(_params, session, socket) do
    with {:ok, selected_club} <- selected_club(session),
         {:ok, current_person} <- current_person(socket.assigns[:current_identity]) do
      {:ok,
       assign(socket,
         page_title: "Account settings",
         selected_club: selected_club,
         current_person: current_person,
         current_person_clubs: socket.assigns[:current_identity_clubs] || [],
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
  def render(assigns) do
    ~H"""
    <Layouts.club_site
      flash={@flash}
      club_name={@selected_club.name}
      current_identity={@current_identity}
      member_name={@current_person.name}
    >
      <div
        id="my-settings"
        data-live-view="my-settings"
        data-active-tab={@active_tab}
        class="mx-auto max-w-4xl space-y-8"
      >
        <section class="space-y-4">
          <p class="text-xs font-semibold uppercase tracking-[0.18em] text-ink-2">
            Personal settings
          </p>
          <h1 id="my-settings-title" class="text-4xl font-semibold tracking-tight text-base-content">
            Account settings
          </h1>
          <p class="max-w-2xl text-base leading-7 text-ink-2">
            Manage the personal profile, club memberships, and email addresses connected
            to your Memba identity.
          </p>
        </section>

        <div id="my-settings-tabs" class="section-tabs">
          <div
            id="my-settings-tabs-list"
            class="section-tabs__list"
            role="tablist"
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
          </div>
        </div>

        <section
          id="my-settings-panel-profile"
          role="tabpanel"
          aria-labelledby="my-settings-tab-profile"
          hidden={@active_tab != :profile}
          class="rounded-3xl border border-base-300 bg-base-100 p-6 shadow-sm"
        >
          <h2 class="text-xl font-semibold text-base-content">Profile</h2>
          <p class="mt-2 text-sm leading-6 text-ink-2">
            Your profile settings will appear here.
          </p>
        </section>

        <section
          id="my-settings-panel-clubs"
          role="tabpanel"
          aria-labelledby="my-settings-tab-clubs"
          hidden={@active_tab != :clubs}
          class="rounded-3xl border border-base-300 bg-base-100 p-6 shadow-sm"
        >
          <h2 class="text-xl font-semibold text-base-content">Clubs</h2>
          <p class="mt-2 text-sm leading-6 text-ink-2">
            Your club memberships will appear here.
          </p>
        </section>

        <section
          id="my-settings-panel-emails"
          role="tabpanel"
          aria-labelledby="my-settings-tab-emails"
          hidden={@active_tab != :emails}
          class="rounded-3xl border border-base-300 bg-base-100 p-6 shadow-sm"
        >
          <h2 class="text-xl font-semibold text-base-content">Emails</h2>
          <p class="mt-2 text-sm leading-6 text-ink-2">
            Your email-address settings will appear here.
          </p>
        </section>
      </div>
    </Layouts.club_site>
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

  defp active_tab(:clubs), do: :clubs
  defp active_tab(:emails), do: :emails
  defp active_tab(_live_action), do: :profile

  defp settings_tab_path(:profile), do: ~p"/my/settings/profile"
  defp settings_tab_path(:clubs), do: ~p"/my/settings/clubs"
  defp settings_tab_path(:emails), do: ~p"/my/settings/emails"

  defp settings_tab_class(active_tab, tab) do
    if active_tab == tab do
      "section-tab is-active"
    else
      "section-tab"
    end
  end

  defp settings_tab_selected?(active_tab, tab), do: to_string(active_tab == tab)

  defp forbidden!, do: raise(MembaWeb.ForbiddenError)
end
