defmodule MembaWeb.Admin.MessagesLive.Show do
  use MembaWeb, :live_view

  alias Memba.Messaging
  alias Memba.ReadModelChanges

  @impl Phoenix.LiveView
  def mount(%{"message_id" => message_id}, _session, socket) do
    message = Messaging.get_message(message_id)
    deliveries = Messaging.list_recipient_deliveries(message_id)
    receipts = Messaging.list_member_email_deliverys(message_id)

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Memba.PubSub, ReadModelChanges.topic())
    end

    {:ok,
     socket
     |> assign(:message_id, message_id)
     |> assign(:message, message)
     |> assign(:addressed_recipient_count, length(deliveries))
     |> assign(:delivery_record_count, length(deliveries))
     |> assign(:member_receipt_count, length(receipts))
     |> stream(:addressed_recipients, deliveries,
       dom_id: &"addressed-recipient-#{&1.delivery_id}"
     )
     |> stream(:delivery_records, deliveries, dom_id: &"delivery-record-#{&1.delivery_id}")
     |> stream(:member_email_deliverys, receipts, dom_id: &"member-receipt-#{&1.delivery_id}")}
  end

  @impl Phoenix.LiveView
  def handle_info(
        {:read_model_changed, %{projector: projector, source_event: event}},
        %{assigns: %{message_id: message_id}} = socket
      )
      when projector in [
             Memba.Messaging.Projectors.EmailDelivery,
             Memba.Messaging.Projectors.MemberEmailDelivery
           ] do
    if Map.get(event, :message_id) == message_id do
      {:noreply, refresh_delivery_streams(socket)}
    else
      {:noreply, socket}
    end
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.admin flash={@flash} current_identity={@current_identity} active={:messages}>
      <main
        id="message-show"
        data-admin-page="message-diagnostics"
        class="mx-auto max-w-7xl space-y-6 p-6"
      >
        <%= if @message do %>
          <section class="space-y-3">
            <.link
              id="back-to-club-link"
              navigate={~p"/admin/clubs/#{@message.club_id}"}
              aria-label="Back to club"
              class="inline-flex items-center gap-2 text-sm font-semibold text-[#1f4842] hover:text-[#15201c]"
            >
              ← Club
            </.link>
            <div class="space-y-2">
              <p class="text-sm font-semibold uppercase tracking-wide text-[#7d877f]">
                Memba staff operations
              </p>
              <h1 class="text-3xl font-bold tracking-tight text-[#15201c]">
                {subject_label(@message.subject)}
              </h1>
              <p class="max-w-3xl text-[#4b5a55]">
                Review the existing delivery diagnostics for this projected club message.
              </p>
            </div>
          </section>

          <section
            id="message-diagnostics-summary-cards"
            aria-label="Message delivery diagnostics summary"
            class="grid gap-4 md:grid-cols-3"
          >
            <article class="rounded-2xl border border-[#e6e3dc] bg-white p-5 shadow-sm">
              <p class="text-xs font-semibold uppercase tracking-wide text-[#7d877f]">
                Addressed recipients
              </p>
              <p class="mt-3 text-3xl font-bold tracking-tight text-[#15201c]">
                {@addressed_recipient_count}
              </p>
              <p class="mt-1 text-sm text-[#4b5a55]">
                Recipients captured when the message was sent.
              </p>
            </article>

            <article class="rounded-2xl border border-[#e6e3dc] bg-white p-5 shadow-sm">
              <p class="text-xs font-semibold uppercase tracking-wide text-[#7d877f]">
                Email deliveries
              </p>
              <p class="mt-3 text-3xl font-bold tracking-tight text-[#15201c]">
                {@delivery_record_count}
              </p>
              <p class="mt-1 text-sm text-[#4b5a55]">
                Raw delivery records for this message.
              </p>
            </article>

            <article class="rounded-2xl border border-[#e6e3dc] bg-white p-5 shadow-sm">
              <p class="text-xs font-semibold uppercase tracking-wide text-[#7d877f]">
                Member receipts
              </p>
              <p class="mt-3 text-3xl font-bold tracking-tight text-[#15201c]">
                {@member_receipt_count}
              </p>
              <p class="mt-1 text-sm text-[#4b5a55]">
                Member-facing status projections for receipt views.
              </p>
            </article>
          </section>

          <section
            id="message-diagnostics-note"
            class="rounded-2xl border border-[#d6d2c8] bg-[#e6ece4] p-4 text-sm text-[#1f4842]"
          >
            This page is read-only diagnostics for one existing message. It does not add resend,
            delete, bulk action, filtering, or staff-side message composition behaviour in this
            slice.
          </section>

          <section
            id="message-body-card"
            class="rounded-2xl border border-[#e6e3dc] bg-white p-5 shadow-sm"
          >
            <p class="text-xs font-semibold uppercase tracking-wide text-[#7d877f]">Message body</p>
            <p class="mt-3 max-w-4xl whitespace-pre-wrap text-[#4b5a55]">{@message.body}</p>
          </section>

          <section
            id="addressed-recipients-card"
            class="overflow-hidden rounded-2xl border border-[#e6e3dc] bg-white shadow-sm"
          >
            <div class="border-b border-[#e6e3dc] p-5">
              <h2 class="text-lg font-semibold text-[#15201c]">Addressed recipients</h2>
              <p class="mt-1 text-sm text-[#7d877f]">
                Original recipient names and email addresses from the message send command.
              </p>
            </div>
            <div
              id="addressed-recipients"
              aria-label="Addressed recipients"
              class="divide-y divide-[#e6e3dc]"
              phx-update="stream"
            >
              <p
                id="addressed-recipients-empty"
                class="hidden px-5 py-4 text-sm text-[#7d877f] only:block"
              >
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
                class="grid gap-2 px-5 py-4 transition-colors hover:bg-[#fbfaf8] sm:grid-cols-[minmax(0,1fr)_minmax(0,1.5fr)]"
              >
                <p class="font-medium text-[#15201c]">{delivery.recipient_name}</p>
                <p class="text-sm text-[#4b5a55]">{delivery.recipient_address}</p>
              </div>
            </div>
          </section>

          <section
            id="delivery-records-card"
            class="overflow-hidden rounded-2xl border border-[#e6e3dc] bg-white shadow-sm"
          >
            <div class="border-b border-[#e6e3dc] p-5">
              <h2 class="text-lg font-semibold text-[#15201c]">Email deliveries</h2>
              <p class="mt-1 text-sm text-[#7d877f]">
                Existing per-recipient delivery projection for this message.
              </p>
            </div>
            <div
              id="delivery-records"
              aria-label="Email deliveries"
              class="divide-y divide-[#e6e3dc]"
              phx-update="stream"
            >
              <p
                id="delivery-records-empty"
                class="hidden px-5 py-4 text-sm text-[#7d877f] only:block"
              >
                No email deliveries.
              </p>
              <div
                :for={{dom_id, delivery} <- @streams.delivery_records}
                id={dom_id}
                data-testid="delivery-record"
                data-delivery-id={delivery.delivery_id}
                data-recipient-id={delivery.recipient_id}
                data-recipient-name={delivery.recipient_name}
                aria-label={"Email delivery for #{delivery.recipient_name}"}
                class="grid gap-3 px-5 py-4 transition-colors hover:bg-[#fbfaf8] sm:grid-cols-[minmax(0,1fr)_minmax(0,1.4fr)_minmax(0,0.7fr)_minmax(0,0.7fr)]"
              >
                <p class="font-medium text-[#15201c]">{delivery.recipient_name}</p>
                <p class="text-sm text-[#4b5a55]">{delivery.recipient_address}</p>
                <p class="text-sm text-[#4b5a55]">{delivery.channel}</p>
                <p
                  id={"delivery-status-#{delivery.delivery_id}"}
                  data-testid="delivery-status"
                  data-delivery-status={delivery.status}
                  aria-label={"Delivery status for #{delivery.recipient_name}: #{delivery.status}"}
                  class={[
                    "inline-flex w-fit rounded-full px-2.5 py-1 text-xs font-semibold",
                    delivery_status_class(delivery.status)
                  ]}
                >
                  {delivery.status}
                </p>
              </div>
            </div>
          </section>

          <section
            id="member-receipts-card"
            class="overflow-hidden rounded-2xl border border-[#e6e3dc] bg-white shadow-sm"
          >
            <div class="border-b border-[#e6e3dc] p-5">
              <h2 class="text-lg font-semibold text-[#15201c]">Member email delivery statuses</h2>
              <p class="mt-1 text-sm text-[#7d877f]">
                Simplified member-facing receipt statuses remain visible for comparison.
              </p>
            </div>
            <div
              id="member-receipts"
              aria-label="Member email delivery statuses"
              class="divide-y divide-[#e6e3dc]"
              phx-update="stream"
            >
              <p id="member-receipts-empty" class="hidden px-5 py-4 text-sm text-[#7d877f] only:block">
                No member email deliveries.
              </p>
              <div
                :for={{dom_id, receipt} <- @streams.member_email_deliverys}
                id={dom_id}
                data-testid="member-receipt"
                data-delivery-id={receipt.delivery_id}
                data-recipient-id={receipt.recipient_id}
                data-recipient-name={receipt.recipient_name}
                aria-label={"Member email delivery for #{receipt.recipient_name}"}
                class="flex items-center justify-between gap-4 px-5 py-4 transition-colors hover:bg-[#fbfaf8]"
              >
                <p class="font-medium text-[#15201c]">{receipt.recipient_name}</p>
                <p
                  id={"receipt-status-#{receipt.delivery_id}"}
                  data-testid="receipt-status"
                  data-receipt-status={receipt.status}
                  aria-label={"Status for #{receipt.recipient_name}: #{receipt.status}"}
                  class={[
                    "rounded-full px-3 py-1 text-sm font-medium",
                    receipt_status_class(receipt.status)
                  ]}
                >
                  {receipt.status}
                </p>
              </div>
            </div>
          </section>
        <% else %>
          <section class="rounded-2xl border border-[#e6e3dc] bg-white p-5 shadow-sm">
            <p class="text-sm font-semibold uppercase tracking-wide text-[#7d877f]">
              Memba staff operations
            </p>
            <h1 class="mt-2 text-2xl font-bold text-[#15201c]">Message not found</h1>
            <p class="mt-2 text-[#4b5a55]">No projected message exists for this URL.</p>
          </section>
        <% end %>
      </main>
    </Layouts.admin>
    """
  end

  defp refresh_delivery_streams(socket) do
    message_id = socket.assigns.message_id
    deliveries = Messaging.list_recipient_deliveries(message_id)
    receipts = Messaging.list_member_email_deliverys(message_id)

    socket
    |> stream(:delivery_records, deliveries, reset: true)
    |> stream(:member_email_deliverys, receipts, reset: true)
  end

  defp subject_label(subject) when is_binary(subject) and subject != "", do: subject
  defp subject_label(_subject), do: "Untitled message"

  defp delivery_status_class("delayed"), do: "bg-[#f3ecd8] text-[#7a5416]"
  defp delivery_status_class("bounced"), do: "bg-[#f6e0c9] text-[#8a3d21]"
  defp delivery_status_class("spam complaint"), do: "bg-[#f6e0c9] text-[#8a3d21]"
  defp delivery_status_class("delivered"), do: "bg-[#e6ece4] text-[#1f4842]"
  defp delivery_status_class(_status), do: "bg-[#f7f6f3] text-[#4b5a55]"

  defp receipt_status_class("delivery problem"), do: "bg-[#f6e0c9] text-[#8a3d21]"
  defp receipt_status_class("delivered"), do: "bg-[#e6ece4] text-[#1f4842]"
  defp receipt_status_class(_status), do: "bg-[#f7f6f3] text-[#4b5a55]"
end
