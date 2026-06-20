defmodule MembaWeb.MemberEmailDeliveryPresentation do
  @moduledoc """
  Presentation mapping for member-facing statuses.

  The messaging projection stores stable internal status values. This
  module maps those values to member-facing copy and Heroicon names without
  changing the projection vocabulary.
  """

  @fallback_status "sent"
  @status_order ["delivered", "sent", "delivery problem"]
  @status_aliases %{
    "pending" => "sent",
    "dispatching" => "sent",
    "failed" => "sent",
    "delayed" => "delivery problem",
    "bounced" => "delivery problem",
    "spam_complaint" => "delivery problem",
    "spam complaint" => "delivery problem"
  }

  @presentations %{
    "sent" => %{label: "Sending", icon: "hero-clock", tone: "warning"},
    "delivered" => %{label: "Delivered", icon: "hero-check-circle", tone: "success"},
    "delivery problem" => %{
      label: "Delivery problem",
      icon: "hero-exclamation-triangle",
      tone: "error"
    }
  }

  @status_bg_classes %{
    "delivered" => "bg-sage-600",
    "sent" => "bg-warning",
    "delivery problem" => "bg-error"
  }

  @status_text_classes %{
    "delivered" => "text-sage-700",
    "sent" => "text-warning",
    "delivery problem" => "text-error"
  }

  @status_tint_classes %{
    "delivered" => "bg-sage-50 text-sage-700 ring-sage-200",
    "sent" => "bg-warning-soft text-warning ring-warning/25",
    "delivery problem" => "bg-error-soft text-error ring-error/25"
  }

  @descriptions %{
    "delivered" => "Email delivered",
    "sent" => "Email still sending",
    "delivery problem" => "Email not delivered"
  }

  @doc """
  Returns the member-facing label and icon for an internal status.

  Blank or missing statuses are treated as the member projection's initial
  `sent` status. Detailed provider outcomes and async dispatch infrastructure
  states are folded into the small member-facing vocabulary before any copy is
  shown.
  """
  def present_status(status) do
    status = normalize_status(status)
    presentation = Map.get(@presentations, status, unknown_presentation(status))

    Map.put(presentation, :status, status)
  end

  @doc """
  Returns the design-system status badge tone for a member delivery status.
  """
  def status_tone(status), do: present_status(status).tone

  @doc """
  Returns the filled bar/dot class for member delivery summary visuals.
  """
  def status_bg_class(status) do
    status
    |> normalize_status()
    |> then(&Map.get(@status_bg_classes, &1, "bg-base-300"))
  end

  @doc """
  Returns the text/icon class for member delivery status accents.
  """
  def status_text_class(status) do
    status
    |> normalize_status()
    |> then(&Map.get(@status_text_classes, &1, "text-ink-2"))
  end

  @doc """
  Returns the soft tint class for member delivery icons and initials.
  """
  def status_tint_class(status) do
    status
    |> normalize_status()
    |> then(&Map.get(@status_tint_classes, &1, "bg-base-200 text-ink-2 ring-base-300"))
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
      status_icon: presentation.icon,
      status_tone: presentation.tone
    }
  end

  @doc """
  Builds the LiveView receipt presentation model for a message.

  The summary always includes the three member-facing statuses in the design
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
    case status do
      "" -> @fallback_status
      status -> Map.get(@status_aliases, status, status)
    end
  end

  defp normalize_status(_status), do: @fallback_status

  defp unknown_presentation(status) do
    %{label: humanize_status(status), icon: "hero-question-mark-circle", tone: "neutral"}
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
      status_tone: presentation.tone,
      description: Map.fetch!(@descriptions, status),
      count: count,
      percentage: percentage(count, total_count)
    }
  end

  defp percentage(_count, 0), do: 0
  defp percentage(count, total_count), do: round(count * 100 / total_count)
end
