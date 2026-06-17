defmodule MembaWeb.Admin.MessagesLive.Index do
  use MembaWeb, :live_view

  alias Memba.Messaging

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    messages = Messaging.list_operator_messages()

    {:ok,
     socket
     |> assign(:message_count, length(messages))
     |> stream(:messages, messages, dom_id: &"message-row-#{&1.message_id}")}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.admin flash={@flash} current_identity={@current_identity} active={:messages}>
      <main id="admin-messages-index" class="space-y-6 p-6">
        <.admin_page_header
          eyebrow="Messages"
          title="Messages"
          description="Read-only club message diagnostics across clubs. Open a row to inspect delivery details."
        />

        <section id="admin-messages-read-only-notice" class="sr-only">
          This index is read-only in this slice. Message composition and delivery actions remain outside the Memba staff operations area.
        </section>

        <.admin_toolbar
          id="admin-messages-toolbar"
          summary_label="All"
          summary_count={@message_count}
        />

        <.admin_table_card
          id="admin-messages-table-card"
          title="Projected messages"
          description="Newest projected messages first, with club and sender context where available."
        >
          <div class="overflow-x-auto">
            <table
              id="admin-messages-table"
              aria-label="Messages"
              class="min-w-full text-left text-sm"
            >
              <thead class="bg-[#efede8] text-xs font-bold uppercase tracking-[0.08em] text-[#7d877f]">
                <tr>
                  <th scope="col" class="px-4 py-3">Message</th>
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
                  class="transition-colors hover:bg-[#fbfaf8]"
                >
                  <td class="px-4 py-3.5">
                    <.admin_identity_cell
                      initials="✉"
                      title={subject_label(message.subject)}
                      subtitle={"From #{sender_label(message)}"}
                      link={~p"/admin/messages/#{message.message_id}"}
                      testid="admin-message-subject"
                    />
                  </td>
                  <td data-testid="admin-message-club" class="px-4 py-3.5 text-[#4b5a55]">
                    {club_label(message)}
                  </td>
                  <td data-testid="admin-message-sender" class="px-4 py-3.5 text-[#4b5a55]">
                    {sender_label(message)}
                  </td>
                  <td
                    data-testid="admin-message-projected-at"
                    class="whitespace-nowrap px-4 py-3.5 text-[#4b5a55]"
                  >
                    {format_projected_at(message.projected_at)}
                  </td>
                  <td class="px-4 py-3.5">
                    <.link
                      navigate={~p"/admin/messages/#{message.message_id}"}
                      class="inline-flex items-center rounded-full border border-[#d6d2c8] px-3 py-1.5 text-xs font-semibold text-[#4b5a55] transition duration-200 hover:-translate-y-0.5 hover:border-[#1f4842] hover:text-[#15201c]"
                    >
                      Open diagnostics
                    </.link>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </.admin_table_card>
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
