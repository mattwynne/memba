defmodule MembaWeb.MemberMessageLive.New do
  @moduledoc """
  LiveView entry point for the member-facing club message compose flow.

  The router references this module as `MemberMessageLive.New` from the
  `scope "/", MembaWeb` block, matching the existing member message LiveView
  namespace without duplicating the `MembaWeb` prefix.
  """
  use MembaWeb, :live_view

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
        class="space-y-8"
      >
        <section class="overflow-hidden rounded-3xl border border-[var(--club-site-line)] bg-[var(--club-site-paper)] p-8 shadow-sm">
          <p
            id="member-compose-selected-club"
            data-club-id={selected_club_id(@selected_club, @route_params)}
            class="text-sm font-semibold uppercase tracking-[0.18em] text-[var(--club-site-accent)]"
          >
            {selected_club_name(@selected_club)}
          </p>
          <p class="mt-4 text-sm font-semibold uppercase tracking-[0.18em] text-[var(--club-site-accent)]">
            New message
          </p>
          <h1 class="mt-3 text-4xl font-semibold tracking-tight text-[var(--club-site-ink)]">
            Send a club message
          </h1>
          <p class="mt-4 max-w-2xl leading-7 text-[var(--club-site-muted)]">
            This LiveView surface is ready for the focused member compose flow.
          </p>

          <div :if={@current_member} class="mt-6 grid gap-4 md:grid-cols-2">
            <p
              id="member-compose-from-summary"
              data-sender-id={@current_member.id}
              class="rounded-2xl border border-[var(--club-site-line)] bg-[var(--club-site-bg)] p-4 text-sm leading-6 text-[var(--club-site-muted)]"
            >
              From <strong class="text-[var(--club-site-ink)]">{@current_member.name}</strong> (you)
            </p>

            <p
              id="member-compose-recipient-summary"
              data-active-member-count={@active_member_count}
              class="rounded-2xl border border-[var(--club-site-line)] bg-[var(--club-site-bg)] p-4 text-sm leading-6 text-[var(--club-site-muted)]"
            >
              This goes to
              <strong class="text-[var(--club-site-ink)]">
                {@active_member_count} active members
              </strong>
              of {selected_club_name(@selected_club)}.
            </p>
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
            />
            <.input
              field={@message_form[:body]}
              id="member-message-body-input"
              label="Message"
              type="textarea"
            />
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

  defp forbidden!(_socket), do: raise(MembaWeb.ForbiddenError)
end
