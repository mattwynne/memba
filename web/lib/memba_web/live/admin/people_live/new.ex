defmodule MembaWeb.Admin.PeopleLive.New do
  use MembaWeb, :live_view

  alias Memba.Membership
  alias MembaWeb.Admin.PersonEmailAddressForm

  @impl Phoenix.LiveView
  def mount(%{"club_id" => club_id}, _session, socket) do
    club = Membership.get_club(club_id)

    {:ok,
     socket
     |> assign(:club_id, club_id)
     |> assign(:club, club)
     |> assign_form(PersonEmailAddressForm.empty_params(), empty_errors())}
  end

  @impl Phoenix.LiveView
  def handle_event("validate_person", %{"person" => person_params}, socket) do
    {:noreply, assign_form(socket, person_params, validation_errors(person_params))}
  end

  def handle_event("add_email_address", _params, socket) do
    {:noreply, assign_form(socket, PersonEmailAddressForm.add_row(socket.assigns.person_params))}
  end

  def handle_event("remove_email_address", %{"index" => index}, socket) do
    {:noreply,
     assign_form(socket, PersonEmailAddressForm.remove_row(socket.assigns.person_params, index))}
  end

  def handle_event("create_person", %{"person" => person_params}, socket) do
    with {:ok, attrs} <- PersonEmailAddressForm.validate(person_params),
         :ok <-
           Membership.create_person(
             %{
               "person_id" => Memba.ID.generate(:person),
               "name" => attrs.name,
               "email_addresses" => attrs.email_addresses
             },
             consistency: :strong
           ) do
      {:noreply,
       socket
       |> put_flash(:info, "Person created")
       |> push_navigate(to: ~p"/admin/clubs/#{socket.assigns.club_id}")}
    else
      {:ok, _result} ->
        {:noreply,
         socket
         |> put_flash(:info, "Person created")
         |> push_navigate(to: ~p"/admin/clubs/#{socket.assigns.club_id}")}

      {:error, %{} = form_errors} ->
        {:noreply, assign_form(socket, person_params, form_errors)}

      {:error, reason} ->
        {:error, form_errors} = PersonEmailAddressForm.with_server_error(person_params, reason)

        {:noreply,
         socket
         |> put_flash(
           :error,
           "Could not create person: #{PersonEmailAddressForm.format_reason(reason)}"
         )
         |> assign_form(person_params, form_errors)}
    end
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
            <.form
              for={@form}
              id="person-form"
              aria-label="Create person"
              class="space-y-5"
              phx-change="validate_person"
              phx-submit="create_person"
            >
              <div>
                <h2 class="text-lg font-semibold text-zinc-900">Person details</h2>
                <p class="mt-1 text-sm text-zinc-600">
                  The first entered email address is selected as primary by default.
                </p>
              </div>

              <.input
                name={@form[:name].name}
                value={@form[:name].value}
                id="person-name-input"
                label="Name"
                aria-label="Person name"
                errors={@form_errors.name}
                required
              />

              <div
                id="person-email-addresses"
                aria-label="Email addresses"
                class="space-y-3 rounded-lg border border-zinc-200 bg-zinc-50 p-4"
              >
                <div>
                  <p class="text-sm font-medium text-zinc-700">
                    Primary and alternate email addresses
                  </p>
                  <p class="mt-1 text-sm text-zinc-500">
                    Choose exactly one primary address. Alternate addresses can still identify this person.
                  </p>
                </div>

                <p
                  :if={@form_errors.global}
                  id="person-email-addresses-error"
                  role="alert"
                  class="text-sm font-medium text-red-700"
                >
                  {@form_errors.global}
                </p>

                <input type="hidden" name="person[primary_email_index]" value="" />

                <div
                  :for={row <- @email_rows}
                  id={"person-email-row-#{row.index}"}
                  data-testid="person-email-row"
                  data-primary={to_string(row.primary?)}
                  class="grid gap-3 rounded-lg border border-zinc-200 bg-white p-3 sm:grid-cols-[auto_1fr_auto] sm:items-start"
                >
                  <label
                    for={"person-primary-radio-#{row.index}"}
                    class="mt-8 flex items-center gap-2 text-sm font-medium text-zinc-700"
                  >
                    <input
                      id={"person-primary-radio-#{row.index}"}
                      type="radio"
                      name="person[primary_email_index]"
                      value={row.index}
                      checked={row.primary?}
                      class="radio radio-sm"
                    /> Primary
                  </label>

                  <.input
                    id={"person-email-input-#{row.index}"}
                    name={"person[email_addresses][#{row.index}][email]"}
                    type="email"
                    label="Email address"
                    aria-label={"Email address #{row.index}"}
                    value={row.email}
                    errors={Map.get(@form_errors.row_errors, row.index, [])}
                    required
                  />

                  <button
                    :if={length(@email_rows) > 1}
                    id={"remove-person-email-address-#{row.index}"}
                    type="button"
                    phx-click="remove_email_address"
                    phx-value-index={row.index}
                    aria-label={"Remove email address #{row.index}"}
                    class="mt-7 rounded-full border border-zinc-300 px-3 py-1.5 text-sm font-semibold text-zinc-700 hover:border-red-300 hover:text-red-700"
                  >
                    Remove
                  </button>
                </div>

                <button
                  id="add-person-email-address"
                  type="button"
                  phx-click="add_email_address"
                  aria-label="Add email address"
                  class="rounded-full border border-zinc-300 px-4 py-2 text-sm font-semibold text-zinc-700 hover:border-blue-300 hover:text-blue-700"
                >
                  Add email address
                </button>
              </div>

              <.button id="create-person-button" type="submit" aria-label="Create person">
                Create person
              </.button>
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

  defp assign_form(socket, person_params, form_errors \\ nil) do
    form_errors = form_errors || empty_errors()

    socket
    |> assign(:person_params, person_params)
    |> assign(:email_rows, PersonEmailAddressForm.rows(person_params))
    |> assign(:form_errors, form_errors)
    |> assign(:form, to_form(person_params, as: :person))
  end

  defp validation_errors(person_params) do
    case PersonEmailAddressForm.validate(person_params) do
      {:ok, _attrs} -> empty_errors()
      {:error, errors} -> errors
    end
  end

  defp empty_errors, do: %{name: [], row_errors: %{}, global: nil}
end
