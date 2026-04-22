# SPDX-FileCopyrightText: 2023 ash_state_machine contributors <https://github.com/ash-project/ash_state_machine/graphs/contributors>
#
# SPDX-License-Identifier: MIT

with {:module, _} <- Code.ensure_loaded(Clarity.Content),
     {:module, _} <- Code.ensure_loaded(Clarity.Vertex.Ash.Resource) do
  defmodule AshStateMachine.Clarity.StateMachineDiagram do
    @moduledoc """
    Clarity content provider that renders a Mermaid state diagram for any
    Ash resource that uses `AshStateMachine`.

    This module is only compiled when [`:clarity`](https://hex.pm/packages/clarity)
    is a dependency of the current project. When it is, the module is
    registered as a content provider via the `:clarity_content_providers`
    key in this library's `application/0` environment and is discovered
    automatically by Clarity — no configuration required in the host app.

    The rendered diagram is produced by
    `AshStateMachine.Charts.mermaid_state_diagram/1` — the same function
    backing `mix ash_state_machine.generate_flow_charts` — so the UI is
    always in lock-step with the DSL.
    """

    @behaviour Clarity.Content

    alias Clarity.Vertex.Ash.Resource

    @impl Clarity.Content
    def name, do: "State Machine"

    @impl Clarity.Content
    def description, do: "Mermaid state diagram generated from the AshStateMachine DSL."

    @impl Clarity.Content
    def applies?(%Resource{resource: resource}, _lens),
      do: uses_state_machine?(resource)

    def applies?(_vertex, _lens), do: false

    @impl Clarity.Content
    def render_static(%Resource{resource: resource}, _lens) do
      {:mermaid, fn _props -> AshStateMachine.Charts.mermaid_state_diagram(resource) end}
    end

    defp uses_state_machine?(resource) do
      Code.ensure_loaded?(resource) and AshStateMachine in Spark.extensions(resource)
    rescue
      _ -> false
    end
  end
end
