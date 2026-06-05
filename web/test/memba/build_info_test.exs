defmodule Memba.BuildInfoTest do
  use ExUnit.Case, async: false

  alias Memba.BuildInfo

  @sha "0123456789abcdef0123456789abcdef01234567"

  setup do
    original_env = System.get_env("MEMBA_GIT_SHA")
    original_footer_config = Application.get_env(:memba, :show_git_commit_in_footer)

    System.delete_env("MEMBA_GIT_SHA")

    on_exit(fn ->
      restore_system_env("MEMBA_GIT_SHA", original_env)
      Application.put_env(:memba, :show_git_commit_in_footer, original_footer_config)
    end)
  end

  test "git_sha reads and normalizes the MEMBA_GIT_SHA environment variable" do
    System.put_env("MEMBA_GIT_SHA", String.upcase(@sha))

    assert BuildInfo.git_sha() == {:ok, @sha}
  end

  test "git_sha rejects missing or invalid values" do
    System.put_env("MEMBA_GIT_SHA", "not-a-sha")

    assert BuildInfo.git_sha() == :error
  end

  test "footer_commit is hidden unless enabled in application config" do
    System.put_env("MEMBA_GIT_SHA", @sha)
    Application.put_env(:memba, :show_git_commit_in_footer, false)

    assert BuildInfo.footer_commit() == nil
  end

  test "footer_commit includes a short SHA and GitHub commit URL when enabled" do
    System.put_env("MEMBA_GIT_SHA", @sha)
    Application.put_env(:memba, :show_git_commit_in_footer, true)

    assert BuildInfo.footer_commit() == %{
             sha: @sha,
             short_sha: "0123456",
             url: "https://github.com/mattwynne/memba/commit/#{@sha}"
           }
  end

  defp restore_system_env(key, nil), do: System.delete_env(key)
  defp restore_system_env(key, value), do: System.put_env(key, value)
end
