defmodule Memba.Membership.InvitationAcceptance do
  @moduledoc """
  Coordinates the pending invitation's person, membership, and acceptance commands.

  Each successful step is durable. A retry recovers the person by invited email
  and the active membership by club/person before deciding which command remains.
  The invitation command remains the one-use boundary; this workflow does not
  send invitation email or change the invitation token.
  """

  import Ecto.Query

  alias Memba.ID
  alias Memba.Membership.CommandDispatch
  alias Memba.Membership.Commands.AcceptClubMemberInvitation
  alias Memba.Membership.Commands.AddClubMember
  alias Memba.Membership.Commands.CreatePerson
  alias Memba.Membership.Projections.ClubInvitation
  alias Memba.Membership.Projections.Membership, as: MembershipProjection
  alias Memba.Membership.Projections.Person
  alias Memba.Membership.Projections.PersonEmailAddress
  alias Memba.Membership.PersonEmailAddressCommands
  alias Memba.Membership.ProjectedIdentityLookup
  alias Memba.Repo

  def accept_existing(attrs, dispatch_opts) do
    {hooks, dispatch_opts} = acceptance_hooks(dispatch_opts)
    dispatch_opts = acceptance_dispatch_opts(dispatch_opts)

    with {:ok, invitation} <- pending_invitation(attrs),
         {:ok, person_id} <- fetch_required(attrs, :person_id),
         {:ok, person_id} <- cast_person_id(person_id),
         {:ok, _person} <- fetch_existing_person(person_id),
         :ok <- ensure_person_has_invitation_email(person_id, invitation),
         :ok <- ensure_invitation_email_recovers_person(invitation, person_id),
         {:ok, membership_id} <- recovered_membership_id(invitation, attrs, person_id),
         {:ok, add_member_result} <-
           add_member(invitation, person_id, membership_id, dispatch_opts),
         :ok <- run_hook(hooks, :after_membership_added),
         {:ok, accept_result} <- accept(invitation, person_id, membership_id, dispatch_opts) do
      {:ok,
       acceptance_result(invitation, person_id, membership_id, add_member_result, accept_result)}
    end
  end

  def complete_profile(attrs, dispatch_opts) do
    {hooks, dispatch_opts} = acceptance_hooks(dispatch_opts)
    dispatch_opts = acceptance_dispatch_opts(dispatch_opts)

    with {:ok, invitation} <- pending_invitation(attrs),
         {:ok, name} <- fetch_required(attrs, :name),
         {:ok, normalized_name} <- normalize_name(name),
         {:ok, person_id, person_step} <- recovered_person(invitation, attrs, normalized_name),
         {:ok, membership_id} <- recovered_membership_id(invitation, attrs, person_id),
         {:ok, create_person_result} <-
           create_recovered_person(
             invitation,
             person_id,
             normalized_name,
             person_step,
             dispatch_opts
           ),
         :ok <- run_hook(hooks, :after_person_created),
         {:ok, add_member_result} <-
           add_member(invitation, person_id, membership_id, dispatch_opts),
         :ok <- run_hook(hooks, :after_membership_added),
         {:ok, accept_result} <- accept(invitation, person_id, membership_id, dispatch_opts) do
      {:ok,
       invitation
       |> acceptance_result(person_id, membership_id, add_member_result, accept_result)
       |> Map.put(:person_execution_result, create_person_result)}
    end
  end

  defp pending_invitation(attrs) do
    with {:ok, invitation_id} <- fetch_required(attrs, :invitation_id) do
      case ProjectedIdentityLookup.club_invitation(invitation_id) do
        nil -> {:error, :pending_invitation_not_found}
        %ClubInvitation{status: "pending"} = invitation -> {:ok, invitation}
        %ClubInvitation{status: "accepted"} -> {:error, :already_accepted}
      end
    end
  end

  defp recovered_person(%ClubInvitation{} = invitation, attrs, normalized_name) do
    with {:ok, recovered_person_id} <- recover_person_id_by_email(invitation),
         {:ok, person_id} <- invitation_person_id(invitation, attrs, recovered_person_id),
         {:ok, step} <- person_step(person_id, recovered_person_id, normalized_name, invitation) do
      {:ok, person_id, step}
    end
  end

  defp ensure_invitation_email_recovers_person(invitation, person_id) do
    with {:ok, recovered_person_id} <- recover_person_id_by_email(invitation) do
      case recovered_person_id do
        ^person_id -> :ok
        nil -> {:error, :person_not_found}
        _different_person_id -> {:error, :invitation_email_mismatch}
      end
    end
  end

  defp recovered_membership_id(invitation, attrs, person_id) do
    with {:ok, recovered_id} <- recover_active_membership_id(invitation.club_id, person_id) do
      invitation_membership_id(invitation, attrs, recovered_id)
    end
  end

  defp invitation_person_id(invitation, attrs, recovered_person_id) do
    case fetch_optional(attrs, :person_id) do
      {:ok, person_id} ->
        with {:ok, person_id} <- cast_person_id(person_id),
             :ok <-
               explicit_identity_matches(
                 person_id,
                 recovered_person_id,
                 :invitation_person_mismatch
               ) do
          {:ok, person_id}
        end

      :error ->
        {:ok,
         recovered_person_id ||
           ID.deterministic(:person, ["club_member_invitation_person", invitation.invitation_id])}
    end
  end

  defp invitation_membership_id(invitation, attrs, recovered_id) do
    case fetch_optional(attrs, :membership_id) do
      {:ok, membership_id} ->
        with {:ok, membership_id} <- cast_membership_id(membership_id),
             :ok <-
               explicit_identity_matches(
                 membership_id,
                 recovered_id,
                 :invitation_membership_mismatch
               ) do
          {:ok, membership_id}
        end

      :error ->
        {:ok,
         recovered_id ||
           ID.deterministic(:membership, [
             "club_member_invitation_membership",
             invitation.invitation_id
           ])}
    end
  end

  defp recover_person_id_by_email(invitation) do
    PersonEmailAddress
    |> where([email_address], email_address.normalized_email == ^invitation.normalized_email)
    |> distinct([email_address], email_address.person_id)
    |> select([email_address], email_address.person_id)
    |> limit(2)
    |> Repo.all()
    |> case do
      [] -> {:ok, nil}
      [person_id] -> {:ok, person_id}
      [_first, _second | _rest] -> {:error, :ambiguous_invitation_person}
    end
  end

  defp recover_active_membership_id(club_id, person_id) do
    MembershipProjection
    |> where([membership], membership.club_id == ^club_id)
    |> where([membership], membership.person_id == ^person_id)
    |> where([membership], membership.active == true)
    |> select([membership], membership.membership_id)
    |> limit(2)
    |> Repo.all()
    |> case do
      [] -> {:ok, nil}
      [membership_id] -> {:ok, membership_id}
      [_first, _second | _rest] -> {:error, :ambiguous_active_membership}
    end
  end

  defp explicit_identity_matches(_candidate_id, nil, _error), do: :ok
  defp explicit_identity_matches(identity, identity, _error), do: :ok
  defp explicit_identity_matches(_candidate_id, _recovered_id, error), do: {:error, error}

  defp person_step(person_id, nil, _name, _invitation) do
    case ProjectedIdentityLookup.person(person_id) do
      nil -> {:ok, :create}
      %Person{} -> {:error, :invitation_person_mismatch}
    end
  end

  defp person_step(person_id, person_id, name, invitation) do
    case ProjectedIdentityLookup.person(person_id) do
      %Person{name: ^name} = person ->
        if person_has_email?(person.person_id, invitation.normalized_email) do
          {:ok, :recovered}
        else
          {:error, :invitation_email_mismatch}
        end

      %Person{} ->
        {:error, :invitation_person_content_mismatch}

      nil ->
        {:error, :person_not_found}
    end
  end

  defp create_recovered_person(invitation, person_id, name, :create, dispatch_opts) do
    with :ok <-
           PersonEmailAddressCommands.prevent_duplicate(person_id, [
             %{normalized_email: invitation.normalized_email}
           ]) do
      dispatch_command(
        %CreatePerson{
          person_id: person_id,
          name: name,
          email_addresses: [%{email: invitation.email, is_primary: true}]
        },
        dispatch_opts
      )
    end
  end

  defp create_recovered_person(_invitation, _person_id, _name, :recovered, _opts), do: {:ok, :ok}

  defp person_has_email?(person_id, normalized_email) do
    PersonEmailAddress
    |> where([email_address], email_address.person_id == ^person_id)
    |> where([email_address], email_address.normalized_email == ^normalized_email)
    |> Repo.exists?()
  end

  defp fetch_existing_person(person_id) do
    case ProjectedIdentityLookup.person(person_id) do
      %Person{} = person -> {:ok, person}
      nil -> {:error, :person_not_found}
    end
  end

  defp ensure_person_has_invitation_email(person_id, invitation) do
    if person_has_email?(person_id, invitation.normalized_email) do
      :ok
    else
      {:error, :invitation_email_mismatch}
    end
  end

  defp add_member(invitation, person_id, membership_id, dispatch_opts) do
    %AddClubMember{
      membership_id: membership_id,
      club_id: invitation.club_id,
      person_id: person_id
    }
    |> dispatch_command(CommandDispatch.system_group_membership_consistency(dispatch_opts))
  end

  defp accept(invitation, person_id, membership_id, dispatch_opts) do
    dispatch_command(
      %AcceptClubMemberInvitation{
        invitation_id: invitation.invitation_id,
        person_id: person_id,
        membership_id: membership_id
      },
      dispatch_opts
    )
  end

  defp dispatch_command(command, dispatch_opts) do
    case CommandDispatch.dispatch(command, dispatch_opts) do
      :ok -> {:ok, :ok}
      {:ok, _result} = ok -> ok
      {:error, _reason} = error -> error
    end
  end

  defp acceptance_hooks(dispatch_opts) do
    {after_person_created, dispatch_opts} =
      Keyword.pop(dispatch_opts, :after_invitation_person_created)

    {after_membership_added, dispatch_opts} =
      Keyword.pop(dispatch_opts, :after_invitation_membership_added)

    {%{
       after_person_created: after_person_created,
       after_membership_added: after_membership_added
     }, dispatch_opts}
  end

  defp acceptance_dispatch_opts(dispatch_opts),
    do: Keyword.put(dispatch_opts, :consistency, :strong)

  defp run_hook(hooks, name) do
    case Map.get(hooks, name) do
      nil -> :ok
      hook when is_function(hook, 0) -> hook.()
      _invalid_hook -> {:error, :invalid_invitation_acceptance_hook}
    end
  end

  defp normalize_name(name) when is_binary(name) do
    case String.trim(name) do
      "" -> {:error, :invalid_name}
      trimmed_name -> {:ok, trimmed_name}
    end
  end

  defp normalize_name(_name), do: {:error, :invalid_name}

  defp cast_person_id(person_id) do
    case ID.cast(:person, person_id) do
      {:ok, person_id} -> {:ok, person_id}
      :error -> {:error, :invalid_person_id}
    end
  end

  defp cast_membership_id(membership_id) do
    case ID.cast(:membership, membership_id) do
      {:ok, membership_id} -> {:ok, membership_id}
      :error -> {:error, :invalid_membership_id}
    end
  end

  defp fetch_required(attrs, key) do
    case fetch_optional(attrs, key) do
      {:ok, value} -> {:ok, value}
      :error -> {:error, {:missing_required_attribute, key}}
    end
  end

  defp fetch_optional(attrs, key) do
    string_key = Atom.to_string(key)

    case attrs do
      %{^key => value} -> {:ok, value}
      %{^string_key => value} -> {:ok, value}
      _attrs -> :error
    end
  end

  defp acceptance_result(invitation, person_id, membership_id, add_member_result, accept_result) do
    %{
      invitation_id: invitation.invitation_id,
      club_id: invitation.club_id,
      person_id: person_id,
      membership_id: membership_id,
      membership_execution_result: add_member_result,
      invitation_execution_result: accept_result
    }
  end
end
