defmodule MembaWeb.Admin.DeliveriesLive.Index do
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
    <Layouts.admin flash={@flash}>
      <main
        id="deliveries-overview"
        data-admin-page="deliveries"
        class="mx-auto max-w-7xl space-y-6 p-6"
      >
        <section class="space-y-2">
          <p class="text-sm font-semibold uppercase tracking-wide text-[#7d877f]">
            Memba staff operations
          </p>
          <h1 class="text-3xl font-bold tracking-tight text-[#15201c]">Deliveries</h1>
          <p id="deliveries-summary" class="max-w-3xl text-[#4b5a55]">
            Review detailed email deliveries across messages, including provider reason text for
            delayed, bounced, and spam complaint reports.
          </p>
        </section>

        <section
          id="deliveries-summary-cards"
          aria-label="Delivery diagnostics summary"
          class="grid gap-4 md:grid-cols-3"
        >
          <article class="rounded-2xl border border-[#e6e3dc] bg-white p-5 shadow-sm">
            <p class="text-xs font-semibold uppercase tracking-wide text-[#7d877f]">
              Delivery records
            </p>
            <p
              id="deliveries-summary-total"
              class="mt-3 text-3xl font-bold tracking-tight text-[#15201c]"
            >
              {@deliveries_count}
            </p>
            <p class="mt-1 text-sm text-[#4b5a55]">
              Total projected email delivery diagnostics rows.
            </p>
          </article>

          <article class="rounded-2xl border border-[#e6e3dc] bg-white p-5 shadow-sm">
            <p class="text-xs font-semibold uppercase tracking-wide text-[#7d877f]">
              Operator detail
            </p>
            <p class="mt-3 text-lg font-semibold text-[#15201c]">Raw staff statuses</p>
            <p class="mt-1 text-sm text-[#4b5a55]">
              Staff see detailed delivery states, not the simplified member-facing vocabulary.
            </p>
          </article>

          <article class="rounded-2xl border border-[#e6e3dc] bg-white p-5 shadow-sm">
            <p class="text-xs font-semibold uppercase tracking-wide text-[#7d877f]">
              Provider context
            </p>
            <p class="mt-3 text-lg font-semibold text-[#15201c]">Reason text preserved</p>
            <p class="mt-1 text-sm text-[#4b5a55]">
              Delays, bounces, and spam complaints keep provider reason text for diagnosis.
            </p>
          </article>
        </section>

        <section
          id="deliveries-diagnostics-note"
          class="rounded-2xl border border-[#d6d2c8] bg-[#e6ece4] p-4 text-sm text-[#1f4842]"
        >
          This page is a read-only operations view of existing delivery diagnostics. It does not
          add resend, delete, bulk action, or filtering behaviour in this slice.
        </section>

        <section
          id="deliveries-table-card"
          class="overflow-hidden rounded-2xl border border-[#e6e3dc] bg-white shadow-sm"
        >
          <div class="flex flex-col gap-2 border-b border-[#e6e3dc] p-5 sm:flex-row sm:items-end sm:justify-between">
            <div>
              <h2 class="text-lg font-semibold text-[#15201c]">Email deliveries</h2>
              <p class="mt-1 text-sm text-[#7d877f]">
                Showing {@deliveries_count} email delivery{if(@deliveries_count == 1,
                  do: "",
                  else: "s"
                )}.
              </p>
            </div>
            <p class="text-sm font-medium text-[#7d877f]">Newest events first</p>
          </div>

          <div class="overflow-x-auto">
            <table
              id="deliveries-table"
              aria-label="Email deliveries"
              class="min-w-full divide-y divide-[#e6e3dc] text-left text-sm"
            >
              <thead class="bg-[#f7f6f3] text-xs font-semibold uppercase tracking-wide text-[#7d877f]">
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
                  <td
                    data-test-id="delivery-message-subject"
                    class="max-w-xs px-4 py-4 font-medium text-[#15201c]"
                  >
                    {message_subject(delivery)}
                  </td>
                  <td data-test-id="delivery-recipient-name" class="px-4 py-4 text-[#4b5a55]">
                    {delivery.recipient_name}
                  </td>
                  <td data-test-id="delivery-recipient-address" class="px-4 py-4 text-[#4b5a55]">
                    {delivery.recipient_address}
                  </td>
                  <td data-test-id="delivery-channel" class="px-4 py-4 text-[#4b5a55]">
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
                    class="whitespace-nowrap px-4 py-4 text-[#4b5a55]"
                  >
                    {format_event_at(delivery.event_at)}
                  </td>
                  <td data-test-id="delivery-reason" class="max-w-sm px-4 py-4 text-[#4b5a55]">
                    {reason_text(delivery.reason)}
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </section>
      </main>
    </Layouts.admin>
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

  defp status_class("delayed"), do: "bg-[#f3ecd8] text-[#7a5416]"
  defp status_class("bounced"), do: "bg-[#f6e0c9] text-[#8a3d21]"
  defp status_class("spam complaint"), do: "bg-[#f6e0c9] text-[#8a3d21]"
  defp status_class("delivered"), do: "bg-[#e6ece4] text-[#1f4842]"
  defp status_class(_status), do: "bg-[#f7f6f3] text-[#4b5a55]"
end
