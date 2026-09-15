defmodule MembaWeb.MembershipCommandBoundaryTest do
  use ExUnit.Case, async: true

  require Mix.Compilers.Elixir, as: ElixirCompiler

  @internal_membership_namespace ["Memba", "Membership", "Commands"]

  test "web delivery does not bypass the public Membership command boundary" do
    manifest = Path.join(Mix.Project.manifest_path(), "compile.elixir")
    {_modules, sources} = ElixirCompiler.read_manifest(manifest)

    assert Enum.any?(sources, fn {source_path, _source} -> source_path == "lib/memba_web.ex" end),
           "expected the compiler manifest to include lib/memba_web.ex"

    violations =
      for {source_path, source} <- sources,
          web_delivery_source?(source_path),
          dependency <- source_dependencies(source),
          internal_membership_command?(dependency),
          do: {source_path, dependency}

    assert violations == [],
           """
           web delivery must use the public Memba.Membership API, not internal commands:
           #{format_violations(violations)}
           """
  end

  defp web_delivery_source?("lib/memba_web.ex"), do: true
  defp web_delivery_source?(path), do: String.starts_with?(path, "lib/memba_web/")

  defp source_dependencies(source) do
    ElixirCompiler.source(source, :compile_references) ++
      ElixirCompiler.source(source, :export_references) ++
      ElixirCompiler.source(source, :runtime_references)
  end

  defp internal_membership_command?(module) when is_atom(module) do
    module_name = Atom.to_string(module)

    String.starts_with?(module_name, "Elixir.") and
      List.starts_with?(Module.split(module), @internal_membership_namespace)
  end

  defp format_violations(violations) do
    Enum.map_join(violations, "\n", fn {source_path, dependency} ->
      "  * #{source_path} references #{inspect(dependency)}"
    end)
  end
end
