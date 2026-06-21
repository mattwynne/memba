defmodule Memba.Messaging.ConversationStopFollowTokenTest do
  use ExUnit.Case, async: true

  alias Memba.Messaging.ConversationStopFollowToken

  test "signs and verifies an opaque token scoped to a club, conversation, and member" do
    scope = %{
      club_id: Memba.ID.generate(:club),
      conversation_id: Memba.ID.generate(:message),
      member_id: Memba.ID.generate(:person)
    }

    assert {:ok, token} = ConversationStopFollowToken.sign(scope)

    refute token =~ scope.club_id
    refute token =~ scope.conversation_id
    refute token =~ scope.member_id

    assert {:ok, ^scope} = ConversationStopFollowToken.verify(token)
  end

  test "rejects missing, malformed, or tampered tokens" do
    assert {:error, :invalid} = ConversationStopFollowToken.sign(%{})
    assert {:error, :invalid} = ConversationStopFollowToken.verify(nil)
    assert {:error, :invalid} = ConversationStopFollowToken.verify("not-a-token")

    scope = %{
      club_id: Memba.ID.generate(:club),
      conversation_id: Memba.ID.generate(:message),
      member_id: Memba.ID.generate(:person)
    }

    assert {:ok, token} = ConversationStopFollowToken.sign(scope)
    assert {:error, :invalid} = ConversationStopFollowToken.verify(token <> "tampered")
  end
end
