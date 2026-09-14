defmodule Memba.Membership.Projectors.Membership do
  @moduledoc """
  Projects membership events into the Membership read model.

  An added membership is not exposed as active until the follow-cleanup policy
  has durably acknowledged that event's global EventStore position. This keeps
  a rapid re-add from making a departed member eligible for stale private-group
  follows while allowing this projector to rebuild independently.
  """

  use Commanded.Projections.Ecto,
    application: Memba.Membership.App,
    repo: Memba.Repo,
    name: "Memba.Membership.Projectors.Membership",
    consistency: :strong

  alias Memba.Membership.Events.ClubMemberAdded
  alias Memba.Membership.Events.ClubMemberRemoved
  alias Memba.Membership.Events.MemberAdded, as: LegacyMemberAdded
  alias Memba.Membership.Events.MemberRemoved, as: LegacyMemberRemoved
  alias Memba.Membership.Policies.ClearRemovedGroupMemberFollows
  alias Memba.Membership.Projections.Membership, as: MembershipProjection
  alias Memba.ProjectionBarrier

  @impl Commanded.Event.Handler
  def handle(%ClubMemberAdded{} = event, metadata) do
    project_member_added_after_follow_cleanup(event, metadata)
  end

  def handle(%LegacyMemberAdded{} = event, metadata) do
    project_member_added_after_follow_cleanup(event, metadata)
  end

  project(%ClubMemberRemoved{} = event, fn multi ->
    project_member_removed(multi, event)
  end)

  project(%LegacyMemberRemoved{} = event, fn multi ->
    project_member_removed(multi, event)
  end)

  defp project_member_added_after_follow_cleanup(event, metadata) do
    with :ok <- await_follow_cleanup(metadata.event_number) do
      update_projection(event, metadata, fn multi ->
        project_member_added(multi, event)
      end)
    end
  end

  defp await_follow_cleanup(event_number) do
    case ProjectionBarrier.await(
           [ClearRemovedGroupMemberFollows],
           checkpoint: event_number,
           timeout: 5_000
         ) do
      {:ok, _result} ->
        :ok

      {:error, :timeout, _result} ->
        {:error, :removed_group_member_follow_cleanup_unavailable}
    end
  end

  defp project_member_added(multi, event) do
    Ecto.Multi.insert(multi, :membership_membership, %MembershipProjection{
      membership_id: event.membership_id,
      club_id: event.club_id,
      person_id: event.person_id,
      active: true
    })
  end

  defp project_member_removed(multi, event) do
    Ecto.Multi.update_all(
      multi,
      :membership_membership,
      membership_query(event.membership_id),
      set: [active: false]
    )
  end

  defp membership_query(membership_id) do
    import Ecto.Query

    from(membership in MembershipProjection,
      where: membership.membership_id == ^membership_id
    )
  end

  @impl Commanded.Projections.Ecto
  def after_update(event, metadata, changes) do
    Memba.ReadModelChanges.publish(__MODULE__, event, metadata, changes)
  end
end
