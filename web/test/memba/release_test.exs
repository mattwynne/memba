defmodule Memba.ReleaseTest do
  use Memba.DataCase, async: false

  alias Memba.Release
  alias Memba.Repo

  test "release schema verification passes when migrated tables match application schemas" do
    assert :ok = Release.verify_repo_schema!(Repo)
  end

  test "release schema verification fails when a recorded migration left the old auth table behind" do
    Repo.query!("ALTER TABLE auth_sign_in_tokens RENAME TO auth_magic_tokens", [])

    assert_raise RuntimeError, ~r/Database schema drift detected after migrations/, fn ->
      Release.verify_repo_schema!(Repo)
    end
  after
    Repo.query!("ALTER TABLE IF EXISTS auth_magic_tokens RENAME TO auth_sign_in_tokens", [])
  end
end
