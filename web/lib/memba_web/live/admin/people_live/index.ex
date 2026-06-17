defmodule MembaWeb.Admin.PeopleLive.Index do
  use MembaWeb, :live_view

  alias Memba.Membership

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    people = Membership.list_operator_people()

    {:ok,
     socket
     |> assign(:people_count, length(people))
     |> stream(:people, people, dom_id: &"person-row-#{&1.person_id}")}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.admin flash={@flash} current_identity={@current_identity} active={:people}>
      <main id="admin-people-index" class="space-y-6 p-6">
        <.admin_page_header
          eyebrow="People"
          title="People"
          description="One row per person, with contact details and club relationships kept separate from club membership records."
        />

        <section id="admin-people-read-only-notice" class="sr-only">
          This index is read-only in this slice. Create and edit person records through the existing club-scoped people workflow.
        </section>

        <.admin_toolbar
          id="admin-people-toolbar"
          summary_label="All"
          summary_count={@people_count}
        />

        <.admin_table_card
          id="admin-people-table-card"
          title="Person records"
          description="Sorted by person name, with active memberships shown as club summaries."
        >
          <div class="overflow-x-auto">
            <table
              id="admin-people-table"
              aria-label="People records"
              class="min-w-full text-left text-sm"
            >
              <thead class="bg-[#efede8] text-xs font-bold uppercase tracking-[0.08em] text-[#7d877f]">
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
                  class="transition-colors hover:bg-[#fbfaf8]"
                >
                  <td class="px-4 py-3.5">
                    <.admin_identity_cell
                      initials={person_initials(person.name)}
                      title={person.name}
                      subtitle="Person record"
                      testid="admin-person-name"
                    />
                  </td>
                  <td
                    data-testid="admin-person-primary-email"
                    class="px-4 py-3.5 font-mono text-xs text-[#4b5a55]"
                  >
                    {email_summary(person.primary_email)}
                  </td>
                  <td
                    data-testid="admin-person-alternate-emails"
                    class="px-4 py-3.5 font-mono text-xs text-[#4b5a55]"
                  >
                    {email_summary(person.alternate_emails)}
                  </td>
                  <td data-testid="admin-person-memberships" class="px-4 py-3.5 text-[#4b5a55]">
                    {membership_summary(person.memberships)}
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

  defp person_initials(name) when is_binary(name) do
    name
    |> String.split(~r/\s+/, trim: true)
    |> Enum.take(2)
    |> Enum.map(&String.first/1)
    |> Enum.join()
    |> String.upcase()
    |> case do
      "" -> "?"
      initials -> initials
    end
  end

  defp person_initials(_name), do: "?"
end
