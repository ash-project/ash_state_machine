defmodule AshStateMachine.Charts do
  @moduledoc """
  Returns a mermaid flow chart of a given state machine resource.
  """

  @spec mermaid_state_diagram(Ash.Resource.t()) :: String.t()
  def mermaid_state_diagram(resource) do
    resource
    |> AshStateMachine.Info.state_machine_initial_states!()
    |> Enum.reduce({["stateDiagram-v2"], MapSet.new()}, fn state, {lines, checked} ->
      add_to_chart(resource, state, lines ++ [], checked, :state_diagram)
    end)
    |> elem(0)
    |> Enum.join("\n")
  end

  @spec mermaid_flowchart(Ash.Resource.t()) :: String.t()
  def mermaid_flowchart(resource) do
    resource
    |> AshStateMachine.Info.state_machine_initial_states!()
    |> Enum.reduce({["flowchart TD"], MapSet.new()}, fn state, {lines, checked} ->
      add_to_chart(resource, state, lines ++ [], checked, :flow_chart)
    end)
    |> elem(0)
    |> Enum.join("\n")
  end

  defp add_to_chart(resource, state, lines, checked, type) do
    if state in checked do
      {lines, checked}
    else
      checked = MapSet.put(checked, state)

      state
      |> transitions_from(resource)
      |> Enum.reduce({lines, checked}, fn event, {lines, checked} ->
        Enum.reduce(List.wrap(event.to), {lines, checked}, fn to, {lines, checked} ->
          lines =
            case type do
              :flow_chart ->
                name =
                  case event.action do
                    :* -> ""
                    action -> "|#{action}|"
                  end

                lines ++ ["#{state} --> #{name} #{to}"]

              :state_diagram ->
                name =
                  case event.action do
                    :* -> ""
                    action -> ": #{action}"
                  end

                lines ++ ["#{state} --> #{to}#{name}"]
            end

          add_to_chart(resource, to, lines, checked, type)
        end)
      end)
    end
  end

  defp transitions_from(state, resource) do
    resource
    |> AshStateMachine.Info.state_machine_transitions()
    |> Enum.filter(fn event ->
      state in List.wrap(event.from)
    end)
  end
end
