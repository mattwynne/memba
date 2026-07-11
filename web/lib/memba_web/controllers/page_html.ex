defmodule MembaWeb.PageHTML do
  @moduledoc """
  This module contains pages rendered by PageController.

  See the `page_html` directory for all templates available.
  """
  use MembaWeb, :html

  alias Memba.ClubInboundEmailAddress
  alias MembaWeb.ClubSite

  embed_templates "page_html/*"

  attr :entry, :map, required: true
  attr :selected_club, :map, required: true
  attr :club_id_source, :string, default: nil

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
          <div
            id={"member-conversation-entry-menu-#{@entry.message.message_id}"}
            data-testid="member-conversation-entry-menu"
            class="message__menu dropdown dropdown-end"
          >
            <button
              id={"member-conversation-entry-menu-button-#{@entry.message.message_id}"}
              type="button"
              tabindex="0"
              role="button"
              aria-haspopup="menu"
              aria-label="Message options"
              class="message__kebab"
            >
              <.icon name="hero-ellipsis-vertical" />
            </button>
            <div tabindex="0" role="menu" class="dropdown-content message-menu">
              <.link
                id={"member-conversation-entry-delivery-link-#{@entry.message.message_id}"}
                data-testid="member-conversation-entry-delivery-link"
                href={
                  member_message_delivery_path(
                    @entry.message.message_id,
                    @selected_club,
                    @club_id_source
                  )
                }
                role="menuitem"
              >
                <.icon name="hero-envelope" /> Delivery details
              </.link>
            </div>
          </div>
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

  defp club_inbound_email_address(club), do: ClubInboundEmailAddress.address(club)

  defp active_member_section?(active_section, section), do: active_section == section

  defp member_section_tab_class(active_section, section) do
    ["section-tab", active_member_section?(active_section, section) && "is-active"]
  end

  defp member_section_aria_selected(active_section, section) do
    active_member_section?(active_section, section) |> to_string()
  end

  defp current_dashboard_member?(%{id: member_id}, %{id: current_member_id}) do
    member_id == current_member_id
  end

  defp current_dashboard_member?(_member, _current_member), do: false

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

  defp member_club_home_path(_selected_club, "host"), do: ~p"/conversations"

  defp member_club_home_path(selected_club, _source),
    do: ClubSite.url(selected_club, "/conversations")

  defp member_section_path("conversations", _selected_club, "host"), do: ~p"/conversations"
  defp member_section_path("members", _selected_club, "host"), do: ~p"/members"

  defp member_section_path(section, selected_club, _source),
    do: ClubSite.url(selected_club, "/#{section}")

  defp member_compose_path(_selected_club, "host"), do: ~p"/messages/new"

  defp member_compose_path(selected_club, _source),
    do: ClubSite.url(selected_club, "/messages/new")

  defp member_invitation_path(_selected_club, "host"), do: ~p"/members/invitations/new"

  defp member_invitation_path(selected_club, _source),
    do: ClubSite.url(selected_club, "/members/invitations/new")

  defp member_message_path(message_id, _selected_club, "host"), do: ~p"/messages/#{message_id}"

  defp member_message_path(message_id, selected_club, _source),
    do: ClubSite.url(selected_club, "/messages/#{message_id}")

  defp member_message_delivery_path(message_id, _selected_club, "host"),
    do: ~p"/messages/#{message_id}/delivery"

  defp member_message_delivery_path(message_id, selected_club, _source),
    do: ClubSite.url(selected_club, "/messages/#{message_id}/delivery")
end
