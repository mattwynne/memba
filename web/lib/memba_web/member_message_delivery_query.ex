defmodule MembaWeb.MemberMessageDeliveryQuery do
  @moduledoc """
  Fresh-authorized live query for one member delivery detail.

  The routed club and message plus the authenticated email are stable inputs.
  Every load reuses the accepted conversation-detail read boundary to normalize
  identity and recheck current club, membership, audience, and conversation
  access. The returned result then keeps only the message and receipt
  presentation needed by the delivery surface.
  """

  alias LiveQuery.Query
  alias MembaWeb.MemberMessageDetailQuery

  @doc """
  Returns the app-owned query descriptor for delivery detail.
  """
  @spec query() :: Query.t()
  def query do
    Query.new!(
      id: :member_message_delivery,
      assign: :delivery_detail,
      load: fn inputs ->
        case load(inputs.club_id, inputs.message_id, inputs.authenticated_email) do
          {:ok, detail} -> {:ok, detail, interests(detail)}
          {:error, reason} -> {:error, reason}
        end
      end
    )
  end

  @doc """
  Loads one coherent delivery model from freshly resolved authority.

  The accepted conversation-detail boundary preserves the existing
  `:forbidden` and `:not_found` distinction. Conversation entries, follow
  state, and raw joined delivery projection records are intentionally omitted.
  """
  @spec load(term(), term(), term()) :: {:ok, map()} | {:error, :forbidden | :not_found}
  def load(club_id, message_id, authenticated_email) do
    case MemberMessageDetailQuery.load(club_id, message_id, authenticated_email) do
      {:ok, detail} -> {:ok, delivery_detail(detail)}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Derives exact represented identities, delivery scope, and authority interests
  from a successful delivery result.
  """
  @spec interests(map()) :: [term()]
  def interests(detail) when is_map(detail) do
    selected_club = Map.fetch!(detail, :selected_club)
    current_member = Map.fetch!(detail, :current_member)
    audience = Map.fetch!(detail, :conversation_audience)
    message = Map.fetch!(detail, :message)

    club_id = Map.fetch!(selected_club, :club_id)
    person_id = Map.fetch!(current_member, :id)
    membership_id = Map.fetch!(current_member, :membership_id)
    group_id = Map.fetch!(audience, :group_id)
    conversation_id = Map.fetch!(audience, :conversation_id)
    requested_message_id = Map.fetch!(message, :message_id)
    delivery_message_id = Map.fetch!(detail, :delivery_message_id)

    [
      {:club, club_id},
      {:membership, membership_id},
      {:person, person_id},
      {:person_club, club_id, person_id},
      {:group_participation, club_id, group_id, person_id},
      {:conversation, conversation_id},
      {:conversation_access, group_id, conversation_id},
      {:message, requested_message_id},
      {:message, delivery_message_id},
      {:message_deliveries, delivery_message_id},
      optional_tuple(:person, Map.get(message, :sender_id))
    ]
    |> Kernel.++(recipient_interests(detail))
    |> Kernel.++(delivery_interests(detail))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp delivery_detail(detail) do
    root_message = Map.fetch!(detail, :root_message)

    %{
      page_title: Map.fetch!(detail, :page_title),
      selected_club: Map.fetch!(detail, :selected_club),
      current_member: Map.fetch!(detail, :current_member),
      message: Map.fetch!(detail, :message),
      conversation_audience: Map.fetch!(detail, :conversation_audience),
      sender_name: Map.fetch!(detail, :sender_name),
      delivery_message_id: Map.fetch!(root_message, :message_id),
      member_email_deliverys: Map.fetch!(detail, :member_email_deliverys),
      member_email_delivery_ids: Map.fetch!(detail, :member_email_delivery_ids),
      member_email_delivery_count: Map.fetch!(detail, :member_email_delivery_count),
      member_email_delivery_summary: Map.fetch!(detail, :member_email_delivery_summary),
      member_email_delivery_groups: Map.fetch!(detail, :member_email_delivery_groups)
    }
  end

  defp recipient_interests(detail) do
    detail
    |> Map.get(:member_email_deliverys, [])
    |> Enum.map(&optional_tuple(:person, Map.get(&1, :recipient_id)))
  end

  defp delivery_interests(detail) do
    detail
    |> Map.get(:member_email_delivery_ids, [])
    |> Enum.map(&optional_tuple(:delivery, &1))
  end

  defp optional_tuple(_name, nil), do: nil
  defp optional_tuple(name, value), do: {name, value}
end
