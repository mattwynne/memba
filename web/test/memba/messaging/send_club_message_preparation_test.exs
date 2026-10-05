defmodule Memba.Messaging.SendClubMessagePreparationTest do
  use ExUnit.Case, async: true

  alias Memba.ID
  alias Memba.Messaging.SendClubMessage

  test "requires a club identity before looking up the audience or dispatching" do
    assert {:error, {:missing_required_attribute, :club_id}} =
             SendClubMessage.prepare(%{message_id: ID.generate(:message)})
  end

  test "rejects a mistyped club identity before looking up the audience" do
    assert {:error, :invalid_club_id} =
             SendClubMessage.prepare(%{
               message_id: ID.generate(:message),
               club_id: ID.generate(:person)
             })
  end

  test "rejects an explicitly null audience rather than silently using Everyone" do
    assert {:error, :invalid_audience_group_id} =
             SendClubMessage.prepare(%{
               message_id: ID.generate(:message),
               club_id: ID.generate(:club),
               sender_id: ID.generate(:person),
               subject: "News",
               body: "Hello",
               audience_group_id: nil
             })
  end
end
