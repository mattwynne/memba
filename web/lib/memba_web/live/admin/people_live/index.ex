defmodule MembaWeb.Admin.PeopleLive.Index do
  use MembaWeb, :live_view

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :people, [], dom_id: &"person-row-#{&1.person_id}")}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.admin flash={@flash}>
      <main id="admin-people-index" class="mx-auto max-w-7xl space-y-6 p-6">
        <section class="space-y-2">
          <p class="text-sm font-semibold uppercase tracking-wide text-[#7d877f]">
            Memba staff operations
          </p>
          <h1 class="text-3xl font-bold tracking-tight text-[#15201c]">People</h1>
          <p class="max-w-3xl text-[#4b5a55]">
            Review global person records separately from the memberships that connect them to
            clubs.
          </p>
        </section>

        <section
          id="admin-people-read-only-notice"
          class="rounded-2xl border border-[#d6d2c8] bg-[#e6ece4] p-4 text-sm text-[#1f4842]"
        >
          This index is read-only in this slice. Create and edit person records through the
          existing club-scoped people workflow.
        </section>

        <section class="overflow-hidden rounded-2xl border border-[#e6e3dc] bg-white shadow-sm">
          <div class="border-b border-[#e6e3dc] p-5">
            <h2 class="text-lg font-semibold text-[#15201c]">Person records</h2>
            <p class="mt-1 text-sm text-[#7d877f]">
              People will appear once the global person summary read model is wired.
            </p>
          </div>

          <div class="overflow-x-auto">
            <table
              id="admin-people-table"
              aria-label="People records"
              class="min-w-full divide-y divide-[#e6e3dc] text-left text-sm"
            >
              <thead class="bg-[#f7f6f3] text-xs font-semibold uppercase tracking-wide text-[#7d877f]">
                <tr>
                  <th scope="col" class="px-4 py-3">Person</th>
                  <th scope="col" class="px-4 py-3">Primary email</th>
                  <th scope="col" class="px-4 py-3">Alternate emails</th>
                  <th scope="col" class="px-4 py-3">Memberships</th>
                </tr>
              </thead>
              <tbody
                id="admin-people-table-body"
                class="divide-y divide-[#e6e3dc]"
                phx-update="stream"
              >
                <tr id="admin-people-empty" class="hidden only:table-row">
                  <td colspan="4" class="px-4 py-6 text-center text-sm text-[#7d877f]">
                    No person records to show yet.
                  </td>
                </tr>
                <tr :for={{dom_id, person} <- @streams.people} id={dom_id}>
                  <td class="px-4 py-4 font-medium text-[#15201c]">{person.name}</td>
                  <td class="px-4 py-4 text-[#4b5a55]">{person.primary_email}</td>
                  <td class="px-4 py-4 text-[#4b5a55]">{person.alternate_emails}</td>
                  <td class="px-4 py-4 text-[#4b5a55]">{person.memberships}</td>
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
