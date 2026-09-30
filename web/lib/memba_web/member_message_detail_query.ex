defmodule MembaWeb.MemberMessageDetailQuery do
  @moduledoc """
  Fresh-authorized live query for one member conversation detail.

  The routed club and message plus the authenticated email are stable inputs.
  Every load normalizes that email, resolves active-club and current-member
  authority again, and returns the complete conversation, follow, and joined
  delivery model with a replacement set of app-private interests.
  """

  alias Memba.Accounts
  alias MembaWeb.LiveQuery.Query
  alias MembaWeb.MemberMessageDetail

  @fallback_families [
    :club,
    :membership,
    :person,
    :group_membership,
    :message,
    :conversation_access,
    :conversation_follow,
    :delivery
  ]

  @doc """
  Returns the extraction-facing query descriptor for conversation detail.
  """
  @spec query() :: Query.t()
  def query do
    Query.new!(
      id: :member_message_detail,
      assign: :message_detail,
      load: fn inputs ->
        case load(inputs.club_id, inputs.message_id, inputs.authenticated_email) do
          {:ok, detail} -> {:ok, detail, interests(detail)}
          {:error, reason} -> {:error, reason}
        end
      end
    )
  end

  @doc """
  Loads one coherent detail model from freshly resolved authenticated authority.
  """
  @spec load(term(), term(), term()) :: {:ok, map()} | {:error, :forbidden | :not_found}
  def load(club_id, message_id, authenticated_email) do
    normalized_email = Accounts.normalize_email(authenticated_email)
    active_clubs = Accounts.list_active_clubs_for_email(normalized_email)
    identity = if normalized_email, do: %{email: normalized_email}

    MemberMessageDetail.load(
      %{"club_id" => club_id, "message_id" => message_id},
      active_clubs,
      identity
    )
  end

  @doc """
  Derives complete collection, identity, delivery, follow, and authority
  interests from a successful coherent result.
  """
  @spec interests(map()) :: [term()]
  def interests(detail) when is_map(detail) do
    selected_club = Map.fetch!(detail, :selected_club)
    current_member = Map.fetch!(detail, :current_member)
    audience = Map.fetch!(detail, :conversation_audience)
    root_message = Map.get(detail, :root_message, Map.fetch!(detail, :message))

    club_id = Map.fetch!(selected_club, :club_id)
    person_id = Map.fetch!(current_member, :id)
    membership_id = Map.fetch!(current_member, :membership_id)
    group_id = Map.fetch!(audience, :group_id)
    conversation_id = Map.fetch!(audience, :conversation_id)
    delivery_message_id = Map.fetch!(root_message, :message_id)

    [
      {:club, club_id},
      {:club_members, club_id},
      {:membership, membership_id},
      {:person, person_id},
      {:person_clubs, person_id},
      {:group_members, group_id},
      {:group_participation, club_id, group_id, person_id},
      {:conversation, conversation_id},
      {:conversation_messages, conversation_id},
      {:conversation_access, group_id, conversation_id},
      {:conversation_follow, conversation_id, person_id},
      {:conversation_follows, conversation_id},
      {:member_conversation_follows, person_id},
      {:message_deliveries, delivery_message_id}
    ]
    |> Kernel.++(message_and_author_interests(detail))
    |> Kernel.++(delivery_interests(detail))
    |> Kernel.++(fallback_interests(club_id))
    |> Enum.uniq()
  end

  defp message_and_author_interests(detail) do
    detail
    |> Map.get(:conversation_entries, [])
    |> Enum.flat_map(fn %{message: message} ->
      [
        optional_tuple(:message, Map.get(message, :message_id)),
        optional_tuple(:person, Map.get(message, :sender_id))
      ]
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp delivery_interests(detail) do
    detail
    |> Map.get(:member_email_delivery_ids, [])
    |> Enum.map(&optional_tuple(:delivery, &1))
    |> Enum.reject(&is_nil/1)
  end

  defp fallback_interests(club_id) do
    Enum.flat_map(@fallback_families, fn family ->
      [{:fallback, family}, {:fallback, family, club_id}]
    end)
  end

  defp optional_tuple(_name, nil), do: nil
  defp optional_tuple(name, value), do: {name, value}
end
