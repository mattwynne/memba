defmodule MembaWeb.MemberReceiptPresentation do
  @moduledoc """
  Presentation mapping for member-facing receipt statuses.

  The messaging projection stores stable internal receipt status values. This
  module maps those values to member-facing copy and Heroicon names without
  changing the projection vocabulary.
  """

  @fallback_status "sent"

  @presentations %{
    "sent" => %{label: "Sending", icon: "hero-clock"},
    "delivered" => %{label: "Delivered", icon: "hero-check-circle"},
    "delivery problem" => %{label: "Delivery problem", icon: "hero-exclamation-triangle"},
    "opened" => %{label: "Opened", icon: "hero-envelope-open"}
  }

  @doc """
  Returns the member-facing label and icon for an internal receipt status.

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
    presentation = present_status(Map.get(receipt, :receipt_status))

    %{
      recipient_id: Map.get(receipt, :recipient_id),
      recipient_name: Map.get(receipt, :recipient_name),
      status: presentation.status,
      status_label: presentation.label,
      status_icon: presentation.icon
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
end
