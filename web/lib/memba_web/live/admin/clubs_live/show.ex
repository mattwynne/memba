defmodule MembaWeb.Admin.ClubsLive.Show do
  use MembaWeb, :live_view

  alias Memba.Membership
  alias MembaWeb.Admin.ClubSlugForm
  alias MembaWeb.ClubSite

  @impl Phoenix.LiveView
  def mount(%{"club_id" => club_id}, _session, socket) do
    club = Membership.get_club(club_id)
    people = Membership.list_people() |> people_with_email_summaries()
    members = Membership.list_active_members_of_club(club_id) |> members_with_email_summaries()

    {:ok,
     socket
     |> assign(:club_id, club_id)
     |> assign(:club, club)
     |> assign_forms()
     |> assign_club_slug_feedback(club)
     |> assign(:people_count, length(people))
     |> assign(:member_count, length(members))
     |> stream(:people, people, dom_id: &"person-#{&1.person_id}")
     |> stream(:members, members, dom_id: &"member-#{&1.id}")}
  end

  @impl Phoenix.LiveView
  def handle_event("validate_club_slug", %{"club" => club_params}, socket) do
    {:noreply,
     socket
     |> assign(:club_form, ClubSlugForm.to_form(club_params))
     |> assign_club_slug_feedback(Map.get(club_params, "slug"))}
  end

  def handle_event("update_club", %{"club" => club_params}, socket) do
    attrs =
      club_params
      |> Map.take(["name", "slug"])
      |> Map.put("club_id", socket.assigns.club_id)

    case Membership.update_club(attrs, consistency: :strong) do
      :ok ->
        {:noreply,
         socket
         |> put_flash(:info, "Club updated")
         |> refresh_club()}

      {:ok, _result} ->
        {:noreply,
         socket
         |> put_flash(:info, "Club updated")
         |> refresh_club()}

      {:error, reason} ->
        {:noreply,
         socket
         |> put_flash(:error, "Could not update club: #{format_reason(reason)}")
         |> assign(:club_form, ClubSlugForm.to_form(club_params))
         |> assign_club_slug_feedback(Map.get(club_params, "slug"))}
    end
  end

  def handle_event("add_member", _params, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "Invite members by email instead of adding active memberships directly.")
     |> push_navigate(to: ~p"/admin/clubs/#{socket.assigns.club_id}/invitations/new")}
  end

  def handle_event("remove_member", %{"membership_id" => membership_id}, socket) do
    case Membership.remove_member(%{"membership_id" => membership_id}, consistency: :strong) do
      :ok ->
        {:noreply,
         socket
         |> put_flash(:info, "Member removed")
         |> refresh_members()}

      {:ok, _result} ->
        {:noreply,
         socket
         |> put_flash(:info, "Member removed")
         |> refresh_members()}

      {:error, reason} ->
        {:noreply,
         socket
         |> put_flash(:error, "Could not remove member: #{format_reason(reason)}")
         |> refresh_members()}
    end
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.admin flash={@flash} current_identity={@current_identity} active={:clubs}>
      <main id="club-show" data-admin-page="club-detail" class="mx-auto max-w-7xl space-y-6 p-6">
        <%= if @club do %>
          <section class="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
            <div class="space-y-2">
              <.link
                id="back-to-clubs-link"
                navigate={~p"/admin/clubs"}
                aria-label="Back to clubs"
                class="text-sm font-semibold text-[#1f4842] transition duration-200 hover:text-[#15201c]"
              >
                ← Clubs
              </.link>
              <p class="text-sm font-semibold uppercase tracking-wide text-[#7d877f]">
                Club operations
              </p>
              <h1 class="text-3xl font-bold tracking-tight text-[#15201c]">{@club.name}</h1>
              <p class="max-w-3xl text-[#4b5a55]">
                Keep club facts current, maintain person records, and manage the memberships that
                connect people to this club.
              </p>
            </div>

            <.link
              id="staff-club-home-link"
              href={ClubSite.url(@club)}
              aria-label={"Open #{@club.name} home page"}
              class="inline-flex items-center justify-center rounded-full border border-[#d6d2c8] bg-white px-4 py-2 text-sm font-semibold text-[#4b5a55] shadow-sm transition duration-200 hover:-translate-y-0.5 hover:border-[#1f4842] hover:text-[#15201c] hover:shadow-md"
            >
              Open club home page
            </.link>
          </section>

          <section
            id="club-operation-summary"
            aria-label="Club operations summary"
            class="grid gap-4 md:grid-cols-3"
          >
            <article
              id="club-facts-card"
              class="rounded-2xl border border-[#e6e3dc] bg-white p-5 shadow-sm"
            >
              <p class="text-xs font-semibold uppercase tracking-wide text-[#7d877f]">Club facts</p>
              <p class="mt-3 text-xl font-bold tracking-tight text-[#15201c]">{@club.name}</p>
              <p id="club-slug-display" class="mt-2 text-sm font-medium text-[#4b5a55]">
                Slug
                <span class="ml-1 rounded-full bg-[#f7f6f3] px-2 py-1 font-mono text-xs text-[#4b5a55]">
                  {@club.slug}
                </span>
              </p>
              <p class="mt-3 break-all font-mono text-xs text-[#7d877f]">{@club.club_id}</p>
            </article>

            <article class="rounded-2xl border border-[#e6e3dc] bg-white p-5 shadow-sm">
              <p class="text-xs font-semibold uppercase tracking-wide text-[#7d877f]">
                Person records
              </p>
              <p class="mt-3 text-3xl font-bold tracking-tight text-[#15201c]">{@people_count}</p>
              <p class="mt-1 text-sm text-[#4b5a55]">
                Staff-created identity and email records available to club workflows.
              </p>
            </article>

            <article class="rounded-2xl border border-[#e6e3dc] bg-white p-5 shadow-sm">
              <p class="text-xs font-semibold uppercase tracking-wide text-[#7d877f]">Memberships</p>
              <p class="mt-3 text-3xl font-bold tracking-tight text-[#15201c]">{@member_count}</p>
              <p class="mt-1 text-sm text-[#4b5a55]">
                Active links between person records and this club.
              </p>
            </article>
          </section>

          <section
            id="club-facts-edit-card"
            class="rounded-2xl border border-[#e6e3dc] bg-white p-5 shadow-sm"
          >
            <div class="flex flex-col gap-1">
              <h2 class="text-lg font-semibold text-[#15201c]">Edit club facts</h2>
              <p class="text-sm text-[#7d877f]">
                Update the operational club record without changing people or memberships.
              </p>
            </div>

            <.form
              for={@club_form}
              id="edit-club-form"
              aria-label="Edit club"
              class="mt-5 grid gap-4 lg:grid-cols-[minmax(0,1fr)_minmax(0,1fr)_auto] lg:items-end"
              phx-change="validate_club_slug"
              phx-submit="update_club"
            >
              <.input
                field={@club_form[:name]}
                id="edit-club-name-input"
                label="Name"
                aria-label="Club name"
                required
              />
              <div>
                <.input
                  field={@club_form[:slug]}
                  id="edit-club-slug-input"
                  label="Slug"
                  aria-label="Club slug"
                  aria-describedby="edit-club-slug-help edit-club-slug-feedback"
                  aria-invalid={@club_slug_feedback.status in ["invalid", "taken"]}
                  maxlength={ClubSlugForm.max_length()}
                  required
                />
                <p id="edit-club-slug-help" class="mt-1 text-xs text-zinc-500">
                  Use lowercase letters, numbers, and hyphens.
                </p>
                <p
                  id="edit-club-slug-feedback"
                  role="status"
                  aria-live="polite"
                  data-status={@club_slug_feedback.status}
                  class={ClubSlugForm.feedback_class(@club_slug_feedback)}
                >
                  {@club_slug_feedback.message}
                </p>
              </div>
              <.button
                id="update-club-button"
                type="submit"
                aria-label="Save club"
                disabled={not @club_slug_feedback.valid}
              >
                Save club
              </.button>
            </.form>
          </section>

          <div class="grid gap-6 xl:grid-cols-[minmax(0,1.15fr)_minmax(0,0.85fr)]">
            <section
              id="people-records-card"
              class="overflow-hidden rounded-2xl border border-[#e6e3dc] bg-white shadow-sm"
            >
              <div class="flex items-start justify-between gap-4 border-b border-[#e6e3dc] p-5">
                <div>
                  <p class="text-xs font-semibold uppercase tracking-wide text-[#7d877f]">
                    Person records
                  </p>
                  <h2 class="mt-1 text-lg font-semibold text-[#15201c]">People</h2>
                  <p class="mt-1 text-sm text-[#7d877f]">
                    Identity and contact records stay separate from club memberships.
                  </p>
                </div>

                <.link
                  id="new-person-link"
                  navigate={~p"/admin/clubs/#{@club_id}/people/new"}
                  aria-label="New person"
                  class="inline-flex shrink-0 rounded-full border border-[#1f4842] bg-[#1f4842] px-4 py-2 text-sm font-semibold text-white shadow-sm transition duration-200 hover:-translate-y-0.5 hover:bg-[#15201c] hover:shadow-md"
                >
                  New person
                </.link>
              </div>

              <div class="overflow-x-auto">
                <table
                  id="people-records-table"
                  aria-label="Person records"
                  class="min-w-full divide-y divide-[#e6e3dc] text-left text-sm"
                >
                  <thead class="bg-[#f7f6f3] text-xs font-semibold uppercase tracking-wide text-[#7d877f]">
                    <tr>
                      <th scope="col" class="px-4 py-3">Person</th>
                      <th scope="col" class="px-4 py-3">Primary email</th>
                      <th scope="col" class="px-4 py-3">Alternate emails</th>
                      <th scope="col" class="px-4 py-3">Edit</th>
                    </tr>
                  </thead>
                  <tbody
                    id="people"
                    aria-label="People"
                    class="divide-y divide-[#e6e3dc]"
                    phx-update="stream"
                  >
                    <tr id="people-empty" class="hidden only:table-row">
                      <td colspan="4" class="px-4 py-6 text-center text-sm text-[#7d877f]">
                        No people yet.
                      </td>
                    </tr>
                    <tr
                      :for={{dom_id, person} <- @streams.people}
                      id={dom_id}
                      data-testid="person-row"
                      data-person-id={person.person_id}
                      data-person-name={person.name}
                      aria-label={"Person #{person.name}"}
                    >
                      <td class="px-4 py-4">
                        <div class="flex items-center gap-3">
                          <div class="flex size-10 shrink-0 items-center justify-center rounded-full bg-[#e6ece4] text-xs font-bold text-[#1f4842]">
                            {initials(person.name)}
                          </div>
                          <div>
                            <p class="font-semibold text-[#15201c]">{person.name}</p>
                            <p class="mt-1 break-all font-mono text-xs text-[#7d877f]">
                              {person.person_id}
                            </p>
                          </div>
                        </div>
                      </td>
                      <td class="px-4 py-4">
                        <p
                          id={"person-primary-email-#{person.person_id}"}
                          data-testid="person-primary-email"
                          class="font-medium text-[#4b5a55]"
                        >
                          {person.primary_email}
                        </p>
                      </td>
                      <td class="px-4 py-4">
                        <div
                          id={"person-alternate-emails-#{person.person_id}"}
                          data-testid="person-alternate-emails"
                          data-alternate-count={person.alternate_count}
                          class="space-y-1 text-sm text-[#4b5a55]"
                        >
                          <p class="font-medium text-[#15201c]">Alternate email addresses</p>
                          <p
                            :if={person.alternate_count == 0}
                            data-testid="person-alternate-empty"
                            class="text-[#7d877f]"
                          >
                            No alternate email addresses
                          </p>
                          <ul :if={person.alternate_count > 0} class="space-y-1">
                            <li
                              :for={email <- person.alternate_emails}
                              data-testid="person-alternate-email"
                              class="font-medium text-[#4b5a55]"
                            >
                              {email}
                            </li>
                          </ul>
                        </div>
                      </td>
                      <td class="px-4 py-4">
                        <.link
                          id={"edit-person-link-#{person.person_id}"}
                          navigate={~p"/admin/clubs/#{@club_id}/people/#{person.person_id}/edit"}
                          data-testid="edit-person-link"
                          aria-label={"Edit #{person.name}"}
                          class="inline-flex rounded-full border border-[#d6d2c8] px-3 py-1.5 text-xs font-semibold text-[#4b5a55] transition duration-200 hover:-translate-y-0.5 hover:border-[#1f4842] hover:text-[#15201c]"
                        >
                          Edit
                        </.link>
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </section>

            <section
              id="memberships-card"
              class="overflow-hidden rounded-2xl border border-[#e6e3dc] bg-white shadow-sm"
            >
              <div class="flex items-start justify-between gap-4 border-b border-[#e6e3dc] p-5">
                <div>
                  <p class="text-xs font-semibold uppercase tracking-wide text-[#7d877f]">
                    Memberships
                  </p>
                  <h2 class="mt-1 text-lg font-semibold text-[#15201c]">
                    Active club memberships
                  </h2>
                  <p class="mt-1 text-sm text-[#7d877f]">
                    Members become active after accepting an invitation. Existing active members
                    can still be removed from this club.
                  </p>
                </div>

                <.link
                  id="invite-member-link"
                  navigate={~p"/admin/clubs/#{@club_id}/invitations/new"}
                  aria-label="Invite member"
                  class="inline-flex shrink-0 rounded-full border border-[#1f4842] bg-[#1f4842] px-4 py-2 text-sm font-semibold text-white shadow-sm transition duration-200 hover:-translate-y-0.5 hover:bg-[#15201c] hover:shadow-md"
                >
                  Invite member
                </.link>
              </div>

              <div
                id="memberships-invitation-notice"
                class="border-b border-[#e6e3dc] bg-[#f7f6f3] p-5"
              >
                <p class="text-sm font-semibold text-[#15201c]">Invitation required</p>
                <p class="mt-1 max-w-3xl text-sm text-[#4b5a55]">
                  Staff no longer create active club memberships directly. Send an invitation so
                  the person controls their email address and completes any required profile
                  details before membership starts.
                </p>
              </div>

              <div class="overflow-x-auto">
                <table
                  id="memberships-table"
                  aria-label="Memberships"
                  class="min-w-full divide-y divide-[#e6e3dc] text-left text-sm"
                >
                  <thead class="bg-white text-xs font-semibold uppercase tracking-wide text-[#7d877f]">
                    <tr>
                      <th scope="col" class="px-4 py-3">Person</th>
                      <th scope="col" class="px-4 py-3">Primary email</th>
                      <th scope="col" class="px-4 py-3">Membership</th>
                      <th scope="col" class="px-4 py-3">Remove</th>
                    </tr>
                  </thead>
                  <tbody
                    id="members"
                    aria-label="Members"
                    class="divide-y divide-[#e6e3dc]"
                    phx-update="stream"
                  >
                    <tr id="members-empty" class="hidden only:table-row">
                      <td colspan="4" class="px-4 py-6 text-center text-sm text-[#7d877f]">
                        No members yet.
                      </td>
                    </tr>
                    <tr
                      :for={{dom_id, member} <- @streams.members}
                      id={dom_id}
                      data-testid="member-row"
                      data-member-id={member.id}
                      data-member-name={member.name}
                      aria-label={"Member #{member.name}"}
                    >
                      <td class="px-4 py-4">
                        <div class="flex items-center gap-3">
                          <div class="flex size-10 shrink-0 items-center justify-center rounded-full bg-[#e6ece4] text-xs font-bold text-[#1f4842]">
                            {initials(member.name)}
                          </div>
                          <div>
                            <p class="font-semibold text-[#15201c]">{member.name}</p>
                            <p class="mt-1 break-all font-mono text-xs text-[#7d877f]">
                              {member.id}
                            </p>
                          </div>
                        </div>
                      </td>
                      <td class="px-4 py-4">
                        <p
                          id={"member-primary-email-#{member.id}"}
                          data-testid="member-primary-email"
                          class="font-medium text-[#4b5a55]"
                        >
                          {member.primary_email}
                        </p>
                        <div
                          id={"member-alternate-emails-#{member.id}"}
                          data-testid="member-alternate-emails"
                          data-alternate-count={member.alternate_count}
                          class="mt-2 space-y-1 text-sm text-[#4b5a55]"
                        >
                          <p class="font-medium text-[#15201c]">Alternate email addresses</p>
                          <p
                            :if={member.alternate_count == 0}
                            data-testid="member-alternate-empty"
                            class="text-[#7d877f]"
                          >
                            No alternate email addresses
                          </p>
                          <ul :if={member.alternate_count > 0} class="space-y-1">
                            <li
                              :for={email <- member.alternate_emails}
                              data-testid="member-alternate-email"
                              class="font-medium text-[#4b5a55]"
                            >
                              {email}
                            </li>
                          </ul>
                        </div>
                      </td>
                      <td class="px-4 py-4">
                        <span class="rounded-full bg-[#e6ece4] px-2.5 py-1 text-xs font-semibold text-[#1f4842]">
                          Active membership
                        </span>
                        <p class="mt-2 break-all font-mono text-xs text-[#7d877f]">
                          {member.membership_id}
                        </p>
                      </td>
                      <td class="px-4 py-4">
                        <.button
                          id={"remove-member-button-#{member.membership_id}"}
                          type="button"
                          data-testid="remove-member-button"
                          phx-click="remove_member"
                          phx-value-membership_id={member.membership_id}
                          aria-label={"Remove #{member.name} from #{@club.name}"}
                          variant="danger"
                        >
                          Remove
                        </.button>
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </section>
          </div>

          <section
            id="club-messaging-card"
            class="overflow-hidden rounded-2xl border border-[#e6e3dc] bg-white shadow-sm"
          >
            <div class="grid gap-5 p-5 md:grid-cols-[minmax(0,1fr)_auto] md:items-center">
              <div>
                <p class="text-xs font-semibold uppercase tracking-wide text-[#7d877f]">
                  Message diagnostics
                </p>
                <h2 class="mt-1 text-lg font-semibold text-[#15201c]">Messages live globally</h2>
                <p class="mt-2 max-w-3xl text-sm text-[#4b5a55]">
                  Club-scoped message rows are no longer embedded on this page. Use the global
                  Messages area to review projected messages across clubs and open delivery
                  diagnostics. A future club-filtered view can build from that operations index.
                </p>
              </div>

              <.link
                id="club-messages-link"
                navigate={~p"/admin/messages"}
                aria-label="Open global Messages"
                class="inline-flex items-center justify-center rounded-full border border-[#1f4842] bg-[#1f4842] px-4 py-2 text-sm font-semibold text-white shadow-sm transition duration-200 hover:-translate-y-0.5 hover:bg-[#15201c] hover:shadow-md"
              >
                Open global Messages
              </.link>
            </div>
          </section>
        <% else %>
          <section class="space-y-4">
            <.link
              id="back-to-clubs-link"
              navigate={~p"/admin/clubs"}
              aria-label="Back to clubs"
              class="text-sm font-semibold text-[#1f4842] transition duration-200 hover:text-[#15201c]"
            >
              ← Clubs
            </.link>
            <div class="rounded-2xl border border-[#e6e3dc] bg-white p-5 shadow-sm">
              <h1 class="text-2xl font-bold text-[#15201c]">Club not found</h1>
              <p class="mt-2 text-[#4b5a55]">No projected club exists for this URL.</p>
            </div>
          </section>
        <% end %>
      </main>
    </Layouts.admin>
    """
  end

  defp assign_forms(socket) do
    socket
    |> assign(
      :club_form,
      ClubSlugForm.to_form(ClubSlugForm.params_from_club(socket.assigns.club))
    )
  end

  defp refresh_club(socket) do
    club = Membership.get_club(socket.assigns.club_id)

    socket
    |> assign(:club, club)
    |> assign(:club_form, ClubSlugForm.to_form(ClubSlugForm.params_from_club(club)))
    |> assign_club_slug_feedback(club)
  end

  defp refresh_members(socket) do
    members =
      socket.assigns.club_id
      |> Membership.list_active_members_of_club()
      |> members_with_email_summaries()

    socket
    |> assign(:member_count, length(members))
    |> stream(:members, members, reset: true, dom_id: &"member-#{&1.id}")
  end

  defp people_with_email_summaries(people) do
    Enum.map(people, fn person ->
      alternate_emails = Membership.list_person_alternate_emails(person.person_id)

      %{
        person_id: person.person_id,
        name: person.name,
        primary_email: person.email,
        alternate_emails: alternate_emails,
        alternate_count: length(alternate_emails)
      }
    end)
  end

  defp members_with_email_summaries(members) do
    Enum.map(members, fn member ->
      alternate_emails = Membership.list_person_alternate_emails(member.id)

      %{
        membership_id: member.membership_id,
        id: member.id,
        name: member.name,
        email: member.email,
        primary_email: member.email,
        alternate_emails: alternate_emails,
        alternate_count: length(alternate_emails)
      }
    end)
  end

  defp current_club_slug(nil), do: ""
  defp current_club_slug(slug) when is_binary(slug), do: slug
  defp current_club_slug(%{slug: slug}), do: slug

  defp assign_club_slug_feedback(socket, club_or_slug) do
    slug = current_club_slug(club_or_slug)

    assign(socket, :club_slug_feedback, ClubSlugForm.feedback(socket.assigns.club_id, slug))
  end

  defp initials(name) when is_binary(name) do
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

  defp initials(_name), do: "?"

  defp format_reason(reason), do: reason |> inspect() |> String.replace("_", " ")
end
