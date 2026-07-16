defmodule MembaWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use MembaWeb, :html

  alias MembaWeb.ClubSite

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  defp git_commit_footer_link, do: Memba.BuildInfo.footer_commit()

  defp hide_public_footer?(assigns) do
    assigns
    |> Map.get(:conn)
    |> public_footer_suppressed?()
  end

  defp public_footer_suppressed?(%Plug.Conn{assigns: %{hide_public_footer: true}}), do: true
  defp public_footer_suppressed?(_conn), do: false

  @doc """
  Renders the shared public/visitor header.

  Matches the marketing nav from the design system: the wordmark and link
  cluster sit together on the left, with the sign-in / request-access actions
  pushed to the right. Used by the public homepage and every public-chrome page
  so visitors never see the navigation change as they move between pages.
  """
  def site_header(assigns) do
    ~H"""
    <header class="relative z-20 border-b border-line bg-paper/85 backdrop-blur">
      <div class="mx-auto flex max-w-7xl items-center gap-8 px-4 py-4 sm:px-6 lg:px-8">
        <a
          href={~p"/"}
          class="min-w-0 shrink-0 transition duration-200 hover:opacity-80"
          aria-label="Memba home"
        >
          <.logo />
        </a>

        <nav
          class="hidden items-center gap-7 text-sm font-medium text-ink-2 md:flex"
          aria-label="Main navigation"
        >
          <a href="/#features" class="transition hover:text-ink">Features</a>
          <a href={~p"/get-started"} class="transition hover:text-ink">Pricing</a>
          <a href={~p"/about"} class="transition hover:text-ink">About</a>
        </nav>

        <div class="ml-auto flex items-center gap-3">
          <a
            href={~p"/auth"}
            class="hidden rounded-full border border-line-strong bg-paper px-5 py-2.5 text-sm font-semibold text-ink transition duration-200 hover:-translate-y-0.5 hover:bg-white sm:inline-flex"
          >
            Sign in
          </a>
          <a
            href={~p"/get-started"}
            class="shrink-0 rounded-full border border-sage-600 bg-sage-600 px-5 py-2.5 text-sm font-semibold text-cream shadow-sm transition duration-200 hover:-translate-y-0.5 hover:bg-sage-700 hover:shadow-md"
          >
            Request access
          </a>
        </div>
      </div>
    </header>
    """
  end

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <.site_header />

    <main class="px-4 py-16 sm:px-6 lg:px-8">
      <div class="mx-auto max-w-2xl space-y-4">
        {render_slot(@inner_block)}
      </div>
    </main>

    <.flash_group flash={@flash} />
    """
  end

  @doc """
  Renders the Memba staff layout.

  The admin surface keeps Memba branding visible while using a calm
  operations shell for internal workflows and diagnostics.
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  attr :current_identity, :map,
    default: nil,
    doc: "the signed-in staff identity shown in the staff chrome"

  attr :active, :atom,
    default: nil,
    values: [nil, :clubs, :requests, :people, :messages, :deliveries],
    doc: "the active staff navigation item"

  slot :inner_block, required: true

  def admin(assigns) do
    ~H"""
    <div
      id="admin-layout"
      data-surface="admin"
      class="min-h-screen bg-[#f7f6f3] text-[#15201c] lg:flex"
    >
      <aside
        id="admin-sidebar"
        class="border-b border-[#1b2a24] bg-[#102019] px-4 text-white shadow-sm lg:sticky lg:top-0 lg:flex lg:h-screen lg:w-60 lg:flex-col lg:border-r lg:border-b-0 lg:px-3"
      >
        <div class="flex flex-col gap-6 py-5 lg:min-h-full">
          <a
            href={~p"/admin/clubs"}
            class="inline-flex w-fit items-center gap-2.5 px-1 transition duration-200 hover:opacity-80"
            aria-label="Memba staff home"
          >
            <span class="flex size-7 items-center justify-center rounded-lg bg-[#24574d] text-white">
              <.sprig class="size-4 text-white" />
            </span>
            <span class="text-base font-bold tracking-tight text-white">Memba</span>
            <span class="rounded-full bg-[#6b614b] px-2 py-0.5 text-[10px] font-bold uppercase tracking-[0.18em] text-[#eee6cf]">
              Staff
            </span>
          </a>

          <nav class="space-y-6" aria-label="Memba staff navigation">
            <div class="space-y-2">
              <p
                id="admin-navigation-group"
                class="px-2 text-[11px] font-bold uppercase tracking-[0.18em] text-white/45"
              >
                Operations
              </p>
              <div class="grid gap-1">
                <.link
                  navigate={~p"/admin/clubs"}
                  id="admin-nav-clubs"
                  data-admin-nav-item="clubs"
                  class={admin_nav_class(@active == :clubs)}
                >
                  <span class="flex items-center gap-3">
                    <.icon name="hero-building-office-2" class="size-4 bg-current" /> Clubs
                  </span>
                </.link>
                <.link
                  navigate={~p"/admin/requests"}
                  id="admin-nav-requests"
                  data-admin-nav-item="requests"
                  class={admin_nav_class(@active == :requests)}
                >
                  <span class="flex items-center gap-3">
                    <.icon name="hero-inbox-tray" class="size-4 bg-current" /> Requests
                  </span>
                </.link>
                <.link
                  navigate={~p"/admin/people"}
                  id="admin-nav-people"
                  data-admin-nav-item="people"
                  class={admin_nav_class(@active == :people)}
                >
                  <span class="flex items-center gap-3">
                    <.icon name="hero-users" class="size-4 bg-current" /> People
                  </span>
                </.link>
              </div>
            </div>

            <div class="space-y-2">
              <p class="px-2 text-[11px] font-bold uppercase tracking-[0.18em] text-white/45">
                Messaging
              </p>
              <div class="grid gap-1">
                <.link
                  navigate={~p"/admin/messages"}
                  id="admin-nav-messages"
                  data-admin-nav-item="messages"
                  class={admin_nav_class(@active == :messages)}
                >
                  <span class="flex items-center gap-3">
                    <.icon name="hero-envelope" class="size-4 bg-current" /> Messages
                  </span>
                </.link>
                <.link
                  navigate={~p"/admin/deliveries"}
                  id="admin-nav-deliveries"
                  data-admin-nav-item="deliveries"
                  class={admin_nav_class(@active == :deliveries)}
                >
                  <span class="flex items-center gap-3">
                    <.icon name="hero-paper-airplane" class="size-4 bg-current" /> Deliveries
                  </span>
                </.link>
              </div>
            </div>
          </nav>

          <div
            id="admin-staff-identity-block"
            class="mt-auto border-t border-white/10 px-2 pt-3"
          >
            <div class="flex items-center justify-between gap-3">
              <div class="flex min-w-0 items-center gap-3">
                <div class="flex size-8 shrink-0 items-center justify-center rounded-full bg-[#2f6257] text-xs font-bold text-white">
                  {staff_identity_initials(@current_identity)}
                </div>
                <div class="min-w-0">
                  <p class="truncate text-sm font-semibold text-white">
                    {staff_identity_label(@current_identity)}
                  </p>
                  <p class="truncate text-xs text-white/50">Signed in</p>
                </div>
              </div>
              <.form for={%{}} action={~p"/auth"} method="delete" id="admin-sign-out-form">
                <.button id="admin-sign-out-button" type="submit" variant="ghost">
                  Sign out
                </.button>
              </.form>
            </div>
          </div>
        </div>
      </aside>

      <div id="admin-content" class="min-w-0 flex-1">
        {render_slot(@inner_block)}
      </div>
    </div>

    <.flash_group flash={@flash} />
    """
  end

  defp staff_identity_label(%{email: email}) when is_binary(email), do: email
  defp staff_identity_label(_identity), do: "Memba staff"

  defp staff_identity_initials(%{email: email}) when is_binary(email) do
    email
    |> String.split("@", parts: 2)
    |> List.first()
    |> String.split(~r/[^a-zA-Z0-9]+/, trim: true)
    |> Enum.take(2)
    |> Enum.map(&String.first/1)
    |> Enum.join()
    |> String.upcase()
    |> case do
      "" -> "MS"
      initials -> initials
    end
  end

  defp staff_identity_initials(_identity), do: "MS"

  defp admin_nav_class(true) do
    "flex items-center justify-between rounded-lg bg-[#1f574e] px-3 py-2.5 text-sm font-semibold text-white shadow-sm transition duration-200"
  end

  defp admin_nav_class(false) do
    "flex items-center justify-between rounded-lg px-3 py-2.5 text-sm font-medium text-white/75 transition duration-200 hover:bg-white/10 hover:text-white"
  end

  @doc """
  Renders the member/public club-site layout in the canonical Memba theme.
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :club_name, :string, default: "Club", doc: "the club name shown in the site chrome"

  attr :current_identity, :map,
    default: nil,
    doc: "the signed-in identity shown in club member chrome"

  attr :member_name, :string,
    default: nil,
    doc: "the optional signed-in member display name shown in club member chrome"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  slot :inner_block, required: true

  def club_site(assigns) do
    ~H"""
    <div
      id="club-site-layout"
      data-surface="club-site"
      class="app-frame"
    >
      <div id="club-site-global-bar" class="global-bar">
        <div class="global-bar__inner">
          <div class="global-bar__brand">
            <.sprig variant={:solid} class="global-bar__mark" />
            <span class="global-bar__word">Memba</span>
          </div>

          <details :if={@current_identity} class="dropdown dropdown-end global-bar__id">
            <summary
              id="club-site-identity-menu-button"
              class="global-bar__me"
              aria-controls="club-site-identity-menu"
              aria-label="Member identity menu"
            >
              <span class="global-bar__avatar">
                {club_identity_initials(@member_name, @current_identity)}
              </span>
            </summary>

            <div
              id="club-site-identity-menu"
              role="menu"
              class="dropdown-content app-menu app-menu--id"
            >
              <div class="app-menu__who">
                <div class="app-menu__who-name">
                  {club_identity_label(@member_name, @current_identity)}
                </div>
                <div class="app-menu__who-email">{club_identity_email(@current_identity)}</div>
              </div>
              <div class="app-menu__divider" role="separator" aria-orientation="horizontal" />
              <.link
                navigate={~p"/my/settings"}
                id="club-site-account-settings-link"
                role="menuitem"
                class="app-menu__item"
              >
                Account settings
              </.link>
              <div
                id="club-site-identity-menu-divider"
                class="app-menu__divider"
                role="separator"
                aria-orientation="horizontal"
              />
              <.form for={%{}} action={~p"/auth"} method="delete" id="club-site-sign-out-form">
                <.button
                  id="club-site-sign-out-button"
                  type="submit"
                  role="menuitem"
                  variant="ghost"
                >
                  Sign out
                </.button>
              </.form>
            </div>
          </details>
        </div>
      </div>

      <div class="app-card">
        <header>
          <div class="app-bar">
            <div class="app-bar__brand">
              <span class="app-bar__club">{@club_name}</span>
            </div>
          </div>
        </header>

        <main class="px-4 py-10 sm:px-6 lg:px-8">
          {render_slot(@inner_block)}
        </main>
      </div>

      <footer
        id="club-site-footer"
        class="app-foot"
      >
        Powered by
        <a
          id="club-site-footer-memba-home-link"
          href={ClubSite.root_url()}
          aria-label="Visit Memba home"
        >
          Memba
        </a>
      </footer>
    </div>

    <.flash_group flash={@flash} />
    """
  end

  defp club_identity_label(member_name, identity) when is_binary(member_name) do
    case String.trim(member_name) do
      "" -> club_identity_label(nil, identity)
      name -> name
    end
  end

  defp club_identity_label(_member_name, %{email: email}) when is_binary(email) do
    email_local_part(email)
  end

  defp club_identity_label(_member_name, _identity), do: "Member"

  defp club_identity_initials(member_name, identity) do
    member_name
    |> club_identity_label(identity)
    |> initials()
  end

  defp club_identity_email(%{email: email}) when is_binary(email), do: email
  defp club_identity_email(_identity), do: nil

  defp email_local_part(email) do
    email
    |> String.split("@", parts: 2)
    |> List.first()
    |> String.trim()
    |> case do
      "" -> "Member"
      local_part -> local_part
    end
  end

  defp initials(name) when is_binary(name) do
    name
    |> String.split(~r/[^\p{L}\p{N}]+/u, trim: true)
    |> Enum.take(2)
    |> Enum.map(&String.first/1)
    |> Enum.join()
    |> String.upcase()
    |> case do
      "" -> "M"
      initials -> initials
    end
  end

  defp initials(_name), do: "M"

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end
end
