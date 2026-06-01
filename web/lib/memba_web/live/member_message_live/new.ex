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
  alias Memba.Membership
  alias Memba.Messaging

  @impl Phoenix.LiveView
  def mount(%{"club_id" => club_id} = params, _session, socket) do
    socket = ensure_identity_assigns(socket)

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
  end

  def mount(params, _session, socket) when is_map(params) do
    {:ok,
     socket
     |> ensure_identity_assigns()
     |> assign(:route_params, params)
     |> assign_empty_compose_context()}
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
    case send_current_member_message(socket, message_params) do
      {:ok, message_id} ->
        {:noreply,
         socket
         |> assign(:compose_state, :sent)
         |> assign(:sent_message_id, message_id)
         |> assign(:send_error, nil)}

      {:error, reason} ->
        log_send_failure(socket, reason)

        {:noreply,
         socket
         |> assign(:compose_state, :send_failed)
         |> assign(:sent_message_id, nil)
         |> assign(:send_error, reason)
         |> assign(:message_form, message_form(message_params))}
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
     |> assign(:send_error, nil)}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.club_site
      flash={@flash}
      club_name={selected_club_name(@selected_club)}
      current_identity={@current_identity}
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
          class="mx-auto max-w-2xl overflow-hidden rounded-3xl border border-[var(--club-site-line)] bg-[var(--club-site-paper)] p-6 text-center shadow-sm sm:p-10"
        >
          <div class="mx-auto flex size-16 items-center justify-center rounded-full bg-emerald-50 text-emerald-700 ring-1 ring-emerald-100">
            <.icon name="hero-check" class="size-8" />
          </div>

          <p class="mt-6 text-xs font-semibold uppercase tracking-[0.18em] text-[var(--club-site-accent)]">
            Club message
          </p>

          <h1 class="mt-2 text-4xl font-semibold tracking-tight text-[var(--club-site-ink)]">
            Message sent.
          </h1>

          <p
            id="member-compose-success-summary"
            data-active-member-count={@active_member_count}
            class="mx-auto mt-4 max-w-xl text-base leading-7 text-[var(--club-site-muted)]"
          >
            Your note is on its way to {active_member_count_summary(@active_member_count)}. You can watch it land on the message page.
          </p>

          <div class="mt-8 flex flex-col justify-center gap-3 sm:flex-row sm:flex-wrap">
            <.link
              id="member-compose-see-receipts-link"
              href={message_detail_path(@sent_message_id, @selected_club, @route_params)}
              class="inline-flex min-h-12 items-center justify-center gap-2 rounded-full bg-[var(--club-site-accent)] px-6 py-3 text-sm font-semibold text-white shadow-sm transition duration-200 hover:-translate-y-0.5 hover:shadow-md"
            >
              <.icon name="hero-eye" class="size-4" /> See who got it
            </.link>
            <.link
              id="member-compose-send-another-link"
              href={compose_path(@selected_club, @route_params)}
              class="inline-flex min-h-12 items-center justify-center rounded-full border border-[var(--club-site-line)] bg-[var(--club-site-paper)] px-6 py-3 text-sm font-semibold text-[var(--club-site-ink)] transition duration-200 hover:-translate-y-0.5 hover:bg-white"
            >
              Send another message
            </.link>
            <.link
              id="member-compose-back-home-link"
              href={club_home_path(@selected_club, @route_params)}
              class="inline-flex min-h-12 items-center justify-center rounded-full border border-transparent px-6 py-3 text-sm font-semibold text-[var(--club-site-muted)] transition duration-200 hover:text-[var(--club-site-ink)]"
            >
              Back to home
            </.link>
          </div>
        </section>

        <section
          :if={@compose_state == :send_failed}
          id="member-compose-error-state"
          class="mx-auto max-w-2xl overflow-hidden rounded-3xl border border-rose-100 bg-[var(--club-site-paper)] p-6 text-center shadow-sm sm:p-10"
        >
          <div class="mx-auto flex size-16 items-center justify-center rounded-full bg-rose-50 text-rose-700 ring-1 ring-rose-100">
            <.icon name="hero-exclamation-triangle" class="size-8" />
          </div>

          <p class="mt-6 text-xs font-semibold uppercase tracking-[0.18em] text-[var(--club-site-accent)]">
            Club message
          </p>

          <h1 class="mt-2 text-4xl font-semibold tracking-tight text-[var(--club-site-ink)]">
            That didn’t send.
          </h1>

          <p
            id="member-compose-error-summary"
            class="mx-auto mt-4 max-w-xl text-base leading-7 text-[var(--club-site-muted)]"
          >
            Your message was not sent to anyone. Please contact support so we can investigate before you try again.
          </p>

          <div class="mt-8 flex flex-col justify-center gap-3 sm:flex-row sm:flex-wrap">
            <button
              id="member-compose-try-again-button"
              type="button"
              phx-click="try_again"
              class="inline-flex min-h-12 items-center justify-center gap-2 rounded-full bg-[var(--club-site-accent)] px-6 py-3 text-sm font-semibold text-white shadow-sm transition duration-200 hover:-translate-y-0.5 hover:shadow-md"
            >
              <.icon name="hero-arrow-path" class="size-4" /> Try again
            </button>
            <.link
              id="member-compose-back-home-after-error-link"
              href={club_home_path(@selected_club, @route_params)}
              class="inline-flex min-h-12 items-center justify-center rounded-full border border-[var(--club-site-line)] bg-[var(--club-site-paper)] px-6 py-3 text-sm font-semibold text-[var(--club-site-ink)] transition duration-200 hover:-translate-y-0.5 hover:bg-white"
            >
              Back to club home
            </.link>
          </div>
        </section>

        <section
          :if={@compose_state == :composing}
          class="mx-auto max-w-3xl overflow-hidden rounded-3xl border border-[var(--club-site-line)] bg-[var(--club-site-paper)] p-6 shadow-sm sm:p-8"
        >
          <.link
            id="member-compose-club-home-link"
            href={club_home_path(@selected_club, @route_params)}
            class="inline-flex w-fit items-center gap-2 text-sm font-semibold text-[var(--club-site-muted)] transition duration-200 hover:text-[var(--club-site-ink)]"
          >
            <.icon name="hero-arrow-left" class="size-4" /> Club home
          </.link>

          <p
            id="member-compose-eyebrow"
            class="mt-5 text-xs font-semibold uppercase tracking-[0.18em] text-[var(--club-site-muted)]"
          >
            New message
          </p>

          <h1 class="mt-2 text-4xl font-semibold tracking-tight text-[var(--club-site-ink)]">
            Send a club message
          </h1>

          <p
            id="member-compose-selected-club"
            data-club-id={selected_club_id(@selected_club, @route_params)}
            class="mt-3 text-sm font-semibold uppercase tracking-[0.18em] text-[var(--club-site-accent)]"
          >
            {selected_club_name(@selected_club)}
          </p>

          <div
            id="member-compose-recipient-summary"
            data-active-member-count={@active_member_count}
            class="mt-6 flex gap-3 rounded-2xl border border-sky-100 bg-sky-50 px-4 py-3 text-sm leading-6 text-sky-950"
          >
            <span class="mt-0.5 flex size-8 shrink-0 items-center justify-center rounded-full bg-white text-sky-700 ring-1 ring-sky-100">
              <.icon name="hero-users" class="size-4" />
            </span>
            <p>
              This goes to
              <strong class="font-semibold text-sky-950">
                {active_member_count_summary(@active_member_count)}
              </strong>
              of {selected_club_name(@selected_club)}. There’s no list to pick — everyone with a current membership gets it.
            </p>
          </div>

          <div :if={@current_member} class="mt-6">
            <p class="mb-2 text-sm font-semibold text-[var(--club-site-ink)]">From</p>
            <div
              id="member-compose-from-summary"
              data-sender-id={@current_member.id}
              aria-label={"Sending as #{@current_member.name}"}
              class="flex items-center gap-3 rounded-xl border border-[var(--club-site-line)] bg-[var(--club-site-paper)] px-4 py-3"
            >
              <span class="flex size-9 shrink-0 items-center justify-center rounded-full bg-[var(--club-site-bg)] text-xs font-semibold text-[var(--club-site-accent)] ring-1 ring-[var(--club-site-line)]">
                {member_initials(@current_member.name)}
              </span>
              <span class="min-w-0">
                <strong class="block truncate text-sm font-semibold text-[var(--club-site-ink)]">
                  {@current_member.name} (you)
                </strong>
                <span class="block text-xs text-[var(--club-site-muted)]">Sending as yourself</span>
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
              placeholder="What's this about?"
              class="w-full rounded-lg border border-[var(--club-site-line)] bg-[var(--club-site-paper)] px-4 py-3 text-[var(--club-site-ink)] placeholder:text-[var(--club-site-muted)] focus:border-[var(--club-site-accent)] focus:outline-none focus:ring-2 focus:ring-[var(--club-site-accent)]/15"
            />
            <.input
              field={@message_form[:body]}
              id="member-message-body-input"
              label="Message"
              type="textarea"
              placeholder="Write your note to the club…"
              rows="8"
              class="min-h-40 w-full resize-y rounded-lg border border-[var(--club-site-line)] bg-[var(--club-site-paper)] px-4 py-3 text-[var(--club-site-ink)] placeholder:text-[var(--club-site-muted)] focus:border-[var(--club-site-accent)] focus:outline-none focus:ring-2 focus:ring-[var(--club-site-accent)]/15"
            />

            <div class="mt-2 flex flex-col gap-3 sm:flex-row">
              <button
                id="member-message-send-button"
                type="submit"
                class="inline-flex min-h-12 items-center justify-center gap-2 rounded-full bg-[var(--club-site-accent)] px-6 py-3 text-sm font-semibold text-white shadow-sm transition duration-200 hover:-translate-y-0.5 hover:shadow-md"
              >
                <.icon name="hero-paper-airplane" class="size-4" /> Send to all members
              </button>
              <.link
                id="member-message-cancel-link"
                href={club_home_path(@selected_club, @route_params)}
                class="inline-flex min-h-12 items-center justify-center rounded-full border border-[var(--club-site-line)] bg-[var(--club-site-paper)] px-6 py-3 text-sm font-semibold text-[var(--club-site-ink)] transition duration-200 hover:-translate-y-0.5 hover:bg-white"
              >
                Cancel
              </.link>
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
      message_id = Ecto.UUID.generate()

      attrs = %{
        "message_id" => message_id,
        "club_id" => club_id,
        "sender_id" => sender_id,
        "subject" => Map.get(message_params, "subject", ""),
        "body" => Map.get(message_params, "body", "")
      }

      case Messaging.send_club_message(attrs, consistency: :strong) do
        :ok -> {:ok, message_id}
        {:ok, _result} -> {:ok, message_id}
        {:error, reason} -> {:error, reason}
      end
    else
      _missing_compose_context -> {:error, :forbidden}
    end
  end

  defp log_send_failure(socket, reason) do
    Logger.error("Member message send failed",
      club_id: selected_club_id(socket.assigns.selected_club, socket.assigns.route_params),
      sender_id: current_member_id(socket.assigns.current_member),
      reason: inspect(reason)
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

  defp selected_club_name(nil), do: "Club"
  defp selected_club_name(selected_club), do: selected_club.name

  defp selected_club_id(nil, route_params), do: Map.get(route_params, "club_id")
  defp selected_club_id(selected_club, _route_params), do: selected_club.club_id

  defp current_member_id(nil), do: nil
  defp current_member_id(current_member), do: current_member.id

  defp club_home_path(nil, route_params) do
    case Map.get(route_params, "club_id") do
      nil -> ~p"/"
      club_id -> ~p"/?club_id=#{club_id}"
    end
  end

  defp club_home_path(selected_club, _route_params), do: ~p"/?club_id=#{selected_club.club_id}"

  defp compose_path(nil, route_params) do
    case Map.get(route_params, "club_id") do
      nil -> ~p"/messages/new"
      club_id -> ~p"/messages/new?club_id=#{club_id}"
    end
  end

  defp compose_path(selected_club, _route_params),
    do: ~p"/messages/new?club_id=#{selected_club.club_id}"

  defp message_detail_path(message_id, selected_club, route_params) do
    ~p"/messages/#{message_id}?club_id=#{selected_club_id(selected_club, route_params)}"
  end

  defp active_member_count_summary(nil), do: "all active members"
  defp active_member_count_summary(1), do: "the active member"
  defp active_member_count_summary(count), do: "all #{count} active members"

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
