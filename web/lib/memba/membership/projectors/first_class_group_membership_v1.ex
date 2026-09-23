defmodule Memba.Membership.Projectors.FirstClassGroupMembershipV1 do
  @moduledoc """
  Projects first-class custom GroupMembership lifecycle history.

  This deliberately uses a new, versioned subscription identity and starts from
  origin. A deployment therefore replays `GroupMembershipStarted` and
  `GroupMembershipEnded` facts that an older group-membership projector may
  already have acknowledged while it did not handle those event types.

  This projector owns only the first-class lifecycle table. In particular, its
  historical catch-up never rewrites the live legacy current-state projection;
  companion legacy facts remain the responsibility of the existing projector.
  """

  use Commanded.Projections.Ecto,
    application: Memba.Membership.App,
    repo: Memba.Repo,
    name: "Memba.Membership.Projectors.FirstClassGroupMembershipV1",
    consistency: :strong,
    start_from: :origin

  alias Memba.Membership.Events.GroupMembershipEnded
  alias Memba.Membership.Events.GroupMembershipStarted
  alias Memba.Membership.Projections.FirstClassGroupMembership

  project(%GroupMembershipStarted{} = event, fn multi ->
    Ecto.Multi.insert(
      multi,
      :first_class_group_membership,
      %FirstClassGroupMembership{
        group_membership_id: event.group_membership_id,
        club_id: event.club_id,
        group_id: event.group_id,
        club_membership_id: event.club_membership_id,
        person_id: event.person_id,
        active: true
      },
      on_conflict: :nothing,
      conflict_target: :group_membership_id
    )
  end)

  project(%GroupMembershipEnded{} = event, fn multi ->
    Ecto.Multi.insert(
      multi,
      :first_class_group_membership,
      %FirstClassGroupMembership{
        group_membership_id: event.group_membership_id,
        club_id: event.club_id,
        group_id: event.group_id,
        club_membership_id: event.club_membership_id,
        person_id: event.person_id,
        active: false,
        end_idempotency_key: event.idempotency_key,
        end_reason: event.reason
      },
      on_conflict: [
        set: [
          active: false,
          end_idempotency_key: event.idempotency_key,
          end_reason: event.reason
        ]
      ],
      conflict_target: :group_membership_id
    )
  end)

  @impl Commanded.Projections.Ecto
  def after_update(event, metadata, changes) do
    Memba.ReadModelChanges.publish(__MODULE__, event, metadata, changes)
  end
end
