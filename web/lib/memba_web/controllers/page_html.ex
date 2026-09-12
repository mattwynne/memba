defmodule MembaWeb.PageHTML do
  @moduledoc """
  This module contains pages rendered by PageController.

  See the `page_html` directory for all templates available.
  """
  use MembaWeb, :html

  import MembaWeb.MemberComponents, only: [conversation_list: 1, member_list: 1]

  alias MembaWeb.ClubSite
  alias MembaWeb.MemberDashboardGroupTabs

  embed_templates "page_html/*"

  attr :entry, :map, required: true
  attr :selected_club, :map, required: true
  attr :club_id_source, :string, default: nil
  attr :group_id, :string, default: nil

  defp conversation_entry_card(assigns) do
    ~H"""
    <article
      id={"member-conversation-entry-#{@entry.message.message_id}"}
      data-testid="member-conversation-entry"
      data-conversation-kind={@entry.kind}
      data-message-id={@entry.message.message_id}
      data-sender-id={@entry.message.sender_id}
      class={["message", @entry.kind == :original && "message--original"]}
    >
      <span class="message__avatar">
        {conversation_sender_initial(@entry.sender_name)}
      </span>
      <div class="message__body">
        <div class="message__head">
          <p class="message__name">{@entry.sender_name}</p>
          <time
            data-testid="member-conversation-entry-time"
            datetime={DateTime.to_iso8601(@entry.message.inserted_at)}
            class="message__time"
          >
            {format_message_time(@entry.message.inserted_at)}
          </time>
          <.context_kebab_menu
            id={"member-conversation-entry-menu-#{@entry.message.message_id}"}
            button_id={"member-conversation-entry-menu-button-#{@entry.message.message_id}"}
            data-testid="member-conversation-entry-menu"
            label="Message options"
          >
            <.link
              id={"member-conversation-entry-delivery-link-#{@entry.message.message_id}"}
              data-testid="member-conversation-entry-delivery-link"
              href={
                member_message_delivery_path(
                  @entry.message.message_id,
                  @selected_club,
                  @club_id_source,
                  @group_id
                )
              }
            >
              <.icon name="hero-envelope" /> Delivery details
            </.link>
          </.context_kebab_menu>
        </div>
        <p id={conversation_entry_body_id(@entry)} class="message__text">
          {@entry.message.body}
        </p>
      </div>
    </article>
    """
  end

  defp format_message_time(%DateTime{} = inserted_at) do
    Calendar.strftime(inserted_at, "%-d %b, %-I:%M%P")
  end

  defp active_member_section?(active_section, section), do: active_section == section

  defp member_group_rail_item_class(group, selected_group) do
    ["group-rail__item", selected_group?(group, selected_group) && "is-active"]
  end

  defp member_group_aria_current(group, selected_group) do
    if selected_group?(group, selected_group), do: "true"
  end

  defp selected_group?(%{group_id: group_id}, %{group_id: selected_group_id}) do
    group_id == selected_group_id
  end

  defp group_member_count_label(1), do: "1 member"

  defp group_member_count_label(member_count) when is_integer(member_count) do
    "#{member_count} members"
  end

  defp dashboard_conversation_rows(rows, selected_club, club_id_source, selected_group_route_id) do
    Enum.map(rows, fn row ->
      Map.put(
        row,
        :href,
        member_message_path(row.message_id, selected_club, club_id_source, selected_group_route_id)
      )
    end)
  end

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

  defp conversation_entry_body_id(%{kind: :original}), do: "member-message-body"

  defp conversation_entry_body_id(%{message: %{message_id: message_id}}) do
    "member-conversation-body-#{message_id}"
  end

  defp member_club_home_path(_selected_club, %{
         "club_id_source" => "host",
         "group_id" => group_id
       })
       when is_binary(group_id) and group_id != "",
       do: ~p"/groups/#{group_id}"

  defp member_club_home_path(selected_club, %{"group_id" => group_id})
       when is_binary(group_id) and group_id != "",
       do: ClubSite.url(selected_club, ~p"/groups/#{group_id}")

  defp member_club_home_path(_selected_club, %{"club_id_source" => "host"}),
    do: ~p"/conversations"

  defp member_club_home_path(selected_club, _route_params),
    do: ClubSite.url(selected_club, "/conversations")

  defp member_section_path("conversations", _selected_club, "host", group_id)
       when is_binary(group_id),
       do: ~p"/groups/#{group_id}"

  defp member_section_path("members", _selected_club, "host", group_id)
       when is_binary(group_id),
       do: ~p"/groups/#{group_id}/members"

  defp member_section_path("conversations", _selected_club, "host", nil),
    do: ~p"/conversations"

  defp member_section_path("members", _selected_club, "host", nil), do: ~p"/members"

  defp member_section_path("conversations", selected_club, _source, group_id)
       when is_binary(group_id),
       do: ClubSite.url(selected_club, ~p"/groups/#{group_id}")

  defp member_section_path("members", selected_club, _source, group_id)
       when is_binary(group_id),
       do: ClubSite.url(selected_club, ~p"/groups/#{group_id}/members")

  defp member_section_path(section, selected_club, _source, nil),
    do: ClubSite.url(selected_club, "/#{section}")

  defp member_compose_path(selected_club, source, group_id) do
    selected_club
    |> member_compose_path(source)
    |> with_group_context(group_id)
  end

  defp member_compose_path(_selected_club, "host"), do: ~p"/messages/new"

  defp member_compose_path(selected_club, _source),
    do: ClubSite.url(selected_club, "/messages/new")

  defp member_invitation_path(selected_club, source, group_id) do
    selected_club
    |> member_invitation_path(source)
    |> with_group_context(group_id)
  end

  defp member_invitation_path(_selected_club, "host"), do: ~p"/members/invitations/new"

  defp member_invitation_path(selected_club, _source),
    do: ClubSite.url(selected_club, "/members/invitations/new")

  defp member_message_path(message_id, selected_club, source, group_id) do
    message_id
    |> member_message_path(selected_club, source)
    |> with_group_context(group_id)
  end

  defp member_message_path(message_id, _selected_club, "host"),
    do: ~p"/messages/#{message_id}"

  defp member_message_path(message_id, selected_club, _source),
    do: ClubSite.url(selected_club, "/messages/#{message_id}")

  defp member_message_delivery_path(message_id, selected_club, source, group_id) do
    message_id
    |> member_message_delivery_path(selected_club, source)
    |> with_group_context(group_id)
  end

  defp member_message_delivery_path(message_id, _selected_club, "host") do
    ~p"/messages/#{message_id}/delivery"
  end

  defp member_message_delivery_path(message_id, selected_club, _source),
    do: ClubSite.url(selected_club, "/messages/#{message_id}/delivery")

  defp with_group_context(path, group_id) when is_binary(group_id) and group_id != "" do
    path <> "?" <> URI.encode_query(%{"group_id" => group_id})
  end

  defp with_group_context(path, _group_id), do: path
end
