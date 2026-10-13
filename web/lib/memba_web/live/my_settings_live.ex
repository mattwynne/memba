defmodule MembaWeb.MySettingsLive do
  @moduledoc """
  Global personal settings surface for signed-in club members.

  The page is mounted from the authenticated club-member LiveView session so it
  can reuse the club-site shell while keeping the selected settings tab in the
  URL via LiveView patches.
  """
  use MembaWeb, :live_view

  alias LiveQuery.Binding
  alias Memba.Membership.PersonEmailVerification
  alias Memba.Membership.CommandDispatch
  alias Memba.Membership.PersonEmailAddressCommands
  alias Memba.Membership.PersonEmailAddressVerificationEmail
  alias MembaWeb.PersonEmailAddressTransition
  alias MembaWeb.LiveQuery.MembaReadModelSource
  alias MembaWeb.MemberSettingsQuery

  @settings_query_id :member_settings

  @impl Phoenix.LiveView
  def mount(_params, %{"club_id" => club_id}, socket) when is_binary(club_id) do
    socket =
      assign(socket,
        page_title: "Account settings",
        add_email_form: to_form(%{"email" => ""}, as: :email_address),
        add_email_error: nil,
        active_tab: :profile,
        name_form: nil
      )

    case Binding.bind(
           socket,
           MemberSettingsQuery.query(),
           settings_inputs(club_id, socket),
           MembaReadModelSource.new()
         ) do
      {:ok, socket} ->
        {:ok, socket}

      {:error, errors, socket} ->
        settings_binding_error!(errors, socket)
    end
  end

  def mount(_params, _session, _socket), do: forbidden!()

  @impl Phoenix.LiveView
  def handle_params(_params, _uri, socket) do
    {:noreply, assign(socket, :active_tab, active_tab(socket.assigns.live_action))}
  end

  @impl Phoenix.LiveView
  def handle_info({:read_model_changed, _change} = notification, socket) do
    previous_name = current_person(socket).name

    case Binding.handle_notification(socket, notification) do
      {:ignored, socket} ->
        {:noreply, socket}

      {:ok, socket} ->
        socket =
          if socket.assigns.name_form do
            state =
              Map.get(socket.assigns, :name_state) ||
                MembaWeb.FormConflict.new(%{"name" => previous_name})

            normalize = fn name ->
              name |> String.split(~r/[\s\p{Z}]+/u, trim: true) |> Enum.join(" ")
            end

            state =
              MembaWeb.FormConflict.observe(
                state,
                %{"name" => current_person(socket).name},
                normalize
              )

            assign(socket,
              name_state: state,
              name_form: to_form(state.draft, as: :person),
              # Notifications cannot acknowledge a locally submitted draft.
              name_reconcile_from: nil
            )
          else
            socket
          end

        {:noreply, socket}

      {:error, errors, socket} ->
        settings_binding_error!(errors, socket)
    end
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  @impl Phoenix.LiveView
  def handle_event("edit_name", _params, socket) do
    socket = refresh_settings(socket)

    state = MembaWeb.FormConflict.new(%{"name" => current_person(socket).name})

    {:noreply,
     assign(socket,
       name_state: state,
       name_opened_name: state.baseline["name"],
       name_reconcile_from: nil,
       name_form: to_form(state.draft, as: :person),
       name_error: nil
     )}
  end

  def handle_event("change_name", %{"person" => %{"name" => name}} = params, socket) do
    state =
      Map.get(socket.assigns, :name_state) ||
        MembaWeb.FormConflict.new(%{"name" => socket.assigns.name_form.params["name"]})

    state =
      state
      |> browser_name_baseline(params, socket)
      |> MembaWeb.FormConflict.edit(%{"name" => name})

    normalize = fn value ->
      value |> String.split(~r/[\s\p{Z}]+/u, trim: true) |> Enum.join(" ")
    end

    previous_draft = state.draft["name"]
    state = MembaWeb.FormConflict.observe(state, state.latest, normalize)

    {:noreply,
     assign(socket,
       name_state: state,
       name_form: to_form(state.draft, as: :person),
       name_reconcile_from: if(state.draft["name"] != previous_draft, do: previous_draft),
       name_error: nil
     )}
  end

  def handle_event("save_name", %{"person" => %{"name" => name}} = params, socket) do
    state =
      Map.get(socket.assigns, :name_state) ||
        MembaWeb.FormConflict.new(socket.assigns.name_form.params)

    state =
      state
      |> browser_name_baseline(params, socket)
      |> MembaWeb.FormConflict.edit(%{"name" => name})

    socket = refresh_settings(socket)
    person = current_person(socket)

    result =
      with {:ok, command} <-
             Memba.Membership.PersonCommands.prepare_rename(
               %{person_id: person.person_id},
               %{person_id: person.person_id, name: name, expected_name: state.baseline["name"]}
             ) do
        CommandDispatch.dispatch(command, consistency: :strong)
      end

    case normalize_context_result(result) do
      :ok ->
        case Memba.ProjectionBarrier.await([Memba.Membership.Projectors.Person], timeout: 1_000) do
          {:ok, _checkpoint} ->
            {:noreply, socket |> refresh_settings() |> assign(name_form: nil, name_state: nil)}

          {:error, :timeout, _checkpoint} ->
            {:noreply,
             socket
             |> assign(name_state: state, name_form: to_form(state.draft, as: :person))
             |> put_flash(:error, "We could not load your latest name. Please try again.")}
        end

      {:error, {:name_conflict, latest}} ->
        state = MembaWeb.FormConflict.rejected(state, %{"name" => latest})

        {:noreply,
         socket
         |> assign(name_state: state, name_form: to_form(state.draft, as: :person))
         |> push_event("focus_form_conflict", %{id: "my-settings-name-conflict"})}

      {:error, reason} when reason in [:invalid_name, :name_too_long] ->
        {:noreply,
         assign(socket,
           name_state: state,
           name_form: to_form(state.draft, as: :person),
           name_error: MembaWeb.PersonNameTransition.error_message(reason)
         )}

      {:error, _reason} ->
        {:noreply,
         socket
         |> assign(name_state: state, name_form: to_form(state.draft, as: :person))
         |> put_flash(:error, "We could not update your name. Please try again.")}
    end
  end

  def handle_event("confirm_name", _params, socket) do
    socket = refresh_settings(socket)
    state = Map.get(socket.assigns, :name_state)
    person = current_person(socket)

    if state && state.confirmation do
      result =
        with {:ok, command} <-
               Memba.Membership.PersonCommands.prepare_rename(
                 %{person_id: person.person_id},
                 %{
                   person_id: person.person_id,
                   name: state.draft["name"],
                   expected_name: state.confirmation["name"]
                 }
               ) do
          CommandDispatch.dispatch(command, consistency: :strong)
        end

      case normalize_context_result(result) do
        :ok ->
          case Memba.ProjectionBarrier.await([Memba.Membership.Projectors.Person], timeout: 1_000) do
            {:ok, _checkpoint} ->
              {:noreply, socket |> refresh_settings() |> assign(name_form: nil, name_state: nil)}

            {:error, :timeout, _checkpoint} ->
              {:noreply,
               put_flash(socket, :error, "We could not load your latest name. Please try again.")}
          end

        {:error, {:name_conflict, latest}} ->
          {:noreply,
           assign(socket, :name_state, MembaWeb.FormConflict.rejected(state, %{"name" => latest}))}

        {:error, _reason} ->
          {:noreply,
           put_flash(socket, :error, "We could not update your name. Please try again.")}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("cancel_name", _params, socket) do
    socket = refresh_settings(socket)

    case Memba.ProjectionBarrier.await([Memba.Membership.Projectors.Person], timeout: 1_000) do
      {:ok, _checkpoint} ->
        {:noreply, socket |> refresh_settings() |> assign(name_form: nil, name_state: nil)}

      {:error, :timeout, _checkpoint} ->
        {:noreply,
         put_flash(socket, :error, "We could not load your latest name. Please try again.")}
    end
  end

  def handle_event(
        "add_email_address",
        %{"email_address" => %{"email" => email}},
        socket
      ) do
    attrs = %{person_id: current_person(socket).person_id, email: email}

    case add_pending_email_address_and_deliver_verification(socket, attrs) do
      :ok ->
        {:noreply,
         socket
         |> put_flash(:info, verification_email_sent_message())
         |> assign(:add_email_error, nil)
         |> assign(:add_email_form, to_form(%{"email" => ""}, as: :email_address))
         |> refresh_settings()}

      {:error, reason} ->
        {:noreply,
         socket
         |> put_flash(:error, add_email_error_message(reason))
         |> assign(:add_email_error, add_email_error_message(reason))
         |> assign(:add_email_form, to_form(%{"email" => email}, as: :email_address))}
    end
  end

  def handle_event("resend_verification", %{"email" => email}, socket) do
    case deliver_person_email_address_verification(socket, email) do
      :ok ->
        {:noreply, put_flash(socket, :info, verification_email_sent_message())}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, email_action_error_message(reason))}
    end
  end

  def handle_event("make_primary", %{"email" => email}, socket) do
    attrs = %{person_id: current_person(socket).person_id, email: email}

    result =
      with {:ok, command} <- PersonEmailAddressCommands.prepare_make_primary(attrs) do
        CommandDispatch.dispatch(command, consistency: :strong)
      end

    case result do
      :ok ->
        {:noreply, refresh_settings(socket)}

      {:ok, _result} ->
        {:noreply, refresh_settings(socket)}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, email_action_error_message(reason))}
    end
  end

  def handle_event("remove_email", %{"email" => email}, socket) do
    attrs = %{person_id: current_person(socket).person_id, email: email}

    result =
      attrs
      |> PersonEmailAddressCommands.prepare_remove()
      |> PersonEmailAddressTransition.dispatch_prepared(consistency: :strong)

    case result do
      :ok ->
        {:noreply, refresh_settings(socket)}

      {:ok, _result} ->
        {:noreply, refresh_settings(socket)}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, email_action_error_message(reason))}
    end
  end

  @impl Phoenix.LiveView
  def render(%{settings: settings} = assigns) do
    assigns = assign(assigns, settings)

    ~H"""
    <Layouts.club_site
      flash={@flash}
      club_name={@selected_club.name}
      current_identity={@current_identity}
      member_name={@current_person.name}
    >
      <main id="my-settings-main" class="px-6 py-7 sm:px-8 sm:py-10">
        <div
          id="my-settings"
          data-live-view="my-settings"
          data-active-tab={@active_tab}
          class="mx-auto grid max-w-[860px] gap-5"
        >
          <section class="grid gap-1">
            <.link
              id="my-settings-back-to-club"
              navigate={~p"/conversations"}
              class="inline-flex items-center gap-1 text-sm font-semibold text-ink-3 transition hover:text-sage-700"
            >
              ‹ Back to club
            </.link>
            <h1
              id="my-settings-title"
              class="text-[30px] font-bold leading-tight tracking-[-0.03em] text-ink"
            >
              Account settings
            </h1>
          </section>

          <div
            id="my-settings-layout"
            class="settings-layout flex flex-col gap-5 md:flex-row md:gap-7"
          >
            <nav
              id="my-settings-tabs-list"
              class="settings-tabs flex shrink-0 flex-row gap-1 overflow-x-auto md:w-44 md:flex-col md:overflow-visible"
              role="tablist"
              aria-orientation="vertical"
              aria-label="Account settings sections"
            >
              <.link
                id="my-settings-tab-profile"
                patch={settings_tab_path(:profile)}
                class={settings_tab_class(@active_tab, :profile)}
                data-tab="profile"
                role="tab"
                aria-selected={settings_tab_selected?(@active_tab, :profile)}
                aria-controls="my-settings-panel-profile"
              >
                Profile
              </.link>
              <.link
                id="my-settings-tab-clubs"
                patch={settings_tab_path(:clubs)}
                class={settings_tab_class(@active_tab, :clubs)}
                data-tab="clubs"
                role="tab"
                aria-selected={settings_tab_selected?(@active_tab, :clubs)}
                aria-controls="my-settings-panel-clubs"
              >
                Clubs
              </.link>
              <.link
                id="my-settings-tab-emails"
                patch={settings_tab_path(:emails)}
                class={settings_tab_class(@active_tab, :emails)}
                data-tab="emails"
                role="tab"
                aria-selected={settings_tab_selected?(@active_tab, :emails)}
                aria-controls="my-settings-panel-emails"
              >
                Emails
              </.link>
            </nav>

            <div id="my-settings-panels" class="min-w-0 flex-1">
              <section
                id="my-settings-panel-profile"
                role="tabpanel"
                aria-labelledby="my-settings-tab-profile"
                hidden={@active_tab != :profile}
                class="settings-panel"
              >
                <.settings_card id="my-settings-profile-card" title="Profile">
                  <div class="flex items-center gap-3">
                    <div
                      id="my-settings-profile-avatar"
                      class="grid size-10 shrink-0 place-items-center rounded-full bg-sage-400 text-sm font-bold text-white"
                    >
                      {person_initials(@current_person.name)}
                    </div>
                    <p id="my-settings-profile-name" class="text-xl font-bold text-ink">
                      {@current_person.name}
                    </p>
                    <.button
                      :if={!@name_form}
                      id="my-settings-edit-name"
                      type="button"
                      phx-click="edit_name"
                      variant="secondary"
                      size="sm"
                    >
                      Edit
                    </.button>
                  </div>
                  <.form
                    :if={@name_form}
                    for={@name_form}
                    id="my-settings-name-form"
                    phx-remove={JS.focus(to: "#my-settings-edit-name")}
                    phx-change="change_name"
                    phx-submit="save_name"
                    phx-hook=".ProfileNameBaseline"
                    data-latest-name={@name_state.latest["name"]}
                    data-reconcile-from={Map.get(assigns, :name_reconcile_from)}
                    data-confirming-name={not is_nil(@name_state.confirmation)}
                    data-latest-baseline={
                      name_baseline_token(@current_person.person_id, @name_state.latest["name"])
                    }
                    class="mt-4"
                  >
                    <span id="my-settings-name-baseline" hidden phx-update="ignore">
                      <input
                        id="my-settings-name-baseline-token"
                        type="hidden"
                        name="person[baseline_token]"
                        value={
                          name_baseline_token(@current_person.person_id, @name_state.baseline["name"])
                        }
                        data-name={@name_state.baseline["name"]}
                      />
                    </span>
                    <script :type={Phoenix.LiveView.ColocatedHook} name=".ProfileNameBaseline">
                      export default {
                        mounted() { this.reconcile() },
                        beforeUpdate() {
                          const input = this.el.querySelector("#my-settings-name-input")
                          const baseline = this.el.querySelector("[name='person[baseline_token]']")
                          this.localValue = input.value
                          this.localDirty = input.value !== baseline.dataset.name
                        },
                        updated() {
                          if (this.localDirty) {
                            this.el.querySelector("#my-settings-name-input").value = this.localValue
                          }
                          this.reconcile()
                        },
                        reconcile() {
                          const input = this.el.querySelector("#my-settings-name-input")
                          const baseline = this.el.querySelector("[name='person[baseline_token]']")
                          const from = this.el.dataset.reconcileFrom
                          const freshReconciliation = from !== this.reconciledFrom
                          this.reconciledFrom = from
                          // A rejected Save freezes the displayed/server draft
                          // until the member explicitly confirms or edits it.
                          if (this.el.dataset.confirmingName === "true") return
                          // A patch may precede a locally typed change event. Never
                          // advance that draft's baseline or overwrite its text.
                          // Consume normalized-undo acknowledgements only once.
                          if (input.value === baseline.dataset.name || (freshReconciliation && input.value === from)) {
                            input.value = this.el.dataset.latestName
                            baseline.dataset.name = this.el.dataset.latestName
                            baseline.value = this.el.dataset.latestBaseline
                          }
                        }
                      }
                    </script>
                    <.input
                      id="my-settings-name-input"
                      field={@name_form[:name]}
                      type="text"
                      label="Your name"
                      aria-invalid={Map.get(assigns, :name_error) && "true"}
                      aria-describedby={Map.get(assigns, :name_error) && "my-settings-name-error"}
                    />
                    <p
                      :if={Map.get(assigns, :name_error)}
                      id="my-settings-name-error"
                      class="mt-2 rounded-lg border border-error bg-error/10 p-3 text-sm font-semibold text-error"
                    >
                      {Map.get(assigns, :name_error)}
                    </p>
                    <.button id="my-settings-save-name" type="submit" size="sm">Save</.button>
                    <.button
                      id="my-settings-cancel-name"
                      type="button"
                      phx-click="cancel_name"
                      variant="ghost"
                      size="sm"
                    >
                      Cancel
                    </.button>
                    <MembaWeb.FormConflictComponents.warning
                      id="my-settings-name-conflict"
                      state={Map.get(assigns, :name_state)}
                    >
                      <:actions>
                        <.button
                          id="my-settings-name-save-anyway"
                          type="button"
                          phx-click="confirm_name"
                          size="sm"
                        >
                          Save anyway
                        </.button>
                        <.button
                          id="my-settings-name-cancel-changes"
                          type="button"
                          phx-click="cancel_name"
                          variant="secondary"
                          size="sm"
                        >
                          Cancel my changes
                        </.button>
                      </:actions>
                    </MembaWeb.FormConflictComponents.warning>
                  </.form>
                </.settings_card>
              </section>

              <section
                id="my-settings-panel-clubs"
                role="tabpanel"
                aria-labelledby="my-settings-tab-clubs"
                hidden={@active_tab != :clubs}
                class="settings-panel"
              >
                <.settings_card id="my-settings-clubs-card" title="Current clubs">
                  <div id="my-settings-club-chip-list" class="flex flex-wrap gap-2">
                    <span
                      :for={club <- @current_person_clubs}
                      id={"my-settings-club-chip-#{club.club_id}"}
                      class="inline-flex items-center gap-2 rounded-full border border-base-300 bg-base-200 py-1.5 pr-3 pl-1.5"
                    >
                      <span class="grid size-[22px] place-items-center rounded-full bg-sage-200 text-[10px] font-bold text-sage-800">
                        {club_initials(club.club_name)}
                      </span>
                      <span>
                        <span class="text-sm font-semibold text-ink">{club.club_name}</span>
                        <br />
                        <span class="text-xs text-ink-3">
                          Member since {format_month_year(club.member_since)}
                        </span>
                      </span>
                    </span>
                  </div>
                </.settings_card>
              </section>

              <section
                id="my-settings-panel-emails"
                role="tabpanel"
                aria-labelledby="my-settings-tab-emails"
                hidden={@active_tab != :emails}
                class="settings-panel"
              >
                <.settings_card
                  id="my-settings-email-addresses-card"
                  title="Email addresses"
                  description="Your primary address is the one we'll send emails to. We'll accept incoming emails from your other verified addresses."
                >
                  <div id="my-settings-email-list" class="email-list">
                    <.email_address_row
                      :for={email_address <- @current_person_email_addresses}
                      email_address={email_address}
                      dom_id={email_dom_id(email_address)}
                      state={email_state(email_address)}
                      verified?={verified_email_address?(email_address)}
                      actions={email_address_actions(email_address)}
                    />
                  </div>

                  <.form
                    for={@add_email_form}
                    id="my-settings-add-email-form"
                    class="mt-4 flex flex-wrap items-end gap-3"
                    phx-submit="add_email_address"
                  >
                    <div class="min-w-60 flex-1">
                      <.input
                        id="settings-add-email-input"
                        field={@add_email_form[:email]}
                        type="email"
                        label="Add an email address"
                        placeholder="dana@example.com"
                      />
                    </div>
                    <div class="mb-1">
                      <.button id="my-settings-add-email-button" type="submit" size="sm">
                        Add email address
                      </.button>
                    </div>
                  </.form>

                  <p
                    :if={@add_email_error}
                    id="my-settings-add-email-error"
                    class="mt-2 text-sm font-semibold text-error"
                  >
                    {@add_email_error}
                  </p>
                </.settings_card>
              </section>
            </div>
          </div>
        </div>
      </main>
    </Layouts.club_site>
    """
  end

  attr :id, :string, required: true
  attr :title, :string, required: true
  attr :description, :string, default: nil
  slot :inner_block, required: true

  defp settings_card(assigns) do
    ~H"""
    <div id={@id} class="settings-card">
      <div class="settings-card__head">
        <h2 class="settings-card__title">{@title}</h2>
        <p :if={@description} class="mt-1 text-sm leading-5 text-ink-3">
          {@description}
        </p>
      </div>
      <div class="settings-card__body">
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  attr :email_address, :any, required: true
  attr :dom_id, :string, required: true
  attr :state, :string, required: true, values: ~w(primary verified pending)
  attr :verified?, :boolean, required: true
  attr :actions, :list, required: true

  defp email_address_row(assigns) do
    ~H"""
    <div
      id={"my-settings-email-row-#{@dom_id}"}
      class="email-row"
      data-testid="person-email-row"
      data-state={@state}
    >
      <div class="email-row__top">
        <div class="email-row__address-line">
          <span class="email-row__address">
            {@email_address.email}
          </span>
          <span
            :if={@state == "primary"}
            class="my-settings-primary-badge badge badge-primary badge-soft"
          >
            Primary
          </span>
        </div>
        <.verified_badge :if={@verified?} />
        <.pending_badge :if={!@verified?} />
      </div>

      <div :if={@actions != []} class="email-row__actions-cell">
        <.button
          :if={:make_primary in @actions}
          id={"my-settings-make-primary-#{@dom_id}"}
          type="button"
          phx-click="make_primary"
          phx-value-email={@email_address.email}
          variant="secondary"
          size="sm"
        >
          Make primary
        </.button>
        <.button
          :if={:resend_verification in @actions}
          id={"my-settings-resend-verification-#{@dom_id}"}
          type="button"
          phx-click="resend_verification"
          phx-value-email={@email_address.email}
          variant="secondary"
          size="sm"
        >
          Resend verification
        </.button>
        <.button
          :if={:remove in @actions}
          id={"my-settings-remove-email-#{@dom_id}"}
          type="button"
          phx-click="remove_email"
          phx-value-email={@email_address.email}
          variant="ghost"
          size="sm"
        >
          Remove
        </.button>
      </div>
    </div>
    """
  end

  attr :rest, :global

  defp verified_badge(assigns) do
    ~H"""
    <span class="my-settings-verified-badge badge badge-success badge-soft gap-1.5" {@rest}>
      <.icon name="hero-check" class="size-3 shrink-0" />Verified
    </span>
    """
  end

  attr :rest, :global

  defp pending_badge(assigns) do
    ~H"""
    <span class="my-settings-pending-badge badge badge-warning badge-soft gap-1.5" {@rest}>
      <span class="dot size-1.5 rounded-full bg-current"></span>Pending verification
    </span>
    """
  end

  defp current_person(socket), do: socket.assigns.settings.current_person

  defp refresh_settings(socket) do
    case Binding.rebind(socket, @settings_query_id, settings_inputs(socket)) do
      {:ok, socket} -> socket
      {:error, errors, socket} -> settings_binding_error!(errors, socket)
    end
  end

  defp add_pending_email_address_and_deliver_verification(socket, attrs) do
    with {:ok, command} <- PersonEmailAddressCommands.prepare_add(attrs),
         :ok <- normalize_context_result(CommandDispatch.dispatch(command, consistency: :strong)),
         :ok <- deliver_person_email_address_verification(socket, attrs.email) do
      :ok
    end
  end

  defp deliver_person_email_address_verification(socket, email) do
    attrs = %{person_id: current_person(socket).person_id, email: email}

    with {:ok, %{issuer_result: %{token: token}}} <-
           PersonEmailVerification.resend(attrs, []),
         :ok <-
           PersonEmailAddressVerificationEmail.deliver(%{
             person_id: attrs.person_id,
             email: email,
             verification_url: url(~p"/my/settings/email-verifications/#{token}")
           }) do
      :ok
    end
  end

  defp normalize_context_result(:ok), do: :ok
  defp normalize_context_result({:ok, _result}), do: :ok
  defp normalize_context_result({:error, _reason} = error), do: error

  defp verification_email_sent_message,
    do:
      "You've been sent a verification email. Click the link in your email to verify this address"

  defp add_email_error_message(:email_address_taken),
    do: "That email address is already in use by another Memba user."

  defp add_email_error_message({:error, reason}), do: add_email_error_message(reason)

  defp add_email_error_message(_reason),
    do: "We could not add that email address. Please check it and try again."

  defp email_action_error_message({:error, reason}), do: email_action_error_message(reason)

  defp email_action_error_message(_reason),
    do: "We could not update that email address. Please try again."

  defp settings_inputs(club_id, socket) do
    %{
      club_id: club_id,
      authenticated_email: socket.assigns.current_identity_email
    }
  end

  defp settings_inputs(socket) do
    settings_inputs(socket.assigns.settings.selected_club.club_id, socket)
  end

  defp settings_binding_error!([{@settings_query_id, :forbidden} | _errors], _socket),
    do: forbidden!()

  defp settings_binding_error!(errors, _socket) do
    raise "member settings live query failed: #{inspect(errors)}"
  end

  defp active_tab(:clubs), do: :clubs
  defp active_tab(:emails), do: :emails
  defp active_tab(_live_action), do: :profile

  defp settings_tab_path(:profile), do: ~p"/my/settings/profile"
  defp settings_tab_path(:clubs), do: ~p"/my/settings/clubs"
  defp settings_tab_path(:emails), do: ~p"/my/settings/emails"

  defp settings_tab_class(active_tab, tab) do
    if active_tab == tab do
      [
        "settings-tab is-active rounded-lg bg-sage-50 px-3 py-2.5 text-left text-sm font-semibold text-sage-700 transition"
      ]
    else
      [
        "settings-tab rounded-lg px-3 py-2.5 text-left text-sm font-semibold text-ink-2 transition hover:bg-base-200 hover:text-ink"
      ]
    end
  end

  defp settings_tab_selected?(active_tab, tab), do: to_string(active_tab == tab)

  defp name_baseline_token(person_id, name) do
    Phoenix.Token.sign(MembaWeb.Endpoint, "profile-name-baseline", %{
      person_id: person_id,
      name: name
    })
  end

  defp browser_name_baseline(state, params, socket) do
    person_id = current_person(socket).person_id
    token = get_in(params, ["person", "baseline_token"])

    baseline =
      case Phoenix.Token.verify(MembaWeb.Endpoint, "profile-name-baseline", token,
             max_age: 86_400
           ) do
        {:ok, %{person_id: ^person_id, name: name}} when is_binary(name) -> name
        # A missing/forged/expired acknowledgement must never advance the
        # baseline. Keep the trusted name with which this editor was opened.
        _invalid -> Map.get(socket.assigns, :name_opened_name, state.baseline["name"])
      end

    %{state | baseline: %{"name" => baseline}}
  end

  defp person_initials(name), do: initials(name)

  defp club_initials(name), do: initials(name)

  defp initials(name) when is_binary(name) do
    name
    |> String.split(~r/\s+/, trim: true)
    |> Enum.take(2)
    |> Enum.map_join("", fn word -> String.first(word) || "" end)
    |> String.upcase()
    |> case do
      "" -> "?"
      initials -> initials
    end
  end

  defp initials(_name), do: "?"

  defp format_month_year(%DateTime{} = date_time), do: Calendar.strftime(date_time, "%b %Y")
  defp format_month_year(_date_time), do: "joining"

  defp email_state(%{primary?: true}), do: "primary"

  defp email_state(email_address),
    do: if(verified_email_address?(email_address), do: "verified", else: "pending")

  defp email_address_actions(%{primary?: true}), do: []

  defp email_address_actions(email_address) do
    if verified_email_address?(email_address) do
      [:make_primary, :remove]
    else
      [:resend_verification, :remove]
    end
  end

  defp verified_email_address?(%{verified_at: nil}), do: false
  defp verified_email_address?(%{verified_at: _verified_at}), do: true

  defp email_dom_id(%{normalized_email: normalized_email}) when is_binary(normalized_email) do
    Regex.replace(~r/[^a-zA-Z0-9_-]+/, normalized_email, "-")
    |> String.trim("-")
  end

  defp email_dom_id(_email_address), do: "unknown"

  defp forbidden!, do: raise(MembaWeb.ForbiddenError)
end
