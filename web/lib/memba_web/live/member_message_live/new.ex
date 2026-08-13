defmodule MembaWeb.MemberMessageLive.New do
  @moduledoc """
  LiveView entry point for the member-facing club message compose flow.

  The router references this module as `MemberMessageLive.New` from the
  `scope "/", MembaWeb` block, matching the existing member message LiveView
  namespace without duplicating the `MembaWeb` prefix.
  """
  use MembaWeb, :live_view

  require Logger

  alias Memba.Accounts
  alias Memba.ClubInboundEmailAddress
  alias Memba.Membership
  alias Memba.Messaging
  alias Memba.Messaging.Projectors.Message, as: MessageProjector
  alias MembaWeb.ClubSite

  @impl Phoenix.LiveView
  def mount(params, session, socket) when is_map(params) do
    params = put_session_club_id(params, session) |> put_club_id_source(session)
    socket = ensure_identity_assigns(socket)

    case params do
      %{"club_id" => club_id} ->
        case compose_context(
               club_id,
               socket.assigns.current_identity,
               socket.assigns.current_identity_clubs
             ) do
          {:ok, compose_assigns} ->
            {:ok,
             socket
             |> assign(:route_params, params)
             |> assign(compose_assigns)
             |> assign_initial_send_state()
             |> assign(:message_form, message_form())}

          {:error, :forbidden} ->
            forbidden!(socket)
        end

      _params ->
        {:ok,
         socket
         |> assign(:route_params, params)
         |> assign_empty_compose_context()}
    end
  end

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> ensure_identity_assigns()
     |> assign(:route_params, %{})
     |> assign_empty_compose_context()}
  end

  @impl Phoenix.LiveView
  def handle_event("send_message", %{"message" => message_params}, socket) do
    if blank_body?(message_params) do
      {:noreply,
       socket
       |> assign(:compose_state, :composing)
       |> assign(:sent_message_id, nil)
       |> assign(:send_error, nil)
       |> assign(:body_error, "Message body can’t be blank.")
       |> assign(:message_form, message_form(message_params))}
    else
      case send_current_member_message(socket, message_params) do
        {:ok, message_id} ->
          {:noreply,
           socket
           |> assign(:compose_state, :sent)
           |> assign(:sent_message_id, message_id)
           |> assign(:send_error, nil)
           |> assign(:body_error, nil)}

        {:error, reason} ->
          log_send_failure(socket, reason)

          {:noreply,
           socket
           |> assign(:compose_state, :send_failed)
           |> assign(:sent_message_id, nil)
           |> assign(:send_error, reason)
           |> assign(:body_error, nil)
           |> assign(:message_form, message_form(message_params))}
      end
    end
  end

  def handle_event("send_message", _params, socket) do
    handle_event("send_message", %{"message" => %{}}, socket)
  end

  def handle_event("try_again", _params, socket) do
    {:noreply,
     socket
     |> assign(:compose_state, :composing)
     |> assign(:sent_message_id, nil)
     |> assign(:send_error, nil)
     |> assign(:body_error, nil)}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <% inbound_email_address = club_inbound_email_address(@selected_club) %>
    <Layouts.club_site
      flash={@flash}
      club_name={selected_club_name(@selected_club)}
      current_identity={@current_identity}
      member_name={@current_member && @current_member.name}
    >
      <div
        id="member-message-compose"
        data-live-view="member-message-compose"
        data-club-id={selected_club_id(@selected_club, @route_params)}
        data-current-member-id={current_member_id(@current_member)}
        data-active-member-count={@active_member_count}
        data-compose-state={@compose_state}
        data-sent-message-id={@sent_message_id}
        class="space-y-8"
      >
        <section
          :if={@compose_state == :sent}
          id="member-compose-success-state"
          class="mx-auto max-w-2xl overflow-hidden rounded-3xl border border-base-300 bg-base-100 p-6 text-center shadow-sm sm:p-10"
        >
          <div class="mx-auto flex size-16 items-center justify-center rounded-full bg-success-soft text-success ring-1 ring-success/20">
            <.icon name="hero-check" class="size-8" />
          </div>

          <p class="mt-6 text-xs font-semibold uppercase tracking-[0.18em] text-primary">
            Club message
          </p>

          <h1 class="mt-2 text-4xl font-semibold tracking-tight text-base-content">
            Your message is being sent.
          </h1>

          <p
            id="member-compose-success-summary"
            data-active-member-count={@active_member_count}
            class="mx-auto mt-4 max-w-xl text-base leading-7 text-ink-2"
          >
            Memba is sending your message to {active_member_count_summary(@active_member_count)}. You can check delivery on the message page.
          </p>

          <div class="mt-8 flex flex-col justify-center gap-3 sm:flex-row sm:flex-wrap">
            <.button
              id="member-compose-see-receipts-link"
              href={message_detail_path(@sent_message_id, @selected_club, @route_params)}
              variant="primary"
              size="lg"
            >
              <.icon name="hero-eye" class="size-4" /> Check delivery
            </.button>
            <.button
              id="member-compose-send-another-link"
              href={compose_path(@selected_club, @route_params)}
              variant="secondary"
              size="lg"
            >
              Send another message
            </.button>
            <.button
              id="member-compose-back-home-link"
              href={club_home_path(@selected_club, @route_params)}
              variant="ghost"
              size="lg"
            >
              Back to club home
            </.button>
          </div>
        </section>

        <section
          :if={@compose_state == :send_failed}
          id="member-compose-error-state"
          class="mx-auto max-w-2xl overflow-hidden rounded-3xl border border-error/20 bg-base-100 p-6 text-center shadow-sm sm:p-10"
        >
          <div class="mx-auto flex size-16 items-center justify-center rounded-full bg-error-soft text-error ring-1 ring-error/20">
            <.icon name="hero-exclamation-triangle" class="size-8" />
          </div>

          <p class="mt-6 text-xs font-semibold uppercase tracking-[0.18em] text-primary">
            Club message
          </p>

          <h1 class="mt-2 text-4xl font-semibold tracking-tight text-base-content">
            Your message was not sent.
          </h1>

          <p
            id="member-compose-error-summary"
            class="mx-auto mt-4 max-w-xl text-base leading-7 text-ink-2"
          >
            No one received this message. Please try again. If it still fails, ask a group organizer to contact Memba.
          </p>

          <div class="mt-8 flex flex-col justify-center gap-3 sm:flex-row sm:flex-wrap">
            <.button
              id="member-compose-try-again-button"
              type="button"
              phx-click="try_again"
              variant="primary"
              size="lg"
            >
              <.icon name="hero-arrow-path" class="size-4" /> Try again
            </.button>
            <.button
              id="member-compose-back-home-after-error-link"
              href={club_home_path(@selected_club, @route_params)}
              variant="secondary"
              size="lg"
            >
              Back to club home
            </.button>
          </div>
        </section>

        <section
          :if={@compose_state == :composing}
          class="mx-auto max-w-3xl overflow-hidden rounded-3xl border border-base-300 bg-base-100 p-6 shadow-sm sm:p-8"
        >
          <.link
            id="member-compose-club-home-link"
            href={club_home_path(@selected_club, @route_params)}
            class="inline-flex w-fit items-center gap-2 text-sm font-semibold text-ink-2 transition duration-200 hover:text-base-content"
          >
            <.icon name="hero-arrow-left" class="size-4" /> Club home
          </.link>

          <p
            id="member-compose-eyebrow"
            class="mt-5 text-xs font-semibold uppercase tracking-[0.18em] text-ink-2"
          >
            New message
          </p>

          <h1 class="mt-2 text-4xl font-semibold tracking-tight text-base-content">
            Send a message to all current members
          </h1>

          <p
            id="member-compose-selected-club"
            data-club-id={selected_club_id(@selected_club, @route_params)}
            class="mt-3 text-sm font-semibold uppercase tracking-[0.18em] text-primary"
          >
            {selected_club_name(@selected_club)}
          </p>

          <div
            id="member-compose-recipient-summary"
            data-active-member-count={@active_member_count}
            class="mt-6 flex gap-3 rounded-2xl border border-info/20 bg-info-soft px-4 py-3 text-sm leading-6 text-base-content"
          >
            <span class="mt-0.5 flex size-8 shrink-0 items-center justify-center rounded-full bg-base-100 text-info ring-1 ring-info/20">
              <.icon name="hero-users" class="size-4" />
            </span>
            <p>
              Before you send: this message will be emailed to
              <strong class="font-semibold text-base-content">
                {active_member_count_summary(@active_member_count)}
              </strong>
              of {selected_club_name(@selected_club)}. There is no list to pick.
            </p>
          </div>

          <div
            :if={inbound_email_address}
            id="member-compose-inbound-email"
            data-inbound-address={inbound_email_address}
            class="mt-4 flex gap-3 rounded-2xl border border-base-300 bg-base-200 px-4 py-3 text-sm leading-6 text-ink-2"
          >
            <span class="mt-0.5 flex size-8 shrink-0 items-center justify-center rounded-full bg-base-100 text-primary ring-1 ring-base-300">
              <.icon name="hero-envelope" class="size-4" />
            </span>
            <p>
              Prefer email? You can also send a club-wide message to
              <a
                id="member-compose-inbound-email-link"
                href={"mailto:#{inbound_email_address}"}
                class="font-semibold text-primary underline decoration-primary/30 underline-offset-4 transition duration-200 hover:decoration-primary"
              >
                {inbound_email_address}
              </a>
            </p>
          </div>

          <div :if={@current_member} class="mt-6">
            <p class="mb-2 text-sm font-semibold text-base-content">From</p>
            <div
              id="member-compose-from-summary"
              data-sender-id={@current_member.id}
              aria-label={"Sending as #{@current_member.name}"}
              class="flex items-center gap-3 rounded-xl border border-base-300 bg-base-100 px-4 py-3"
            >
              <.avatar
                id="member-compose-from-avatar"
                data-testid="member-compose-from-avatar"
                initials={member_initials(@current_member.name)}
                size={:md}
                class="shrink-0"
                title={@current_member.name}
              />
              <span class="min-w-0">
                <strong class="block truncate text-sm font-semibold text-base-content">
                  {@current_member.name} (you)
                </strong>
                <span class="block text-xs text-ink-2">Sending as yourself</span>
              </span>
            </div>
          </div>

          <.form
            for={@message_form}
            id="member-message-compose-form"
            phx-submit="send_message"
            class="mt-6 grid gap-4"
          >
            <.input
              field={@message_form[:subject]}
              id="member-message-subject-input"
              label="Subject"
              placeholder="Example: Saturday trail day"
              class="w-full rounded-lg border border-base-300 bg-base-100 px-4 py-3 text-base-content placeholder:text-ink-2 focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/15"
            />
            <.input
              field={@message_form[:body]}
              id="member-message-body-input"
              label="Message"
              type="textarea"
              placeholder="Write the message members should receive."
              rows="8"
              class="min-h-40 w-full resize-y rounded-lg border border-base-300 bg-base-100 px-4 py-3 text-base-content placeholder:text-ink-2 focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/15"
            />
            <p
              :if={@body_error}
              id="member-message-body-error"
              class="text-sm font-semibold text-error"
            >
              {@body_error}
            </p>

            <div class="mt-2 flex flex-col gap-3 sm:flex-row">
              <.button
                id="member-message-send-button"
                type="submit"
                variant="primary"
                size="lg"
              >
                <.icon name="hero-paper-airplane" class="size-4" /> Send to all current members
              </.button>
              <.button
                id="member-message-cancel-link"
                href={club_home_path(@selected_club, @route_params)}
                variant="secondary"
                size="lg"
              >
                Cancel
              </.button>
            </div>
          </.form>
        </section>
      </div>
    </Layouts.club_site>
    """
  end

  defp ensure_identity_assigns(socket) do
    socket
    |> assign_new(:current_identity, fn -> nil end)
    |> assign_new(:current_identity_clubs, fn -> [] end)
  end

  defp send_current_member_message(socket, message_params) do
    with %{selected_club: %{club_id: club_id}, current_member: %{id: sender_id}} <- socket.assigns do
      message_id = Memba.ID.generate(:message)

      attrs = %{
        "message_id" => message_id,
        "club_id" => club_id,
        "sender_id" => sender_id,
        "subject" => Map.get(message_params, "subject", ""),
        "body" => Map.get(message_params, "body", "")
      }

      case Messaging.send_club_message(attrs, consistency: [MessageProjector]) do
        :ok -> {:ok, message_id}
        {:ok, _result} -> {:ok, message_id}
        {:error, reason} -> {:error, reason}
      end
    else
      _missing_compose_context -> {:error, :forbidden}
    end
  end

  defp log_send_failure(socket, reason) do
    inspected_reason = inspect(reason)

    Logger.error("Member message send failed: #{inspected_reason}",
      club_id: selected_club_id(socket.assigns.selected_club, socket.assigns.route_params),
      sender_id: current_member_id(socket.assigns.current_member),
      reason: inspected_reason
    )
  end

  defp compose_context(club_id, current_identity, current_identity_clubs) do
    with selected_club when not is_nil(selected_club) <-
           selected_club(current_identity_clubs, club_id),
         members <- Membership.list_active_members_of_club(club_id),
         current_member when not is_nil(current_member) <-
           current_member_for_identity(members, current_identity) do
      {:ok,
       %{
         selected_club: selected_club,
         current_member: current_member,
         active_member_count: Enum.count(members)
       }}
    else
      _not_authorized -> {:error, :forbidden}
    end
  end

  defp selected_club(current_identity_clubs, club_id) do
    Enum.find(current_identity_clubs, fn club -> club.club_id == club_id end)
  end

  defp current_member_for_identity(_members, nil), do: nil

  defp current_member_for_identity(members, identity) do
    identity_email = Accounts.normalize_email(identity.email)

    Enum.find(members, fn member -> Accounts.normalize_email(member.email) == identity_email end)
  end

  defp assign_empty_compose_context(socket) do
    socket
    |> assign(:selected_club, nil)
    |> assign(:current_member, nil)
    |> assign(:active_member_count, nil)
    |> assign_initial_send_state()
    |> assign(:message_form, message_form())
  end

  defp assign_initial_send_state(socket) do
    socket
    |> assign(:compose_state, :composing)
    |> assign(:sent_message_id, nil)
    |> assign(:send_error, nil)
    |> assign(:body_error, nil)
  end

  defp blank_body?(message_params) do
    message_params
    |> Map.get("body", "")
    |> to_string()
    |> String.trim()
    |> Kernel.==("")
  end

  defp message_form do
    message_form(%{"subject" => "", "body" => ""})
  end

  defp message_form(message_params) do
    message_params
    |> Map.take(["subject", "body"])
    |> Map.put_new("subject", "")
    |> Map.put_new("body", "")
    |> to_form(as: :message)
  end

  defp put_session_club_id(params, session) do
    case {Map.get(params, "club_id"), Map.get(session, "club_id")} do
      {nil, club_id} when is_binary(club_id) -> Map.put(params, "club_id", club_id)
      _club_id_present_or_missing -> params
    end
  end

  defp put_club_id_source(params, session) do
    case Map.get(session, "club_id_source") do
      "host" -> Map.put(params, "club_id_source", "host")
      _source -> params
    end
  end

  defp selected_club_name(nil), do: "Club"
  defp selected_club_name(selected_club), do: selected_club.name

  defp club_inbound_email_address(club), do: ClubInboundEmailAddress.address(club)

  defp selected_club_id(nil, route_params), do: Map.get(route_params, "club_id")
  defp selected_club_id(selected_club, _route_params), do: selected_club.club_id

  defp current_member_id(nil), do: nil
  defp current_member_id(current_member), do: current_member.id

  defp club_home_path(nil, _route_params), do: ~p"/conversations"

  defp club_home_path(_selected_club, %{"club_id_source" => "host"}), do: ~p"/conversations"

  defp club_home_path(selected_club, _route_params),
    do: ClubSite.url(selected_club, "/conversations")

  defp compose_path(nil, _route_params), do: ~p"/messages/new"

  defp compose_path(_selected_club, %{"club_id_source" => "host"}), do: ~p"/messages/new"

  defp compose_path(selected_club, _route_params),
    do: ClubSite.url(selected_club, "/messages/new")

  defp message_detail_path(message_id, _selected_club, %{"club_id_source" => "host"}) do
    ~p"/messages/#{message_id}"
  end

  defp message_detail_path(message_id, selected_club, _route_params) do
    case selected_club do
      nil -> ~p"/messages/#{message_id}"
      club -> ClubSite.url(club, "/messages/#{message_id}")
    end
  end

  defp active_member_count_summary(nil), do: "all current members"
  defp active_member_count_summary(1), do: "the current member"
  defp active_member_count_summary(count), do: "all #{count} current members"

  defp member_initials(nil), do: "ME"

  defp member_initials(name) do
    name
    |> String.split(~r/\s+/, trim: true)
    |> Enum.take(2)
    |> Enum.map(&String.first/1)
    |> Enum.join()
    |> String.upcase()
    |> case do
      "" -> "ME"
      initials -> initials
    end
  end

  defp forbidden!(_socket), do: raise(MembaWeb.ForbiddenError)
end
