defmodule MembaWeb.MemberEmailDeliveryPresentation do
  @moduledoc """
  Presentation mapping for member-facing statuses.

  The messaging projection stores stable internal status values. This
  module maps those values to member-facing copy and Heroicon names without
  changing the projection vocabulary.
  """

  @fallback_status "sent"
  @status_order ["opened", "delivered", "sent", "delivery problem"]

  @presentations %{
    "sent" => %{label: "Sending", icon: "hero-clock"},
    "delivered" => %{label: "Delivered", icon: "hero-check-circle"},
    "delivery problem" => %{label: "Delivery problem", icon: "hero-exclamation-triangle"},
    "opened" => %{label: "Opened", icon: "hero-envelope-open"}
  }

  @descriptions %{
    "opened" => "read it",
    "delivered" => "arrived, not opened yet",
    "sent" => "on its way",
    "delivery problem" => "we couldn't reach them"
  }

  @doc """
  Returns the member-facing label and icon for an internal status.

  Blank or missing statuses are treated as the projection's initial `sent`
  status. Unknown statuses keep their internal value available to callers while
  falling back to readable copy and a neutral icon.
  """
  def present_status(status) do
    status = normalize_status(status)
    presentation = Map.get(@presentations, status, unknown_presentation(status))

    Map.put(presentation, :status, status)
  end

  @doc """
  Returns a template-friendly receipt map with raw status plus presentation data.
  """
  def present_receipt(receipt) do
    presentation = present_status(Map.get(receipt, :status))

    %{
      recipient_id: Map.get(receipt, :recipient_id),
      recipient_name: Map.get(receipt, :recipient_name),
      status: presentation.status,
      status_label: presentation.label,
      status_icon: presentation.icon
    }
  end

  @doc """
  Builds the LiveView receipt presentation model for a message.

  The summary always includes the four member-facing statuses in the design
  order, even when a status has no receipts. Groups are built from the same
  status models but only include statuses with at least one receipt.
  """
  def present_receipts(receipts) when is_list(receipts) do
    presented_receipts = Enum.map(receipts, &present_receipt/1)
    total_count = Enum.count(presented_receipts)
    receipts_by_status = Enum.group_by(presented_receipts, & &1.status)

    summary =
      Enum.map(@status_order, fn status ->
        status_receipts = Map.get(receipts_by_status, status, [])
        status_model(status, status_receipts, total_count)
      end)

    groups =
      summary
      |> Enum.filter(&(&1.count > 0))
      |> Enum.map(fn status_model ->
        Map.put(status_model, :receipts, Map.fetch!(receipts_by_status, status_model.status))
      end)

    %{
      receipts: presented_receipts,
      total_count: total_count,
      summary: summary,
      groups: groups
    }
  end

  defp normalize_status(status) when is_binary(status) do
    if status == "", do: @fallback_status, else: status
  end

  defp normalize_status(_status), do: @fallback_status

  defp unknown_presentation(status) do
    %{label: humanize_status(status), icon: "hero-question-mark-circle"}
  end

  defp humanize_status(status) do
    status
    |> String.split(~r/\s+/, trim: true)
    |> case do
      [] -> "Sending"
      words -> words |> Enum.join(" ") |> String.capitalize()
    end
  end

  defp status_model(status, receipts, total_count) do
    presentation = present_status(status)
    count = Enum.count(receipts)

    %{
      status: status,
      status_label: presentation.label,
      status_icon: presentation.icon,
      description: Map.fetch!(@descriptions, status),
      count: count,
      percentage: percentage(count, total_count)
    }
  end

  defp percentage(_count, 0), do: 0
  defp percentage(count, total_count), do: round(count * 100 / total_count)
end
