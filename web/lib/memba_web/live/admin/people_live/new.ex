defmodule MembaWeb.Admin.PeopleLive.New do
  use MembaWeb, :live_view

  alias Memba.Membership

  @person_form %{"name" => ""}

  @impl Phoenix.LiveView
  def mount(%{"club_id" => club_id}, _session, socket) do
    club = Membership.get_club(club_id)

    {:ok,
     socket
     |> assign(:club_id, club_id)
     |> assign(:club, club)
     |> assign(:form, to_form(@person_form, as: :person))}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.admin flash={@flash}>
      <main id="person-new" data-club-id={@club_id} class="mx-auto max-w-4xl space-y-8 p-6">
        <.link
          id="back-to-club-link"
          navigate={~p"/admin/clubs/#{@club_id}"}
          aria-label="Back to club"
          class="text-sm font-medium text-blue-700 hover:text-blue-900"
        >
          ← Club
        </.link>

        <%= if @club do %>
          <section class="space-y-2">
            <p class="text-sm font-semibold uppercase tracking-wide text-zinc-500">
              {@club.name}
            </p>
            <h1 class="text-3xl font-bold tracking-tight text-zinc-900">New person</h1>
            <p class="text-zinc-600">
              Create a person for this club context and manage their primary and alternate email addresses.
            </p>
          </section>

          <section class="rounded-xl border border-zinc-200 bg-white p-5 shadow-sm">
            <.form for={@form} id="person-form" aria-label="Create person" class="space-y-5">
              <div>
                <h2 class="text-lg font-semibold text-zinc-900">Person details</h2>
                <p class="mt-1 text-sm text-zinc-600">
                  The dedicated create form is ready for the multi-address fields in this iteration.
                </p>
              </div>

              <.input
                field={@form[:name]}
                id="person-name-input"
                label="Name"
                aria-label="Person name"
                required
              />

              <div
                id="person-email-addresses"
                aria-label="Email addresses"
                class="rounded-lg border border-dashed border-zinc-300 bg-zinc-50 p-4"
              >
                <p class="text-sm font-medium text-zinc-700">Primary and alternate email addresses</p>
                <p class="mt-1 text-sm text-zinc-500">
                  Email address rows and primary selection are added by the staff form task.
                </p>
              </div>
            </.form>
          </section>
        <% else %>
          <section class="rounded-xl border border-zinc-200 bg-white p-5 shadow-sm">
            <h1 class="text-2xl font-bold text-zinc-900">Club not found</h1>
            <p class="mt-2 text-zinc-600">No projected club exists for this URL.</p>
          </section>
        <% end %>
      </main>
    </Layouts.admin>
    """
  end
end
