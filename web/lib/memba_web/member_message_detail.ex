defmodule MembaWeb.MemberMessageDetail do
  @moduledoc """
  Loads the member-facing message detail data for the LiveView route.

  The route-level plugs keep the public HTTP authorization semantics intact.
  This helper repeats the selected-club and message ownership checks inside the
  LiveView mount path so connected LiveView mounts do not depend only on the
  initial controller pipeline.
  """

  alias Memba.Membership
  alias Memba.Messaging
  alias MembaWeb.MemberEmailDeliveryPresentation

  @doc """
  Load the selected club message detail for a signed-in member.

  Returns:

    * `{:ok, assigns}` when the selected active club owns the requested message;
    * `{:error, :forbidden}` for missing, invalid, or inactive selected clubs;
    * `{:error, :not_found}` for missing messages or message/club mismatches.
  """
  def load(params, active_clubs) when is_map(params) and is_list(active_clubs) do
    with {:ok, club_id} <- cast_selected_club_id(params),
         {:ok, selected_club} <- fetch_selected_club(active_clubs, club_id),
         {:ok, message} <- fetch_message(params),
         :ok <- require_message_in_club(message, club_id) do
      {:ok, detail_assigns(selected_club, message)}
    end
  end

  def load(_params, _active_clubs), do: {:error, :forbidden}

  defp cast_selected_club_id(params) do
    case Ecto.UUID.cast(Map.get(params, "club_id")) do
      {:ok, club_id} -> {:ok, club_id}
      :error -> {:error, :forbidden}
    end
  end

  defp fetch_selected_club(active_clubs, club_id) do
    case Enum.find(active_clubs, fn club -> club.club_id == club_id end) do
      nil -> {:error, :forbidden}
      selected_club -> {:ok, selected_club}
    end
  end

  defp fetch_message(params) do
    case Messaging.get_message(Map.get(params, "message_id")) do
      nil -> {:error, :not_found}
      message -> {:ok, message}
    end
  end

  defp require_message_in_club(message, club_id) do
    if message.club_id == club_id do
      :ok
    else
      {:error, :not_found}
    end
  end

  defp detail_assigns(selected_club, message) do
    receipt_model =
      message.message_id
      |> Messaging.list_member_email_deliverys()
      |> MemberEmailDeliveryPresentation.present_receipts()

    sender = Membership.get_person(message.sender_id)

    %{
      page_title: message.subject,
      selected_club: selected_club,
      message: message,
      sender_name: sender_name(sender),
      member_email_deliverys: receipt_model.receipts,
      member_email_delivery_count: receipt_model.total_count,
      member_email_delivery_summary: receipt_model.summary,
      member_email_delivery_groups: receipt_model.groups
    }
  end

  defp sender_name(%{name: name}) when is_binary(name) and name != "", do: name
  defp sender_name(_sender), do: "Club member"
end
