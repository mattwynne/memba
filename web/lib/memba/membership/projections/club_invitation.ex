defmodule Memba.Membership.Projections.ClubInvitation do
  @moduledoc """
  Read model projection for a club member invitation.
  """

  use Ecto.Schema

  @primary_key {:invitation_id, :string, autogenerate: false}
  schema "membership_club_invitations" do
    field :club_id, :string
    field :email, :string
    field :normalized_email, :string
    field :token_hash, :string
    field :status, :string
    field :accepted_person_id, :string
    field :accepted_membership_id, :string
    field :resend_count, :integer

    timestamps(type: :utc_datetime_usec)
  end
end
