defmodule MembaWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use MembaWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  defp git_commit_footer_link, do: Memba.BuildInfo.footer_commit()

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
    <header class="border-b border-line bg-paper px-4 sm:px-6 lg:px-8">
      <div class="mx-auto flex max-w-7xl flex-col gap-4 py-4 sm:flex-row sm:items-center sm:justify-between">
        <a
          href={~p"/"}
          class="w-fit transition duration-200 hover:opacity-80"
          aria-label="Memba home"
        >
          <.logo />
        </a>

        <nav
          class="flex flex-wrap items-center gap-3 text-sm font-medium"
          aria-label="Public navigation"
        >
          <a
            href={~p"/"}
            class="rounded-full px-3 py-2 text-ink-2 transition duration-200 hover:bg-cream hover:text-ink"
          >
            Home
          </a>
          <a
            href={~p"/about"}
            class="rounded-full px-3 py-2 text-ink-2 transition duration-200 hover:bg-cream hover:text-ink"
          >
            About
          </a>
          <a
            href={~p"/auth"}
            class="rounded-full border border-line-strong bg-paper px-4 py-2 text-ink transition duration-200 hover:-translate-y-0.5 hover:bg-white"
          >
            Sign in
          </a>
          <a
            href={~p"/get-started"}
            class="rounded-full border border-sage-600 bg-sage-600 px-4 py-2 font-semibold text-cream shadow-sm transition duration-200 hover:-translate-y-0.5 hover:bg-sage-700 hover:shadow-md"
          >
            Get started
          </a>
        </nav>
      </div>
    </header>

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
        class="border-b border-[#e6e3dc] bg-white/90 px-4 shadow-sm lg:sticky lg:top-0 lg:flex lg:h-screen lg:w-72 lg:flex-col lg:border-r lg:border-b-0 lg:px-5"
      >
        <div class="flex flex-col gap-5 py-5 lg:min-h-full">
          <a
            href={~p"/admin/clubs"}
            class="inline-flex w-fit items-center gap-3 transition duration-200 hover:opacity-80"
            aria-label="Memba staff home"
          >
            <.logo />
            <span class="flex flex-col leading-tight">
              <span class="text-xs font-semibold uppercase tracking-[0.22em] text-[#7d877f]">
                Staff
              </span>
              <span class="text-sm font-semibold text-[#1f4842]">Operations</span>
            </span>
          </a>

          <nav class="space-y-2" aria-label="Memba staff navigation">
            <p
              id="admin-navigation-group"
              class="text-xs font-semibold uppercase tracking-[0.2em] text-[#7d877f]"
            >
              Operations
            </p>
            <div class="grid gap-1 sm:grid-cols-2 lg:grid-cols-1">
              <.link
                navigate={~p"/admin/clubs"}
                id="admin-nav-clubs"
                data-admin-nav-item="clubs"
                class="group flex items-center justify-between rounded-xl border border-transparent px-3 py-2.5 text-sm font-semibold text-[#4b5a55] transition duration-200 hover:-translate-y-0.5 hover:border-[#d6d2c8] hover:bg-[#f7f6f3] hover:text-[#15201c]"
              >
                <span>Clubs</span>
                <span class="text-xs text-[#7d877f] transition group-hover:text-[#1f4842]">
                  Manage
                </span>
              </.link>
              <.link
                href="/admin/people"
                id="admin-nav-people"
                data-admin-nav-item="people"
                class="group flex items-center justify-between rounded-xl border border-transparent px-3 py-2.5 text-sm font-semibold text-[#4b5a55] transition duration-200 hover:-translate-y-0.5 hover:border-[#d6d2c8] hover:bg-[#f7f6f3] hover:text-[#15201c]"
              >
                <span>People</span>
                <span class="text-xs text-[#7d877f] transition group-hover:text-[#1f4842]">
                  Records
                </span>
              </.link>
              <.link
                href="/admin/messages"
                id="admin-nav-messages"
                data-admin-nav-item="messages"
                class="group flex items-center justify-between rounded-xl border border-transparent px-3 py-2.5 text-sm font-semibold text-[#4b5a55] transition duration-200 hover:-translate-y-0.5 hover:border-[#d6d2c8] hover:bg-[#f7f6f3] hover:text-[#15201c]"
              >
                <span>Messages</span>
                <span class="text-xs text-[#7d877f] transition group-hover:text-[#1f4842]">
                  Review
                </span>
              </.link>
              <.link
                navigate={~p"/admin/deliveries"}
                id="admin-nav-deliveries"
                data-admin-nav-item="deliveries"
                class="group flex items-center justify-between rounded-xl border border-transparent px-3 py-2.5 text-sm font-semibold text-[#4b5a55] transition duration-200 hover:-translate-y-0.5 hover:border-[#d6d2c8] hover:bg-[#f7f6f3] hover:text-[#15201c]"
              >
                <span>Deliveries</span>
                <span class="text-xs text-[#7d877f] transition group-hover:text-[#1f4842]">
                  Diagnose
                </span>
              </.link>
            </div>
          </nav>

          <div
            id="admin-staff-identity-block"
            class="mt-auto flex items-center justify-between gap-3 rounded-2xl border border-[#e6e3dc] bg-[#f7f6f3] p-3"
          >
            <div class="flex min-w-0 items-center gap-3">
              <div class="flex size-9 shrink-0 items-center justify-center rounded-full bg-[#1f4842] text-xs font-bold text-white">
                MS
              </div>
              <div class="min-w-0">
                <p class="truncate text-sm font-semibold text-[#15201c]">Memba staff</p>
                <p class="truncate text-xs text-[#7d877f]">Memba operations</p>
              </div>
            </div>
            <.form for={%{}} action={~p"/auth"} method="delete" id="admin-sign-out-form">
              <button
                id="admin-sign-out-button"
                type="submit"
                class="rounded-full border border-[#d6d2c8] bg-white px-3 py-1.5 text-xs font-semibold text-[#4b5a55] transition duration-200 hover:-translate-y-0.5 hover:border-[#1f4842] hover:text-[#15201c]"
              >
                Sign out
              </button>
            </.form>
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

  @club_site_theme_defaults %{
    background: "#f8fafc",
    paper: "#ffffff",
    ink: "#0f172a",
    muted: "#64748b",
    accent: "#334155",
    line: "#e2e8f0"
  }

  @doc """
  Renders the future club-site layout seam.

  This layout is intentionally not wired into production routes yet. It provides
  neutral slate defaults via CSS custom properties so a later white-label slice
  can pass resolved club theme values without extracting layout structure from
  the Memba staff surface.
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :club_name, :string, default: "Club", doc: "the club name shown in the site chrome"

  attr :current_identity, :map,
    default: nil,
    doc: "the signed-in identity shown in club member chrome"

  attr :theme, :map,
    default: %{},
    doc: "optional CSS color values keyed by the club-site theme names"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  slot :inner_block, required: true

  def club_site(assigns) do
    assigns = assign(assigns, :theme_style, club_site_theme_style(assigns.theme))

    ~H"""
    <div
      id="club-site-layout"
      data-surface="club-site"
      class="min-h-screen bg-[var(--club-site-bg)] text-[var(--club-site-ink)]"
      style={@theme_style}
    >
      <header class="border-b border-[var(--club-site-line)] bg-[var(--club-site-paper)] px-4 sm:px-6 lg:px-8">
        <div class="mx-auto flex max-w-7xl flex-col gap-4 py-4 sm:flex-row sm:items-center sm:justify-between">
          <a href={~p"/"} class="text-lg font-semibold tracking-tight text-[var(--club-site-ink)]">
            {@club_name}
          </a>

          <nav
            :if={@current_identity}
            class="flex flex-wrap items-center gap-3 text-sm font-medium"
            aria-label="Club member navigation"
          >
            <span id="club-site-current-identity" class="text-[var(--club-site-muted)]">
              Signed in as {@current_identity.email}
            </span>
            <.form for={%{}} action={~p"/auth"} method="delete" id="club-site-sign-out-form">
              <button
                id="club-site-sign-out-button"
                type="submit"
                class="rounded-full border border-[var(--club-site-line)] bg-[var(--club-site-paper)] px-4 py-2 text-sm font-semibold text-[var(--club-site-ink)] transition duration-200 hover:-translate-y-0.5 hover:bg-white"
              >
                Sign out
              </button>
            </.form>
          </nav>
        </div>
      </header>

      <main class="mx-auto max-w-7xl px-4 py-10 sm:px-6 lg:px-8">
        {render_slot(@inner_block)}
      </main>

      <footer
        id="club-site-footer"
        class="border-t border-[var(--club-site-line)] bg-[var(--club-site-paper)] px-4 py-6 sm:px-6 lg:px-8"
      >
        <div class="mx-auto max-w-7xl text-sm font-medium text-[var(--club-site-muted)]">
          Powered by <span class="font-semibold text-[var(--club-site-accent)]">Memba</span>
        </div>
      </footer>
    </div>

    <.flash_group flash={@flash} />
    """
  end

  defp club_site_theme_style(theme) do
    Enum.map_join(@club_site_theme_defaults, " ", fn {name, default_value} ->
      value = theme_value(theme, name, default_value)
      "--club-site-#{css_name(name)}: #{value};"
    end)
  end

  defp theme_value(theme, name, default_value) when is_map(theme) do
    Map.get(theme, name) || Map.get(theme, to_string(name)) || default_value
  end

  defp theme_value(_theme, _name, default_value), do: default_value

  defp css_name(:background), do: "bg"
  defp css_name(name), do: to_string(name)

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
