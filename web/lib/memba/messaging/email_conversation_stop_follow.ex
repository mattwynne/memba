defmodule Memba.Messaging.EmailConversationStopFollow do
  @moduledoc """
  Coordinate a signed reply-email stop-follow request without requiring current
  membership. A former member may still reduce notifications from an old email.
  """

  alias Memba.Messaging.CommandDispatch
  alias Memba.Messaging.ConversationFollowPreparation
  alias Memba.Messaging.ConversationFollowQueries
  alias Memba.Messaging.ConversationStopFollowToken
  alias Memba.Messaging.MessageQueries
  alias Memba.Messaging.Projections.Message, as: MessageProjection

  def stop_following(token, dispatch_opts) when is_list(dispatch_opts) do
    with {:ok, scope} <- ConversationStopFollowToken.verify(token),
         {:ok, root_message} <- fetch_conversation_root(scope.conversation_id),
         :ok <- ensure_stop_follow_scope(root_message, scope),
         :ok <- reconcile_projected_follow_before_unfollow(scope, dispatch_opts) do
      case dispatch_unfollow(scope, dispatch_opts) do
        {:error, _reason} = error -> error
        dispatch_result -> {:ok, Map.put(scope, :dispatch_result, dispatch_result)}
      end
    else
      {:error, _reason} -> {:error, :invalid_stop_follow_token}
      nil -> {:error, :invalid_stop_follow_token}
    end
  end

  defp fetch_conversation_root(conversation_id) do
    case MessageQueries.get_message(conversation_id) do
      %MessageProjection{} = message -> {:ok, message}
      nil -> {:error, :conversation_not_found}
    end
  end

  defp ensure_stop_follow_scope(
         %MessageProjection{club_id: club_id, message_id: conversation_id},
         %{club_id: club_id, conversation_id: conversation_id}
       ),
       do: :ok

  defp ensure_stop_follow_scope(%MessageProjection{}, _scope), do: {:error, :wrong_scope}

  # A follow row can outlive its aggregate state (for example after a replay).
  # Reassert the projected follow before unfollowing so the command emits an
  # unfollow event rather than silently returning an empty event list.
  defp reconcile_projected_follow_before_unfollow(scope, dispatch_opts) do
    if ConversationFollowQueries.following_conversation?(scope.conversation_id, scope.member_id) do
      case ConversationFollowPreparation.prepare_follow(scope) do
        {:ok, command} ->
          case CommandDispatch.dispatch(command, dispatch_opts) do
            {:error, _reason} = error -> error
            {:ok, _dispatch_result} -> :ok
          end

        {:error, _reason} = error ->
          error
      end
    else
      :ok
    end
  end

  defp dispatch_unfollow(scope, dispatch_opts) do
    with {:ok, command} <- ConversationFollowPreparation.prepare_unfollow(scope),
         {:ok, dispatch_result} <- CommandDispatch.dispatch(command, dispatch_opts) do
      dispatch_result
    end
  end
end
