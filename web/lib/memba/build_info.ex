defmodule Memba.BuildInfo do
  @moduledoc """
  Build metadata surfaced in the application UI.
  """

  @repository_url "https://github.com/mattwynne/memba"
  @git_sha_env "MEMBA_GIT_SHA"

  @type footer_commit :: %{sha: String.t(), short_sha: String.t(), url: String.t()}

  @spec footer_commit :: footer_commit() | nil
  def footer_commit do
    if Application.get_env(:memba, :show_git_commit_in_footer, false) do
      case git_sha() do
        {:ok, sha} ->
          %{sha: sha, short_sha: String.slice(sha, 0, 7), url: "#{@repository_url}/commit/#{sha}"}

        :error ->
          nil
      end
    end
  end

  @spec git_sha :: {:ok, String.t()} | :error
  def git_sha do
    [git_sha_file_contents(), System.get_env(@git_sha_env), git_sha_from_git()]
    |> Enum.find_value(&normalize_git_sha/1)
    |> case do
      nil -> :error
      sha -> {:ok, sha}
    end
  end

  defp git_sha_from_git do
    if Application.get_env(:memba, :read_git_commit_from_git, false) do
      case System.cmd("git", ["rev-parse", "HEAD"], stderr_to_stdout: true) do
        {sha, 0} -> sha
        {_output, _status} -> nil
      end
    end
  rescue
    ErlangError -> nil
  end

  defp git_sha_file_contents do
    :memba
    |> Application.app_dir("priv/git_sha")
    |> File.read()
    |> case do
      {:ok, contents} -> contents
      {:error, _reason} -> nil
    end
  end

  defp normalize_git_sha(value) when is_binary(value) do
    value = String.trim(value)

    if Regex.match?(~r/\A[0-9a-f]{40}\z/i, value) do
      String.downcase(value)
    end
  end

  defp normalize_git_sha(_value), do: nil
end
