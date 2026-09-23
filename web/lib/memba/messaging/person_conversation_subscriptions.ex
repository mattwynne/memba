defmodule Memba.Messaging.PersonConversationSubscriptions do
  @moduledoc """
  Messaging aggregate owning every conversation subscription for one person.

  Routing all subscription intents, explicit unfollows, and GroupMembership
  revocations through `person_id` gives their ordering one consistency boundary.
  Authority is copied from the canonical decision at intent initiation and is
  never replaced by authority discovered during a retry.
  """

  alias Commanded.Aggregates.Aggregate
  alias Memba.ID
  alias Memba.Membership
  alias Memba.Membership.ConversationSubscriptionAuthorityDecision
  alias Memba.Messaging.Commands.AuthorizePersonConversationSubscriptionIntent
  alias Memba.Messaging.Commands.CancelPersonConversationSubscriptionIntent
  alias Memba.Messaging.Commands.EndPersonConversationSubscription
  alias Memba.Messaging.Commands.RevokeGroupMembershipConversationSubscriptions
  alias Memba.Messaging.Commands.StartPersonConversationSubscriptionIntent
  alias Memba.Messaging.Events.ConversationSubscriptionAuthorizationGranted
  alias Memba.Messaging.Events.ConversationSubscriptionAuthorizationRevoked
  alias Memba.Messaging.Events.ConversationSubscriptionEnded
  alias Memba.Messaging.Events.ConversationSubscriptionIntentCancelled
  alias Memba.Messaging.Events.ConversationSubscriptionIntentStarted
  alias Memba.Messaging.Events.GroupMembershipSubscriptionRevocationCompleted
  alias Memba.Messaging.Events.GroupMembershipSubscriptionRevocationRecorded

  @behaviour Aggregate
  @sources [:manual, :root, :reply]

  defstruct person_id: nil,
            intents: %{},
            grants: %{},
            revoked_group_memberships: %{},
            revocations: %{},
            unfollows: %{},
            cancellations: %{}

  @doc false
  def revalidate_authority_before_execute(_subscriptions, %{command: command}) do
    with :ok <-
           Membership.revalidate_conversation_subscription_authority(command.authority_decision) do
      run_authority_revalidation_hook(command.authority_decision)
    end
  end

  @impl Aggregate
  def execute(
        %__MODULE__{} = subscriptions,
        %StartPersonConversationSubscriptionIntent{} = command
      ) do
    with :ok <- validate_start(command),
         :ok <- validate_person(subscriptions, command.person_id),
         :ok <- validate_subscription_identity(command),
         :ok <- validate_new_intent(subscriptions, command) do
      %ConversationSubscriptionIntentStarted{
        person_id: command.person_id,
        club_id: command.club_id,
        conversation_id: command.conversation_id,
        conversation_group_ids: command.conversation_group_ids,
        conversation_stream_version: command.conversation_stream_version,
        subscription_id: command.subscription_id,
        subscription_intent_id: command.subscription_intent_id,
        authority_decision_id: command.authority_decision_id,
        source: command.source,
        club_membership_id: command.club_membership_id,
        group_membership_ids: Enum.sort(command.group_membership_ids)
      }
    else
      :exact_retry -> []
      error -> error
    end
  end

  def execute(
        %__MODULE__{} = subscriptions,
        %AuthorizePersonConversationSubscriptionIntent{} = command
      ) do
    with :ok <- validate_authorize(command),
         :ok <- validate_person(subscriptions, command.person_id),
         {:ok, intent} <- fetch_open_intent(subscriptions, command.subscription_intent_id),
         :ok <- validate_authority_decision(intent, command.authority_decision_id),
         {:ok, group_membership_ids} <-
           grantable_group_memberships(subscriptions, intent, command) do
      group_membership_ids
      |> Enum.map(fn group_membership_id ->
        authorization_id = authorization_id(intent.subscription_intent_id, group_membership_id)

        %ConversationSubscriptionAuthorizationGranted{
          person_id: command.person_id,
          conversation_id: intent.conversation_id,
          subscription_id: intent.subscription_id,
          subscription_intent_id: intent.subscription_intent_id,
          authority_decision_id: intent.authority_decision_id,
          authorization_id: authorization_id,
          club_membership_id: intent.club_membership_id,
          group_membership_id: group_membership_id
        }
      end)
    end
  end

  def execute(
        %__MODULE__{} = subscriptions,
        %CancelPersonConversationSubscriptionIntent{} = command
      ) do
    with :ok <- validate_cancel(command),
         :ok <- validate_person(subscriptions, command.person_id),
         {:ok, intent} <- fetch_intent(subscriptions, command.subscription_intent_id),
         :ok <- validate_cancellation_retry(subscriptions, intent, command) do
      if intent.status == :cancelled do
        []
      else
        %ConversationSubscriptionIntentCancelled{
          person_id: command.person_id,
          conversation_id: intent.conversation_id,
          subscription_id: intent.subscription_id,
          subscription_intent_id: intent.subscription_intent_id,
          cancellation_id: command.cancellation_id,
          reason: command.reason
        }
      end
    end
  end

  def execute(%__MODULE__{} = subscriptions, %EndPersonConversationSubscription{} = command) do
    with :ok <- validate_end(command),
         :ok <- validate_person(subscriptions, command.person_id),
         :ok <- validate_unfollow_retry(subscriptions, command) do
      cancellation_events =
        subscriptions.intents
        |> Map.values()
        |> Enum.filter(&(&1.conversation_id == command.conversation_id and &1.status == :open))
        |> Enum.sort_by(& &1.subscription_intent_id)
        |> Enum.map(fn intent ->
          %ConversationSubscriptionIntentCancelled{
            person_id: command.person_id,
            conversation_id: command.conversation_id,
            subscription_id: intent.subscription_id,
            subscription_intent_id: intent.subscription_intent_id,
            cancellation_id: command.unfollow_id,
            reason: "unfollowed"
          }
        end)

      revocation_events =
        subscriptions.grants
        |> Map.values()
        |> Enum.filter(&(&1.conversation_id == command.conversation_id and &1.active))
        |> Enum.sort_by(&{&1.conversation_id, &1.authorization_id})
        |> Enum.map(fn grant ->
          authorization_revoked(grant,
            reason: "unfollowed",
            unfollow_id: command.unfollow_id
          )
        end)

      subscription_id = subscription_id(command.person_id, command.conversation_id)

      cancellation_events ++
        revocation_events ++
        [
          %ConversationSubscriptionEnded{
            person_id: command.person_id,
            conversation_id: command.conversation_id,
            subscription_id: subscription_id,
            unfollow_id: command.unfollow_id
          }
        ]
    else
      :exact_retry -> []
      error -> error
    end
  end

  def execute(
        %__MODULE__{} = subscriptions,
        %RevokeGroupMembershipConversationSubscriptions{} = command
      ) do
    with :ok <- validate_revoke(command),
         :ok <- validate_person(subscriptions, command.person_id),
         :ok <- validate_revocation_retry(subscriptions, command) do
      revoked =
        subscriptions.grants
        |> Map.values()
        |> Enum.filter(&(&1.group_membership_id == command.group_membership_id and &1.active))
        |> Enum.sort_by(&{&1.conversation_id, &1.authorization_id})
        |> Enum.map(fn grant ->
          authorization_revoked(grant,
            reason: "group_membership_revoked",
            revocation_id: command.revocation_id
          )
        end)

      [
        %GroupMembershipSubscriptionRevocationRecorded{
          person_id: command.person_id,
          group_membership_id: command.group_membership_id,
          revocation_id: command.revocation_id
        }
        | revoked
      ] ++
        [
          %GroupMembershipSubscriptionRevocationCompleted{
            person_id: command.person_id,
            group_membership_id: command.group_membership_id,
            revocation_id: command.revocation_id
          }
        ]
    else
      :exact_retry -> []
      error -> error
    end
  end

  @impl Aggregate
  def apply(%__MODULE__{} = subscriptions, %ConversationSubscriptionIntentStarted{} = event) do
    intent = %{
      person_id: event.person_id,
      club_id: event.club_id,
      conversation_id: event.conversation_id,
      conversation_group_ids: event.conversation_group_ids,
      conversation_stream_version: event.conversation_stream_version,
      subscription_id: event.subscription_id,
      subscription_intent_id: event.subscription_intent_id,
      authority_decision_id: event.authority_decision_id,
      source: normalize_source(event.source),
      club_membership_id: event.club_membership_id,
      group_membership_ids: event.group_membership_ids,
      status: :open
    }

    %{
      subscriptions
      | person_id: event.person_id,
        intents: Map.put(subscriptions.intents, event.subscription_intent_id, intent)
    }
  end

  def apply(%__MODULE__{} = subscriptions, %ConversationSubscriptionIntentCancelled{} = event) do
    intents =
      Map.update!(
        subscriptions.intents,
        event.subscription_intent_id,
        &Map.put(&1, :status, :cancelled)
      )

    cancellation = %{intent_id: event.subscription_intent_id, reason: event.reason}

    %{
      subscriptions
      | intents: intents,
        cancellations: Map.put(subscriptions.cancellations, event.cancellation_id, cancellation)
    }
  end

  def apply(
        %__MODULE__{} = subscriptions,
        %ConversationSubscriptionAuthorizationGranted{} = event
      ) do
    grant = %{
      person_id: event.person_id,
      conversation_id: event.conversation_id,
      subscription_id: event.subscription_id,
      subscription_intent_id: event.subscription_intent_id,
      authority_decision_id: event.authority_decision_id,
      authorization_id: event.authorization_id,
      club_membership_id: event.club_membership_id,
      group_membership_id: event.group_membership_id,
      active: true
    }

    %{subscriptions | grants: Map.put(subscriptions.grants, event.authorization_id, grant)}
  end

  def apply(
        %__MODULE__{} = subscriptions,
        %ConversationSubscriptionAuthorizationRevoked{} = event
      ) do
    %{
      subscriptions
      | grants:
          Map.update!(subscriptions.grants, event.authorization_id, &Map.put(&1, :active, false))
    }
  end

  def apply(%__MODULE__{} = subscriptions, %ConversationSubscriptionEnded{} = event) do
    unfollow = %{conversation_id: event.conversation_id, subscription_id: event.subscription_id}
    %{subscriptions | unfollows: Map.put(subscriptions.unfollows, event.unfollow_id, unfollow)}
  end

  def apply(
        %__MODULE__{} = subscriptions,
        %GroupMembershipSubscriptionRevocationRecorded{} = event
      ) do
    %{
      subscriptions
      | revoked_group_memberships:
          Map.put(
            subscriptions.revoked_group_memberships,
            event.group_membership_id,
            event.revocation_id
          )
    }
  end

  def apply(
        %__MODULE__{} = subscriptions,
        %GroupMembershipSubscriptionRevocationCompleted{} = event
      ) do
    revocation = %{group_membership_id: event.group_membership_id, completed: true}

    %{
      subscriptions
      | revocations: Map.put(subscriptions.revocations, event.revocation_id, revocation)
    }
  end

  def apply(%__MODULE__{} = subscriptions, _event), do: subscriptions

  def subscription_id(person_id, conversation_id),
    do: ID.deterministic(:conversation_subscription, [person_id, conversation_id])

  def authorization_id(subscription_intent_id, group_membership_id),
    do:
      ID.deterministic(:subscription_authorization, [subscription_intent_id, group_membership_id])

  def revocation_id(group_membership_id),
    do: ID.deterministic(:subscription_revocation, [group_membership_id])

  defp authorization_revoked(grant, opts) do
    %ConversationSubscriptionAuthorizationRevoked{
      person_id: grant.person_id,
      conversation_id: grant.conversation_id,
      subscription_id: grant.subscription_id,
      authorization_id: grant.authorization_id,
      group_membership_id: grant.group_membership_id,
      revocation_id: Keyword.get(opts, :revocation_id),
      unfollow_id: Keyword.get(opts, :unfollow_id),
      reason: Keyword.fetch!(opts, :reason)
    }
  end

  defp validate_start(command) do
    with :ok <- validate_authority_proof(command),
         :ok <- validate_id(:person, command.person_id, :invalid_person_id),
         :ok <- validate_id(:club, command.club_id, :invalid_club_id),
         :ok <- validate_id(:message, command.conversation_id, :invalid_conversation_id),
         :ok <-
           validate_id(
             :conversation_subscription,
             command.subscription_id,
             :invalid_subscription_id
           ),
         :ok <-
           validate_id(
             :subscription_intent,
             command.subscription_intent_id,
             :invalid_subscription_intent_id
           ),
         :ok <-
           validate_id(
             :authority_decision,
             command.authority_decision_id,
             :invalid_authority_decision_id
           ),
         :ok <- validate_id(:membership, command.club_membership_id, :invalid_club_membership_id),
         :ok <- validate_source(command.source),
         :ok <- validate_group_memberships(command.group_membership_ids) do
      if command.group_membership_ids == Enum.sort(Enum.uniq(command.group_membership_ids)),
        do: :ok,
        else: {:error, :group_membership_ids_not_canonical}
    end
  end

  defp validate_authorize(command) do
    with :ok <- validate_authority_proof(command),
         :ok <- validate_id(:person, command.person_id, :invalid_person_id),
         :ok <-
           validate_id(
             :subscription_intent,
             command.subscription_intent_id,
             :invalid_subscription_intent_id
           ),
         :ok <-
           validate_id(
             :authority_decision,
             command.authority_decision_id,
             :invalid_authority_decision_id
           ) do
      validate_group_memberships(command.current_group_membership_ids, allow_empty: true)
    end
  end

  defp validate_cancel(command) do
    with :ok <- validate_id(:person, command.person_id, :invalid_person_id),
         :ok <-
           validate_id(
             :subscription_intent,
             command.subscription_intent_id,
             :invalid_subscription_intent_id
           ),
         :ok <- validate_uuid(command.cancellation_id, :invalid_cancellation_id) do
      validate_reason(command.reason)
    end
  end

  defp validate_end(command) do
    with :ok <- validate_id(:person, command.person_id, :invalid_person_id),
         :ok <- validate_id(:message, command.conversation_id, :invalid_conversation_id) do
      validate_uuid(command.unfollow_id, :invalid_unfollow_id)
    end
  end

  defp validate_revoke(command) do
    with :ok <- validate_id(:person, command.person_id, :invalid_person_id),
         :ok <-
           validate_id(
             :group_membership,
             command.group_membership_id,
             :invalid_group_membership_id
           ),
         :ok <-
           validate_id(:subscription_revocation, command.revocation_id, :invalid_revocation_id) do
      if command.revocation_id == revocation_id(command.group_membership_id),
        do: :ok,
        else: {:error, :revocation_id_mismatch}
    end
  end

  defp run_authority_revalidation_hook(decision) do
    case Application.get_env(:memba, :conversation_subscription_authority_revalidation_hook) do
      hook when is_function(hook, 1) -> hook.(decision)
      _no_hook -> :ok
    end
  end

  defp validate_authority_proof(
         %{
           authority_decision: %ConversationSubscriptionAuthorityDecision{} = decision
         } = command
       ) do
    matches? =
      decision.person_id == command.person_id and
        decision.subscription_intent_id == command.subscription_intent_id and
        decision.source == Map.get(command, :source, decision.source) and
        decision.club_id == Map.get(command, :club_id, decision.club_id) and
        decision.conversation_id ==
          Map.get(command, :conversation_id, decision.conversation_id) and
        decision.conversation_group_ids ==
          Map.get(command, :conversation_group_ids, decision.conversation_group_ids) and
        decision.conversation_stream_version ==
          Map.get(
            command,
            :conversation_stream_version,
            decision.conversation_stream_version
          ) and
        decision.authority_decision_id == command.authority_decision_id and
        decision.club_membership_id ==
          Map.get(command, :club_membership_id, decision.club_membership_id) and
        decision.group_membership_ids ==
          Map.get(command, :group_membership_ids, decision.group_membership_ids) and
        decision.group_membership_ids ==
          Map.get(command, :current_group_membership_ids, decision.group_membership_ids)

    if matches? and Membership.valid_conversation_authority_signature?(decision),
      do: :ok,
      else: {:error, :invalid_conversation_subscription_authority}
  end

  defp validate_authority_proof(_command),
    do: {:error, :invalid_conversation_subscription_authority}

  defp validate_subscription_identity(command) do
    if command.subscription_id == subscription_id(command.person_id, command.conversation_id),
      do: :ok,
      else: {:error, :subscription_id_mismatch}
  end

  defp validate_new_intent(subscriptions, command) do
    expected = %{
      person_id: command.person_id,
      club_id: command.club_id,
      conversation_id: command.conversation_id,
      conversation_group_ids: command.conversation_group_ids,
      conversation_stream_version: command.conversation_stream_version,
      subscription_id: command.subscription_id,
      subscription_intent_id: command.subscription_intent_id,
      authority_decision_id: command.authority_decision_id,
      source: command.source,
      club_membership_id: command.club_membership_id,
      group_membership_ids: command.group_membership_ids,
      status: :open
    }

    case Map.get(subscriptions.intents, command.subscription_intent_id) do
      nil ->
        :ok

      intent ->
        if Map.drop(intent, [:status]) == Map.drop(expected, [:status]),
          do: :exact_retry,
          else: {:error, :subscription_intent_id_conflict}
    end
  end

  defp fetch_intent(subscriptions, intent_id) do
    case Map.fetch(subscriptions.intents, intent_id) do
      {:ok, intent} -> {:ok, intent}
      :error -> {:error, :subscription_intent_not_found}
    end
  end

  defp fetch_open_intent(subscriptions, intent_id) do
    with {:ok, intent} <- fetch_intent(subscriptions, intent_id) do
      if intent.status == :open, do: {:ok, intent}, else: {:error, :subscription_intent_cancelled}
    end
  end

  defp validate_authority_decision(%{authority_decision_id: decision_id}, decision_id), do: :ok

  defp validate_authority_decision(_intent, _decision_id),
    do: {:error, :authority_decision_mismatch}

  defp grantable_group_memberships(subscriptions, intent, command) do
    current = MapSet.new(command.current_group_membership_ids)
    bound = MapSet.new(intent.group_membership_ids)

    if MapSet.subset?(current, bound) do
      grantable =
        intent.group_membership_ids
        |> Enum.filter(&MapSet.member?(current, &1))
        |> Enum.reject(&Map.has_key?(subscriptions.revoked_group_memberships, &1))
        |> Enum.reject(fn group_membership_id ->
          Map.has_key?(
            subscriptions.grants,
            authorization_id(intent.subscription_intent_id, group_membership_id)
          )
        end)

      cond do
        grantable != [] -> {:ok, grantable}
        previously_granted?(subscriptions, intent) -> {:ok, []}
        true -> {:error, :authority_no_longer_current}
      end
    else
      {:error, :authority_not_bound_to_intent}
    end
  end

  defp previously_granted?(subscriptions, intent) do
    Enum.any?(intent.group_membership_ids, fn group_membership_id ->
      Map.has_key?(
        subscriptions.grants,
        authorization_id(intent.subscription_intent_id, group_membership_id)
      )
    end)
  end

  defp validate_cancellation_retry(subscriptions, intent, command) do
    case Map.get(subscriptions.cancellations, command.cancellation_id) do
      nil ->
        :ok

      %{intent_id: intent_id, reason: reason}
      when intent_id == intent.subscription_intent_id and reason == command.reason ->
        :ok

      _other ->
        {:error, :cancellation_id_conflict}
    end
  end

  defp validate_unfollow_retry(subscriptions, command) do
    expected = %{
      conversation_id: command.conversation_id,
      subscription_id: subscription_id(command.person_id, command.conversation_id)
    }

    case Map.get(subscriptions.unfollows, command.unfollow_id) do
      nil -> :ok
      ^expected -> :exact_retry
      _other -> {:error, :unfollow_id_conflict}
    end
  end

  defp validate_revocation_retry(subscriptions, command) do
    case Map.get(subscriptions.revocations, command.revocation_id) do
      nil ->
        case Map.get(subscriptions.revoked_group_memberships, command.group_membership_id) do
          nil -> :ok
          _other_revocation_id -> {:error, :group_membership_already_revoked}
        end

      %{group_membership_id: group_membership_id, completed: true}
      when group_membership_id == command.group_membership_id ->
        :exact_retry

      _other ->
        {:error, :revocation_id_conflict}
    end
  end

  defp validate_person(%__MODULE__{person_id: nil}, _person_id), do: :ok
  defp validate_person(%__MODULE__{person_id: person_id}, person_id), do: :ok
  defp validate_person(_subscriptions, _person_id), do: {:error, :person_id_mismatch}

  defp validate_source(source) when source in @sources, do: :ok
  defp validate_source(_source), do: {:error, :invalid_subscription_source}

  defp normalize_source("manual"), do: :manual
  defp normalize_source("root"), do: :root
  defp normalize_source("reply"), do: :reply
  defp normalize_source(source) when source in @sources, do: source

  defp validate_group_memberships(group_membership_ids, opts \\ [])

  defp validate_group_memberships(group_membership_ids, opts)
       when is_list(group_membership_ids) do
    allow_empty? = Keyword.get(opts, :allow_empty, false)

    cond do
      group_membership_ids == [] and not allow_empty? ->
        {:error, :no_authorizing_group_memberships}

      Enum.all?(group_membership_ids, &ID.valid?(:group_membership, &1)) ->
        :ok

      true ->
        {:error, :invalid_group_membership_id}
    end
  end

  defp validate_group_memberships(_group_membership_ids, _opts),
    do: {:error, :invalid_group_membership_ids}

  defp validate_reason(reason) when is_binary(reason) and byte_size(reason) > 0, do: :ok
  defp validate_reason(_reason), do: {:error, :invalid_cancellation_reason}

  defp validate_uuid(value, error) when is_binary(value) do
    case Ecto.UUID.cast(value) do
      {:ok, ^value} -> :ok
      _other -> {:error, error}
    end
  end

  defp validate_uuid(_value, error), do: {:error, error}

  defp validate_id(type, value, error) do
    if ID.valid?(type, value), do: :ok, else: {:error, error}
  end
end
