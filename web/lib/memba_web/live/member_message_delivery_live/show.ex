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
        <h1
          id="member-delivery-message-subject"
          class="delivery-title"
        >
          Delivery — “{@message.subject}”
        </h1>
        <p id="member-delivery-message-meta" class="delivery-meta">
          Sent by <span class="font-semibold text-base-content">{@sender_name}</span>
          ·
          <time
            id="member-delivery-message-sent-at"
            datetime={DateTime.to_iso8601(@message.inserted_at)}
          >
            {format_message_time(@message.inserted_at)}
          </time>
          · to {member_count_label(@member_email_delivery_count)}
        </p>

        <section id="member-delivery-receipt-model" class="mt-8 space-y-6">
          <div id="member-delivery-summary" class="delivery-summary">
            <div class="delivery-summary__head">
              <h2 class="delivery-summary__title">Message delivery</h2>
              <span
                id="member-delivery-summary-count"
                data-receipt-count={@member_email_delivery_count}
                class="delivery-summary__count"
              >
                {member_count_label(@member_email_delivery_count)}
              </span>
            </div>

            <div
              id="member-delivery-summary-bar"
              class="delivery-bar"
              aria-hidden="true"
            >
              <span
                :for={status <- @member_email_delivery_summary}
                data-testid="member-delivery-summary-bar-segment"
                data-receipt-status={status.status}
                data-receipt-count={status.count}
                data-receipt-percentage={status.percentage}
                class={delivery_status_class(status.status)}
                style={receipt_bar_width(status)}
              />
            </div>

            <div id="member-delivery-summary-legend" class="delivery-legend">
              <div
                :for={status <- @member_email_delivery_summary}
                data-testid="member-delivery-summary-status"
                data-receipt-status={status.status}
                data-receipt-count={status.count}
                data-receipt-percentage={status.percentage}
                class="delivery-legend__item"
              >
                <span class={["delivery-legend__sw", delivery_status_class(status.status)]} />
                <span class="delivery-legend__txt">
                  <span class="delivery-legend__lab">
                    {delivery_status_label(status)}
                  </span>
                  <span class="delivery-legend__desc">
                    {delivery_status_description(status)}
                  </span>
                </span>
                <span class="delivery-legend__n">{status.count}</span>
              </div>
            </div>
          </div>

          <div id="member-delivery-receipt-groups" class="space-y-3">
            <p
              :if={@member_email_delivery_groups == []}
              id="member-delivery-receipts-empty"
              class="rounded-2xl border border-dashed border-base-300 bg-base-100 p-5 text-sm text-ink-2"
            >
              Memba has not prepared the delivery list for this message yet. Check again in a moment.
            </p>

            <details
              :for={group <- delivery_groups(@member_email_delivery_groups)}
              id={"member-delivery-group-#{status_slug(group.status)}"}
              data-testid="member-delivery-group"
              data-receipt-status={group.status}
              data-receipt-count={group.count}
              class="delivery-group"
              open={delivery_group_open?(group.status)}
            >
              <summary
                id={"member-delivery-group-toggle-#{status_slug(group.status)}"}
                aria-controls={"member-delivery-receipts-#{status_slug(group.status)}"}
                class="delivery-group__btn"
              >
                <span class={["delivery-group__ic", delivery_status_tint_class(group.status)]}>
                  <.icon name={group.status_icon} />
                </span>
                <span class="delivery-group__t">
                  <span class="delivery-group__lab">{delivery_status_label(group)}</span>
                  <span class="delivery-group__desc">{delivery_status_description(group)}</span>
                </span>
                <span class="delivery-group__n">{group.count}</span>
                <.icon name="hero-chevron-down" class="delivery-group__chev" />
              </summary>

              <div
                id={"member-delivery-receipts-#{status_slug(group.status)}"}
                class="delivery-group__rows"
              >
                <div
                  :for={receipt <- group.receipts}
                  id={"member-delivery-receipt-#{receipt.recipient_id}"}
                  data-testid="member-delivery-receipt"
                  data-recipient-id={receipt.recipient_id}
                  data-recipient-name={receipt.recipient_name}
                  data-receipt-status={receipt.status}
                  data-recipient-reason={receipt.reason}
                  class="recipient"
                >
                  <span class="recipient__id">
                    <span class={["recipient__av", delivery_status_tint_class(receipt.status)]}>
                      {recipient_initials(receipt.recipient_name)}
                    </span>
                    <span class="recipient__name">{receipt.recipient_name}</span>
                  </span>
                  <span class="recipient__reason">{recipient_delivery_reason(receipt)}</span>
                </div>
              </div>
            </details>
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

  defp receipt_bar_width(%{percentage: percentage}) when is_integer(percentage) do
    "width: #{max(percentage, 0)}%;"
  end

  defp receipt_bar_width(_status), do: "width: 0%;"

  defp delivery_groups(groups) when is_list(groups) do
    Enum.sort_by(groups, &delivery_group_order(&1.status))
  end

  defp delivery_groups(_groups), do: []

  defp delivery_group_order("delivery problem"), do: 0
  defp delivery_group_order("sent"), do: 1
  defp delivery_group_order("delivered"), do: 2
  defp delivery_group_order(_status), do: 3

  defp delivery_group_open?("delivery problem"), do: true
  defp delivery_group_open?(_status), do: false

  defp delivery_status_label(%{status: "delivery problem"}), do: "Didn't go through"
  defp delivery_status_label(%{status_label: status_label}), do: status_label
  defp delivery_status_label(_status), do: "Delivery status"

  defp delivery_status_description(%{status: "delivered"}), do: "Arrived in member inboxes"
  defp delivery_status_description(%{status: "sent"}), do: "Still on the way"

  defp delivery_status_description(%{status: "delivery problem"}),
    do: "Bounced — couldn't be delivered"

  defp delivery_status_description(%{description: description}), do: description
  defp delivery_status_description(_status), do: "Delivery status for this message"

  defp recipient_delivery_reason(%{status: "delivery problem", reason: reason})
       when is_binary(reason) and reason != "",
       do: reason

  defp recipient_delivery_reason(receipt), do: delivery_status_label(receipt)

  defp delivery_status_class("delivered"), do: "deliv-ok"
  defp delivery_status_class("sent"), do: "deliv-snd"
  defp delivery_status_class("delivery problem"), do: "deliv-bad"
  defp delivery_status_class(_status), do: "deliv-unknown"

  defp delivery_status_tint_class("delivered"), do: "deliv-tint-ok"
  defp delivery_status_tint_class("sent"), do: "deliv-tint-snd"
  defp delivery_status_tint_class("delivery problem"), do: "deliv-tint-bad"
  defp delivery_status_tint_class(_status), do: "deliv-tint-unknown"

  defp recipient_initials(name) when is_binary(name) do
    name
    |> String.split(~r/\s+/, trim: true)
    |> Enum.map(&String.first/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.take(2)
    |> case do
      [] -> "?"
      initials -> initials |> Enum.join() |> String.upcase()
    end
  end

  defp recipient_initials(_name), do: "?"

  defp member_count_label(1), do: "1 member"
  defp member_count_label(count), do: "#{count} members"

  defp format_message_time(%DateTime{} = inserted_at) do
    Calendar.strftime(inserted_at, "%-d %b, %-I:%M%P")
  end

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
