defmodule Memba.Membership.CustomGroup.Preview do
  @moduledoc """
  Advisory, authenticated custom-group identity preview from club projections.

  No identity is reserved here; the Club aggregate decides creation on dispatch.
  """

  import Ecto.Query

  alias Memba.ClubInboundEmailAddress
  alias Memba.ID
  alias Memba.Membership.Authorization
  alias Memba.Membership.CustomGroup.Required
  alias Memba.Membership.CustomGroupSlug
  alias Memba.Membership.GroupName
  alias Memba.Membership.Projections.Club
  alias Memba.Membership.Projections.Group
  alias Memba.Repo

  def call(attrs) when is_map(attrs) do
    with {:ok, club_id} <- Required.fetch(attrs, :club_id),
         {:ok, club_id} <- cast_id(:club, club_id, :not_found),
         {:ok, actor_person_id} <- Required.fetch(attrs, :actor_person_id),
         {:ok, actor_person_id} <- cast_id(:person, actor_person_id, :unauthorized),
         :ok <- Authorization.authorize_manage_members(club_id, actor_person_id),
         %Club{} = club <- Repo.get(Club, club_id),
         {:ok, submitted_name} <- Required.fetch(attrs, :name),
         {:ok, name} <- GroupName.normalize(submitted_name) do
      identity_preview(club, name)
    else
      nil -> {:error, :not_found}
      {:error, _reason} = error -> error
    end
  end

  defp cast_id(type, id, error) do
    case ID.cast(type, id) do
      {:ok, cast_id} -> {:ok, cast_id}
      :error -> {:error, error}
    end
  end

  defp identity_preview(%Club{} = club, name) do
    name_uniqueness_key = GroupName.uniqueness_key(name)

    case Repo.get_by(Group,
           club_id: club.club_id,
           name_uniqueness_key: name_uniqueness_key
         ) do
      nil ->
        available_identity_preview(club, name)

      %Group{name: existing_name} ->
        {:error, {:group_name_already_defined, existing_name}}
    end
  end

  defp available_identity_preview(%Club{} = club, name) do
    club_id = club.club_id

    occupied_email_slugs =
      Group
      |> where([group], group.club_id == ^club_id)
      |> where([group], not is_nil(group.email_slug))
      |> select([group], group.email_slug)
      |> Repo.all()
      |> MapSet.new()

    unsuffixed_email_slug = CustomGroupSlug.allocate(name, MapSet.new())
    email_slug = CustomGroupSlug.allocate(name, occupied_email_slugs)

    collision_group_name =
      if email_slug == unsuffixed_email_slug do
        nil
      else
        Group
        |> where([group], group.club_id == ^club_id)
        |> where([group], group.email_slug == ^unsuffixed_email_slug)
        |> select([group], group.name)
        |> Repo.one()
      end

    {:ok,
     %{
       name: name,
       email_slug: email_slug,
       email_address: ClubInboundEmailAddress.address(club, email_slug),
       unsuffixed_email_slug: unsuffixed_email_slug,
       collision_group_name: collision_group_name
     }}
  end
end
