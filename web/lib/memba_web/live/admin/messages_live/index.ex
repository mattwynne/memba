defmodule MembaWeb.Admin.MessagesLive.Index do
  use MembaWeb, :live_view

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :messages, [], dom_id: &"message-row-#{&1.message_id}")}
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
              Messages will appear once the global message summary read model is wired.
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
                <tr :for={{dom_id, message} <- @streams.messages} id={dom_id}>
                  <td class="px-4 py-4 font-medium text-[#15201c]">{message.subject}</td>
                  <td class="px-4 py-4 text-[#4b5a55]">{message.club_name}</td>
                  <td class="px-4 py-4 text-[#4b5a55]">{message.sender_name}</td>
                  <td class="px-4 py-4 text-[#4b5a55]">{message.projected_at}</td>
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
end
