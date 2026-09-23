defmodule Memba.Messaging.ConversationFollowProjectionTest do
  use Memba.EventSourcedCase, async: false

  alias Commanded.Event.Mapper
  alias Memba.ConversationSubscriptionFixtures
  alias Memba.ID
  alias Memba.Messaging
  alias Memba.Messaging.App
  alias Memba.Messaging.Commands.SendMessage
  alias Memba.Messaging.ConversationFollowers
  alias Memba.Messaging.Events.MessageSent
  alias Memba.Messaging.Projectors.ConversationFollow, as: ConversationFollowProjector
  alias Memba.Messaging.Projections.ConversationFollow, as: ConversationFollowProjection
  alias Memba.Messaging.Recipient

  test "manual follow and explicit unfollow use canonical markers and exact retries" do
    ids = ConversationSubscriptionFixtures.canonical_subscription_fixture!()
    follow = follow_attrs(ids, ids.intent_id)

    assert :ok = Messaging.follow_conversation(follow, consistency: :strong)
    assert Messaging.following_conversation?(ids.conversation_id, ids.person_id)

    assert :ok = Messaging.follow_conversation(follow, consistency: :strong)

    unfollow = %{
      person_id: ids.person_id,
      conversation_id: ids.conversation_id,
      unfollow_id: Ecto.UUID.generate()
    }

    assert :ok = Messaging.unfollow_conversation(unfollow, consistency: :strong)
    refute Messaging.following_conversation?(ids.conversation_id, ids.person_id)
    assert :ok = Messaging.unfollow_conversation(unfollow, consistency: :strong)

    assert {:error, :subscription_intent_cancelled} =
             Messaging.follow_conversation(follow, consistency: :strong)

    assert :ok =
             Messaging.follow_conversation(
               follow_attrs(ids, ID.generate(:subscription_intent)),
               consistency: :strong
             )

    assert Messaging.following_conversation?(ids.conversation_id, ids.person_id)
  end

  test "legacy follows fall back only until a canonical unfollow tombstone exists" do
    club_id = ID.generate(:club)
    conversation_id = ID.generate(:message)
    person_id = ID.generate(:person)
    follow_id = ConversationFollowers.follow_id(conversation_id, person_id)

    legacy = %MessageSent{
      message_id: conversation_id,
      club_id: club_id,
      sender_id: person_id,
      subject: "Historic system-group message",
      body: "Historic MessageSent remains readable."
    }

    :ok =
      Commanded.EventStore.append_to_stream(
        App,
        conversation_id,
        0,
        [Mapper.map_to_event_data(legacy)]
      )

    :ok =
      Commanded.Subscriptions.wait_for(App, conversation_id, 1,
        consistency: [ConversationFollowProjector]
      )

    assert Messaging.following_conversation?(conversation_id, person_id)

    assert :ok =
             Messaging.unfollow_conversation(
               %{
                 person_id: person_id,
                 conversation_id: conversation_id,
                 unfollow_id: Ecto.UUID.generate()
               },
               consistency: :strong
             )

    refute Messaging.following_conversation?(conversation_id, person_id)
    assert Messaging.list_conversation_followers(conversation_id) == []

    assert %ConversationFollowProjection{following: true} =
             Repo.get!(ConversationFollowProjection, follow_id)
  end

  test "paused canonical projector cannot resurrect legacy follow or hide a new grant" do
    ids = ConversationSubscriptionFixtures.canonical_subscription_fixture!()
    follow_id = ConversationFollowers.follow_id(ids.conversation_id, ids.person_id)

    :ok =
      Commanded.EventStore.append_to_stream(
        App,
        ids.conversation_id,
        2,
        [
          Mapper.map_to_event_data(%Memba.Messaging.Events.ConversationFollowed{
            follow_id: follow_id,
            club_id: ids.club_id,
            conversation_id: ids.conversation_id,
            member_id: ids.person_id
          })
        ]
      )

    :ok =
      Commanded.Subscriptions.wait_for(App, ids.conversation_id, 3,
        consistency: [ConversationFollowProjector]
      )

    projector_child_id =
      stop_projector!(Memba.Messaging.Projectors.PersonConversationSubscriptionsV1)

    assert :ok =
             Messaging.unfollow_conversation(
               %{
                 person_id: ids.person_id,
                 conversation_id: ids.conversation_id,
                 unfollow_id: Ecto.UUID.generate()
               },
               consistency: :eventual
             )

    refute Messaging.following_conversation?(ids.conversation_id, ids.person_id)

    unfollow_listing =
      Task.async(fn -> Messaging.list_conversation_followers(ids.conversation_id) end)

    assert Task.yield(unfollow_listing, 50) == nil
    restart_projector!(projector_child_id)
    assert Task.await(unfollow_listing) == []

    projector_child_id =
      stop_projector!(Memba.Messaging.Projectors.PersonConversationSubscriptionsV1)

    assert :ok =
             Messaging.follow_conversation(
               follow_attrs(ids, ID.generate(:subscription_intent)),
               consistency: :eventual
             )

    assert Messaging.following_conversation?(ids.conversation_id, ids.person_id)

    follow_listing =
      Task.async(fn -> Messaging.list_conversation_followers(ids.conversation_id) end)

    assert Task.yield(follow_listing, 50) == nil
    restart_projector!(projector_child_id)

    assert [%ConversationFollowProjection{member_id: person_id}] =
             Task.await(follow_listing)

    assert person_id == ids.person_id

    legacy_projector_child_id = stop_projector!(ConversationFollowProjector)

    assert :ok =
             Messaging.unfollow_conversation(
               %{
                 person_id: ids.person_id,
                 conversation_id: ids.conversation_id,
                 unfollow_id: Ecto.UUID.generate()
               },
               consistency: :eventual
             )

    legacy_lag_listing =
      Task.async(fn -> Messaging.list_conversation_followers(ids.conversation_id) end)

    assert Task.yield(legacy_lag_listing, 50) == nil
    restart_projector!(legacy_projector_child_id)
    assert Task.await(legacy_lag_listing) == []
  end

  test "new MessageSent facts do not write canonical or legacy follow state" do
    club_id = ID.generate(:club)
    root_message_id = ID.generate(:message)
    sender_id = ID.generate(:person)

    assert :ok =
             App.dispatch(
               %SendMessage{
                 message_id: root_message_id,
                 club_id: club_id,
                 sender_id: sender_id,
                 subject: "Raw internal send",
                 body: "No implicit follow",
                 recipients: [
                   %Recipient{
                     delivery_id: ID.generate(:delivery),
                     person_id: sender_id,
                     name: "Sender",
                     email: "sender@example.com"
                   }
                 ]
               },
               consistency: :strong
             )

    refute Messaging.following_conversation?(root_message_id, sender_id)
  end

  defp stop_projector!(projector) do
    child_id =
      Supervisor.which_children(Memba.Supervisor)
      |> Enum.find_value(fn
        {child_id, _pid, :worker, [^projector]} -> child_id
        _child -> nil
      end)

    assert child_id
    assert :ok = Supervisor.terminate_child(Memba.Supervisor, child_id)
    child_id
  end

  defp restart_projector!(child_id) do
    case Supervisor.restart_child(Memba.Supervisor, child_id) do
      {:ok, _pid} -> :ok
      {:ok, _pid, _info} -> :ok
      {:error, :running} -> :ok
    end
  end

  defp follow_attrs(ids, intent_id) do
    %{
      person_id: ids.person_id,
      conversation_id: ids.conversation_id,
      subscription_intent_id: intent_id,
      source: :manual
    }
  end
end
