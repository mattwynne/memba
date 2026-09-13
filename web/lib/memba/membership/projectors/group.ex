defmodule Memba.Membership.Projectors.Group do
  @moduledoc """
  Projects group definition events into the Membership group read model.
  """

  use Commanded.Projections.Ecto,
    application: Memba.Membership.App,
    repo: Memba.Repo,
    name: "Memba.Membership.Projectors.Group",
    consistency: :strong

  alias Memba.Membership.Events.GroupCreated
  alias Memba.Membership.Events.GroupEmailSlugAssigned
  alias Memba.Membership.GroupName
  alias Memba.Membership.Projections.Group, as: GroupProjection

  project(%GroupCreated{} = event, fn multi ->
    now = DateTime.utc_now(:microsecond)
    name_uniqueness_key = GroupName.uniqueness_key(event.name)

    Ecto.Multi.insert(
      multi,
      :membership_group,
      %GroupProjection{
        club_id: event.club_id,
        group_id: event.group_id,
        group_key: event.group_key,
        name: event.name,
        name_uniqueness_key: name_uniqueness_key,
        inserted_at: now,
        updated_at: now
      },
      on_conflict: [
        set: [
          club_id: event.club_id,
          group_key: event.group_key,
          name: event.name,
          name_uniqueness_key: name_uniqueness_key,
          updated_at: now
        ]
      ],
      conflict_target: :group_id
    )
  end)

  project(%GroupEmailSlugAssigned{} = event, fn multi ->
    Ecto.Multi.update_all(
      multi,
      :membership_group_email_slug,
      group_query(event),
      set: [email_slug: event.email_slug, updated_at: DateTime.utc_now(:microsecond)]
    )
  end)

  defp group_query(event) do
    Ecto.Query.from(
      group in GroupProjection,
      where: group.club_id == ^event.club_id and group.group_id == ^event.group_id
    )
  end

  @impl Commanded.Projections.Ecto
  def after_update(event, metadata, changes) do
    Memba.ReadModelChanges.publish(__MODULE__, event, metadata, changes)
  end
end
