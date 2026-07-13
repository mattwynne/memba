defmodule Memba.Membership.Projectors.Person do
  @moduledoc """
  Projects person events into the Membership person read model.
  """

  use Commanded.Projections.Ecto,
    application: Memba.Membership.App,
    repo: Memba.Repo,
    name: "Memba.Membership.Projectors.Person",
    consistency: :strong

  alias Memba.Membership.Events.PersonEmailAddressAdded
  alias Memba.Membership.Events.PersonEmailAddressRemoved
  alias Memba.Membership.Events.PersonEmailAddressVerified
  alias Memba.Membership.Events.PersonEmailAddressesReplaced
  alias Memba.Membership.Events.PersonCreated
  alias Memba.Membership.Events.PersonPrimaryEmailAddressChanged
  alias Memba.Membership.Projections.Person, as: PersonProjection
  alias Memba.Membership.Projections.PersonEmailAddress

  project(%PersonCreated{} = event, fn multi ->
    multi
    |> Ecto.Multi.insert(:membership_person, %PersonProjection{
      person_id: event.person_id,
      name: event.name,
      email: event.email
    })
    |> upsert_legacy_primary_email_address(event)
  end)

  project(%PersonEmailAddressesReplaced{} = event, fn multi ->
    multi
    |> Ecto.Multi.update_all(
      :membership_person_primary_email,
      person_query(event.person_id),
      set: [email: event.primary_email, updated_at: DateTime.utc_now()]
    )
    |> Ecto.Multi.delete_all(
      :membership_person_email_addresses_deleted,
      email_addresses_query(event.person_id)
    )
    |> insert_email_addresses(event.person_id, event.email_addresses)
  end)

  project(%PersonEmailAddressAdded{} = event, fn multi ->
    Ecto.Multi.insert(
      multi,
      :membership_person_email_address_added,
      PersonEmailAddress.changeset(%PersonEmailAddress{}, %{
        person_id: event.person_id,
        email: event.email,
        is_primary: false,
        verified_at: nil
      })
    )
  end)

  project(%PersonEmailAddressVerified{} = event, fn multi ->
    Ecto.Multi.update_all(
      multi,
      :membership_person_email_address_verified,
      email_address_query(event.person_id, event.normalized_email),
      set: [verified_at: verified_at!(event.verified_at), updated_at: DateTime.utc_now()]
    )
  end)

  project(%PersonPrimaryEmailAddressChanged{} = event, fn multi ->
    multi
    |> Ecto.Multi.update_all(
      :membership_person_primary_email,
      person_query(event.person_id),
      set: [email: event.primary_email, updated_at: DateTime.utc_now()]
    )
    |> Ecto.Multi.update_all(
      :membership_person_email_addresses_non_primary,
      email_addresses_query(event.person_id),
      set: [is_primary: false, updated_at: DateTime.utc_now()]
    )
    |> Ecto.Multi.update_all(
      :membership_person_email_address_primary,
      email_address_query(event.person_id, event.normalized_email),
      set: [is_primary: true, updated_at: DateTime.utc_now()]
    )
  end)

  project(%PersonEmailAddressRemoved{} = event, fn multi ->
    Ecto.Multi.delete_all(
      multi,
      :membership_person_email_address_removed,
      email_address_query(event.person_id, event.normalized_email)
    )
  end)

  defp upsert_legacy_primary_email_address(multi, %PersonCreated{} = event) do
    changeset =
      PersonEmailAddress.changeset(%PersonEmailAddress{}, %{
        person_id: event.person_id,
        email: event.email,
        is_primary: true,
        verified_at: DateTime.utc_now()
      })

    Ecto.Multi.insert(
      multi,
      :membership_person_primary_email_address,
      changeset,
      on_conflict:
        {:replace, [:email, :normalized_email, :is_primary, :verified_at, :updated_at]},
      conflict_target: {:unsafe_fragment, "(person_id) WHERE is_primary = true"}
    )
  end

  defp insert_email_addresses(multi, person_id, email_addresses) do
    Enum.reduce(email_addresses, multi, fn email_address, multi ->
      attrs = email_address_attrs(person_id, email_address)

      Ecto.Multi.insert(
        multi,
        {:membership_person_email_address, attrs.normalized_email},
        PersonEmailAddress.changeset(%PersonEmailAddress{}, attrs)
      )
    end)
  end

  defp email_address_attrs(person_id, email_address) do
    %{
      person_id: person_id,
      email: field(email_address, :email),
      normalized_email: field(email_address, :normalized_email),
      is_primary: field(email_address, :is_primary),
      verified_at: replacement_verified_at(email_address)
    }
  end

  defp field(email_address, key) when is_map(email_address) do
    case Map.fetch(email_address, key) do
      {:ok, value} -> value
      :error -> Map.get(email_address, Atom.to_string(key))
    end
  end

  defp replacement_verified_at(email_address) do
    if has_field?(email_address, :verified_at) do
      email_address
      |> field(:verified_at)
      |> verified_at_or_nil!()
    else
      DateTime.utc_now()
    end
  end

  defp has_field?(email_address, key) when is_map(email_address) do
    Map.has_key?(email_address, key) or Map.has_key?(email_address, Atom.to_string(key))
  end

  defp person_query(person_id) do
    Ecto.Query.from(person in PersonProjection, where: person.person_id == ^person_id)
  end

  defp email_addresses_query(person_id) do
    Ecto.Query.from(email_address in PersonEmailAddress,
      where: email_address.person_id == ^person_id
    )
  end

  defp email_address_query(person_id, normalized_email) do
    Ecto.Query.from(email_address in PersonEmailAddress,
      where:
        email_address.person_id == ^person_id and
          email_address.normalized_email == ^normalized_email
    )
  end

  defp verified_at!(%DateTime{} = verified_at), do: verified_at

  defp verified_at!(verified_at) when is_binary(verified_at) do
    case DateTime.from_iso8601(verified_at) do
      {:ok, verified_at, _offset} -> verified_at
      {:error, _reason} -> DateTime.utc_now()
    end
  end

  defp verified_at_or_nil!(nil), do: nil
  defp verified_at_or_nil!(verified_at), do: verified_at!(verified_at)

  @impl Commanded.Projections.Ecto
  def after_update(event, metadata, changes) do
    Memba.ReadModelChanges.publish(__MODULE__, event, metadata, changes)
  end
end
