defmodule MembaWeb.AuthLive.SignIn do
  use MembaWeb, :live_view

  require Logger

  alias Memba.Accounts
  alias Memba.Accounts.AuthEmail
  alias MembaWeb.ClubSite

  @neutral_notice "Thanks. You should have an email in your inbox with a sign-in link."

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:form, to_form(%{"email" => ""}, as: :auth))
     |> assign(:notice, @neutral_notice)}
  end

  @impl Phoenix.LiveView
  def handle_params(_params, uri, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:auth_callback_base_url, auth_callback_base_url(uri))}
  end

  @impl Phoenix.LiveView
  def handle_event("request_sign_in_link", params, socket) do
    params
    |> email_param()
    |> request_and_deliver_sign_in_link(socket.assigns.auth_callback_base_url)

    {:noreply, push_patch(socket, to: ~p"/auth/check-email")}
  end

  @impl Phoenix.LiveView
  def render(%{live_action: :sent} = assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <section id="auth-sign-in-sent" class="space-y-8">
        <div class="space-y-4">
          <p class="text-sm font-semibold uppercase tracking-[0.2em] text-sage-600">
            Check your email
          </p>
          <h1 class="text-4xl font-semibold tracking-tight text-ink sm:text-5xl">
            We’ve sent your sign-in link
          </h1>
          <p id="sign-in-link-sent-notice" class="text-lg leading-8 text-ink-2">
            {@notice}
          </p>
        </div>

        <div class="rounded-3xl border border-line bg-paper p-6 shadow-sm">
          <p class="text-sm leading-6 text-ink-3">
            The link expires soon and can only be used once. If it does not arrive, check your spam folder or try again.
          </p>

          <.link
            id="request-another-sign-in-link"
            patch={~p"/auth"}
            class="mt-6 inline-flex rounded-full border border-line px-4 py-2 text-sm font-semibold text-ink transition hover:border-sage-600 hover:text-sage-700"
          >
            Request another link
          </.link>
        </div>
      </section>
    </Layouts.app>
    """
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <section id="auth-sign-in" class="space-y-8">
        <div class="space-y-4">
          <p class="text-sm font-semibold uppercase tracking-[0.2em] text-sage-600">
            Sign in
          </p>
          <h1 class="text-4xl font-semibold tracking-tight text-ink sm:text-5xl">
            Sign in to your club
          </h1>
          <p class="text-lg leading-8 text-ink-2">
            Enter your email address and we’ll send you a link to sign in.
          </p>
        </div>

        <.form
          for={@form}
          phx-submit="request_sign_in_link"
          id="sign-in-link-form"
          class="rounded-3xl border border-line bg-paper p-6 shadow-sm"
        >
          <.input
            field={@form[:email]}
            id="auth_email_input"
            type="email"
            label="Email address"
            autocomplete="email"
            placeholder="you@example.com"
            required
          />

          <.button
            id="request-sign-in-link-button"
            type="submit"
            variant="primary"
            class="mt-4 btn btn-primary"
          >
            Email me a sign-in link
          </.button>
        </.form>

        <p class="text-sm leading-6 text-ink-3">
          For your privacy, the response is the same whether or not we recognize the email address.
        </p>
      </section>
    </Layouts.app>
    """
  end

  defp page_title(:sent), do: "Check your email"
  defp page_title(_live_action), do: "Sign in"

  defp email_param(%{"auth" => %{"email" => email}}), do: email
  defp email_param(_params), do: nil

  defp request_and_deliver_sign_in_link(email, callback_base_url) do
    case Accounts.request_sign_in_link(email) do
      {:ok, %{email: recipient_email, token: token}} ->
        deliver_sign_in_link(recipient_email, token, callback_base_url)

      {:ok, nil} ->
        :ok

      {:error, reason} ->
        Logger.warning("Could not create auth sign-in link: #{inspect(reason)}")
    end
  end

  defp deliver_sign_in_link(recipient_email, token, callback_base_url) do
    callback_url = callback_base_url <> ~p"/auth/sign-in/#{token}"

    case AuthEmail.deliver_sign_in_link(recipient_email, callback_url) do
      :ok ->
        :ok

      {:error, reason} ->
        Logger.warning("Could not deliver auth sign-in link email: #{inspect(reason)}")
    end
  end

  defp auth_callback_base_url(uri) when is_binary(uri) do
    case URI.parse(uri) do
      %URI{scheme: scheme, host: host, port: port}
      when scheme in ["http", "https"] and is_binary(host) ->
        if ClubSite.club_host?(host) do
          scheme <> "://" <> host <> port_suffix(scheme, port)
        else
          MembaWeb.Endpoint.url()
        end

      _uri ->
        MembaWeb.Endpoint.url()
    end
  end

  defp auth_callback_base_url(_uri), do: MembaWeb.Endpoint.url()

  defp port_suffix("http", port) when port in [nil, 80], do: ""
  defp port_suffix("https", port) when port in [nil, 443], do: ""
  defp port_suffix(_scheme, nil), do: ""
  defp port_suffix(_scheme, port), do: ":#{port}"
end
