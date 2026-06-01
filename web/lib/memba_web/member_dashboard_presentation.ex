defmodule MembaWeb.MemberDashboardPresentation do
  @moduledoc """
  Loads and shapes data for the member dashboard LiveView.

  The LiveView owns the route/session boundary; this helper owns the selected
  club authorization checks and presentation-friendly row data so the mount path
  stays readable and the dashboard data model can be unit-tested directly.
  """

  import Ecto.Query

  alias Memba.Accounts
  alias Memba.Membership
  alias Memba.Messaging
  alias Memba.Messaging.Projections.MemberReceipt
  alias Memba.Repo
  alias MembaWeb.MemberReceiptPresentation

  @doc """
  Load dashboard assigns for a signed-in active member of the selected club.

  Returns `{:ok, assigns}` when the selected club belongs to the current
  identity and the identity can be resolved to an active member row. Missing,
  invalid, inactive, or unauthorized club/member combinations return
  `{:error, :forbidden}` so the LiveView can preserve existing route semantics.
  """
  def load(club_id, current_identity, active_clubs)
      when is_list(active_clubs) do
    with {:ok, club_id} <- cast_selected_club_id(club_id),
         {:ok, selected_club} <- fetch_selected_club(active_clubs, club_id),
         members <- load_members(club_id),
         {:ok, current_member} <- fetch_current_member(members, current_identity) do
      messages = load_messages(club_id)
      member_names_by_id = Map.new(members, &{&1.id, &1.name})
      message_rows = present_message_rows(messages, member_names_by_id)

      {:ok,
       %{
         page_title: selected_club.name,
         selected_club: selected_club,
         members: members,
         active_member_count: Enum.count(members),
         current_member: current_member,
         member_names_by_id: member_names_by_id,
         messages: messages,
         message_rows: message_rows
       }}
    else
      _missing_or_unauthorized -> {:error, :forbidden}
    end
  end

  def load(_club_id, _current_identity, _active_clubs), do: {:error, :forbidden}

  defp cast_selected_club_id(club_id) do
    case Ecto.UUID.cast(club_id) do
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

  defp load_members(club_id) do
    club_id
    |> Membership.list_active_members_of_club()
    |> Enum.map(&present_member/1)
  end

  defp fetch_current_member(_members, nil), do: {:error, :forbidden}

  defp fetch_current_member(members, identity) do
    identity_email =
      identity
      |> Map.get(:email)
      |> Accounts.normalize_email()

    case Enum.find(members, fn member ->
           Accounts.normalize_email(member.email) == identity_email
         end) do
      nil -> {:error, :forbidden}
      current_member -> {:ok, current_member}
    end
  end

  defp load_messages(club_id) do
    club_id
    |> Messaging.list_messages_for_club()
    |> Enum.reverse()
  end

  defp present_message_rows(messages, member_names_by_id) do
    receipts_by_message_id = receipts_by_message_id(messages)

    Enum.map(messages, fn message ->
      receipt_model =
        message.message_id
        |> then(&Map.get(receipts_by_message_id, &1, []))
        |> MemberReceiptPresentation.present_receipts()

      sender_name = Map.get(member_names_by_id, message.sender_id, "Club member")

      %{
        message: message,
        message_id: message.message_id,
        sender_id: message.sender_id,
        sender_name: sender_name,
        sender_initials: initials(sender_name),
        subject: message.subject,
        body: message.body,
        receipt_count: receipt_model.total_count,
        receipt_summary: receipt_model.summary,
        receipt_groups: receipt_model.groups
      }
    end)
  end

  defp receipts_by_message_id([]), do: %{}

  defp receipts_by_message_id(messages) do
    message_ids = Enum.map(messages, & &1.message_id)

    MemberReceipt
    |> where([receipt], receipt.message_id in ^message_ids)
    |> order_by([receipt],
      asc: receipt.message_id,
      asc: receipt.recipient_name,
      asc: receipt.recipient_id
    )
    |> Repo.all()
    |> Enum.group_by(& &1.message_id)
  end

  defp present_member(member) do
    initials = initials(member.name)

    member
    |> Map.put(:initials, initials)
    |> Map.put(:avatar_initials, initials)
  end

  defp initials(name) when is_binary(name) do
    name
    |> String.split(~r/\s+/, trim: true)
    |> Enum.take(2)
    |> Enum.map_join("", fn <<first::utf8, _rest::binary>> -> String.upcase(<<first::utf8>>) end)
    |> case do
      "" -> "?"
      value -> value
    end
  end

  defp initials(_name), do: "?"
end
