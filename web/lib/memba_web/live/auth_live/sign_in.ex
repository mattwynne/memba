defmodule MembaWeb.AuthLive.SignIn do
  use MembaWeb, :live_view

  require Logger

  alias Memba.Accounts
  alias Memba.Accounts.AuthEmail
  alias Memba.Accounts.AuthEmailRequest
  alias Memba.AuthEmailProgressChanges
  alias Memba.Membership
  alias MembaWeb.ClubSite

  @neutral_notice "If that email address can sign in to Memba, the sign-in email is on its way."
  @progress_message_pre_send "Preparing your sign-in link…"
  @progress_message_sent "If this email can sign in, the link is on its way."
  @progress_message_provider_accepted "Your mailbox provider has accepted the email. It should appear shortly."
  @progress_message_fallback "If it does not arrive, check junk mail or ask for another link."
  @progress_message_expired "This sign-in-link request has expired. Ask for another link."
  @fallback_after_seconds 60

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:form, to_form(%{"email" => ""}, as: :auth))
     |> assign(:notice, @neutral_notice)
     |> assign(:auth_email_request_id, nil)
     |> assign(:auth_email_progress_request, nil)
     |> assign(:auth_email_progress_message, @neutral_notice)
     |> assign(:auth_email_progress_subscribed_request_id, nil)}
  end

  @impl Phoenix.LiveView
  def handle_params(params, uri, socket) do
    request_id = auth_email_request_id(params)

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:auth_email_request_id, request_id)
     |> assign_auth_email_progress(request_id)
     |> maybe_subscribe_to_auth_email_progress(request_id)
     |> maybe_schedule_auth_email_progress_fallback()
     |> assign(:auth_callback_base_url, auth_callback_base_url(uri))
     |> assign(:sign_in_email_context, sign_in_email_context(uri))}
  end

  @impl Phoenix.LiveView
  def handle_info(
        {:auth_email_progress_changed, %{request_id: request_id}},
        %{assigns: %{auth_email_request_id: request_id}} = socket
      ) do
    {:noreply,
     socket
     |> assign_auth_email_progress(request_id)
     |> maybe_schedule_auth_email_progress_fallback()}
  end

  def handle_info({:auth_email_progress_fallback, request_id}, socket) do
    if socket.assigns.auth_email_request_id == request_id do
      {:noreply,
       socket
       |> assign_auth_email_progress(request_id)
       |> maybe_schedule_auth_email_progress_fallback()}
    else
      {:noreply, socket}
    end
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  @impl Phoenix.LiveView
  def handle_event("request_sign_in_link", params, socket) do
    check_email_path =
      params
      |> email_param()
      |> create_request_and_deliver_sign_in_link(
        socket.assigns.auth_callback_base_url,
        Map.get(socket.assigns, :sign_in_email_context, %{})
      )
      |> check_email_path()

    {:noreply, push_patch(socket, to: check_email_path)}
  end

  defp check_email_path({:ok, request_id}), do: ~p"/auth/check-email/#{request_id}"
  defp check_email_path(:error), do: ~p"/auth/check-email"

  defp auth_email_request_id(%{"request_id" => request_id}) do
    case Memba.ID.cast(:auth_email_request, request_id) do
      {:ok, request_id} -> request_id
      :error -> nil
    end
  end

  defp auth_email_request_id(_params), do: nil

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
            Check your email for the sign-in link.
          </h1>
          <p id="sign-in-link-sent-notice" class="text-lg leading-8 text-ink-2">
            {@notice}
          </p>
        </div>

        <div class="rounded-3xl border border-line bg-paper p-6 shadow-sm">
          <div
            id="auth-email-progress"
            class="mb-5 rounded-2xl border border-sage-200 bg-sage-50/70 p-4"
          >
            <p class="text-xs font-semibold uppercase tracking-[0.18em] text-sage-700">
              Sign-in link progress
            </p>
            <p id="auth-email-progress-message" class="mt-2 text-base leading-7 text-ink">
              {@auth_email_progress_message}
            </p>
          </div>

          <p class="text-sm leading-6 text-ink-3">
            Open the email on this iPad and tap the sign-in button. The link works once and expires in 15 minutes. If it does not arrive, check your junk mail or ask for another link.
          </p>

          <.link
            id="request-another-sign-in-link"
            patch={~p"/auth"}
            class="mt-6 inline-flex rounded-full border border-line px-4 py-2 text-sm font-semibold text-ink transition hover:border-sage-600 hover:text-sage-700"
          >
            Ask for another sign-in link
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
            Sign in with your email.
          </h1>
          <p class="text-lg leading-8 text-ink-2">
            Use the email address your club or group has for you. We’ll email you a private sign-in link.
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
          >
            Email me a sign-in link
          </.button>
        </.form>

        <p class="text-sm leading-6 text-ink-3">
          To protect member privacy, this page does not say whether that email address is on a club list.
        </p>
      </section>
    </Layouts.app>
    """
  end

  defp page_title(:sent), do: "Check your email"
  defp page_title(_live_action), do: "Sign in"

  defp assign_auth_email_progress(socket, nil) do
    socket
    |> assign(:auth_email_progress_request, nil)
    |> assign(:auth_email_progress_message, @neutral_notice)
  end

  defp assign_auth_email_progress(socket, request_id) do
    request = Accounts.get_auth_email_request(request_id)

    socket
    |> assign(:auth_email_progress_request, request)
    |> assign(:auth_email_progress_message, auth_email_progress_message(request))
  end

  defp maybe_subscribe_to_auth_email_progress(socket, nil), do: socket

  defp maybe_subscribe_to_auth_email_progress(socket, request_id) do
    if connected?(socket) &&
         socket.assigns.auth_email_progress_subscribed_request_id != request_id do
      case AuthEmailProgressChanges.subscribe(request_id) do
        :ok ->
          assign(socket, :auth_email_progress_subscribed_request_id, request_id)

        {:error, :invalid_request_id} ->
          socket
      end
    else
      socket
    end
  end

  defp maybe_schedule_auth_email_progress_fallback(socket) do
    request = socket.assigns.auth_email_progress_request

    if connected?(socket) && schedule_fallback_timer?(request) do
      Process.send_after(
        self(),
        {:auth_email_progress_fallback, request.request_id},
        fallback_timer_ms(request)
      )
    end

    socket
  end

  defp schedule_fallback_timer?(%AuthEmailRequest{} = request) do
    not Accounts.auth_email_request_expired?(request) &&
      request.status != AuthEmailRequest.status_provider_accepted() &&
      seconds_since_request_created(request) < @fallback_after_seconds
  end

  defp schedule_fallback_timer?(_request), do: false

  defp fallback_timer_ms(%AuthEmailRequest{} = request) do
    seconds_remaining =
      @fallback_after_seconds - seconds_since_request_created(request)

    max(seconds_remaining, 0) * 1_000
  end

  defp auth_email_progress_message(nil), do: @neutral_notice

  defp auth_email_progress_message(%AuthEmailRequest{} = request) do
    cond do
      Accounts.auth_email_request_expired?(request) ->
        @progress_message_expired

      request.status == AuthEmailRequest.status_provider_accepted() ->
        @progress_message_provider_accepted

      seconds_since_request_created(request) >= @fallback_after_seconds ->
        @progress_message_fallback

      request.status == AuthEmailRequest.status_created() ->
        @progress_message_pre_send

      true ->
        @progress_message_sent
    end
  end

  defp seconds_since_request_created(%AuthEmailRequest{inserted_at: %DateTime{} = inserted_at}) do
    DateTime.utc_now(:microsecond)
    |> DateTime.diff(inserted_at, :second)
    |> max(0)
  end

  defp seconds_since_request_created(_request), do: 0

  defp email_param(%{"auth" => %{"email" => email}}), do: email
  defp email_param(_params), do: nil

  defp create_request_and_deliver_sign_in_link(email, callback_base_url, email_context) do
    case Accounts.create_auth_email_request() do
      {:ok, request} ->
        request_and_deliver_sign_in_link(email, callback_base_url, email_context, request)
        {:ok, request.request_id}

      {:error, reason} ->
        Logger.warning("Could not create auth email progress request: #{inspect(reason)}")
        :error
    end
  end

  defp request_and_deliver_sign_in_link(email, callback_base_url, email_context, request) do
    case Accounts.request_sign_in_link(email) do
      {:ok, %{email: recipient_email, token: token}} ->
        deliver_sign_in_link(recipient_email, token, callback_base_url, email_context, request)

      {:ok, nil} ->
        :ok

      {:error, reason} ->
        Logger.warning("Could not create auth sign-in link: #{inspect(reason)}")
    end
  end

  defp deliver_sign_in_link(recipient_email, token, callback_base_url, email_context, request) do
    callback_url = callback_base_url <> ~p"/auth/sign-in/#{token}"
    email_context = Map.put(email_context, :auth_email_request_id, request.request_id)

    case AuthEmail.deliver_sign_in_link(recipient_email, callback_url, email_context) do
      :ok ->
        mark_auth_email_sent(request, recipient_email)

      {:error, reason} ->
        Logger.warning("Could not deliver auth sign-in link email: #{inspect(reason)}")
    end
  end

  defp mark_auth_email_sent(request, recipient_email) do
    attrs = %{
      recipient_email: recipient_email,
      provider: auth_email_provider(),
      provider_message_stream: auth_email_message_stream()
    }

    case Accounts.mark_auth_email_sent(request.request_id, attrs) do
      {:ok, _request} ->
        :ok

      {:error, reason} ->
        Logger.warning("Could not mark auth email progress request sent: #{inspect(reason)}")
    end
  end

  defp auth_email_provider do
    case Keyword.get(auth_email_config(), :provider, :postmark) do
      :resend -> "resend"
      _provider -> "postmark"
    end
  end

  defp auth_email_message_stream do
    Keyword.get(auth_email_config(), :message_stream)
  end

  defp auth_email_config do
    Application.get_env(:memba, AuthEmail, [])
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

  defp sign_in_email_context(uri) when is_binary(uri) do
    with %URI{host: host} when is_binary(host) <- URI.parse(uri),
         {:ok, slug} <- ClubSite.slug_from_host(host),
         %{name: _name} = club <- Membership.get_club_by_slug(slug) do
      %{club: club}
    else
      _no_club_context -> %{}
    end
  end

  defp sign_in_email_context(_uri), do: %{}

  defp port_suffix("http", port) when port in [nil, 80], do: ""
  defp port_suffix("https", port) when port in [nil, 443], do: ""
  defp port_suffix(_scheme, nil), do: ""
  defp port_suffix(_scheme, port), do: ":#{port}"
end
