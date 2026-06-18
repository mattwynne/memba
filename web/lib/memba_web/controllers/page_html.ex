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

  defp receipt_segment_width(%{width_percentage: percentage}) when is_integer(percentage) do
    "width: #{percentage |> max(0) |> min(100)}%;"
  end

  defp receipt_segment_width(_segment), do: "width: 0%;"

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

  defp status_bg_class(status), do: MemberEmailDeliveryPresentation.status_bg_class(status)
  defp status_text_class(status), do: MemberEmailDeliveryPresentation.status_text_class(status)
  defp status_tint_class(status), do: MemberEmailDeliveryPresentation.status_tint_class(status)
end
