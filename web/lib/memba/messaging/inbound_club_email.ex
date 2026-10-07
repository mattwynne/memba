defmodule Memba.Messaging.InboundClubEmail do
  @moduledoc """
  Coordinate durable receipt, posting or reply, recovery and audit for inbound club email.

  Preparation is a separate decision; this coordinator alone dispatches commands.
  """

  alias Commanded.Commands.ExecutionResult
  alias Memba.ID
  alias Memba.Membership.AuthoritativeMembershipQueries
  alias Memba.Messaging.App
  alias Memba.Messaging.AuthorizationCheckpoint
  alias Memba.Messaging.CommandDispatch
  alias Memba.Messaging.Commands.AcceptInboundClubEmail
  alias Memba.Messaging.Commands.PostMessageReply
  alias Memba.Messaging.Commands.ReceiveInboundEmail
  alias Memba.Messaging.Commands.RejectInboundClubEmail
  alias Memba.Messaging.Commands.SendMessage
  alias Memba.Messaging.ConversationAccess
  alias Memba.Messaging.ConversationAudience
  alias Memba.Messaging.ConversationFollowQueries
  alias Memba.Messaging.Events.InboundClubEmailRejected
  alias Memba.Messaging.GroupEmailPostingPolicy
  alias Memba.Messaging.InboundClubDestination
  alias Memba.Messaging.InboundClubEmailPreparation
  alias Memba.Messaging.InboundClubRejectionEmail
  alias Memba.Messaging.InboundClubSender
  alias Memba.Messaging.InboundEmail
  alias Memba.Messaging.InboundEmailBody
  alias Memba.Messaging.InboundEmailReceipt
  alias Memba.Messaging.Message
  alias Memba.Messaging.MessageSourceQueries
  alias Memba.Messaging.Projectors.ConversationFollow, as: ConversationFollowProjector
  alias Memba.Messaging.Recipient
  alias Memba.Messaging.ReplyCommand
  alias Memba.Messaging.SendClubMessage

  def command(attrs) when is_map(attrs) do
    with {:ok, inbound_email} <- InboundEmail.new(attrs) do
      {:ok,
       %ReceiveInboundEmail{
         inbound_email_id: InboundEmail.identity(inbound_email),
         inbound_email: inbound_email
       }}
    end
  end

  def command(_attrs), do: {:error, :invalid_inbound_email}

  def receive(attrs, dispatch_opts) when is_map(attrs) and is_list(dispatch_opts) do
    with {:ok, receive_command} <- command(attrs),
         {:ok, receive_result} <- dispatch_inbound_email_received(receive_command, dispatch_opts) do
      if completed_duplicate_inbound_email_receipt?(receive_result) do
        duplicate_inbound_email_response(receive_command, receive_result)
      else
        recover_or_post_first_inbound_club_email(receive_command, dispatch_opts)
      end
    end
  end

  def receive(_attrs, _dispatch_opts), do: {:error, :invalid_inbound_email}

  defp dispatch_ok(command, dispatch_opts) do
    case CommandDispatch.dispatch(command, dispatch_opts) do
      {:ok, _dispatch_result} -> :ok
      {:error, _reason} = error -> error
    end
  end

  defp dispatch_inbound_email_received(receive_command, dispatch_opts) do
    dispatch_opts = Keyword.put(dispatch_opts, :returning, :execution_result)

    case CommandDispatch.dispatch(receive_command, dispatch_opts) do
      {:ok, {:ok, %ExecutionResult{} = result}} -> {:ok, result}
      {:error, _reason} = error -> error
    end
  end

  defp completed_duplicate_inbound_email_receipt?(%ExecutionResult{
         events: [],
         aggregate_state: %InboundEmailReceipt{status: status}
       })
       when status in [:accepted, :rejected],
       do: true

  defp completed_duplicate_inbound_email_receipt?(%ExecutionResult{}), do: false

  defp duplicate_inbound_email_response(
         receive_command,
         %ExecutionResult{aggregate_state: %InboundEmailReceipt{} = receipt}
       ) do
    {:ok,
     %{
       inbound_email_id: receive_command.inbound_email_id,
       duplicate?: true,
       status: receipt.status,
       message_id: receipt.message_id,
       rejection_reason: receipt.rejection_reason
     }}
  end

  defp recover_or_post_first_inbound_club_email(receive_command, dispatch_opts) do
    message_id = inbound_message_id(receive_command)

    case App.aggregate_state(Message, message_id) do
      %Message{message_id: ^message_id} = message ->
        recover_committed_inbound_message(
          message,
          receive_command,
          dispatch_opts
        )

      _missing_message ->
        post_first_inbound_club_email(receive_command, dispatch_opts)
    end
  end

  defp post_first_inbound_club_email(receive_command, dispatch_opts) do
    case InboundClubEmailPreparation.prepare(receive_command.inbound_email) do
      {:ok, destination, sender} ->
        post_authorized_first_inbound_club_email(
          receive_command,
          destination,
          sender,
          dispatch_opts
        )

      {:reject, to_address, reason, opts} ->
        reject_first_inbound_club_email(receive_command, to_address, reason, dispatch_opts, opts)

      {:error, _reason} = error ->
        error
    end
  end

  defp recover_committed_inbound_message(
         %Message{} = message,
         receive_command,
         dispatch_opts
       ) do
    with :ok <- confirm_matching_committed_inbound_message_content(message, receive_command),
         {:ok, %InboundClubDestination{} = destination} <-
           InboundClubDestination.resolve(receive_command.inbound_email),
         {:ok, %InboundClubSender{} = sender} <-
           InboundClubSender.resolve(receive_command.inbound_email),
         :ok <-
           confirm_matching_committed_inbound_message_context(
             message,
             receive_command,
             destination,
             sender
           ),
         :ok <-
           record_inbound_club_email_accepted(
             receive_command.inbound_email,
             destination,
             sender,
             message.message_id,
             dispatch_opts
           ) do
      {:ok,
       accepted_inbound_email_response(
         receive_command,
         destination,
         sender,
         message
       )}
    end
  end

  defp confirm_matching_committed_inbound_message_content(%Message{} = message, receive_command) do
    with {:ok, body} <- InboundEmailBody.normalize_text_body(receive_command.inbound_email),
         true <- message.message_id == inbound_message_id(receive_command),
         true <-
           committed_inbound_message_subject_matches?(message, receive_command.inbound_email),
         true <- message.body == body do
      :ok
    else
      _mismatch -> {:error, :inbound_message_mismatch}
    end
  end

  defp confirm_matching_committed_inbound_message_context(
         %Message{} = message,
         receive_command,
         destination,
         sender
       ) do
    with true <- message.club_id == destination.club_id,
         true <- message.sender_id == sender.person_id,
         true <-
           committed_inbound_message_destination_matches?(
             message,
             receive_command,
             destination
           ) do
      :ok
    else
      _mismatch -> {:error, :inbound_message_mismatch}
    end
  end

  defp committed_inbound_message_subject_matches?(
         %Message{
           message_id: message_id,
           conversation_id: message_id,
           subject: subject
         },
         %InboundEmail{subject: subject}
       ),
       do: true

  defp committed_inbound_message_subject_matches?(
         %Message{message_id: message_id, conversation_id: conversation_id, subject: subject},
         %InboundEmail{}
       )
       when message_id != conversation_id do
    case App.aggregate_state(Message, conversation_id) do
      %Message{
        message_id: ^conversation_id,
        conversation_id: ^conversation_id,
        subject: ^subject
      } ->
        true

      _missing_or_different_root ->
        false
    end
  end

  defp committed_inbound_message_subject_matches?(%Message{}, %InboundEmail{}), do: false

  defp committed_inbound_message_destination_matches?(
         %Message{
           message_id: message_id,
           conversation_id: message_id,
           group_access: group_access
         },
         _receive_command,
         destination
       ) do
    Map.get(group_access, destination.group_id) == "write"
  end

  defp committed_inbound_message_destination_matches?(
         %Message{conversation_id: conversation_id},
         receive_command,
         destination
       ) do
    case resolve_inbound_reply_reference(receive_command.inbound_email, destination) do
      %{conversation_id: ^conversation_id} -> true
      _missing_or_different_reference -> false
    end
  end

  defp accepted_inbound_email_response(receive_command, destination, sender, message) do
    response = %{
      inbound_email_id: receive_command.inbound_email_id,
      message_id: message.message_id,
      club_id: destination.club_id,
      sender_id: sender.person_id,
      from_address: sender.from_address,
      to_address: destination.to_address
    }

    if message.conversation_id == message.message_id do
      response
    else
      Map.put(response, :conversation_id, message.conversation_id)
    end
  end

  defp post_authorized_first_inbound_club_email(
         receive_command,
         %InboundClubDestination{} = destination,
         %InboundClubSender{} = sender,
         dispatch_opts
       ) do
    if inbound_email_has_attachments?(receive_command.inbound_email) do
      reject_first_inbound_club_email(
        receive_command,
        destination.to_address,
        "attachments_not_supported",
        dispatch_opts,
        club_name: destination.club_name
      )
    else
      case InboundEmailBody.normalize_text_body(receive_command.inbound_email) do
        {:ok, body} ->
          accept_first_inbound_club_email_or_reply(
            receive_command,
            destination,
            sender,
            body,
            dispatch_opts
          )

        {:error, :plain_text_required} ->
          reject_first_inbound_club_email(
            receive_command,
            destination.to_address,
            "plain_text_required",
            dispatch_opts,
            club_name: destination.club_name
          )
      end
    end
  end

  defp inbound_email_has_attachments?(%InboundEmail{attachments: [_attachment | _attachments]}),
    do: true

  defp inbound_email_has_attachments?(%InboundEmail{}), do: false

  defp accept_first_inbound_club_email_or_reply(
         receive_command,
         %InboundClubDestination{} = destination,
         %InboundClubSender{} = sender,
         body,
         dispatch_opts
       ) do
    case resolve_inbound_reply_reference(receive_command.inbound_email, destination) do
      %{conversation_id: conversation_id} ->
        accept_first_inbound_club_email_reply(
          receive_command,
          destination,
          sender,
          body,
          conversation_id,
          dispatch_opts
        )

      nil ->
        accept_first_inbound_club_email(
          receive_command,
          destination,
          sender,
          body,
          dispatch_opts
        )
    end
  end

  defp accept_first_inbound_club_email_reply(
         receive_command,
         %InboundClubDestination{} = destination,
         %InboundClubSender{} = sender,
         body,
         conversation_id,
         dispatch_opts
       ) do
    message_id = inbound_message_id(receive_command)

    case post_inbound_club_message_reply(
           conversation_id,
           sender,
           message_id,
           body,
           dispatch_opts
         ) do
      :ok ->
        with :ok <-
               record_inbound_club_email_accepted(
                 receive_command.inbound_email,
                 destination,
                 sender,
                 message_id,
                 dispatch_opts
               ) do
          {:ok,
           %{
             inbound_email_id: receive_command.inbound_email_id,
             message_id: message_id,
             conversation_id: conversation_id,
             club_id: destination.club_id,
             sender_id: sender.person_id,
             from_address: sender.from_address,
             to_address: destination.to_address
           }}
        end

      {:error, :not_current_member} ->
        reject_first_inbound_club_email(
          receive_command,
          destination.to_address,
          "not_current_member",
          dispatch_opts,
          club_name: destination.club_name
        )

      {:error, _reason} = error ->
        error
    end
  end

  defp accept_first_inbound_club_email(
         receive_command,
         %InboundClubDestination{} = destination,
         %InboundClubSender{} = sender,
         body,
         dispatch_opts
       ) do
    message_id = inbound_message_id(receive_command)

    case send_inbound_club_message(
           receive_command.inbound_email,
           destination,
           sender,
           message_id,
           body,
           dispatch_opts
         ) do
      :ok ->
        with :ok <-
               record_inbound_club_email_accepted(
                 receive_command.inbound_email,
                 destination,
                 sender,
                 message_id,
                 dispatch_opts
               ) do
          {:ok,
           %{
             inbound_email_id: receive_command.inbound_email_id,
             message_id: message_id,
             club_id: destination.club_id,
             sender_id: sender.person_id,
             from_address: sender.from_address,
             to_address: destination.to_address
           }}
        end

      {:error, :sender_not_active_member, _details} ->
        reject_first_inbound_club_email(
          receive_command,
          destination.to_address,
          "sender_not_active_member",
          dispatch_opts,
          club_name: destination.club_name
        )

      {:error, _reason} = error ->
        error
    end
  end

  defp reject_first_inbound_club_email(
         receive_command,
         to_address,
         rejection_reason,
         dispatch_opts,
         opts
       ) do
    rejection_email_delivery_reference = ID.generate(:delivery)

    case record_inbound_club_email_rejected(
           receive_command.inbound_email,
           to_address,
           rejection_reason,
           rejection_email_delivery_reference,
           dispatch_opts
         ) do
      {:ok, :recorded} ->
        with :ok <-
               InboundClubRejectionEmail.deliver(
                 receive_command.inbound_email,
                 to_address,
                 rejection_reason,
                 rejection_email_delivery_reference,
                 opts
               ) do
          {:ok,
           %{
             inbound_email_id: receive_command.inbound_email_id,
             status: :rejected,
             rejection_reason: rejection_reason,
             from_address: receive_command.inbound_email.from_address,
             to_address: to_address,
             rejection_email_delivery_reference: rejection_email_delivery_reference
           }}
        end

      {:ok, {:duplicate, %ExecutionResult{} = result}} ->
        duplicate_inbound_email_response(receive_command, result)

      {:error, _reason} = error ->
        error
    end
  end

  defp send_inbound_club_message(
         %InboundEmail{} = inbound_email,
         %InboundClubDestination{} = destination,
         %InboundClubSender{} = sender,
         message_id,
         body,
         dispatch_opts
       ) do
    attrs = %{
      message_id: message_id,
      club_id: destination.club_id,
      sender_id: sender.person_id,
      audience_group_id: destination.group_id,
      subject: inbound_email.subject,
      body: body
    }

    with {:ok, command} <-
           AuthorizationCheckpoint.run(fn ->
             with :ok <- GroupEmailPostingPolicy.authorize(sender, destination),
                  {:ok, command} <- SendClubMessage.prepare(attrs) do
               {:ok, command}
             end
           end) do
      dispatch_inbound_message_once(command, dispatch_opts)
    end
  end

  defp post_inbound_club_message_reply(
         conversation_id,
         %InboundClubSender{} = sender,
         message_id,
         body,
         dispatch_opts
       ) do
    attrs = %{
      message_id: message_id,
      conversation_id: conversation_id,
      sender_id: sender.person_id,
      body: body
    }

    with {:ok, command} <-
           AuthorizationCheckpoint.run(
             fn ->
               with {:ok, command} <- post_message_reply_command(attrs),
                    :ok <- authorize_reply_sender(command) do
                 {:ok, command}
               end
             end,
             projections: [ConversationFollowProjector]
           ) do
      dispatch_inbound_message_once(command, dispatch_opts)
    end
  end

  defp inbound_message_id(%ReceiveInboundEmail{inbound_email_id: inbound_email_id}) do
    ID.deterministic(:message, [inbound_email_id])
  end

  defp dispatch_inbound_message_once(command, dispatch_opts) do
    case dispatch_ok(command, dispatch_opts) do
      :ok -> :ok
      {:error, :already_sent} -> confirm_matching_inbound_message(command)
      {:error, _reason} = error -> error
    end
  end

  defp confirm_matching_inbound_message(%SendMessage{} = command) do
    case App.aggregate_state(Message, command.message_id) do
      %Message{
        message_id: message_id,
        club_id: club_id,
        sender_id: sender_id,
        conversation_id: message_id,
        group_access: group_access
      }
      when message_id == command.message_id and club_id == command.club_id and
             sender_id == command.sender_id ->
        if Map.get(group_access, command.audience_group_id) == "write" do
          :ok
        else
          {:error, :already_sent}
        end

      _missing_or_different_message ->
        {:error, :already_sent}
    end
  end

  defp confirm_matching_inbound_message(%PostMessageReply{} = command) do
    case App.aggregate_state(Message, command.message_id) do
      %Message{
        message_id: message_id,
        club_id: club_id,
        sender_id: sender_id,
        conversation_id: conversation_id,
        reply_to_message_id: reply_to_message_id
      }
      when message_id == command.message_id and club_id == command.club_id and
             sender_id == command.sender_id and conversation_id == command.conversation_id and
             reply_to_message_id == command.reply_to_message_id ->
        :ok

      _missing_or_different_message ->
        {:error, :already_sent}
    end
  end

  defp resolve_inbound_reply_reference(
         %InboundEmail{} = inbound_email,
         %InboundClubDestination{} = destination
       ) do
    inbound_email
    |> inbound_reply_message_ids()
    |> Enum.find_value(&same_club_outbound_message_reference(&1, destination))
  end

  defp inbound_reply_message_ids(%InboundEmail{} = inbound_email) do
    in_reply_to_message_ids = inbound_email.in_reply_to_message_ids || []
    references_message_ids = inbound_email.references_message_ids || []

    in_reply_to_message_ids ++ Enum.reverse(references_message_ids)
  end

  defp same_club_outbound_message_reference(message_id, %InboundClubDestination{} = destination) do
    case MessageSourceQueries.get_outbound_message_reference(message_id) do
      %{club_id: club_id} = reference when club_id == destination.club_id -> reference
      _unknown_or_other_club -> nil
    end
  end

  defp record_inbound_club_email_accepted(
         %InboundEmail{} = inbound_email,
         %InboundClubDestination{} = destination,
         %InboundClubSender{} = sender,
         message_id,
         dispatch_opts
       ) do
    dispatch_ok(
      %AcceptInboundClubEmail{
        inbound_email_id: InboundEmail.identity(inbound_email),
        inbound_email: inbound_email,
        to_address: destination.to_address,
        club_id: destination.club_id,
        sender_id: sender.person_id,
        message_id: message_id
      },
      dispatch_opts
    )
  end

  defp record_inbound_club_email_rejected(
         %InboundEmail{} = inbound_email,
         to_address,
         rejection_reason,
         rejection_email_delivery_reference,
         dispatch_opts
       ) do
    command = %RejectInboundClubEmail{
      inbound_email_id: InboundEmail.identity(inbound_email),
      inbound_email: inbound_email,
      to_address: to_address,
      rejection_reason: rejection_reason,
      rejection_email_delivery_reference: rejection_email_delivery_reference
    }

    dispatch_opts = Keyword.put(dispatch_opts, :returning, :execution_result)

    case CommandDispatch.dispatch(command, dispatch_opts) do
      {:ok, {:ok, %ExecutionResult{events: [%InboundClubEmailRejected{} | _events]}}} ->
        {:ok, :recorded}

      {:ok,
       {:ok,
        %ExecutionResult{
          events: [],
          aggregate_state: %InboundEmailReceipt{status: :rejected}
        } = result}} ->
        {:ok, {:duplicate, result}}

      {:error, _reason} = error ->
        error
    end
  end

  defp post_message_reply_command(attrs) do
    ReplyCommand.prepare(attrs, fn club_id, conversation_id, group_id, sender_id ->
      resolve_reply_recipients(club_id, conversation_id, group_id, except_person_id: sender_id)
    end)
  end

  defp authorize_reply_sender(%PostMessageReply{} = command) do
    case member_has_authoritative_conversation_access?(
           command.conversation_id,
           command.club_id,
           command.sender_id,
           :write
         ) do
      true -> :ok
      false -> {:error, :not_current_member}
    end
  end

  defp member_has_authoritative_conversation_access?(
         conversation_id,
         club_id,
         person_id,
         access_level
       ) do
    with {:ok, conversation_id} <- ID.cast(:message, conversation_id),
         {:ok, club_id} <- ID.cast(:club, club_id),
         {:ok, person_id} <- ID.cast(:person, person_id),
         {:ok, access_level} <- ConversationAccess.normalize_access_level(access_level),
         %Message{
           message_id: ^conversation_id,
           club_id: ^club_id,
           group_access: group_access
         } <- App.aggregate_state(Message, conversation_id),
         {:ok, group_id, granted_access_level} <-
           ConversationAudience.canonical_group_access(group_access) do
      grant_levels = ConversationAccess.grant_levels_including(access_level)

      granted_access_level in grant_levels and
        AuthoritativeMembershipQueries.active_member_of_group_authoritatively?(
          club_id,
          group_id,
          person_id
        )
    else
      _invalid_missing_or_inaccessible -> false
    end
  end

  defp resolve_reply_recipients(club_id, conversation_id, group_id, opts) do
    except_person_id = Keyword.get(opts, :except_person_id)
    follower_ids = current_follower_ids(club_id, conversation_id)

    club_id
    |> AuthoritativeMembershipQueries.list_active_members_of_group_authoritatively(group_id)
    |> Enum.filter(&MapSet.member?(follower_ids, &1.id))
    |> Enum.reject(&(&1.id == except_person_id))
    |> Enum.map(&resolved_recipient/1)
  end

  defp current_follower_ids(club_id, conversation_id) do
    conversation_id
    |> ConversationFollowQueries.list_conversation_followers()
    |> Enum.filter(&(&1.club_id == club_id))
    |> Enum.map(& &1.member_id)
    |> MapSet.new()
  end

  defp resolved_recipient(%{id: person_id, name: name, email: email}) do
    %Recipient{
      delivery_id: Memba.ID.generate(:delivery),
      person_id: person_id,
      name: name,
      email: email
    }
  end
end
