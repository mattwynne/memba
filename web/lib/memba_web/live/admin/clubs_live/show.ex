defmodule MembaWeb.Admin.ClubsLive.Show do
  use MembaWeb, :live_view

  alias Memba.Membership
  alias Memba.Membership.Slug
  alias Memba.Messaging

  @empty_club %{"name" => "", "slug" => ""}
  @empty_person %{"name" => "", "email" => ""}
  @empty_membership %{"person_id" => ""}
  @empty_message %{"sender_id" => "", "subject" => "", "body" => ""}

  @impl Phoenix.LiveView
  def mount(%{"club_id" => club_id}, _session, socket) do
    club = Membership.get_club(club_id)
    people = Membership.list_people()
    members = Membership.list_active_members_of_club(club_id)
    messages = Messaging.list_messages_for_club(club_id)

    {:ok,
     socket
     |> assign(:club_id, club_id)
     |> assign(:club, club)
     |> assign_forms()
     |> assign(:person_options, person_options(people))
     |> assign(:member_options, member_options(members))
     |> stream(:people, people, dom_id: &"person-#{&1.person_id}")
     |> stream(:members, members, dom_id: &"member-#{&1.id}")
     |> stream(:messages, messages, dom_id: &"message-#{&1.message_id}")}
  end

  @impl Phoenix.LiveView
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
         |> assign(:club_form, to_form(club_params, as: :club))}
    end
  end

  def handle_event("create_person", %{"person" => person_params}, socket) do
    attrs =
      person_params
      |> Map.take(["name", "email"])
      |> Map.put("person_id", Ecto.UUID.generate())

    case Membership.create_person(attrs, consistency: :strong) do
      :ok ->
        {:noreply,
         socket
         |> put_flash(:info, "Person created")
         |> assign(:person_form, to_form(@empty_person, as: :person))
         |> refresh_people()}

      {:ok, _result} ->
        {:noreply,
         socket
         |> put_flash(:info, "Person created")
         |> assign(:person_form, to_form(@empty_person, as: :person))
         |> refresh_people()}

      {:error, reason} ->
        {:noreply,
         socket
         |> put_flash(:error, "Could not create person: #{format_reason(reason)}")
         |> assign(:person_form, to_form(person_params, as: :person))}
    end
  end

  def handle_event("add_member", %{"membership" => membership_params}, socket) do
    attrs =
      membership_params
      |> Map.take(["person_id"])
      |> Map.merge(%{
        "membership_id" => Ecto.UUID.generate(),
        "club_id" => socket.assigns.club_id
      })

    case Membership.add_member(attrs, consistency: :strong) do
      :ok ->
        {:noreply,
         socket
         |> put_flash(:info, "Member added")
         |> assign(:membership_form, to_form(@empty_membership, as: :membership))
         |> refresh_members()}

      {:ok, _result} ->
        {:noreply,
         socket
         |> put_flash(:info, "Member added")
         |> assign(:membership_form, to_form(@empty_membership, as: :membership))
         |> refresh_members()}

      {:error, reason} ->
        {:noreply,
         socket
         |> put_flash(:error, "Could not add member: #{format_reason(reason)}")
         |> assign(:membership_form, to_form(membership_params, as: :membership))}
    end
  end

  def handle_event("send_message", %{"message" => message_params}, socket) do
    attrs =
      message_params
      |> Map.take(["sender_id", "subject", "body"])
      |> Map.merge(%{
        "message_id" => Ecto.UUID.generate(),
        "club_id" => socket.assigns.club_id
      })

    case Messaging.send_club_message(attrs, consistency: :strong) do
      :ok ->
        {:noreply,
         socket
         |> put_flash(:info, "Message sent")
         |> assign(:message_form, to_form(@empty_message, as: :message))
         |> refresh_messages()}

      {:ok, _result} ->
        {:noreply,
         socket
         |> put_flash(:info, "Message sent")
         |> assign(:message_form, to_form(@empty_message, as: :message))
         |> refresh_messages()}

      {:error, reason} ->
        {:noreply,
         socket
         |> put_flash(:error, "Could not send message: #{format_reason(reason)}")
         |> assign(:message_form, to_form(message_params, as: :message))}
    end
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.admin flash={@flash}>
      <main id="club-show" class="mx-auto max-w-6xl space-y-8 p-6">
        <.link
          id="back-to-clubs-link"
          navigate={~p"/admin/clubs"}
          aria-label="Back to clubs"
          class="text-sm font-medium text-blue-700 hover:text-blue-900"
        >
          ← Clubs
        </.link>

        <%= if @club do %>
          <section class="space-y-2">
            <p class="text-sm font-semibold uppercase tracking-wide text-zinc-500">Club</p>
            <h1 class="text-3xl font-bold tracking-tight text-zinc-900">{@club.name}</h1>
            <p id="club-slug-display" class="text-sm font-medium text-zinc-600">
              Slug: <span class="font-mono">{@club.slug}</span>
            </p>
            <p class="text-zinc-600">
              Add people to this club, then send a message to the active members.
            </p>
          </section>

          <section class="rounded-xl border border-zinc-200 bg-white p-5 shadow-sm">
            <h2 class="text-lg font-semibold text-zinc-900">Edit club</h2>

            <.form
              for={@club_form}
              id="edit-club-form"
              aria-label="Edit club"
              class="mt-4 grid gap-4 sm:grid-cols-[1fr_1fr_auto] sm:items-end"
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
                  maxlength={Slug.max_length()}
                  required
                />
                <p id="edit-club-slug-help" class="mt-1 text-xs text-zinc-500">
                  Use lowercase letters, numbers, and hyphens.
                </p>
              </div>
              <.button id="update-club-button" type="submit" aria-label="Save club">
                Save club
              </.button>
            </.form>
          </section>

          <div class="grid gap-6 lg:grid-cols-2">
            <section class="rounded-xl border border-zinc-200 bg-white p-5 shadow-sm">
              <h2 class="text-lg font-semibold text-zinc-900">Create a person</h2>

              <.form
                for={@person_form}
                id="new-person-form"
                aria-label="Create a person"
                class="mt-4 space-y-4"
                phx-submit="create_person"
              >
                <.input
                  field={@person_form[:name]}
                  id="person-name-input"
                  label="Name"
                  aria-label="Person name"
                  required
                />
                <.input
                  field={@person_form[:email]}
                  id="person-email-input"
                  label="Email"
                  type="email"
                  aria-label="Person email"
                  required
                />
                <.button id="create-person-button" type="submit" aria-label="Create person">
                  Create person
                </.button>
              </.form>

              <div
                id="people"
                aria-label="People"
                class="mt-5 divide-y divide-zinc-100"
                phx-update="stream"
              >
                <p id="people-empty" class="hidden py-4 text-sm text-zinc-500 only:block">
                  No people yet.
                </p>
                <div
                  :for={{dom_id, person} <- @streams.people}
                  id={dom_id}
                  data-testid="person-row"
                  data-person-id={person.person_id}
                  data-person-name={person.name}
                  aria-label={"Person #{person.name}"}
                  class="py-3"
                >
                  <p class="font-medium text-zinc-900">{person.name}</p>
                  <p class="text-sm text-zinc-500">{person.email}</p>
                </div>
              </div>
            </section>

            <section class="rounded-xl border border-zinc-200 bg-white p-5 shadow-sm">
              <h2 class="text-lg font-semibold text-zinc-900">Members</h2>

              <.form
                for={@membership_form}
                id="add-member-form"
                aria-label="Add a member"
                class="mt-4 space-y-4"
                phx-submit="add_member"
              >
                <.input
                  field={@membership_form[:person_id]}
                  id="member-person-select"
                  label="Person"
                  type="select"
                  aria-label="Person to add as member"
                  prompt="Choose a person"
                  options={@person_options}
                  required
                />
                <.button
                  id="add-member-button"
                  type="submit"
                  aria-label="Add selected person as member"
                >
                  Add member
                </.button>
              </.form>

              <div
                id="members"
                aria-label="Members"
                class="mt-5 divide-y divide-zinc-100"
                phx-update="stream"
              >
                <p id="members-empty" class="hidden py-4 text-sm text-zinc-500 only:block">
                  No members yet.
                </p>
                <div
                  :for={{dom_id, member} <- @streams.members}
                  id={dom_id}
                  data-testid="member-row"
                  data-member-id={member.id}
                  data-member-name={member.name}
                  aria-label={"Member #{member.name}"}
                  class="py-3"
                >
                  <p class="font-medium text-zinc-900">{member.name}</p>
                  <p class="text-sm text-zinc-500">{member.email}</p>
                </div>
              </div>
            </section>
          </div>

          <section class="rounded-xl border border-zinc-200 bg-white p-5 shadow-sm">
            <h2 class="text-lg font-semibold text-zinc-900">Send a club message</h2>

            <.form
              for={@message_form}
              id="new-message-form"
              aria-label="Send a club message"
              class="mt-4 grid gap-4 lg:grid-cols-2"
              phx-submit="send_message"
            >
              <.input
                field={@message_form[:sender_id]}
                id="message-sender-select"
                label="Sender"
                type="select"
                aria-label="Message sender"
                prompt="Choose a sender"
                options={@member_options}
                required
              />
              <.input
                field={@message_form[:subject]}
                id="message-subject-input"
                label="Subject"
                aria-label="Message subject"
                required
              />
              <div class="lg:col-span-2">
                <.input
                  field={@message_form[:body]}
                  id="message-body-input"
                  label="Body"
                  type="textarea"
                  aria-label="Message body"
                  required
                />
              </div>
              <div class="lg:col-span-2">
                <.button id="send-message-button" type="submit" aria-label="Send club message">
                  Send message
                </.button>
              </div>
            </.form>

            <div
              id="messages"
              aria-label="Messages"
              class="mt-5 divide-y divide-zinc-100"
              phx-update="stream"
            >
              <p id="messages-empty" class="hidden py-4 text-sm text-zinc-500 only:block">
                No messages yet.
              </p>
              <div
                :for={{dom_id, message} <- @streams.messages}
                id={dom_id}
                data-testid="message-row"
                data-message-id={message.message_id}
                data-message-subject={message.subject}
                aria-label={"Message #{message.subject}"}
                class="py-3"
              >
                <.link
                  id={"message-link-#{message.message_id}"}
                  navigate={~p"/admin/messages/#{message.message_id}"}
                  data-testid="message-link"
                  aria-label={"Open message #{message.subject}"}
                  class="font-medium text-blue-700 hover:text-blue-900"
                >
                  {message.subject}
                </.link>
                <p class="mt-1 text-sm text-zinc-600">{message.body}</p>
              </div>
            </div>
          </section>
        <% else %>
          <section class="rounded-xl border border-zinc-200 bg-white p-5 shadow-sm">
            <h1 class="text-2xl font-bold text-zinc-900">Club not found</h1>
            <p class="mt-2 text-zinc-600">No projected club exists for this URL.</p>
          </section>
        <% end %>
      </main>
    </Layouts.admin>
    """
  end

  defp assign_forms(socket) do
    socket
    |> assign(:club_form, to_form(club_form_params(socket.assigns.club), as: :club))
    |> assign(:person_form, to_form(@empty_person, as: :person))
    |> assign(:membership_form, to_form(@empty_membership, as: :membership))
    |> assign(:message_form, to_form(@empty_message, as: :message))
  end

  defp refresh_club(socket) do
    club = Membership.get_club(socket.assigns.club_id)

    socket
    |> assign(:club, club)
    |> assign(:club_form, to_form(club_form_params(club), as: :club))
  end

  defp refresh_people(socket) do
    people = Membership.list_people()

    socket
    |> assign(:person_options, person_options(people))
    |> stream(:people, people, reset: true, dom_id: &"person-#{&1.person_id}")
  end

  defp refresh_members(socket) do
    members = Membership.list_active_members_of_club(socket.assigns.club_id)

    socket
    |> assign(:member_options, member_options(members))
    |> stream(:members, members, reset: true, dom_id: &"member-#{&1.id}")
  end

  defp refresh_messages(socket) do
    stream(socket, :messages, Messaging.list_messages_for_club(socket.assigns.club_id),
      reset: true,
      dom_id: &"message-#{&1.message_id}"
    )
  end

  defp person_options(people), do: Enum.map(people, &{&1.name, &1.person_id})

  defp member_options(members), do: Enum.map(members, &{&1.name, &1.id})

  defp club_form_params(nil), do: @empty_club

  defp club_form_params(club) do
    %{"name" => club.name, "slug" => club.slug}
  end

  defp format_reason(reason), do: reason |> inspect() |> String.replace("_", " ")
end
