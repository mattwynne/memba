defmodule Mix.Tasks.Memba.AdminHistory do
  @moduledoc """
  Plan or apply the legacy Admin history reconciliation.

      mix memba.admin_history --dry-run
      mix memba.admin_history --apply --club-id clb_... --operation-id INC-... \
        --approval-reference APPROVAL-... \
        --acknowledgement YES_APPEND_MISSING_ADMIN_FACTS
  """

  use Mix.Task

  alias Memba.Membership.AdminHistoryReconciliation

  @shortdoc "Plan or apply legacy Admin history reconciliation"

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    opts = parse!(args)

    case AdminHistoryReconciliation.run(opts) do
      {:ok, report} ->
        IO.puts(Jason.encode!(report))

      {:error, reason} ->
        encoded = Jason.encode!(%{error: reason})
        IO.puts(encoded)
        Mix.raise(encoded)
    end
  end

  defp parse!(args) do
    {parsed, rest, invalid} =
      OptionParser.parse(args,
        strict: [
          dry_run: :boolean,
          apply: :boolean,
          club_id: :keep,
          operation_id: :string,
          approval_reference: :string,
          acknowledgement: :string
        ]
      )

    if rest != [] or invalid != [] do
      Mix.raise("invalid options: #{inspect(rest ++ invalid)}")
    end

    mode = mode!(parsed)

    [mode: mode]
    |> maybe_put(:club_ids, Keyword.get_values(parsed, :club_id))
    |> maybe_put(:operation_id, parsed[:operation_id])
    |> maybe_put(:approval_reference, parsed[:approval_reference])
    |> maybe_put(:acknowledgement, parsed[:acknowledgement])
  end

  defp mode!(parsed) do
    case {Keyword.get(parsed, :dry_run, false), Keyword.get(parsed, :apply, false)} do
      {true, true} -> Mix.raise("choose either --dry-run or --apply, not both")
      {_dry_run, true} -> :apply
      _other -> :dry_run
    end
  end

  defp maybe_put(opts, _key, nil), do: opts
  defp maybe_put(opts, :club_ids, []), do: opts
  defp maybe_put(opts, key, value), do: Keyword.put(opts, key, value)
end
