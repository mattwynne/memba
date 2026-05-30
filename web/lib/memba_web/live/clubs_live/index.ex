defmodule MembaWeb.ClubsLive.Index do
  use MembaWeb, :live_view

  alias Memba.Membership

  @empty_club %{"name" => ""}

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    clubs = Membership.list_clubs()

    {:ok,
     socket
     |> assign(:club_form, to_form(@empty_club, as: :club))
     |> stream(:clubs, clubs, dom_id: &"club-#{&1.club_id}")}
  end

  @impl Phoenix.LiveView
  def handle_event("create_club", %{"club" => club_params}, socket) do
    attrs =
      club_params
      |> Map.take(["name"])
      |> Map.put("club_id", Ecto.UUID.generate())

    case Membership.create_club(attrs, consistency: :strong) do
      :ok ->
        {:noreply,
         socket
         |> put_flash(:info, "Club created")
         |> assign(:club_form, to_form(@empty_club, as: :club))
         |> stream(:clubs, Membership.list_clubs(), reset: true, dom_id: &"club-#{&1.club_id}")}

      {:ok, _result} ->
        {:noreply,
         socket
         |> put_flash(:info, "Club created")
         |> assign(:club_form, to_form(@empty_club, as: :club))
         |> stream(:clubs, Membership.list_clubs(), reset: true, dom_id: &"club-#{&1.club_id}")}

      {:error, reason} ->
        {:noreply,
         socket
         |> put_flash(:error, "Could not create club: #{format_reason(reason)}")
         |> assign(:club_form, to_form(club_params, as: :club))}
    end
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <main id="clubs-index" class="mx-auto max-w-5xl space-y-8 p-6">
        <section class="space-y-2">
          <p class="text-sm font-semibold uppercase tracking-wide text-zinc-500">
            Browser acceptance harness
          </p>
          <h1 class="text-3xl font-bold tracking-tight text-zinc-900">Clubs</h1>
          <p class="text-zinc-600">
            Create a club, then open it to add people, members, and club messages.
          </p>
        </section>

        <section class="rounded-xl border border-zinc-200 bg-white p-5 shadow-sm">
          <h2 class="text-lg font-semibold text-zinc-900">Create a club</h2>

          <.form
            for={@club_form}
            id="new-club-form"
            aria-label="Create a club"
            class="mt-4 flex flex-col gap-4 sm:flex-row sm:items-end"
            phx-submit="create_club"
          >
            <div class="flex-1">
              <.input
                field={@club_form[:name]}
                id="club-name-input"
                label="Name"
                aria-label="Club name"
                required
              />
            </div>
            <.button id="create-club-button" type="submit" aria-label="Create club">
              Create club
            </.button>
          </.form>
        </section>

        <section class="rounded-xl border border-zinc-200 bg-white p-5 shadow-sm">
          <h2 class="text-lg font-semibold text-zinc-900">Existing clubs</h2>

          <div
            id="clubs"
            aria-label="Clubs"
            class="mt-4 divide-y divide-zinc-100"
            phx-update="stream"
          >
            <p id="clubs-empty" class="hidden py-4 text-sm text-zinc-500 only:block">
              No clubs yet.
            </p>
            <div
              :for={{dom_id, club} <- @streams.clubs}
              id={dom_id}
              data-testid="club-row"
              data-club-id={club.club_id}
              data-club-name={club.name}
              aria-label={"Club #{club.name}"}
              class="flex items-center justify-between gap-4 py-3"
            >
              <div>
                <.link
                  id={"club-link-#{club.club_id}"}
                  navigate={~p"/clubs/#{club.club_id}"}
                  data-testid="club-link"
                  aria-label={"Open club #{club.name}"}
                  class="font-medium text-blue-700 hover:text-blue-900"
                >
                  {club.name}
                </.link>
              </div>
              <span class="text-xs text-zinc-500">{club.club_id}</span>
            </div>
          </div>
        </section>
      </main>
    </Layouts.app>
    """
  end

  defp format_reason(reason), do: reason |> inspect() |> String.replace("_", " ")
end
