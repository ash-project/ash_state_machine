defmodule Mix.Tasks.AshStateMachine.GenerateFlowCharts do
  @moduledoc """
  Generates a Mermaid Flow Chart for each `Ash.Resource` with the `AshStateMachine`
  extension alongside the resource.

  ## Prerequisites

  This mix task requires the Mermaid CLI to be installed on your system.

  See https://github.com/mermaid-js/mermaid-cli

  ## Command line options

    * `--type` - generates a given type. Valid values are `"state_diagram"` and `"flow_chart"`. Defaults to `"state_diagram"`.
    * `--only` - only generates the given Flow file
    * `--format` - Can be set to one of either:
      * `plain` - Prints just the mermaid output as text. This is the default.
      * `md` - Prints the mermaid diagram in a markdown code block.
      * `svg` - Generates an SVG
      * `pdf` - Generates a PDF
      * `png` - Generates a PNG

  """
  use Mix.Task

  @recursive true

  @shortdoc "Generates Mermaid Flow Charts for each resource using `AshStateMachine`"
  def run(argv) do
    Mix.Task.run("compile")

    {opts, _} =
      OptionParser.parse!(argv,
        strict: [only: :keep, format: :string, type: :string],
        aliases: [o: :only, f: :format, t: :type]
      )

    only =
      if opts[:only] && opts[:only] != [] do
        Enum.map(List.wrap(opts[:only]), &Path.expand/1)
      end

    format = Keyword.get(opts, :format, "plain")

    state_machines()
    |> Task.async_stream(
      fn state_machine ->
        source = state_machine.module_info(:compile)[:source]

        if is_nil(only) || Path.expand(source) in only do
          diagram =
            case opts[:type] || "state_diagram" do
              "state_diagram" ->
                AshStateMachine.Charts.mermaid_state_diagram(state_machine)

              "flow_chart" ->
                AshStateMachine.Charts.mermaid_flowchart(state_machine)
            end

          Mix.Mermaid.generate_diagram(
            source,
            "mermaid-flowchart",
            format,
            diagram,
            "Generated Mermaid flowchart for #{inspect(state_machine)}"
          )
        end
      end,
      timeout: :infinity
    )
    |> Stream.run()
  end

  defp modules do
    Mix.Project.config()[:app]
    |> :application.get_key(:modules)
    |> case do
      {:ok, mods} when is_list(mods) ->
        mods

      _ ->
        []
    end
  end

  defp state_machine?(module) do
    Spark.Dsl.is?(module, Ash.Resource) and AshStateMachine in Spark.extensions(module)
  end

  defp state_machines do
    for module <- modules(),
        {:module, module} = Code.ensure_compiled(module),
        state_machine?(module) do
      module
    end
  end
end
