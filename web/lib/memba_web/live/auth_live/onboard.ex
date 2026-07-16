defmodule MembaWeb.AuthLive.Onboard do
  use MembaWeb, :live_view

  alias Memba.Accounts
  alias Memba.Membership
  alias MembaWeb.IdentityAuth

  @impl Phoenix.LiveView
  def mount(_params, session, socket) do
    email = session |> Map.get(IdentityAuth.identity_session_key()) |> Accounts.normalize_email()

    return_to =
      safe_return_to(Map.get(session, IdentityAuth.staff_onboarding_return_to_session_key()))

    cond do
      is_nil(email) ->
        {:ok, redirect(socket, to: ~p"/auth")}

      not Accounts.staff_email?(email) ->
        {:ok,
         socket
         |> put_flash(:error, "You are not authorized to access that page.")
         |> redirect(to: ~p"/")}

      staff_person?(email) ->
        {:ok, redirect(socket, to: return_to || ~p"/admin/clubs")}

      true ->
        {:ok,
         socket
         |> assign(:page_title, "Welcome to Memba")
         |> assign(:email, email)
         |> assign(:return_to, return_to)
         |> assign(:form, to_form(%{"name" => ""}, as: :staff))}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("finish_onboarding", %{"staff" => %{"name" => name}}, socket) do
    case create_staff_person(socket.assigns.email, name) do
      :ok ->
        {:noreply,
         socket
         |> put_flash(:info, "Welcome to Memba, #{String.trim(name)}.")
         |> push_navigate(to: socket.assigns.return_to || ~p"/admin/clubs")}

      {:error, reason} ->
        {:noreply,
         socket
         |> put_flash(:error, staff_onboarding_error(reason))
         |> assign(:form, to_form(%{"name" => name}, as: :staff))}
    end
  end

  def handle_event("finish_onboarding", _params, socket) do
    {:noreply, put_flash(socket, :error, "Please tell us your name.")}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <section id="staff-onboarding" class="space-y-8">
        <div class="space-y-4">
          <p class="text-sm font-semibold uppercase tracking-[0.2em] text-sage-600">
            Welcome
          </p>
          <h1 class="text-4xl font-semibold tracking-tight text-ink sm:text-5xl">
            Tell us your name
          </h1>
          <p class="text-lg leading-8 text-ink-2">
            We’ll use this to create your staff person record so messages and diagnostics can show who you are.
          </p>
        </div>

        <.form
          for={@form}
          phx-submit="finish_onboarding"
          id="staff-onboarding-form"
          class="rounded-3xl border border-line bg-paper p-6 shadow-sm"
        >
          <.input
            field={@form[:name]}
            id="staff-name-input"
            type="text"
            label="Your name"
            autocomplete="name"
            placeholder="Pat Example"
            required
          />

          <.button
            id="finish-staff-onboarding-button"
            type="submit"
            variant="primary"
          >
            Continue to Memba staff
          </.button>
        </.form>
      </section>
    </Layouts.app>
    """
  end

  defp create_staff_person(email, name) do
    Membership.create_person(
      %{person_id: Memba.ID.generate(:person), name: name, email: email},
      consistency: :strong
    )
  end

  defp staff_person?(email), do: not is_nil(Membership.get_person_by_email(email))

  defp safe_return_to(return_to) when is_binary(return_to) do
    cond do
      String.starts_with?(return_to, "//") -> nil
      String.starts_with?(return_to, "/") -> return_to
      true -> nil
    end
  end

  defp safe_return_to(_return_to), do: nil

  defp staff_onboarding_error(:invalid_name), do: "Please tell us your name."
  defp staff_onboarding_error(:email_address_taken), do: "That email address is already in use."
  defp staff_onboarding_error(reason), do: "Could not finish staff onboarding: #{inspect(reason)}"
end
