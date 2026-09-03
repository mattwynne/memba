defmodule Memba.Messaging.AppTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  alias Memba.Messaging.App
  alias Memba.Messaging.Commands.AcceptInboundClubEmail
  alias Memba.Messaging.Commands.FollowConversation
  alias Memba.Messaging.Commands.PostMessageReply
  alias Memba.Messaging.Commands.RejectInboundClubEmail
  alias Memba.Messaging.Commands.ReportEmailDeliveryBounced
  alias Memba.Messaging.Commands.ReportEmailDeliveryDelayed
  alias Memba.Messaging.Commands.ReportEmailDeliveryDelivered
  alias Memba.Messaging.Commands.ReportEmailDeliverySpamComplaint
  alias Memba.Messaging.Commands.ReceiveInboundEmail
  alias Memba.Messaging.Commands.SendMessage
  alias Memba.Messaging.Commands.UnfollowConversation
  alias Memba.Messaging.Projectors.ConversationGroupAccess, as: ConversationGroupAccessProjector
  alias Memba.Messaging.Projectors.ConversationFollow, as: ConversationFollowProjector
  alias Memba.Messaging.EmailDeliveryDispatcher
  alias Memba.Messaging.Projectors.InboundEmailSource, as: InboundEmailSourceProjector
  alias Memba.Messaging.Router

  test "Messaging Commanded app is supervised by the Phoenix application" do
    assert is_pid(Process.whereis(App))
    assert is_pid(Process.whereis(Memba.EventStore))
    assert is_pid(Process.whereis(Memba.Messaging.EventStore))

    assert Enum.any?(Supervisor.which_children(Memba.Supervisor), fn
             {App, pid, :supervisor, [App]} when is_pid(pid) -> true
             _child -> false
           end)

    assert Enum.any?(Supervisor.which_children(Memba.Supervisor), fn
             {{ConversationGroupAccessProjector, _opts}, pid, :worker,
              [ConversationGroupAccessProjector]}
             when is_pid(pid) ->
               true

             _child ->
               false
           end)

    assert Enum.any?(Supervisor.which_children(Memba.Supervisor), fn
             {{ConversationFollowProjector, _opts}, pid, :worker, [ConversationFollowProjector]}
             when is_pid(pid) ->
               true

             _child ->
               false
           end)

    assert Enum.any?(Supervisor.which_children(Memba.Supervisor), fn
             {{InboundEmailSourceProjector, _opts}, pid, :worker, [InboundEmailSourceProjector]}
             when is_pid(pid) ->
               true

             _child ->
               false
           end)
  end

  test "email delivery dispatcher is supervised by the Phoenix application" do
    assert is_pid(Process.whereis(EmailDeliveryDispatcher))

    assert Enum.any?(Supervisor.which_children(Memba.Supervisor), fn
             {EmailDeliveryDispatcher, pid, :worker, [EmailDeliveryDispatcher]}
             when is_pid(pid) ->
               true

             _child ->
               false
           end)
  end

  test "Messaging Commanded app includes the Messaging router" do
    expected_commands =
      MapSet.new([
        SendMessage,
        PostMessageReply,
        FollowConversation,
        UnfollowConversation,
        ReceiveInboundEmail,
        AcceptInboundClubEmail,
        RejectInboundClubEmail,
        ReportEmailDeliveryDelivered,
        ReportEmailDeliveryDelayed,
        ReportEmailDeliveryBounced,
        ReportEmailDeliverySpamComplaint
      ])

    assert MapSet.new(App.__registered_commands__()) == expected_commands
    assert MapSet.new(Router.__registered_commands__()) == expected_commands
  end

  test "Messaging Commanded app dispatches through its router" do
    log =
      capture_log(fn ->
        assert {:error, :unregistered_command} = App.dispatch(%URI{})
      end)

    assert log =~ "attempted to dispatch an unregistered command"
  end
end
