defmodule Mix.Tasks.Memba.SourceBackedAdminInvariant do
  @moduledoc """
  Run the read-only source-backed Admin invariant check.

      mix memba.source_backed_admin_invariant [--phase PHASE]
  """

  use Mix.Task

  alias Memba.Membership.SourceBackedAdminInvariant

  @shortdoc "Run the source-backed Admin invariant check"

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    report =
      args
      |> parse!()
      |> SourceBackedAdminInvariant.check!()

    IO.puts(Jason.encode!(report))
  end

  defp parse!(args) do
    {parsed, rest, invalid} = OptionParser.parse(args, strict: [phase: :string])

    if rest != [] or invalid != [] do
      Mix.raise("invalid options: #{inspect(rest ++ invalid)}")
    end

    []
    |> maybe_put(:phase, parsed[:phase])
  end

  defp maybe_put(opts, _key, nil), do: opts
  defp maybe_put(opts, _key, ""), do: opts
  defp maybe_put(opts, key, value), do: Keyword.put(opts, key, value)
end
