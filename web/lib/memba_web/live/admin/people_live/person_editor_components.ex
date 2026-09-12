defmodule MembaWeb.Admin.PeopleLive.PersonEditorComponents do
  @moduledoc false

  use Phoenix.Component

  import MembaWeb.CoreComponents

  attr :mode, :atom, required: true, values: [:new, :edit]
  attr :form, Phoenix.HTML.Form, required: true
  attr :form_errors, :map, required: true
  attr :email_rows, :list, required: true
  attr :validate_event, :string, required: true
  attr :submit_event, :string, required: true
  attr :add_email_event, :string, required: true
  attr :remove_email_event, :string, required: true
  attr :cancel_to, :string, required: true, doc: "navigation target for the cancel link"

  def person_email_address_editor(assigns) do
    assigns = assign(assigns, editor_copy(assigns.mode))

    ~H"""
    <section
      id="person-form-card"
      class="overflow-hidden rounded-2xl border border-[#e6e3dc] bg-white shadow-sm"
    >
      <div class="border-b border-[#e6e3dc] p-5">
        <p class="text-xs font-semibold uppercase tracking-wide text-[#7d877f]">
          Person record
        </p>
        <h2 class="mt-1 text-lg font-semibold text-[#15201c]">{@card_title}</h2>
        <p class="mt-1 text-sm text-[#7d877f]">
          {@card_description}
        </p>
      </div>

      <.form
        for={@form}
        id="person-form"
        aria-label={@form_aria_label}
        class="space-y-5 p-5"
        phx-change={@validate_event}
        phx-submit={@submit_event}
      >
        <div id="person-form-section" class="space-y-1">
          <h3 class="text-base font-semibold text-[#15201c]">Identity</h3>
          <p class="text-sm text-[#7d877f]">
            {@identity_description}
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
            readonly={@name_readonly}
          />
        </div>

        <div
          id="person-email-addresses"
          aria-label="Email addresses"
          class="space-y-4 rounded-2xl border border-[#e6e3dc] bg-[#f7f6f3] p-4"
        >
          <div>
            <h3 class="text-sm font-semibold text-[#15201c]">{@email_title}</h3>
            <p class="mt-1 text-sm text-[#7d877f]">
              {@email_description}
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
                phx-click={@remove_email_event}
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
            phx-click={@add_email_event}
            aria-label="Add email address"
            variant="secondary"
          >
            Add email address
          </.button>
        </div>

        <div class="flex flex-col gap-3 border-t border-[#e6e3dc] pt-5 sm:flex-row sm:items-center">
          <.button id={@submit_button_id} type="submit" aria-label={@submit_aria_label}>
            {@submit_label}
          </.button>
          <.button id="cancel-person-link" navigate={@cancel_to} variant="secondary">
            Cancel
          </.button>
        </div>
      </.form>
    </section>
    """
  end

  defp editor_copy(:new) do
    %{
      card_title: "Create person details",
      card_description:
        "Capture the name and email addresses without creating a membership automatically.",
      form_aria_label: "Create person",
      identity_description:
        "Names belong to person records; club participation is handled as a separate membership.",
      name_readonly: false,
      email_title: "Primary and alternate email addresses",
      email_description:
        "The first entered email address is selected as primary by default. Choose exactly one primary address. Alternate addresses can still identify this person.",
      submit_button_id: "create-person-button",
      submit_aria_label: "Create person",
      submit_label: "Create person"
    }
  end

  defp editor_copy(:edit) do
    %{
      card_title: "Edit email details",
      card_description:
        "The person name is shown for context; this workflow preserves the existing email-address editing behaviour.",
      form_aria_label: "Edit person",
      identity_description:
        "The name is read-only in this route; global person rename semantics are outside this slice.",
      name_readonly: true,
      email_title: "Email addresses",
      email_description:
        "Alternate addresses can identify this person; only the primary address receives club messages.",
      submit_button_id: "save-person-button",
      submit_aria_label: "Save person",
      submit_label: "Save person"
    }
  end
end
