defmodule Memba.Repo.Migrations.CreatePersonConversationSubscriptionsProjection do
  use Ecto.Migration

  def change do
    create table(:messaging_person_conversation_subscriptions, primary_key: false) do
      add :subscription_id, :text, primary_key: true
      add :person_id, :text, null: false
      add :conversation_id, :text, null: false
      add :effective, :boolean, null: false, default: false
      add :last_intent_id, :text
      add :last_unfollow_id, :text
      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:messaging_person_conversation_subscriptions, [
             :person_id,
             :conversation_id
           ])

    create index(:messaging_person_conversation_subscriptions, [:person_id], where: "effective")

    create table(:messaging_conversation_subscription_authorizations, primary_key: false) do
      add :authorization_id, :text, primary_key: true
      add :person_id, :text, null: false
      add :conversation_id, :text, null: false

      add :subscription_id,
          references(:messaging_person_conversation_subscriptions,
            column: :subscription_id,
            type: :text,
            on_delete: :delete_all
          ),
          null: false

      add :subscription_intent_id, :text, null: false
      add :authority_decision_id, :text, null: false
      add :club_membership_id, :text, null: false
      add :group_membership_id, :text, null: false
      add :effective, :boolean, null: false, default: true
      add :revocation_id, :text
      add :unfollow_id, :text
      add :revocation_reason, :text
      timestamps(type: :utc_datetime_usec)
    end

    create index(:messaging_conversation_subscription_authorizations, [:subscription_id],
             where: "effective"
           )

    create index(
             :messaging_conversation_subscription_authorizations,
             [:person_id, :group_membership_id],
             where: "effective"
           )

    create constraint(
             :messaging_conversation_subscription_authorizations,
             :messaging_subscription_authorization_revocation_check,
             check:
               "(effective AND revocation_reason IS NULL) OR (NOT effective AND revocation_reason IS NOT NULL)"
           )

    create table(:messaging_group_membership_subscription_revocation_receipts, primary_key: false) do
      add :revocation_id, :text, primary_key: true
      add :person_id, :text, null: false
      add :group_membership_id, :text, null: false
      add :completed, :boolean, null: false, default: false
      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:messaging_group_membership_subscription_revocation_receipts, [
             :person_id,
             :group_membership_id
           ])
  end
end
