defmodule MembaWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use MembaWeb, :html

  alias MembaWeb.{ClubSite, IdentityAuth}

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
  Renders the shared hosting and source details with a surface-specific introduction.
  """
  attr :id, :string, required: true
  attr :variant, :string, default: "club", values: ~w(club public)
  slot :inner_block, required: true

  def footer_details(assigns) do
    ~H"""
    <div id={@id} class={["footer-details", @variant == "public" && "footer-details--public"]}>
      <ul role="list">
        <li>{render_slot(@inner_block)}</li>
        <li>
          <.icon name="brand-canadian-maple-leaf" class="size-[15px] shrink-0" aria-hidden="true" />
          <span>Proudly hosted in Canada.</span>
        </li>
        <li>
          <a id={"#{@id}-source-link"} href="https://github.com/mattwynne/memba">
            <.icon name="brand-github" class="size-[15px] shrink-0" aria-hidden="true" /> Open source
          </a>
        </li>
      </ul>
    </div>
    """
  end

  @doc """
  Renders the shared public/visitor header.

  Matches the marketing nav from the design system: the wordmark and link
  cluster sit together on the left, with the sign-in / request-access actions
  pushed to the right. Used by the public homepage and every public-chrome page
  so visitors never see the navigation change as they move between pages.
  """
  attr :return_to, :string, default: nil

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
            href={IdentityAuth.with_return_to(~p"/auth", @return_to)}
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
  attr :return_to, :string, default: nil

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <.site_header return_to={@return_to} />

    <main class="px-4 py-16 sm:px-6 lg:px-8">
      <div class="mx-auto max-w-2xl space-y-4">
        {render_slot(@inner_block)}
      </div>
    </main>

    <.flash_group flash={@flash} />
    """
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

  attr :wide, :boolean,
    default: false,
    doc: "expands the member card and removes main padding for split-screen app layouts"

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
        <div class={["global-bar__inner", @wide && "global-bar__inner--wide"]}>
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
              class="dropdown-content app-menu app-menu--id"
            >
              <div class="app-menu__who">
                <div class="app-menu__who-name">
                  {club_identity_label(@member_name, @current_identity)}
                </div>
                <div class="app-menu__who-email">{club_identity_email(@current_identity)}</div>
              </div>
              <div class="app-menu__divider" aria-hidden="true" />
              <.link
                navigate={~p"/my/settings"}
                id="club-site-account-settings-link"
                class="app-menu__item"
              >
                Account settings
              </.link>
              <div
                id="club-site-identity-menu-divider"
                class="app-menu__divider"
                aria-hidden="true"
              />
              <.form for={%{}} action={~p"/auth"} method="delete" id="club-site-sign-out-form">
                <.button
                  id="club-site-sign-out-button"
                  type="submit"
                  variant="ghost"
                  class="app-menu__signout"
                >
                  Sign out
                </.button>
              </.form>
            </div>
          </details>
        </div>
      </div>

      <div class={["app-card", @wide && "app-card--wide"]}>
        <header>
          <div class="app-bar">
            <div class="app-bar__brand">
              <span class="app-bar__club">{@club_name}</span>
            </div>
          </div>
        </header>

        <main class={(@wide && "app-main--flush") || "px-4 py-10 sm:px-6 lg:px-8"}>
          {render_slot(@inner_block)}
        </main>
      </div>

      <footer
        id="club-site-footer"
        class="app-foot"
      >
        <.footer_details id="club-site-footer-details">
          <span>
            Powered by <a
              id="club-site-footer-memba-home-link"
              href={ClubSite.root_url()}
              aria-label="Visit Memba home"
            >Memba</a>.
          </span>
        </.footer_details>
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

      <.connection_status
        id="client-error"
        message={gettext("Connection paused — reconnecting…")}
        phx-disconnected={
          show(".phx-client-error #client-error")
          |> JS.remove_attribute("hidden", to: ".phx-client-error #client-error")
        }
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      />

      <.connection_status
        id="server-error"
        message={gettext("Memba is temporarily unavailable — retrying…")}
        phx-disconnected={
          show(".phx-server-error #server-error")
          |> JS.remove_attribute("hidden", to: ".phx-server-error #server-error")
        }
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      />
    </div>
    """
  end

  attr :id, :string, required: true
  attr :message, :string, required: true
  attr :rest, :global

  defp connection_status(assigns) do
    ~H"""
    <div
      id={@id}
      class={[
        "connection-status inline-flex max-w-[calc(100vw-2rem)] items-center gap-2",
        "rounded-full border border-sage-300 bg-paper/95 py-2.5 pr-3.5 pl-3",
        "text-[13px] font-semibold leading-[1.2] text-ink-2",
        "shadow-lg shadow-ink/10 backdrop-blur-sm"
      ]}
      role="status"
      aria-live="polite"
      aria-atomic="true"
      {@rest}
    >
      <span
        class={[
          "connection-status__spinner size-3.5 shrink-0 rounded-full",
          "border-2 border-sage-100 border-t-sage-500"
        ]}
        aria-hidden="true"
      >
      </span>
      <span>{@message}</span>
    </div>
    """
  end
end
