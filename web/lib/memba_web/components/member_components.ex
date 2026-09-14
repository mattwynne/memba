defmodule MembaWeb.MemberComponents do
  @moduledoc """
  Stateless presentation components for signed-in member surfaces.

  These components deliberately receive already-shaped presentation rows and
  route URLs from their caller. They do not load data, check domain
  permissions, or infer dashboard route context.
  """
  use MembaWeb, :html

  attr :rows, :list, required: true
  slot :empty_action, required: true

  def conversation_list(assigns) do
    ~H"""
    <div id="member-message-list" class="conversation-list mt-4">
      <div
        :if={@rows == []}
        id="member-message-list-empty"
        class="rounded-3xl border border-dashed border-base-300 bg-base-100 px-6 py-8 text-center shadow-sm"
      >
        <div class="mx-auto flex size-12 items-center justify-center rounded-2xl bg-base-200 text-ink-2 ring-1 ring-base-300">
          <.icon name="hero-envelope" class="size-6" />
        </div>
        <h3 class="mt-4 text-base font-semibold text-base-content">
          No club messages yet
        </h3>
        <p class="mx-auto mt-1 max-w-sm text-sm leading-6 text-ink-2">
          When a member sends a message, it will appear here.
        </p>
        <div class="mt-5">
          {render_slot(@empty_action)}
        </div>
      </div>

      <.conversation_row :for={row <- @rows} row={row} />
    </div>
    """
  end

  attr :row, :map, required: true

  def conversation_row(assigns) do
    ~H"""
    <article
      id={"member-message-#{@row.message_id}"}
      data-testid="club-message-row"
      data-message-id={@row.message_id}
      data-message-subject={@row.subject}
    >
      <.link data-testid="club-message-link" href={@row.href} class="conversation">
        <.avatar
          data-testid="message-originator-initials"
          initials={@row.originator_initials}
          size={:md}
          class="conversation__avatar"
        />

        <div class="conversation__body">
          <div class="conversation__head">
            <span class="conversation__subject">
              {@row.subject}
            </span>

            <span
              :if={@row.sent_at_label}
              data-testid="message-sent-at"
              class="conversation__date"
            >
              {@row.sent_at_label}
            </span>
          </div>

          <div data-testid="message-body-preview" class="conversation__preview">
            {@row.body}
          </div>

          <span
            data-testid="message-started-by"
            data-originator-id={@row.originator_id}
            data-originator-name={@row.originator_name}
            class="conversation__replies"
          >
            Started by {@row.originator_name}
          </span>

          <div class="conversation__participants">
            <.participant_avatar_stack
              participants={@row.participants}
              additional_count={@row.additional_participant_count}
            />

            <span
              data-testid="message-reply-activity"
              data-reply-count={@row.reply_count}
              data-latest-replier-id={@row.latest_replier_id}
              data-latest-replier-name={@row.latest_replier_name}
              class="conversation__replies"
            >
              {@row.reply_activity_label}
            </span>
          </div>
        </div>
      </.link>
    </article>
    """
  end

  attr :participants, :list, required: true
  attr :additional_count, :integer, default: 0

  def participant_avatar_stack(assigns) do
    ~H"""
    <div
      :if={participant_avatar_stack_visible?(@participants, @additional_count)}
      class="avatar-stack"
      data-testid="message-participant-avatar-stack"
      aria-label="Conversation participants"
    >
      <.avatar
        :for={participant <- @participants}
        data-testid="message-participant-avatar"
        data-participant-id={participant.id}
        data-participant-name={participant.name}
        initials={participant.initials}
        size={:sm}
        title={participant.name}
      />
      <span
        :if={@additional_count > 0}
        class="is-more"
        data-testid="message-participant-overflow"
        aria-label={"#{@additional_count} more participants"}
      >
        +{@additional_count}
      </span>
    </div>
    """
  end

  attr :rows, :list, required: true
  attr :active_member_count, :integer, required: true
  attr :current_member, :map, default: nil
  attr :group_name, :string, required: true

  def member_list(assigns) do
    ~H"""
    <div
      id="active-members-list"
      data-active-member-count={@active_member_count}
      data-active-members-state={active_members_state(@active_member_count)}
      class="member-list mt-4"
    >
      <p :if={@rows == []} id="active-members-empty-state" class="empty-members">
        <strong>{@group_name} has no members.</strong>
        Its conversations and emails are kept; whoever you add next will see them all.
      </p>
      <.member_row :for={row <- @rows} row={row} current_member={@current_member} />
    </div>
    """
  end

  attr :row, :map, required: true
  attr :current_member, :map, default: nil

  def member_row(assigns) do
    ~H"""
    <div
      id={"club-member-#{@row.id}"}
      data-testid="club-member-row"
      data-member-id={@row.id}
      data-current-member={to_string(current_dashboard_member?(@row, @current_member))}
      class="member-row"
    >
      <div class="member-row__avatar" aria-hidden="true">
        {@row.initials}
      </div>

      <div class="member-row__body">
        <div class="member-row__name">
          {@row.name}
        </div>
        <div class="member-row__meta">
          <span
            :if={current_dashboard_member?(@row, @current_member)}
            data-testid="club-member-current-indicator"
          >
            You
          </span>
        </div>
      </div>

      <div :if={member_roles(@row) != []} class="flex flex-none flex-wrap justify-end gap-2">
        <span
          :for={role <- member_roles(@row)}
          class="member-row__role badge badge-primary badge-soft"
        >
          {role}
        </span>
      </div>
    </div>
    """
  end

  attr :club_name, :string, required: true
  attr :group_name, :string, required: true

  attr :viewer_access, :atom,
    required: true,
    values: [:participating_member, :outside_admin]

  def custom_group_membership_guidance(assigns) do
    ~H"""
    <p
      id="member-group-membership-guidance"
      class="members-note"
      data-viewer-access={@viewer_access}
    >
      <%= if @viewer_access == :participating_member do %>
        {@group_name} members can read every {@group_name} conversation and get its emails.
        Anyone in {@group_name} can add other <strong>{@club_name}</strong>
        members—that never changes their club membership.
      <% else %>
        Anyone in {@group_name} can add other <strong>{@club_name}</strong>
        members. As a club admin you can too—that never changes anyone's club membership.
      <% end %>
    </p>
    """
  end

  attr :club_name, :string, required: true
  attr :group_name, :string, required: true
  attr :candidates, :list, required: true
  attr :query, :string, default: ""
  attr :search_form, Phoenix.HTML.Form, required: true

  def custom_group_member_picker(assigns) do
    assigns =
      assign(assigns, :visible_candidates, filter_candidates(assigns.candidates, assigns.query))

    ~H"""
    <section
      id="custom-group-member-picker"
      class="picker"
      aria-labelledby="custom-group-member-picker-title"
      phx-window-keydown={close_custom_group_member_picker()}
      phx-key="Escape"
    >
      <div class="picker__head">
        <div>
          <h2 id="custom-group-member-picker-title" class="picker__title">
            Add to {@group_name}
          </h2>
          <p class="picker__hint">
            Only people who are already active members of {@club_name} can be added.
            They'll get a welcome email and can read everything in {@group_name}. Inviting
            someone new to the club stays a separate action on Everyone.
          </p>
        </div>
        <.button
          id="custom-group-member-picker-close"
          type="button"
          variant="ghost"
          size="sm"
          phx-click={close_custom_group_member_picker()}
        >
          Close
        </.button>
      </div>

      <.form
        for={@search_form}
        id="custom-group-member-search-form"
        phx-change="filter_custom_group_member_candidates"
      >
        <.input
          field={@search_form[:query]}
          id="custom-group-member-search"
          type="search"
          class="input mt-3 w-full"
          placeholder="Search club members…"
          autocomplete="off"
          aria-label="Search club members"
          phx-debounce="150"
          phx-mounted={JS.focus()}
        />
      </.form>

      <div
        :if={@visible_candidates != []}
        id="custom-group-member-candidates"
        class="pick-list"
        role="list"
        aria-label={"Club members not yet in #{@group_name}"}
      >
        <div
          :for={candidate <- @visible_candidates}
          id={"custom-group-member-candidate-#{candidate.id}"}
          class="pick-row"
          role="listitem"
          data-testid="custom-group-member-candidate"
          data-membership-id={candidate.membership_id}
          data-person-id={candidate.id}
        >
          <div class="pick-row__avatar" aria-hidden="true">
            {candidate.initials}
          </div>
          <div class="pick-row__name">
            {candidate.name}
            <small :if={candidate_club_admin?(candidate)} class="pick-row__meta">
              Club admin
            </small>
          </div>
          <.button
            id={"custom-group-member-candidate-add-#{candidate.id}"}
            type="button"
            variant="primary"
            size="sm"
            class="btn-outline"
            data-custom-group-member-action="add"
            data-membership-id={candidate.membership_id}
            data-person-id={candidate.id}
          >
            Add
          </.button>
        </div>
      </div>

      <p :if={@visible_candidates == []} id="custom-group-member-picker-empty" class="pick-empty">
        <%= if empty_query?(@query) do %>
          Everyone in {@club_name} is already in {@group_name}.
        <% else %>
          No active club members match your search.
        <% end %>
      </p>
    </section>
    """
  end

  attr :group_name, :string, required: true

  def outside_group_admin_notice(assigns) do
    ~H"""
    <div
      id="member-group-outside-admin-notice"
      class="outside"
      role="region"
      aria-label="You're managing a group you're not in"
    >
      <.icon name="hero-user" class="size-5" aria-hidden="true" />
      <div class="outside__body">
        <h2 class="outside__title">
          You're a club admin, but you're not in {@group_name}
        </h2>
        <p class="outside__copy">
          You can manage who's in it. You can't read its conversations or get its emails
          unless you're a member—being a club admin doesn't grant that on its own.
        </p>
        <div class="outside__actions">
          <.button
            id="member-group-add-self"
            type="button"
            size="sm"
            data-custom-group-member-action="add-self"
          >
            Add yourself to {@group_name}
          </.button>
          <small id="member-group-add-self-help">
            You'll get {@group_name}'s emails from now on and can read its whole history.
            That won't change your club admin role.
          </small>
        </div>
      </div>
    </div>
    """
  end

  defp active_members_state(0), do: "empty"
  defp active_members_state(1), do: "first-member"

  defp active_members_state(_active_member_count), do: "active-members"

  defp close_custom_group_member_picker do
    JS.push("close_custom_group_member_picker")
    |> JS.focus(to: "#member-section-action-add-group-member")
  end

  defp participant_avatar_stack_visible?(participants, additional_count) do
    participants != [] or additional_count > 0
  end

  defp current_dashboard_member?(%{id: member_id}, %{id: current_member_id}) do
    member_id == current_member_id
  end

  defp current_dashboard_member?(_member, _current_member), do: false

  defp member_roles(member), do: Map.get(member, :roles, [])

  defp filter_candidates(candidates, query) do
    normalized_query = query |> to_string() |> String.trim() |> String.downcase()

    if normalized_query == "" do
      candidates
    else
      Enum.filter(candidates, fn candidate ->
        candidate.name
        |> String.downcase()
        |> String.contains?(normalized_query)
      end)
    end
  end

  defp candidate_club_admin?(candidate), do: "Admin" in member_roles(candidate)

  defp empty_query?(query), do: String.trim(to_string(query)) == ""
end
