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
  alias Memba.Membership.Projections.Group, as: GroupProjection

  project(%GroupCreated{} = event, fn multi ->
    now = DateTime.utc_now(:microsecond)

    Ecto.Multi.insert(
      multi,
      :membership_group,
      %GroupProjection{
        club_id: event.club_id,
        group_id: event.group_id,
        group_key: event.group_key,
        name: event.name,
        inserted_at: now,
        updated_at: now
      },
      on_conflict: [
        set: [
          club_id: event.club_id,
          group_key: event.group_key,
          name: event.name,
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
      group_without_different_email_slug_query(event),
      set: [email_slug: event.email_slug, updated_at: DateTime.utc_now(:microsecond)]
    )
  end)

  defp group_without_different_email_slug_query(%GroupEmailSlugAssigned{} = event) do
    Ecto.Query.from(
      group in GroupProjection,
      where: group.group_id == ^event.group_id,
      where: group.club_id == ^event.club_id,
      where: is_nil(group.email_slug) or group.email_slug == ^event.email_slug
    )
  end

  @impl Commanded.Projections.Ecto
  def after_update(event, metadata, changes) do
    Memba.ReadModelChanges.publish(__MODULE__, event, metadata, changes)
  end
end
