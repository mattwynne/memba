defmodule MembaWeb.PublicClubPageLive do
  use MembaWeb, :live_view

  alias Memba.Membership

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
        <section class="rounded-3xl border border-[var(--club-site-line)] bg-[var(--club-site-paper)] p-8 shadow-sm">
          <p class="text-sm font-semibold uppercase tracking-[0.18em] text-[var(--club-site-accent)]">
            Club member space
          </p>
          <div class="mt-3 grid gap-8 lg:grid-cols-[1fr_0.75fr] lg:items-center">
            <div>
              <h1 class="text-4xl font-semibold tracking-tight text-[var(--club-site-ink)] sm:text-5xl">
                Welcome to {@club.name}
              </h1>
              <p class="mt-5 max-w-2xl text-lg leading-8 text-[var(--club-site-muted)]">
                Members can sign in to see club updates, send messages, and keep track of who belongs.
              </p>
              <div class="mt-8 flex flex-col gap-3 sm:flex-row">
                <a
                  id="public-club-page-sign-in-link"
                  href={~p"/auth"}
                  class="inline-flex items-center justify-center rounded-full bg-[var(--club-site-accent)] px-6 py-3 text-sm font-semibold text-white shadow-sm transition duration-200 hover:-translate-y-0.5 hover:shadow-md"
                >
                  Sign in to continue
                </a>
                <a
                  href={~p"/"}
                  class="inline-flex items-center justify-center rounded-full border border-[var(--club-site-line)] bg-[var(--club-site-paper)] px-6 py-3 text-sm font-semibold text-[var(--club-site-ink)] transition duration-200 hover:-translate-y-0.5 hover:bg-white"
                >
                  Back to Memba
                </a>
              </div>
            </div>

            <div class="rounded-3xl border border-[var(--club-site-line)] bg-[var(--club-site-bg)] p-6">
              <h2 class="text-xl font-semibold text-[var(--club-site-ink)]">For members</h2>
              <ul class="mt-5 space-y-4 text-[var(--club-site-muted)]">
                <li class="flex gap-3">
                  <.icon
                    name="hero-envelope"
                    class="mt-0.5 h-5 w-5 shrink-0 text-[var(--club-site-accent)]"
                  />
                  <span>Read and send club messages from one shared place.</span>
                </li>
                <li class="flex gap-3">
                  <.icon
                    name="hero-users"
                    class="mt-0.5 h-5 w-5 shrink-0 text-[var(--club-site-accent)]"
                  />
                  <span>See the current active member list.</span>
                </li>
                <li class="flex gap-3">
                  <.icon
                    name="hero-lock-closed"
                    class="mt-0.5 h-5 w-5 shrink-0 text-[var(--club-site-accent)]"
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
