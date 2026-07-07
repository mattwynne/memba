defmodule MembaWeb.MemberMessageDeliveryLive.Show do
  @moduledoc """
  LiveView entry point for the member-facing per-message delivery details page.

  The delivery route reuses the member message detail loader so it has the same
  selected-club authorization checks and receipt presentation model as the
  conversation page.
  """
  use MembaWeb, :live_view

  alias MembaWeb.MemberMessageDetail

  @impl Phoenix.LiveView
  def mount(params, session, socket) when is_map(params) do
    params = put_session_club_id(params, session) |> put_club_id_source(session)
    socket = ensure_identity_assigns(socket)

    case params do
      %{"club_id" => _club_id, "message_id" => _message_id} ->
        case MemberMessageDetail.load(
               params,
               socket.assigns.current_identity_clubs,
               socket.assigns.current_identity
             ) do
          {:ok, detail_assigns} ->
            {:ok,
             socket
             |> assign(:route_params, params)
             |> assign(detail_assigns)}

          {:error, :forbidden} ->
            forbidden!(socket)

          {:error, :not_found} ->
            not_found!(socket)
        end

      _params ->
        not_found!(socket)
    end
  end

  def mount(_params, _session, socket) do
    {:ok, socket |> ensure_identity_assigns() |> assign(:route_params, %{})}
  end

  @impl Phoenix.LiveView
  def render(%{message: _message} = assigns) do
    ~H"""
    <Layouts.club_site
      flash={@flash}
      club_name={@selected_club.name}
      current_identity={@current_identity}
      member_name={@current_member && @current_member.name}
    >
      <div
        id="member-message-delivery-detail"
        data-live-view="member-message-delivery-detail"
        data-club-id={@selected_club.club_id}
        data-message-id={@message.message_id}
        data-receipt-count={@member_email_delivery_count}
        class="mx-auto max-w-3xl"
      >
        <p class="text-xs font-semibold uppercase tracking-[0.18em] text-ink-2">
          Delivery details
        </p>
        <h1
          id="member-delivery-message-subject"
          class="mt-2 text-4xl font-semibold leading-tight tracking-tight text-base-content sm:text-5xl"
        >
          {@message.subject}
        </h1>

        <section id="member-delivery-receipt-model" class="mt-8 space-y-6">
          <div id="member-delivery-summary" class="grid gap-3 sm:grid-cols-2">
            <div
              :for={status <- @member_email_delivery_summary}
              data-testid="member-delivery-summary-status"
              data-receipt-status={status.status}
              data-receipt-count={status.count}
              data-receipt-percentage={status.percentage}
              class="rounded-2xl border border-base-300 bg-base-100 p-4"
            >
              <p class="font-semibold text-base-content">{status.status_label}</p>
              <p class="mt-1 text-sm text-ink-2">{status.description}</p>
              <p class="mt-3 font-mono text-sm text-ink-2">
                {status.count} / {@member_email_delivery_count} · {status.percentage}%
              </p>
            </div>
          </div>

          <div id="member-delivery-receipt-groups" class="space-y-3">
            <section
              :for={group <- @member_email_delivery_groups}
              id={"member-delivery-group-#{status_slug(group.status)}"}
              data-testid="member-delivery-group"
              data-receipt-status={group.status}
              data-receipt-count={group.count}
              class="rounded-2xl border border-base-300 bg-base-100 p-4"
            >
              <h2 class="font-semibold text-base-content">{group.status_label}</h2>
              <div class="mt-3 divide-y divide-base-300">
                <div
                  :for={receipt <- group.receipts}
                  id={"member-delivery-receipt-#{receipt.recipient_id}"}
                  data-testid="member-delivery-receipt"
                  data-recipient-id={receipt.recipient_id}
                  data-recipient-name={receipt.recipient_name}
                  data-receipt-status={receipt.status}
                  class="py-3"
                >
                  <p class="font-medium text-base-content">{receipt.recipient_name}</p>
                  <p class="text-sm text-ink-2">{receipt.status_label}</p>
                </div>
              </div>
            </section>
          </div>
        </section>
      </div>
    </Layouts.club_site>
    """
  end

  def render(_assigns) do
    raise "MemberMessageDeliveryLive.Show requires a loaded message before rendering"
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

  defp status_slug(status) when is_binary(status), do: String.replace(status, " ", "-")
  defp status_slug(_status), do: "unknown"

  defp ensure_identity_assigns(socket) do
    socket
    |> assign_new(:current_identity, fn -> nil end)
    |> assign_new(:current_identity_clubs, fn -> [] end)
  end

  defp forbidden!(_socket), do: raise(MembaWeb.ForbiddenError)

  defp not_found!(socket) do
    case socket.private[:connect_info] do
      %Plug.Conn{} = conn ->
        raise Phoenix.Router.NoRouteError, conn: conn, router: MembaWeb.Router

      _connect_info ->
        raise "message delivery detail not found"
    end
  end
end
