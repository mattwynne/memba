defmodule MembaWeb.DeliveriesLive.Index do
  use MembaWeb, :live_view

  alias Memba.Messaging

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    deliveries = Messaging.list_operator_deliveries()

    {:ok,
     socket
     |> assign(:deliveries_count, length(deliveries))
     |> stream(:deliveries, deliveries, dom_id: &"delivery-row-#{&1.delivery_id}")}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <main id="deliveries-overview" class="mx-auto max-w-7xl space-y-6 p-6">
        <section class="space-y-2">
          <p class="text-sm font-semibold uppercase tracking-wide text-zinc-500">
            Operator overview
          </p>
          <h1 class="text-3xl font-bold tracking-tight text-zinc-900">Deliveries</h1>
          <p id="deliveries-summary" class="max-w-3xl text-zinc-600">
            Review detailed delivery records across messages, including provider reason text for
            delayed, bounced, and spam complaint reports.
          </p>
        </section>

        <section class="rounded-xl border border-zinc-200 bg-white shadow-sm">
          <div class="flex flex-col gap-2 border-b border-zinc-200 p-5 sm:flex-row sm:items-end sm:justify-between">
            <div>
              <h2 class="text-lg font-semibold text-zinc-900">Delivery records</h2>
              <p class="mt-1 text-sm text-zinc-500">
                Showing {@deliveries_count} delivery record{if(@deliveries_count == 1,
                  do: "",
                  else: "s"
                )}.
              </p>
            </div>
            <p class="text-sm text-zinc-500">Newest events first</p>
          </div>

          <div class="overflow-x-auto">
            <table
              id="deliveries-table"
              aria-label="Delivery records"
              class="min-w-full divide-y divide-zinc-200 text-left text-sm"
            >
              <thead class="bg-zinc-50 text-xs font-semibold uppercase tracking-wide text-zinc-500">
                <tr>
                  <th scope="col" class="px-4 py-3">Message</th>
                  <th scope="col" class="px-4 py-3">Recipient</th>
                  <th scope="col" class="px-4 py-3">Address</th>
                  <th scope="col" class="px-4 py-3">Channel</th>
                  <th scope="col" class="px-4 py-3">Status</th>
                  <th scope="col" class="px-4 py-3">Event time</th>
                  <th scope="col" class="px-4 py-3">Reason</th>
                </tr>
              </thead>
              <tbody
                id="deliveries-table-body"
                class="divide-y divide-zinc-100 bg-white"
                phx-update="stream"
              >
                <tr id="deliveries-empty" class="hidden only:table-row">
                  <td colspan="7" class="px-4 py-6 text-center text-sm text-zinc-500">
                    No delivery records.
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
                  class="transition-colors hover:bg-zinc-50"
                >
                  <td
                    data-test-id="delivery-message-subject"
                    class="max-w-xs px-4 py-4 font-medium text-zinc-900"
                  >
                    {message_subject(delivery)}
                  </td>
                  <td data-test-id="delivery-recipient-name" class="px-4 py-4 text-zinc-700">
                    {delivery.recipient_name}
                  </td>
                  <td data-test-id="delivery-recipient-address" class="px-4 py-4 text-zinc-600">
                    {delivery.recipient_address}
                  </td>
                  <td data-test-id="delivery-channel" class="px-4 py-4 text-zinc-600">
                    {delivery.channel}
                  </td>
                  <td class="px-4 py-4">
                    <span
                      data-test-id="delivery-status"
                      class={[
                        "inline-flex rounded-full px-2.5 py-1 text-xs font-semibold",
                        status_class(delivery.status)
                      ]}
                    >
                      {delivery.status}
                    </span>
                  </td>
                  <td
                    data-test-id="delivery-event-at"
                    class="whitespace-nowrap px-4 py-4 text-zinc-600"
                  >
                    {format_event_at(delivery.event_at)}
                  </td>
                  <td data-test-id="delivery-reason" class="max-w-sm px-4 py-4 text-zinc-600">
                    {reason_text(delivery.reason)}
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </section>
      </main>
    </Layouts.app>
    """
  end

  defp message_subject(%{message_subject: subject}) when is_binary(subject) and subject != "",
    do: subject

  defp message_subject(_delivery), do: "Untitled message"

  defp format_event_at(%DateTime{} = event_at) do
    Calendar.strftime(event_at, "%Y-%m-%d %H:%M:%S UTC")
  end

  defp format_event_at(nil), do: "Unknown"

  defp reason_text(reason) when is_binary(reason) and reason != "", do: reason
  defp reason_text(_reason), do: "—"

  defp status_class("delayed"), do: "bg-amber-100 text-amber-800"
  defp status_class("bounced"), do: "bg-red-100 text-red-800"
  defp status_class("spam complaint"), do: "bg-red-100 text-red-800"
  defp status_class("opened"), do: "bg-emerald-100 text-emerald-800"
  defp status_class("delivered"), do: "bg-blue-100 text-blue-800"
  defp status_class(_status), do: "bg-zinc-100 text-zinc-700"
end
