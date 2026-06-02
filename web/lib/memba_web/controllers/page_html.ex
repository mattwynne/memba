defmodule MembaWeb.PageHTML do
  @moduledoc """
  This module contains pages rendered by PageController.

  See the `page_html` directory for all templates available.
  """
  use MembaWeb, :html

  embed_templates "page_html/*"

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

  defp active_member_count_label(1), do: "1 active member"
  defp active_member_count_label(count), do: "#{count} active members"

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

  defp status_bg_class("opened"), do: "bg-emerald-500"
  defp status_bg_class("delivered"), do: "bg-sky-500"
  defp status_bg_class("sent"), do: "bg-slate-400"
  defp status_bg_class("delivery problem"), do: "bg-amber-500"
  defp status_bg_class(_status), do: "bg-slate-300"

  defp status_text_class("opened"), do: "text-emerald-700"
  defp status_text_class("delivered"), do: "text-sky-700"
  defp status_text_class("sent"), do: "text-slate-600"
  defp status_text_class("delivery problem"), do: "text-amber-700"
  defp status_text_class(_status), do: "text-slate-600"

  defp status_tint_class("opened"), do: "bg-emerald-50 text-emerald-700 ring-emerald-200"
  defp status_tint_class("delivered"), do: "bg-sky-50 text-sky-700 ring-sky-200"
  defp status_tint_class("sent"), do: "bg-slate-100 text-slate-600 ring-slate-200"

  defp status_tint_class("delivery problem"),
    do: "bg-amber-50 text-amber-700 ring-amber-200"

  defp status_tint_class(_status), do: "bg-slate-100 text-slate-600 ring-slate-200"
end
