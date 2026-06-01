defmodule MembaWeb.MemberMessageLive.Show do
  @moduledoc """
  LiveView entry point for the member-facing message detail page.

  The router can reference this module as `MemberMessageLive.Show` from the
  existing `scope "/", MembaWeb` block, avoiding a duplicated `MembaWeb`
  namespace prefix when the member message route is moved from the controller.
  """
  use MembaWeb, :live_view

  alias Memba.Membership
  alias Memba.Messaging
  alias MembaWeb.MemberReceiptPresentation

  @member_receipt_status_order ["opened", "delivered", "sent", "delivery problem"]

  @impl Phoenix.LiveView
  def mount(%{"club_id" => club_id, "message_id" => message_id} = params, _session, socket) do
    socket = ensure_identity_assigns(socket)

    with {:ok, club_id} <- Ecto.UUID.cast(club_id),
         selected_club when not is_nil(selected_club) <- selected_club(socket, club_id),
         message when not is_nil(message) <- Messaging.get_message(message_id),
         true <- message.club_id == club_id do
      receipts =
        message.message_id
        |> Messaging.list_member_receipts()
        |> Enum.map(&MemberReceiptPresentation.present_receipt/1)

      sender = Membership.get_person(message.sender_id)

      {:ok,
       socket
       |> assign(:route_params, params)
       |> assign(:page_title, message.subject)
       |> assign(:selected_club, selected_club)
       |> assign(:message, message)
       |> assign(:sender_name, sender_name(sender))
       |> assign(:member_receipts, receipts)
       |> assign(:member_receipt_count, Enum.count(receipts))
       |> assign(:member_receipt_groups, member_receipt_groups(receipts))}
    else
      :error ->
        not_found!(socket)

      nil ->
        not_found!(socket)

      false ->
        not_found!(socket)
    end
  end

  def mount(params, _session, socket) when is_map(params) do
    {:ok, socket |> ensure_identity_assigns() |> assign(:route_params, params)}
  end

  def mount(_params, _session, socket) do
    {:ok, socket |> ensure_identity_assigns() |> assign(:route_params, %{})}
  end

  @impl Phoenix.LiveView
  def render(%{message: _message} = assigns) do
    MembaWeb.PageHTML.message(assigns)
  end

  def render(assigns) do
    ~H"""
    <Layouts.club_site flash={@flash}>
      <div
        id="member-message-detail"
        data-live-view="member-message-detail"
        data-club-id={Map.get(@route_params, "club_id")}
        data-message-id={Map.get(@route_params, "message_id")}
        class="space-y-8"
      >
        <section class="overflow-hidden rounded-3xl border border-[var(--club-site-line)] bg-[var(--club-site-paper)] p-8 shadow-sm">
          <p class="text-sm font-semibold uppercase tracking-[0.18em] text-[var(--club-site-accent)]">
            Club message
          </p>
          <h1 class="mt-3 text-4xl font-semibold tracking-tight text-[var(--club-site-ink)]">
            Member message detail
          </h1>
          <p class="mt-4 max-w-2xl leading-7 text-[var(--club-site-muted)]">
            This LiveView surface is ready for the existing member message route to load and
            render the selected club message.
          </p>
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

  defp selected_club(socket, club_id) do
    Enum.find(socket.assigns.current_identity_clubs, fn club -> club.club_id == club_id end)
  end

  defp sender_name(%{name: name}) when is_binary(name) and name != "", do: name
  defp sender_name(_sender), do: "Club member"

  defp member_receipt_groups(receipts) do
    receipts_by_status = Enum.group_by(receipts, & &1.status)
    extra_statuses = Map.keys(receipts_by_status) -- @member_receipt_status_order

    (@member_receipt_status_order ++ Enum.sort(extra_statuses))
    |> Enum.map(fn status ->
      status_receipts = Map.get(receipts_by_status, status, [])
      presentation = MemberReceiptPresentation.present_status(status)

      %{
        status: status,
        status_label: presentation.label,
        status_icon: presentation.icon,
        count: Enum.count(status_receipts),
        receipts: status_receipts
      }
    end)
    |> Enum.reject(&(&1.count == 0))
  end

  defp not_found!(socket) do
    case socket.private[:connect_info] do
      %Plug.Conn{} = conn ->
        raise Phoenix.Router.NoRouteError, conn: conn, router: MembaWeb.Router

      _connect_info ->
        raise "message detail not found"
    end
  end
end
