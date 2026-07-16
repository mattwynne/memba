defmodule MembaWeb.Admin.PeopleLive.Edit do
  use MembaWeb, :live_view

  alias Memba.Membership
  alias MembaWeb.Admin.PersonEmailAddressForm

  @impl Phoenix.LiveView
  def mount(%{"club_id" => club_id, "person_id" => person_id}, _session, socket) do
    club = Membership.get_club(club_id)
    person = Membership.get_person(person_id)
    email_addresses = Membership.list_person_email_addresses(person_id)
    person_params = PersonEmailAddressForm.params_for_person(person, email_addresses)

    {:ok,
     socket
     |> assign(:club_id, club_id)
     |> assign(:person_id, person_id)
     |> assign(:club, club)
     |> assign(:person, person)
     |> assign_form(person_params, empty_errors())}
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

  def handle_event("save_person", %{"person" => person_params}, socket) do
    with {:ok, attrs} <- PersonEmailAddressForm.validate(person_params),
         :ok <-
           Membership.replace_person_email_addresses(
             %{
               "person_id" => socket.assigns.person_id,
               "email_addresses" => attrs.email_addresses
             },
             consistency: :strong
           ) do
      {:noreply,
       socket
       |> put_flash(:info, "Person updated")
       |> push_navigate(to: ~p"/admin/clubs/#{socket.assigns.club_id}")}
    else
      {:ok, _result} ->
        {:noreply,
         socket
         |> put_flash(:info, "Person updated")
         |> push_navigate(to: ~p"/admin/clubs/#{socket.assigns.club_id}")}

      {:error, %{} = form_errors} ->
        {:noreply, assign_form(socket, person_params, form_errors)}

      {:error, reason} ->
        {:error, form_errors} = PersonEmailAddressForm.with_server_error(person_params, reason)

        {:noreply,
         socket
         |> put_flash(
           :error,
           "Could not update person: #{PersonEmailAddressForm.format_reason(reason)}"
         )
         |> assign_form(person_params, form_errors)}
    end
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.admin flash={@flash} current_identity={@current_identity} active={:people}>
      <main
        id="person-edit"
        data-admin-page="person-edit"
        data-club-id={@club_id}
        data-person-id={@person_id}
        class="mx-auto max-w-7xl space-y-6 p-6"
      >
        <%= if @club && @person do %>
          <section
            id="person-page-header"
            class="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between"
          >
            <div class="space-y-2">
              <.link
                id="back-to-club-link"
                navigate={~p"/admin/clubs/#{@club_id}"}
                aria-label="Back to club"
                class="text-sm font-semibold text-[#1f4842] transition duration-200 hover:text-[#15201c]"
              >
                ← Club
              </.link>
              <p class="text-sm font-semibold uppercase tracking-wide text-[#7d877f]">
                People operations
              </p>
              <h1 class="text-3xl font-bold tracking-tight text-[#15201c]">
                Edit {@person.name}
              </h1>
              <p class="max-w-3xl text-[#4b5a55]">
                Review the person identity in this club context and maintain the primary and
                alternate email addresses attached to that person.
              </p>
            </div>

            <.link
              id="global-people-link"
              navigate={~p"/admin/people"}
              aria-label="Open global People"
              class="inline-flex items-center justify-center rounded-full border border-[#d6d2c8] bg-white px-4 py-2 text-sm font-semibold text-[#4b5a55] shadow-sm transition duration-200 hover:-translate-y-0.5 hover:border-[#1f4842] hover:text-[#15201c] hover:shadow-md"
            >
              Global People
            </.link>
          </section>

          <section
            id="person-workflow-summary"
            aria-label="Person workflow summary"
            class="grid gap-4 md:grid-cols-3"
          >
            <article
              id="person-club-context-card"
              class="rounded-2xl border border-[#e6e3dc] bg-white p-5 shadow-sm"
            >
              <p class="text-xs font-semibold uppercase tracking-wide text-[#7d877f]">
                Club context
              </p>
              <p class="mt-3 text-xl font-bold tracking-tight text-[#15201c]">{@club.name}</p>
              <p class="mt-2 text-sm text-[#4b5a55]">
                Return here after saving to manage memberships for this club.
              </p>
            </article>

            <article class="rounded-2xl border border-[#e6e3dc] bg-white p-5 shadow-sm">
              <p class="text-xs font-semibold uppercase tracking-wide text-[#7d877f]">
                Person record
              </p>
              <p class="mt-3 text-lg font-semibold text-[#15201c]">{@person.name}</p>
              <p class="mt-2 break-all font-mono text-xs text-[#7d877f]">{@person_id}</p>
            </article>

            <article class="rounded-2xl border border-[#e6e3dc] bg-white p-5 shadow-sm">
              <p class="text-xs font-semibold uppercase tracking-wide text-[#7d877f]">
                Email addresses
              </p>
              <p class="mt-3 text-lg font-semibold text-[#15201c]">Primary plus alternates</p>
              <p class="mt-2 text-sm text-[#4b5a55]">
                Keep identity aliases together while choosing one primary delivery address.
              </p>
            </article>
          </section>

          <div class="grid gap-6 xl:grid-cols-[minmax(0,1fr)_minmax(18rem,0.4fr)]">
            <section
              id="person-form-card"
              class="overflow-hidden rounded-2xl border border-[#e6e3dc] bg-white shadow-sm"
            >
              <div class="border-b border-[#e6e3dc] p-5">
                <p class="text-xs font-semibold uppercase tracking-wide text-[#7d877f]">
                  Person record
                </p>
                <h2 class="mt-1 text-lg font-semibold text-[#15201c]">Edit email details</h2>
                <p class="mt-1 text-sm text-[#7d877f]">
                  The person name is shown for context; this workflow preserves the existing
                  email-address editing behaviour.
                </p>
              </div>

              <.form
                for={@form}
                id="person-form"
                aria-label="Edit person"
                class="space-y-5 p-5"
                phx-change="validate_person"
                phx-submit="save_person"
              >
                <div id="person-form-section" class="space-y-1">
                  <h3 class="text-base font-semibold text-[#15201c]">Identity</h3>
                  <p class="text-sm text-[#7d877f]">
                    The name is read-only in this route; global person rename semantics are outside
                    this slice.
                  </p>
                </div>

                <div class="rounded-2xl border border-[#e6e3dc] bg-[#f7f6f3] p-4">
                  <.input
                    name={@form[:name].name}
                    value={@form[:name].value}
                    id="person-name-input"
                    label="Name"
                    aria-label="Person name"
                    errors={@form_errors.name}
                    required
                    readonly
                  />
                </div>

                <div
                  id="person-email-addresses"
                  aria-label="Email addresses"
                  class="space-y-4 rounded-2xl border border-[#e6e3dc] bg-[#f7f6f3] p-4"
                >
                  <div>
                    <h3 class="text-sm font-semibold text-[#15201c]">Email addresses</h3>
                    <p class="mt-1 text-sm text-[#7d877f]">
                      Alternate addresses can identify this person; only the primary address
                      receives club messages.
                    </p>
                  </div>

                  <p
                    :if={@form_errors.global}
                    id="person-email-addresses-error"
                    role="alert"
                    class="rounded-xl border border-red-200 bg-red-50 px-3 py-2 text-sm font-medium text-red-700"
                  >
                    {@form_errors.global}
                  </p>

                  <input type="hidden" name="person[primary_email_index]" value="" />

                  <div
                    :for={row <- @email_rows}
                    id={"person-email-row-#{row.index}"}
                    data-testid="person-email-row"
                    data-primary={to_string(row.primary?)}
                    class="grid gap-3 rounded-xl border border-[#e6e3dc] bg-white p-3 shadow-sm sm:grid-cols-[auto_1fr_auto] sm:items-start"
                  >
                    <label
                      for={"person-primary-radio-#{row.index}"}
                      class="mt-8 flex items-center gap-2 text-sm font-semibold text-[#4b5a55]"
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

                    <div :if={length(@email_rows) > 1} class="mt-7">
                      <.button
                        id={"remove-person-email-address-#{row.index}"}
                        type="button"
                        phx-click="remove_email_address"
                        phx-value-index={row.index}
                        aria-label={"Remove email address #{row.index}"}
                        variant="danger"
                      >
                        Remove
                      </.button>
                    </div>
                  </div>

                  <.button
                    id="add-person-email-address"
                    type="button"
                    phx-click="add_email_address"
                    aria-label="Add email address"
                    variant="secondary"
                  >
                    Add email address
                  </.button>
                </div>

                <div class="flex flex-col gap-3 border-t border-[#e6e3dc] pt-5 sm:flex-row sm:items-center">
                  <.button
                    id="save-person-button"
                    type="submit"
                    aria-label="Save person"
                  >
                    Save person
                  </.button>
                  <.button
                    id="cancel-person-link"
                    navigate={~p"/admin/clubs/#{@club_id}"}
                    variant="secondary"
                  >
                    Cancel
                  </.button>
                </div>
              </.form>
            </section>

            <aside
              id="person-workflow-help-card"
              class="rounded-2xl border border-[#e6e3dc] bg-white p-5 shadow-sm"
            >
              <p class="text-xs font-semibold uppercase tracking-wide text-[#7d877f]">
                Workflow note
              </p>
              <h2 class="mt-1 text-lg font-semibold text-[#15201c]">
                Edit contact details only
              </h2>
              <p class="mt-2 text-sm text-[#4b5a55]">
                This page preserves the existing club-scoped edit flow. Manage active memberships
                on the club detail page and review global person summaries from People.
              </p>
            </aside>
          </div>
        <% else %>
          <section class="space-y-4">
            <.link
              id="back-to-club-link"
              navigate={~p"/admin/clubs/#{@club_id}"}
              aria-label="Back to club"
              class="text-sm font-semibold text-[#1f4842] transition duration-200 hover:text-[#15201c]"
            >
              ← Club
            </.link>
            <div class="rounded-2xl border border-[#e6e3dc] bg-white p-5 shadow-sm">
              <h1 class="text-2xl font-bold text-[#15201c]">Person not found</h1>
              <p class="mt-2 text-[#4b5a55]">
                No projected club and person combination exists for this URL.
              </p>
            </div>
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
