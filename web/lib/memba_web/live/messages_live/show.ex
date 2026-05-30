defmodule MembaWeb.MessagesLive.Show do
  use MembaWeb, :live_view

  alias Memba.Messaging

  @impl Phoenix.LiveView
  def mount(%{"message_id" => message_id}, _session, socket) do
    message = Messaging.get_message(message_id)
    deliveries = Messaging.list_recipient_deliveries(message_id)
    receipts = Messaging.list_member_receipts(message_id)

    {:ok,
     socket
     |> assign(:message_id, message_id)
     |> assign(:message, message)
     |> stream(:addressed_recipients, deliveries,
       dom_id: &"addressed-recipient-#{&1.delivery_id}"
     )
     |> stream(:delivery_records, deliveries, dom_id: &"delivery-record-#{&1.delivery_id}")
     |> stream(:member_receipts, receipts, dom_id: &"member-receipt-#{&1.delivery_id}")}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <main id="message-show" class="mx-auto max-w-6xl space-y-8 p-6">
        <%= if @message do %>
          <section class="space-y-2">
            <.link
              id="back-to-club-link"
              navigate={~p"/clubs/#{@message.club_id}"}
              aria-label="Back to club"
              class="text-sm font-medium text-blue-700 hover:text-blue-900"
            >
              ← Club
            </.link>
            <p class="text-sm font-semibold uppercase tracking-wide text-zinc-500">Message</p>
            <h1 class="text-3xl font-bold tracking-tight text-zinc-900">{@message.subject}</h1>
            <p class="max-w-3xl whitespace-pre-wrap text-zinc-700">{@message.body}</p>
          </section>

          <section class="rounded-xl border border-zinc-200 bg-white p-5 shadow-sm">
            <h2 class="text-lg font-semibold text-zinc-900">Addressed recipients</h2>
            <div
              id="addressed-recipients"
              aria-label="Addressed recipients"
              class="mt-4 divide-y divide-zinc-100"
              phx-update="stream"
            >
              <p id="addressed-recipients-empty" class="hidden py-4 text-sm text-zinc-500 only:block">
                No addressed recipients.
              </p>
              <div
                :for={{dom_id, delivery} <- @streams.addressed_recipients}
                id={dom_id}
                data-testid="addressed-recipient"
                data-delivery-id={delivery.delivery_id}
                data-recipient-id={delivery.recipient_id}
                data-recipient-name={delivery.recipient_name}
                aria-label={"Addressed recipient #{delivery.recipient_name}"}
                class="py-3"
              >
                <p class="font-medium text-zinc-900">{delivery.recipient_name}</p>
                <p class="text-sm text-zinc-500">{delivery.recipient_address}</p>
              </div>
            </div>
          </section>

          <section class="rounded-xl border border-zinc-200 bg-white p-5 shadow-sm">
            <h2 class="text-lg font-semibold text-zinc-900">Delivery records</h2>
            <div
              id="delivery-records"
              aria-label="Delivery records"
              class="mt-4 divide-y divide-zinc-100"
              phx-update="stream"
            >
              <p id="delivery-records-empty" class="hidden py-4 text-sm text-zinc-500 only:block">
                No delivery records.
              </p>
              <div
                :for={{dom_id, delivery} <- @streams.delivery_records}
                id={dom_id}
                data-testid="delivery-record"
                data-delivery-id={delivery.delivery_id}
                data-recipient-id={delivery.recipient_id}
                data-recipient-name={delivery.recipient_name}
                aria-label={"Delivery record for #{delivery.recipient_name}"}
                class="grid gap-2 py-3 sm:grid-cols-4"
              >
                <p class="font-medium text-zinc-900">{delivery.recipient_name}</p>
                <p class="text-sm text-zinc-500">{delivery.recipient_address}</p>
                <p class="text-sm text-zinc-500">{delivery.channel}</p>
                <p
                  id={"delivery-status-#{delivery.delivery_id}"}
                  data-testid="delivery-status"
                  data-delivery-status={delivery.status}
                  aria-label={"Delivery status for #{delivery.recipient_name}: #{delivery.status}"}
                  class="text-sm font-medium text-zinc-700"
                >
                  {delivery.status}
                </p>
              </div>
            </div>
          </section>

          <section class="rounded-xl border border-zinc-200 bg-white p-5 shadow-sm">
            <h2 class="text-lg font-semibold text-zinc-900">Member receipt statuses</h2>
            <div
              id="member-receipts"
              aria-label="Member receipt statuses"
              class="mt-4 divide-y divide-zinc-100"
              phx-update="stream"
            >
              <p id="member-receipts-empty" class="hidden py-4 text-sm text-zinc-500 only:block">
                No member receipts.
              </p>
              <div
                :for={{dom_id, receipt} <- @streams.member_receipts}
                id={dom_id}
                data-testid="member-receipt"
                data-delivery-id={receipt.delivery_id}
                data-recipient-id={receipt.recipient_id}
                data-recipient-name={receipt.recipient_name}
                aria-label={"Member receipt for #{receipt.recipient_name}"}
                class="flex items-center justify-between gap-4 py-3"
              >
                <p class="font-medium text-zinc-900">{receipt.recipient_name}</p>
                <p
                  id={"receipt-status-#{receipt.delivery_id}"}
                  data-testid="receipt-status"
                  data-receipt-status={receipt.receipt_status}
                  aria-label={"Receipt status for #{receipt.recipient_name}: #{receipt.receipt_status}"}
                  class="rounded-full bg-zinc-100 px-3 py-1 text-sm font-medium text-zinc-700"
                >
                  {receipt.receipt_status}
                </p>
              </div>
            </div>
          </section>
        <% else %>
          <section class="rounded-xl border border-zinc-200 bg-white p-5 shadow-sm">
            <h1 class="text-2xl font-bold text-zinc-900">Message not found</h1>
            <p class="mt-2 text-zinc-600">No projected message exists for this URL.</p>
          </section>
        <% end %>
      </main>
    </Layouts.app>
    """
  end
end
