defmodule MembaWeb.Admin.RequestsLive.Index do
  use MembaWeb, :live_view

  alias Memba.Onboarding

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    requests = Onboarding.list_active_requests()

    {:ok, assign_active_requests(socket, requests)}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.admin flash={@flash} active={:requests}>
      <main id="admin-requests-index" data-admin-page="requests" class="space-y-6 p-6">
        <.admin_page_header
          eyebrow="Requests"
          title="Requests"
          description="Review account requests from club organisers before creating clubs, memberships, or sign-in access."
        />

        <section
          id="admin-requests-summary"
          aria-label="Active request summary"
          class="grid gap-4 md:grid-cols-3"
        >
          <article class="rounded-xl border border-[#e0ddd4] bg-white p-5 shadow-sm">
            <p class="text-xs font-bold uppercase tracking-[0.08em] text-[#7d877f]">
              Active requests
            </p>
            <p
              id="admin-requests-active-count"
              class="mt-3 text-3xl font-bold tracking-tight text-[#15201c]"
            >
              {@active_request_count}
            </p>
            <p class="mt-1 text-sm text-[#4b5a55]">Awaiting Memba staff review.</p>
          </article>

          <article class="rounded-xl border border-[#e0ddd4] bg-white p-5 shadow-sm">
            <p class="text-xs font-bold uppercase tracking-[0.08em] text-[#7d877f]">
              Approval model
            </p>
            <p class="mt-3 text-lg font-semibold text-[#15201c]">Staff approved</p>
            <p class="mt-1 text-sm text-[#4b5a55]">
              Public requests do not create clubs or sending access.
            </p>
          </article>

          <article class="rounded-xl border border-[#e0ddd4] bg-white p-5 shadow-sm">
            <p class="text-xs font-bold uppercase tracking-[0.08em] text-[#7d877f]">
              Next action
            </p>
            <p class="mt-3 text-lg font-semibold text-[#15201c]">Reject or convert</p>
            <p class="mt-1 text-sm text-[#4b5a55]">
              Each active request has triage actions for staff review.
            </p>
          </article>
        </section>

        <.admin_toolbar
          id="admin-requests-toolbar"
          search_placeholder="Search requests..."
          summary_label="Active"
          summary_count={@active_request_count}
        />

        <.admin_table_card
          id="admin-requests-inbox-card"
          title="Active request inbox"
          description="Oldest active requests first, with the details staff need before rejection or conversion."
        >
          <div class="overflow-x-auto">
            <table
              id="admin-requests-table"
              aria-label="Active onboarding requests"
              class="min-w-full text-left text-sm"
            >
              <thead class="bg-[#efede8] text-xs font-bold uppercase tracking-[0.08em] text-[#7d877f]">
                <tr>
                  <th scope="col" class="px-4 py-3">Requester</th>
                  <th scope="col" class="px-4 py-3">Club</th>
                  <th scope="col" class="px-4 py-3">Note</th>
                  <th scope="col" class="px-4 py-3">Submitted</th>
                  <th scope="col" class="px-4 py-3">Actions</th>
                </tr>
              </thead>
              <tbody
                id="admin-requests"
                aria-label="Active requests"
                class="divide-y divide-[#e6e3dc]"
                phx-update="stream"
              >
                <tr id="admin-requests-empty" class="hidden only:table-row">
                  <td colspan="5" class="px-4 py-6 text-center text-sm text-[#7d877f]">
                    No active requests to review.
                  </td>
                </tr>
                <tr
                  :for={{dom_id, request} <- @streams.active_requests}
                  id={dom_id}
                  data-testid="admin-request-row"
                  data-request-id={request.request_id}
                  data-requested-club-name={request.requested_club_name}
                  aria-label={"Request for #{request.requested_club_name}"}
                  class="align-top transition-colors hover:bg-[#fbfaf8]"
                >
                  <td class="px-4 py-3.5">
                    <.admin_identity_cell
                      initials={requester_initials(request.requester_name)}
                      title={request.requester_name}
                      subtitle={request.requester_email}
                      tone="blue"
                      testid="admin-request-requester"
                    />
                    <p class="mt-2 font-mono text-xs text-[#7d877f]">{request.request_id}</p>
                  </td>
                  <td class="px-4 py-3.5">
                    <div class="space-y-2">
                      <p
                        data-testid="admin-request-club"
                        class="font-semibold text-[#15201c]"
                      >
                        {request.requested_club_name}
                      </p>
                      <.admin_status_chip label="Active" tone="info" />
                    </div>
                  </td>
                  <td
                    data-testid="admin-request-note"
                    class="max-w-md whitespace-pre-line px-4 py-3.5 leading-6 text-[#4b5a55]"
                  >
                    {request.note}
                  </td>
                  <td
                    data-testid="admin-request-submitted-at"
                    class="whitespace-nowrap px-4 py-3.5 text-[#4b5a55]"
                  >
                    {format_submitted_at(request.inserted_at)}
                  </td>
                  <td class="px-4 py-3.5">
                    <div data-testid="admin-request-actions" class="flex flex-wrap gap-2">
                      <button
                        id={"reject-request-#{request.request_id}"}
                        type="button"
                        data-admin-request-action="reject"
                        data-request-id={request.request_id}
                        aria-label={"Reject request for #{request.requested_club_name}"}
                        class="inline-flex items-center rounded-full border border-[#d6d2c8] px-3 py-1.5 text-xs font-semibold text-[#7a5416] transition duration-200 hover:-translate-y-0.5 hover:border-[#7a5416] hover:bg-[#f3ecd8]"
                      >
                        Reject
                      </button>
                      <button
                        id={"convert-request-#{request.request_id}"}
                        type="button"
                        data-admin-request-action="convert"
                        data-request-id={request.request_id}
                        aria-label={"Convert request for #{request.requested_club_name}"}
                        class="inline-flex items-center rounded-full border border-[#1f4842] bg-[#1f4842] px-3 py-1.5 text-xs font-semibold text-white transition duration-200 hover:-translate-y-0.5 hover:bg-[#15201c]"
                      >
                        Convert
                      </button>
                    </div>
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

  defp assign_active_requests(socket, requests) do
    socket
    |> assign(:active_request_count, length(requests))
    |> stream(:active_requests, requests, dom_id: &"request-row-#{&1.request_id}")
  end

  defp requester_initials(name) when is_binary(name) do
    name
    |> String.split(~r/\s+/, trim: true)
    |> Enum.take(2)
    |> Enum.map(&String.first/1)
    |> Enum.join()
    |> String.upcase()
    |> case do
      "" -> "RQ"
      initials -> initials
    end
  end

  defp requester_initials(_name), do: "RQ"

  defp format_submitted_at(%DateTime{} = inserted_at) do
    Calendar.strftime(inserted_at, "%Y-%m-%d %H:%M:%S UTC")
  end

  defp format_submitted_at(nil), do: "Unknown"
end
