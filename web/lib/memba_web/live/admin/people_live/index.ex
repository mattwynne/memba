defmodule MembaWeb.Admin.PeopleLive.Index do
  use MembaWeb, :live_view

  alias Memba.Membership

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     stream(socket, :people, Membership.list_operator_people(),
       dom_id: &"person-row-#{&1.person_id}"
     )}
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
              Sorted by person name, with active memberships shown as club summaries.
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
                <tr
                  :for={{dom_id, person} <- @streams.people}
                  id={dom_id}
                  data-testid="admin-person-row"
                  data-person-id={person.person_id}
                  data-person-name={person.name}
                >
                  <td data-testid="admin-person-name" class="px-4 py-4 font-medium text-[#15201c]">
                    {person.name}
                  </td>
                  <td data-testid="admin-person-primary-email" class="px-4 py-4 text-[#4b5a55]">
                    {email_summary(person.primary_email)}
                  </td>
                  <td data-testid="admin-person-alternate-emails" class="px-4 py-4 text-[#4b5a55]">
                    {email_summary(person.alternate_emails)}
                  </td>
                  <td data-testid="admin-person-memberships" class="px-4 py-4 text-[#4b5a55]">
                    {membership_summary(person.memberships)}
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

  defp email_summary(email) when is_binary(email) and email != "", do: email
  defp email_summary(emails) when is_list(emails) and emails != [], do: Enum.join(emails, ", ")
  defp email_summary(_empty), do: "—"

  defp membership_summary([]), do: "No active memberships"

  defp membership_summary(memberships) when is_list(memberships) do
    memberships
    |> Enum.map(&membership_label/1)
    |> Enum.join(", ")
  end

  defp membership_label(%{club_name: name}) when is_binary(name) and name != "", do: name

  defp membership_label(%{club_id: club_id}) when is_binary(club_id) and club_id != "",
    do: club_id

  defp membership_label(_membership), do: "Unknown club"
end
