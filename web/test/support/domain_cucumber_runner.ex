defmodule Memba.DomainCucumberRunner do
  @moduledoc false

  alias Cucumber.Discovery.DiscoveryResult
  alias Cucumber.Runtime

  def selected_scenarios(opts \\ []) do
    discovery = Keyword.get_lazy(opts, :discovery, &discover/0)
    tag_expression = Keyword.get_lazy(opts, :tag_expression, &configured_tag_expression/0)
    excluded_tags = excluded_tags(tag_expression)

    discovery.features
    |> Enum.flat_map(&feature_scenarios/1)
    |> Enum.reject(fn %{feature: feature, scenario: scenario} = selected_scenario ->
      selected_scenario
      |> scenario_tags()
      |> Kernel.++(feature.tags)
      |> Kernel.++(scenario.tags)
      |> excluded?(excluded_tags)
    end)
  end

  def run_scenario(
        %{feature: feature, scenario: scenario} = selected_scenario,
        step_registry,
        context \\ %{}
      ) do
    rule = Map.get(selected_scenario, :rule)

    context =
      Map.merge(context, %{
        feature_file: feature.file,
        feature_tags: feature.tags,
        rule_name: rule && rule.name,
        rule_tags: scenario_tags(selected_scenario),
        scenario_name: scenario.name,
        scenario_tags: scenario.tags,
        scenario_line: (scenario.line || 0) + 1,
        step_history: []
      })

    feature
    |> background_steps()
    |> Kernel.++(background_steps(rule))
    |> Kernel.++(scenario.steps)
    |> Enum.reduce(context, fn step, context ->
      Runtime.execute_step(context, step, step_registry)
    end)
  end

  def discover do
    :global.trans({__MODULE__, :discovery}, fn ->
      cache_key = {__MODULE__, :discovery}

      case :persistent_term.get(cache_key, nil) do
        nil ->
          discovery = discover_without_cucumber_reload_bug()
          :persistent_term.put(cache_key, discovery)
          discovery

        discovery ->
          discovery
      end
    end)
  end

  defp discover_without_cucumber_reload_bug do
    step_modules =
      load_modules(:steps, "test/features/step_definitions/**/*.exs", :__cucumber_steps__)

    hook_modules = load_modules(:support, "test/features/support/**/*.exs", :__cucumber_hooks__)

    %DiscoveryResult{
      features: discover_features(),
      step_modules: step_modules,
      step_registry: build_step_registry(step_modules),
      hook_modules: hook_modules
    }
  end

  defp load_modules(config_key, default_pattern, export) do
    config_key
    |> configured_patterns(default_pattern)
    |> expand_patterns()
    |> Enum.map(&load_module(&1, export))
    |> Enum.filter(& &1)
  end

  defp load_module(path, export) do
    modules =
      case Code.require_file(path) do
        nil -> modules_declared_in(path)
        compiled_modules -> Enum.map(compiled_modules, fn {module, _binary} -> module end)
      end

    Enum.find(modules, fn module -> function_exported?(module, export, 0) end)
  end

  defp modules_declared_in(path) do
    path
    |> File.read!()
    |> then(&Regex.scan(~r/defmodule\s+([A-Za-z0-9_.]+)/, &1))
    |> Enum.map(fn [_match, module_name] -> Module.concat([module_name]) end)
  end

  defp discover_features do
    :features
    |> configured_patterns("test/features/**/*.feature")
    |> expand_patterns()
    |> Enum.map(fn path ->
      path
      |> File.read!()
      |> Gherkin.Parser.parse()
      |> Map.put(:file, path)
    end)
  end

  defp configured_patterns(config_key, default_pattern) do
    config_key
    |> then(&Application.get_env(:cucumber, &1))
    |> case do
      nil -> [default_pattern]
      patterns -> List.wrap(patterns)
    end
  end

  defp expand_patterns(patterns) do
    patterns
    |> Enum.flat_map(&Path.wildcard/1)
    |> Enum.sort()
  end

  defp build_step_registry(step_modules) do
    Enum.reduce(step_modules, %{}, fn module, registry ->
      module.__cucumber_steps__()
      |> Enum.reduce(registry, fn {pattern, metadata}, registry ->
        Map.put(registry, step_pattern_key(pattern), {module, metadata})
      end)
    end)
  end

  defp step_pattern_key({:expression, _pattern_text} = pattern), do: pattern
  defp step_pattern_key({:regex, _regex} = pattern), do: pattern

  defp step_pattern_key(%Regex{} = pattern),
    do: {:regex, {Regex.source(pattern), Regex.opts(pattern)}}

  defp step_pattern_key(pattern) when is_binary(pattern), do: {:expression, pattern}

  defp configured_tag_expression do
    Application.fetch_env!(:cucumber, :tags)
  end

  defp excluded_tags(tag_expression) do
    ~r/not\s+@?([A-Za-z0-9_-]+)/
    |> Regex.scan(tag_expression)
    |> Enum.map(fn [_match, tag] -> tag end)
  end

  defp excluded?(scenario_tags, excluded_tags) do
    normalized_tags = Enum.map(scenario_tags, &String.trim_leading(&1, "@"))
    Enum.any?(excluded_tags, &(&1 in normalized_tags))
  end

  defp feature_scenarios(feature) do
    top_level_scenarios =
      Enum.map(feature.scenarios, fn scenario -> %{feature: feature, scenario: scenario} end)

    rule_scenarios =
      feature
      |> Map.get(:rules, [])
      |> Enum.flat_map(fn rule ->
        Enum.map(rule.scenarios, fn scenario ->
          %{feature: feature, rule: rule, scenario: scenario}
        end)
      end)

    top_level_scenarios ++ rule_scenarios
  end

  defp scenario_tags(%{rule: rule}), do: Map.get(rule, :tags, [])
  defp scenario_tags(_selected_scenario), do: []

  defp background_steps(nil), do: []
  defp background_steps(%{background: nil}), do: []
  defp background_steps(%{background: background}), do: background.steps
end
