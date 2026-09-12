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

  def member_list(assigns) do
    ~H"""
    <div
      id="active-members-list"
      data-active-member-count={@active_member_count}
      data-active-members-state={active_members_state(@active_member_count)}
      class="member-list mt-4"
    >
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

  defp active_members_state(active_member_count) when active_member_count <= 1 do
    "first-member"
  end

  defp active_members_state(_active_member_count), do: "active-members"

  defp participant_avatar_stack_visible?(participants, additional_count) do
    participants != [] or additional_count > 0
  end

  defp current_dashboard_member?(%{id: member_id}, %{id: current_member_id}) do
    member_id == current_member_id
  end

  defp current_dashboard_member?(_member, _current_member), do: false

  defp member_roles(member), do: Map.get(member, :roles, [])
end
