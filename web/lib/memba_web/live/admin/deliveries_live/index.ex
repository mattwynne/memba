defmodule MembaWeb.Admin.DeliveriesLive.Index do
  use MembaWeb, :live_view

  alias Memba.Messaging
  alias Memba.ReadModelChanges

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    deliveries = Messaging.list_operator_deliveries()

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Memba.PubSub, ReadModelChanges.topic())
    end

    {:ok, assign_deliveries(socket, deliveries)}
  end

  @impl Phoenix.LiveView
  def handle_info(
        {:read_model_changed, %{projector: Memba.Messaging.Projectors.MembaStaffEmailDelivery}},
        socket
      ) do
    {:noreply, refresh_deliveries(socket)}
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.admin flash={@flash} current_identity={@current_identity} active={:deliveries}>
      <main
        id="deliveries-overview"
        data-admin-page="deliveries"
        class="space-y-6 p-6"
      >
        <.admin_page_header
          eyebrow="Deliveries"
          title="Deliveries"
          description="Detailed email deliveries across messages, including provider reason text for delayed, bounced, and spam complaint reports."
        />

        <section
          id="deliveries-summary-cards"
          aria-label="Delivery diagnostics summary"
          class="grid gap-4 md:grid-cols-3"
        >
          <article class="rounded-xl border border-[#e0ddd4] bg-white p-5 shadow-sm">
            <p class="text-xs font-bold uppercase tracking-[0.08em] text-[#7d877f]">
              Delivery records
            </p>
            <p
              id="deliveries-summary-total"
              class="mt-3 text-3xl font-bold tracking-tight text-[#15201c]"
            >
              {@deliveries_count}
            </p>
            <p class="mt-1 text-sm text-[#4b5a55]">Projected diagnostics rows.</p>
          </article>

          <article class="rounded-xl border border-[#e0ddd4] bg-white p-5 shadow-sm">
            <p class="text-xs font-bold uppercase tracking-[0.08em] text-[#7d877f]">
              Problem reports
            </p>
            <p class="mt-3 text-3xl font-bold tracking-tight text-[#15201c]">
              {@problem_count}
            </p>
            <p class="mt-1 text-sm text-[#4b5a55]">Delayed, bounced, or complaint statuses.</p>
          </article>

          <article class="rounded-xl border border-[#e0ddd4] bg-white p-5 shadow-sm">
            <p class="text-xs font-bold uppercase tracking-[0.08em] text-[#7d877f]">
              Provider context
            </p>
            <p class="mt-3 text-lg font-semibold text-[#15201c]">Reason text preserved</p>
            <p class="mt-1 text-sm text-[#4b5a55]">Raw provider details stay visible for staff.</p>
          </article>
        </section>

        <section id="deliveries-diagnostics-note" class="sr-only">
          This page is a read-only operations view of existing delivery diagnostics. It does not add resend, delete, bulk action, or filtering behaviour in this slice.
        </section>

        <.admin_toolbar
          id="deliveries-toolbar"
          summary_label="All"
          summary_count={@deliveries_count}
          meta="Newest events first"
        >
          <:chips :for={{status, count} <- @status_counts}>
            <.admin_pill label={status_label(status)} count={count} />
          </:chips>
        </.admin_toolbar>

        <.admin_table_card
          id="deliveries-table-card"
          title="Email deliveries"
          description={"Showing #{@deliveries_count} email delivery#{if(@deliveries_count == 1, do: "", else: "s")}."}
        >
          <div class="overflow-x-auto">
            <table
              id="deliveries-table"
              aria-label="Email deliveries"
              class="min-w-full text-left text-sm"
            >
              <thead class="bg-[#efede8] text-xs font-bold uppercase tracking-[0.08em] text-[#7d877f]">
                <tr>
                  <th scope="col" class="px-4 py-3">Recipient</th>
                  <th scope="col" class="px-4 py-3">Club</th>
                  <th scope="col" class="px-4 py-3">Message</th>
                  <th scope="col" class="px-4 py-3">Status</th>
                  <th scope="col" class="px-4 py-3">Provider event</th>
                  <th scope="col" class="px-4 py-3">Time</th>
                  <th scope="col" class="px-4 py-3">Message ID</th>
                </tr>
              </thead>
              <tbody
                id="deliveries-table-body"
                class="divide-y divide-[#e6e3dc]"
                phx-update="stream"
              >
                <tr id="deliveries-empty" class="hidden only:table-row">
                  <td colspan="7" class="px-4 py-6 text-center text-sm text-[#7d877f]">
                    No email deliveries.
                  </td>
                </tr>
                <tr
                  :for={{dom_id, delivery} <- @streams.deliveries}
                  id={dom_id}
                  data-test-id={"delivery-row-#{delivery.delivery_id}"}
                  data-delivery-id={delivery.delivery_id}
                  data-message-id={delivery.message_id}
                  data-recipient-id={delivery.recipient_id}
                  data-recipient-name={delivery.recipient_name}
                  data-delivery-status={delivery.status}
                  aria-label={"Delivery for #{delivery.recipient_name} on #{message_subject(delivery)}"}
                  class="transition-colors hover:bg-[#fbfaf8]"
                >
                  <td data-test-id="delivery-recipient-name" class="px-4 py-3.5">
                    <.admin_identity_cell
                      initials={recipient_initials(delivery.recipient_name)}
                      title={delivery.recipient_name}
                      subtitle={delivery.recipient_address}
                      tone="muted"
                    />
                  </td>
                  <td class="px-4 py-3.5 text-[#4b5a55]">{club_name(delivery)}</td>
                  <td
                    data-test-id="delivery-message-subject"
                    class="max-w-xs px-4 py-3.5 font-medium text-[#15201c]"
                  >
                    {message_subject(delivery)}
                  </td>
                  <td class="px-4 py-3.5">
                    <.status_badge
                      data-test-id="delivery-status"
                      label={delivery.status}
                      tone={status_tone(delivery.status)}
                    />
                  </td>
                  <td
                    data-test-id="delivery-reason"
                    class="max-w-sm px-4 py-3.5 font-mono text-xs text-[#4b5a55]"
                  >
                    {reason_text(delivery.reason)}
                  </td>
                  <td
                    data-test-id="delivery-event-at"
                    class="whitespace-nowrap px-4 py-3.5 text-[#4b5a55]"
                  >
                    {format_event_at(delivery.event_at)}
                  </td>
                  <td class="px-4 py-3.5 font-mono text-xs text-[#7d877f]">
                    {short_id(delivery.message_id)}
                  </td>
                  <td data-test-id="delivery-recipient-address" class="hidden">
                    {delivery.recipient_address}
                  </td>
                  <td data-test-id="delivery-channel" class="hidden">{delivery.channel}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </.admin_table_card>
      </main>
    </Layouts.admin>
    """
  end

  defp message_subject(%{message_subject: subject}) when is_binary(subject) and subject != "",
    do: subject

  defp message_subject(_delivery), do: "Untitled message"

  defp club_name(%{club_name: name}) when is_binary(name) and name != "", do: name
  defp club_name(%{club_id: club_id}) when is_binary(club_id) and club_id != "", do: club_id
  defp club_name(_delivery), do: "Unknown club"

  defp format_event_at(%DateTime{} = event_at) do
    Calendar.strftime(event_at, "%Y-%m-%d %H:%M:%S UTC")
  end

  defp format_event_at(nil), do: "Unknown"

  defp reason_text(reason) when is_binary(reason) and reason != "", do: reason
  defp reason_text(_reason), do: "—"

  defp status_tone("delayed"), do: "warning"
  defp status_tone("bounced"), do: "error"
  defp status_tone("spam complaint"), do: "error"
  defp status_tone("delivered"), do: "info"
  defp status_tone(_status), do: "neutral"

  defp status_label(status), do: status |> to_string() |> String.capitalize()

  defp refresh_deliveries(socket) do
    Messaging.list_operator_deliveries()
    |> then(&assign_deliveries(socket, &1, reset: true))
  end

  defp assign_deliveries(socket, deliveries, stream_opts \\ []) do
    stream_opts = Keyword.merge([dom_id: &"delivery-row-#{&1.delivery_id}"], stream_opts)
    status_counts = deliveries |> Enum.frequencies_by(& &1.status) |> Enum.sort_by(&elem(&1, 0))

    problem_count =
      Enum.count(deliveries, fn delivery ->
        delivery.status in ["delayed", "bounced", "spam complaint"]
      end)

    socket
    |> assign(:deliveries_count, length(deliveries))
    |> assign(:problem_count, problem_count)
    |> assign(:status_counts, status_counts)
    |> stream(:deliveries, deliveries, stream_opts)
  end

  defp recipient_initials(name) when is_binary(name) do
    name
    |> String.split(~r/\s+/, trim: true)
    |> Enum.take(2)
    |> Enum.map(&String.first/1)
    |> Enum.join()
    |> String.upcase()
    |> case do
      "" -> "?"
      initials -> initials
    end
  end

  defp recipient_initials(_name), do: "?"

  defp short_id(id) when is_binary(id), do: String.slice(id, 0, 8)
  defp short_id(_id), do: "—"
end
