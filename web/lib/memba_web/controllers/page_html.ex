defmodule MembaWeb.PageHTML do
  @moduledoc """
  This module contains pages rendered by PageController.

  See the `page_html` directory for all templates available.
  """
  use MembaWeb, :html

  alias Memba.ClubInboundEmailAddress
  alias MembaWeb.ClubSite
  alias MembaWeb.MemberEmailDeliveryPresentation

  embed_templates "page_html/*"

  attr :entry, :map, required: true

  defp conversation_entry_card(assigns) do
    ~H"""
    <article
      id={"member-conversation-entry-#{@entry.message.message_id}"}
      data-testid="member-conversation-entry"
      data-conversation-kind={@entry.kind}
      data-message-id={@entry.message.message_id}
      data-sender-id={@entry.message.sender_id}
      class={[
        "rounded-3xl border bg-base-100 p-5 shadow-sm sm:p-6",
        if(@entry.kind == :original,
          do: "border-primary/25 ring-1 ring-primary/10",
          else: "border-base-300"
        )
      ]}
    >
      <div class="flex items-start gap-3">
        <span class={[
          "grid size-10 shrink-0 place-items-center rounded-full text-sm font-bold ring-1 ring-inset",
          if(@entry.kind == :original,
            do: "bg-sage-100 text-sage-800 ring-primary/20",
            else: "bg-base-200 text-base-content ring-base-300"
          )
        ]}>
          {conversation_sender_initial(@entry.sender_name)}
        </span>
        <div class="min-w-0 flex-1">
          <div class="flex flex-col gap-1 sm:flex-row sm:items-center sm:justify-between">
            <p class="font-semibold text-base-content">{@entry.sender_name}</p>
            <div class="flex flex-wrap items-center gap-2">
              <time
                :if={@entry.kind == :reply and conversation_entry_time_label(@entry)}
                id={"member-conversation-entry-timestamp-#{@entry.message.message_id}"}
                datetime={conversation_entry_datetime(@entry)}
                class="text-xs font-semibold text-ink-2"
              >
                {conversation_entry_time_label(@entry)}
              </time>
              <span
                data-testid="member-conversation-entry-label"
                class="w-fit rounded-full border border-base-300 bg-base-200 px-2.5 py-1 text-xs font-semibold uppercase tracking-[0.14em] text-ink-2"
              >
                {conversation_entry_label(@entry.kind)}
              </span>
            </div>
          </div>
          <p
            id={conversation_entry_body_id(@entry)}
            class="mt-3 whitespace-pre-wrap text-base leading-8 text-ink-2"
          >
            {@entry.message.body}
          </p>
        </div>
      </div>
    </article>
    """
  end

  defp club_inbound_email_address(club), do: ClubInboundEmailAddress.address(club)

  defp first_name(%{name: name}) when is_binary(name) do
    name
    |> String.split(~r/\s+/, trim: true)
    |> List.first()
    |> case do
      nil -> "member"
      "" -> "member"
      first_name -> first_name
    end
  end

  defp first_name(_member), do: "member"

  defp active_member_count_label(1), do: "1 current member"
  defp active_member_count_label(count), do: "#{count} current members"

  defp status_slug(status) when is_binary(status), do: String.replace(status, " ", "-")
  defp status_slug(_status), do: "unknown"

  defp receipt_bar_width(%{percentage: percentage}) when is_integer(percentage) do
    "width: #{max(percentage, 0)}%;"
  end

  defp receipt_bar_width(_status), do: "width: 0%;"

  defp receipt_recipient_initial(name) when is_binary(name) do
    case String.first(name) do
      nil -> "?"
      initial -> String.upcase(initial)
    end
  end

  defp receipt_recipient_initial(_name), do: "?"

  defp receipt_group_expanded?(%MapSet{} = expanded_groups, status) when is_binary(status) do
    MapSet.member?(expanded_groups, status)
  end

  defp receipt_group_expanded?(_expanded_groups, _status), do: false

  defp delivery_expanded?(assigns) when is_map(assigns) do
    Map.get(assigns, :delivery_expanded?, false)
  end

  defp delivery_expanded?(_assigns), do: false

  defp delivery_summary_line(summary) when is_list(summary) do
    summary
    |> Enum.map(fn status ->
      "#{status.count} #{delivery_summary_status_label(status.status)}"
    end)
    |> Enum.join(" · ")
  end

  defp delivery_summary_line(_summary), do: "Delivery details"

  defp delivery_summary_status_label("delivered"), do: "delivered"
  defp delivery_summary_status_label("sent"), do: "sending"
  defp delivery_summary_status_label("delivery problem"), do: "problems"
  defp delivery_summary_status_label(status) when is_binary(status), do: status
  defp delivery_summary_status_label(_status), do: "unknown"

  defp split_conversation_entries(entries) when is_list(entries) do
    Enum.split_with(entries, &(&1.kind == :original))
  end

  defp split_conversation_entries(_entries), do: {[], []}

  defp conversation_sender_initial(name) when is_binary(name) do
    case String.first(name) do
      nil -> "?"
      initial -> String.upcase(initial)
    end
  end

  defp conversation_sender_initial(_name), do: "?"

  defp conversation_entry_label(:original), do: "Original message"
  defp conversation_entry_label(_kind), do: "Reply"

  defp conversation_entry_time_label(%{message: %{inserted_at: %DateTime{} = inserted_at}}) do
    Calendar.strftime(inserted_at, "%b %d, %I:%M %p UTC")
  end

  defp conversation_entry_time_label(_entry), do: nil

  defp conversation_entry_datetime(%{message: %{inserted_at: %DateTime{} = inserted_at}}) do
    DateTime.to_iso8601(inserted_at)
  end

  defp conversation_entry_datetime(_entry), do: nil

  defp conversation_entry_body_id(%{kind: :original}), do: "member-message-body"

  defp conversation_entry_body_id(%{message: %{message_id: message_id}}) do
    "member-conversation-body-#{message_id}"
  end

  defp member_club_home_path(_selected_club, "host"), do: ~p"/"
  defp member_club_home_path(selected_club, _source), do: ClubSite.url(selected_club)

  defp member_compose_path(_selected_club, "host"), do: ~p"/messages/new"

  defp member_compose_path(selected_club, _source),
    do: ClubSite.url(selected_club, "/messages/new")

  defp member_invitation_path(_selected_club, "host"), do: ~p"/members/invitations/new"

  defp member_invitation_path(selected_club, _source),
    do: ClubSite.url(selected_club, "/members/invitations/new")

  defp member_message_path(message_id, _selected_club, "host"), do: ~p"/messages/#{message_id}"

  defp member_message_path(message_id, selected_club, _source),
    do: ClubSite.url(selected_club, "/messages/#{message_id}")

  defp message_sent_date_label(%{inserted_at: %DateTime{} = inserted_at}) do
    Calendar.strftime(inserted_at, "%b %d, %Y")
  end

  defp message_sent_date_label(_message), do: nil

  defp message_sent_datetime(%{inserted_at: %DateTime{} = inserted_at}) do
    DateTime.to_iso8601(inserted_at)
  end

  defp message_sent_datetime(_message), do: nil

  defp status_bg_class(status), do: MemberEmailDeliveryPresentation.status_bg_class(status)
  defp status_text_class(status), do: MemberEmailDeliveryPresentation.status_text_class(status)
  defp status_tint_class(status), do: MemberEmailDeliveryPresentation.status_tint_class(status)
end
