defmodule MembaWeb.PublicClubPageLive do
  use MembaWeb, :live_view

  alias Memba.Membership
  alias MembaWeb.ClubSite

  @impl Phoenix.LiveView
  def mount(_params, %{"club_id" => club_id}, socket) do
    case Membership.get_club(club_id) do
      nil ->
        {:ok, push_navigate(socket, to: ~p"/")}

      club ->
        {:ok, assign(socket, :club, club)}
    end
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.club_site flash={@flash} club_name={@club.name}>
      <div id="public-club-page-page" data-club-id={@club.club_id} class="space-y-8">
        <section class="rounded-3xl border border-base-300 bg-base-100 p-8 shadow-sm">
          <p class="text-sm font-semibold uppercase tracking-[0.18em] text-primary">
            Member space
          </p>
          <div class="mt-3 grid gap-8 lg:grid-cols-[1fr_0.75fr] lg:items-center">
            <div>
              <h1 class="text-4xl font-semibold tracking-tight text-base-content sm:text-5xl">
                Welcome to {@club.name}
              </h1>
              <p class="mt-5 max-w-2xl text-lg leading-8 text-ink-2">
                Sign in with the email address {@club.name} has for you to read member messages and see the current member list. Member-only details stay private.
              </p>
              <div class="mt-8 flex flex-col gap-3 sm:flex-row">
                <.button
                  id="public-club-page-sign-in-link"
                  href={~p"/auth"}
                  variant="primary"
                >
                  Email me a sign-in link
                </.button>
                <.button
                  id="public-club-page-memba-home-link"
                  href={ClubSite.root_url()}
                  aria-label="Visit Memba home"
                  variant="secondary"
                >
                  Visit Memba home
                </.button>
              </div>
            </div>

            <div class="rounded-3xl border border-base-300 bg-base-200 p-6">
              <h2 class="text-xl font-semibold text-base-content">For members</h2>
              <ul class="mt-5 space-y-4 text-ink-2">
                <li class="flex gap-3">
                  <.icon
                    name="hero-envelope"
                    class="mt-0.5 h-5 w-5 shrink-0 text-primary"
                  />
                  <span>Read messages from your group in one shared place.</span>
                </li>
                <li class="flex gap-3">
                  <.icon
                    name="hero-users"
                    class="mt-0.5 h-5 w-5 shrink-0 text-primary"
                  />
                  <span>See the current member list.</span>
                </li>
                <li class="flex gap-3">
                  <.icon
                    name="hero-lock-closed"
                    class="mt-0.5 h-5 w-5 shrink-0 text-primary"
                  />
                  <span>Member-only details stay behind sign-in.</span>
                </li>
              </ul>
            </div>
          </div>
        </section>
      </div>
    </Layouts.club_site>
    """
  end
end
