defmodule MembaWeb.Admin.MessagesLive.Index do
  use MembaWeb, :live_view

  alias Memba.Messaging

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     stream(socket, :messages, Messaging.list_operator_messages(),
       dom_id: &"message-row-#{&1.message_id}"
     )}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.admin flash={@flash}>
      <main id="admin-messages-index" class="mx-auto max-w-7xl space-y-6 p-6">
        <section class="space-y-2">
          <p class="text-sm font-semibold uppercase tracking-wide text-[#7d877f]">
            Memba staff operations
          </p>
          <h1 class="text-3xl font-bold tracking-tight text-[#15201c]">Messages</h1>
          <p class="max-w-3xl text-[#4b5a55]">
            Review projected club messages and open the existing delivery diagnostics for a
            message.
          </p>
        </section>

        <section
          id="admin-messages-read-only-notice"
          class="rounded-2xl border border-[#d6d2c8] bg-[#e6ece4] p-4 text-sm text-[#1f4842]"
        >
          This index is read-only in this slice. Message composition and delivery actions remain
          outside the Memba staff operations area.
        </section>

        <section class="overflow-hidden rounded-2xl border border-[#e6e3dc] bg-white shadow-sm">
          <div class="border-b border-[#e6e3dc] p-5">
            <h2 class="text-lg font-semibold text-[#15201c]">Projected messages</h2>
            <p class="mt-1 text-sm text-[#7d877f]">
              Newest projected messages first, with club and sender context where available.
            </p>
          </div>

          <div class="overflow-x-auto">
            <table
              id="admin-messages-table"
              aria-label="Messages"
              class="min-w-full divide-y divide-[#e6e3dc] text-left text-sm"
            >
              <thead class="bg-[#f7f6f3] text-xs font-semibold uppercase tracking-wide text-[#7d877f]">
                <tr>
                  <th scope="col" class="px-4 py-3">Subject</th>
                  <th scope="col" class="px-4 py-3">Club</th>
                  <th scope="col" class="px-4 py-3">Sender</th>
                  <th scope="col" class="px-4 py-3">Projected</th>
                  <th scope="col" class="px-4 py-3">Diagnostics</th>
                </tr>
              </thead>
              <tbody
                id="admin-messages-table-body"
                class="divide-y divide-[#e6e3dc]"
                phx-update="stream"
              >
                <tr id="admin-messages-empty" class="hidden only:table-row">
                  <td colspan="5" class="px-4 py-6 text-center text-sm text-[#7d877f]">
                    No projected messages to show yet.
                  </td>
                </tr>
                <tr
                  :for={{dom_id, message} <- @streams.messages}
                  id={dom_id}
                  data-testid="admin-message-row"
                  data-message-id={message.message_id}
                  data-message-subject={message.subject}
                >
                  <td data-testid="admin-message-subject" class="px-4 py-4 font-medium text-[#15201c]">
                    {subject_label(message.subject)}
                  </td>
                  <td data-testid="admin-message-club" class="px-4 py-4 text-[#4b5a55]">
                    {club_label(message)}
                  </td>
                  <td data-testid="admin-message-sender" class="px-4 py-4 text-[#4b5a55]">
                    {sender_label(message)}
                  </td>
                  <td data-testid="admin-message-projected-at" class="px-4 py-4 text-[#4b5a55]">
                    {format_projected_at(message.projected_at)}
                  </td>
                  <td class="px-4 py-4">
                    <.link
                      navigate={~p"/admin/messages/#{message.message_id}"}
                      class="font-semibold text-[#1f4842] hover:text-[#15201c]"
                    >
                      Open diagnostics
                    </.link>
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

  defp subject_label(subject) when is_binary(subject) and subject != "", do: subject
  defp subject_label(_subject), do: "Untitled message"

  defp club_label(%{club_name: name}) when is_binary(name) and name != "", do: name
  defp club_label(%{club_id: club_id}) when is_binary(club_id) and club_id != "", do: club_id
  defp club_label(_message), do: "Unknown club"

  defp sender_label(%{sender_name: name, sender_email: email})
       when is_binary(name) and name != "" and is_binary(email) and email != "" do
    "#{name} (#{email})"
  end

  defp sender_label(%{sender_name: name}) when is_binary(name) and name != "", do: name
  defp sender_label(%{sender_email: email}) when is_binary(email) and email != "", do: email

  defp sender_label(%{sender_id: sender_id}) when is_binary(sender_id) and sender_id != "",
    do: sender_id

  defp sender_label(_message), do: "Unknown sender"

  defp format_projected_at(%DateTime{} = projected_at) do
    Calendar.strftime(projected_at, "%Y-%m-%d %H:%M:%S UTC")
  end

  defp format_projected_at(nil), do: "Unknown"
end
