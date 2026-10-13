defmodule Memba.Membership.PersonMerge do
  @moduledoc """
  Console workflow for merging an uncomplicated duplicate person into a survivor.

  This intentionally accepts only the safe first slice: every source address must
  be verified, every active source club membership must overlap with the target,
  and the source must have no active roles or custom-group memberships.
  """

  import Ecto.Query

  alias Memba.ID
  alias Memba.Membership.ClubMember
  alias Memba.Membership.CommandDispatch
  alias Memba.Membership.Commands.MergePerson
  alias Memba.Membership.Projections.GroupMembership
  alias Memba.Membership.Projections.Membership
  alias Memba.Membership.Projections.Person
  alias Memba.Membership.Projections.PersonEmailAddress
  alias Memba.Membership.Projections.RoleAssignment
  alias Memba.Membership.SystemGroups
  alias Memba.Repo

  @type receipt :: %{
          status: :ready | :merged | :already_merged,
          source_person_id: String.t(),
          target_person_id: String.t(),
          email_addresses: [String.t()],
          memberships_to_collapse: [String.t()]
        }

  @doc "Inspect a proposed merge without changing data."
  @spec preview(String.t(), String.t()) :: {:ok, receipt()} | {:error, term()}
  def preview(source_person_id, target_person_id) do
    case prepare(source_person_id, target_person_id) do
      {:ok, receipt} -> {:ok, Map.delete(receipt, :command)}
      {:error, _reason} = error -> error
    end
  end

  @doc "Merge after applying all of the validations returned by `preview/2`."
  @spec merge(String.t(), String.t()) :: {:ok, receipt()} | {:error, term()}
  def merge(source_person_id, target_person_id) do
    with {:ok, %{status: :already_merged} = receipt} <-
           prepare(source_person_id, target_person_id) do
      {:ok, receipt}
    else
      {:ok, %{status: :ready} = preview} -> execute_merge(preview)
      {:error, _reason} = error -> error
    end
  end

  defp prepare(source_person_id, target_person_id) do
    with {:ok, source_person_id} <- cast_person_id(source_person_id),
         {:ok, target_person_id} <- cast_person_id(target_person_id),
         :ok <- reject_self_merge(source_person_id, target_person_id),
         {:ok, source} <- fetch_person(source_person_id),
         {:ok, target} <- fetch_person(target_person_id),
         {:continue, source, target} <- merge_status(source, target),
         source_addresses <- email_addresses(source_person_id),
         target_addresses <- email_addresses(target_person_id),
         :ok <- require_verified_source_addresses(source_addresses),
         source_memberships <- active_memberships(source_person_id),
         :ok <- require_overlapping_memberships(source_memberships, target_person_id),
         :ok <- reject_active_roles(source_memberships),
         :ok <- reject_active_custom_groups(source_memberships),
         {:ok, merged_addresses} <- merge_email_addresses(target_addresses, source_addresses) do
      {:ok,
       %{
         status: :ready,
         source_person_id: source.person_id,
         target_person_id: target.person_id,
         email_addresses: Enum.map(merged_addresses, & &1.email),
         memberships_to_collapse: Enum.map(source_memberships, & &1.membership_id),
         command: %MergePerson{
           person_id: target.person_id,
           source_person_id: source.person_id,
           email_addresses: merged_addresses
         }
       }}
    else
      {:already_merged, receipt} -> {:ok, receipt}
      {:error, _reason} = error -> error
    end
  end

  defp execute_merge(preview) do
    with :ok <- collapse_memberships(preview.memberships_to_collapse),
         :ok <- CommandDispatch.dispatch(preview.command, consistency: :strong) do
      {:ok,
       preview
       |> Map.delete(:command)
       |> Map.put(:status, :merged)}
    end
  end

  defp collapse_memberships(membership_ids) do
    Enum.reduce_while(membership_ids, :ok, fn membership_id, :ok ->
      result =
        with {:ok, command} <- ClubMember.Remove.prepare(%{membership_id: membership_id}) do
          CommandDispatch.dispatch(command, consistency: :strong)
        end

      case result do
        :ok ->
          {:cont, :ok}

        {:error, reason} ->
          {:halt, {:error, {:membership_collapse_failed, membership_id, reason}}}
      end
    end)
  end

  defp merge_status(
         %Person{merged_into_person_id: nil} = source,
         %Person{
           merged_into_person_id: nil
         } = target
       ),
       do: {:continue, source, target}

  defp merge_status(%Person{merged_into_person_id: target_id} = source, %Person{
         person_id: target_id,
         merged_into_person_id: nil
       }) do
    {:already_merged,
     %{
       status: :already_merged,
       source_person_id: source.person_id,
       target_person_id: target_id,
       email_addresses: [],
       memberships_to_collapse: []
     }}
  end

  defp merge_status(%Person{merged_into_person_id: nil}, %Person{}),
    do: {:error, :target_person_already_merged}

  defp merge_status(%Person{}, %Person{}), do: {:error, :source_person_already_merged}

  defp fetch_person(person_id) do
    case Repo.get(Person, person_id) do
      nil -> {:error, :person_not_found}
      person -> {:ok, person}
    end
  end

  defp email_addresses(person_id) do
    PersonEmailAddress
    |> where([address], address.person_id == ^person_id)
    |> order_by([address], desc: address.is_primary, asc: address.normalized_email)
    |> Repo.all()
  end

  defp active_memberships(person_id) do
    Membership
    |> where([membership], membership.person_id == ^person_id and membership.active == true)
    |> order_by([membership], asc: membership.club_id, asc: membership.membership_id)
    |> Repo.all()
  end

  defp require_verified_source_addresses([]), do: {:error, :source_has_no_email_address}

  defp require_verified_source_addresses(addresses) do
    if Enum.all?(addresses, &(not is_nil(&1.verified_at))) do
      :ok
    else
      {:error, :source_has_pending_email_address}
    end
  end

  defp require_overlapping_memberships(source_memberships, target_person_id) do
    missing_club_ids =
      source_memberships
      |> Enum.map(& &1.club_id)
      |> Enum.reject(&active_membership?(&1, target_person_id))

    case missing_club_ids do
      [] -> :ok
      club_ids -> {:error, {:memberships_need_reconciliation, club_ids}}
    end
  end

  defp active_membership?(club_id, person_id) do
    Membership
    |> where(
      [membership],
      membership.club_id == ^club_id and membership.person_id == ^person_id and
        membership.active == true
    )
    |> Repo.exists?()
  end

  defp reject_active_roles([]), do: :ok

  defp reject_active_roles(memberships) do
    membership_ids = Enum.map(memberships, & &1.membership_id)

    if RoleAssignment
       |> where(
         [assignment],
         assignment.membership_id in ^membership_ids and assignment.active == true
       )
       |> Repo.exists?() do
      {:error, :source_has_active_role_assignments}
    else
      :ok
    end
  end

  defp reject_active_custom_groups([]), do: :ok

  defp reject_active_custom_groups(memberships) do
    membership_ids = Enum.map(memberships, & &1.membership_id)

    custom_group? = fn group_membership ->
      SystemGroups.custom_group?(group_membership)
    end

    has_custom_group =
      GroupMembership
      |> where(
        [group_membership],
        group_membership.membership_id in ^membership_ids and group_membership.active == true
      )
      |> Repo.all()
      |> Enum.any?(custom_group?)

    if has_custom_group, do: {:error, :source_has_active_custom_group_memberships}, else: :ok
  end

  defp merge_email_addresses(target_addresses, source_addresses) do
    target = Enum.map(target_addresses, &address_state(&1, &1.is_primary))
    source = Enum.map(source_addresses, &address_state(&1, false))

    (target ++ source)
    |> Enum.uniq_by(& &1.normalized_email)
    |> Memba.Membership.EmailAddresses.validate_state()
  end

  defp address_state(address, is_primary) do
    %{
      email: address.email,
      normalized_email: address.normalized_email,
      is_primary: is_primary,
      verified_at: address.verified_at
    }
  end

  defp cast_person_id(person_id) do
    case ID.cast(:person, person_id) do
      {:ok, person_id} -> {:ok, person_id}
      :error -> {:error, :invalid_person_id}
    end
  end

  defp reject_self_merge(person_id, person_id), do: {:error, :cannot_merge_person_into_itself}
  defp reject_self_merge(_source_person_id, _target_person_id), do: :ok
end
