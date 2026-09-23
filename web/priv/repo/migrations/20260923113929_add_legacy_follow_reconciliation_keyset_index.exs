defmodule Memba.Repo.Migrations.AddLegacyFollowReconciliationKeysetIndex do
  use Ecto.Migration

  def change do
    create index(:messaging_conversation_follows, [:member_id, :conversation_id],
             where: "following = TRUE",
             name: :messaging_conversation_follows_reconciliation_keyset_index
           )
  end
end
