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
    <header class="navbar border-b border-base-300 bg-base-100 px-4 sm:px-6 lg:px-8">
      <div class="flex-1">
        <a href="/" class="w-fit" aria-label="Memba home">
          <.logo />
        </a>
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
  Renders the staff admin layout.

  The admin surface keeps Memba branding visible while using a compact,
  utilitarian navigation bar for internal operations.
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  slot :inner_block, required: true

  def admin(assigns) do
    ~H"""
    <div id="admin-layout" data-surface="admin" class="min-h-screen bg-zinc-100 text-zinc-900">
      <header class="border-b border-zinc-200 bg-white px-4 shadow-sm sm:px-6 lg:px-8">
        <div class="mx-auto flex max-w-7xl flex-col gap-4 py-4 sm:flex-row sm:items-center sm:justify-between">
          <a href={~p"/admin/clubs"} class="inline-flex w-fit items-center gap-3" aria-label="Memba admin home">
            <.logo />
            <span class="rounded-full border border-zinc-200 bg-zinc-50 px-2.5 py-1 text-xs font-semibold uppercase tracking-[0.18em] text-zinc-600">
              Admin
            </span>
          </a>

          <nav class="flex flex-wrap gap-2 text-sm font-medium" aria-label="Staff admin navigation">
            <.link
              navigate={~p"/admin/clubs"}
              class="rounded-md px-3 py-2 text-zinc-700 transition hover:bg-zinc-100 hover:text-zinc-950"
            >
              Clubs
            </.link>
            <.link
              navigate={~p"/admin/deliveries"}
              class="rounded-md px-3 py-2 text-zinc-700 transition hover:bg-zinc-100 hover:text-zinc-950"
            >
              Deliveries
            </.link>
          </nav>
        </div>
      </header>

      {render_slot(@inner_block)}
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
  the staff admin surface.
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :club_name, :string, default: "Club", doc: "the club name shown in the site chrome"
  attr :theme, :map, default: %{}, doc: "optional CSS color values keyed by the club-site theme names"

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
        <div class="mx-auto flex max-w-7xl items-center justify-between py-4">
          <a href={~p"/"} class="text-lg font-semibold tracking-tight text-[var(--club-site-ink)]">
            {@club_name}
          </a>
          <span class="text-xs font-medium text-[var(--club-site-muted)]">
            Powered by <span class="font-semibold text-[var(--club-site-accent)]">Memba</span>
          </span>
        </div>
      </header>

      <main class="mx-auto max-w-7xl px-4 py-10 sm:px-6 lg:px-8">
        {render_slot(@inner_block)}
      </main>
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
