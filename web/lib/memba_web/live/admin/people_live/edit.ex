defmodule MembaWeb.Admin.PeopleLive.Edit do
  use MembaWeb, :live_view

  alias Memba.Membership

  @impl Phoenix.LiveView
  def mount(%{"club_id" => club_id, "person_id" => person_id}, _session, socket) do
    club = Membership.get_club(club_id)
    person = Membership.get_person(person_id)
    email_addresses = Membership.list_person_email_addresses(person_id)

    {:ok,
     socket
     |> assign(:club_id, club_id)
     |> assign(:person_id, person_id)
     |> assign(:club, club)
     |> assign(:person, person)
     |> assign(:email_addresses, email_addresses)
     |> assign(:form, to_form(person_form_params(person), as: :person))}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.admin flash={@flash}>
      <main
        id="person-edit"
        data-club-id={@club_id}
        data-person-id={@person_id}
        class="mx-auto max-w-4xl space-y-8 p-6"
      >
        <.link
          id="back-to-club-link"
          navigate={~p"/admin/clubs/#{@club_id}"}
          aria-label="Back to club"
          class="text-sm font-medium text-blue-700 hover:text-blue-900"
        >
          ← Club
        </.link>

        <%= if @club && @person do %>
          <section class="space-y-2">
            <p class="text-sm font-semibold uppercase tracking-wide text-zinc-500">
              {@club.name}
            </p>
            <h1 class="text-3xl font-bold tracking-tight text-zinc-900">Edit {@person.name}</h1>
            <p class="text-zinc-600">
              Edit this person's name, primary email address, and alternate email addresses.
            </p>
          </section>

          <section class="rounded-xl border border-zinc-200 bg-white p-5 shadow-sm">
            <.form for={@form} id="person-form" aria-label="Edit person" class="space-y-5">
              <div>
                <h2 class="text-lg font-semibold text-zinc-900">Person details</h2>
                <p class="mt-1 text-sm text-zinc-600">
                  The dedicated edit form is ready for the multi-address fields in this iteration.
                </p>
              </div>

              <.input
                field={@form[:name]}
                id="person-name-input"
                label="Name"
                aria-label="Person name"
                required
              />

              <div id="person-email-addresses" aria-label="Email addresses" class="space-y-3">
                <h2 class="text-lg font-semibold text-zinc-900">Email addresses</h2>
                <p
                  :for={email_address <- @email_addresses}
                  data-testid="person-email-address"
                  data-primary={to_string(email_address.primary?)}
                  class="rounded-lg border border-zinc-200 bg-zinc-50 p-3 text-sm"
                >
                  <span class="font-medium text-zinc-900">{email_address.email}</span>
                  <span class="ml-2 text-zinc-500">
                    {if email_address.primary?, do: "Primary", else: "Alternate"}
                  </span>
                </p>
              </div>
            </.form>
          </section>
        <% else %>
          <section class="rounded-xl border border-zinc-200 bg-white p-5 shadow-sm">
            <h1 class="text-2xl font-bold text-zinc-900">Person not found</h1>
            <p class="mt-2 text-zinc-600">
              No projected club and person combination exists for this URL.
            </p>
          </section>
        <% end %>
      </main>
    </Layouts.admin>
    """
  end

  defp person_form_params(nil), do: %{"name" => ""}
  defp person_form_params(person), do: %{"name" => person.name}
end
