defmodule AshStateMachine.Info do
  use Spark.InfoGenerator, extension: AshStateMachine, sections: [:state_machine]

  @spec state_machine_transitions(Ash.Resource.record() | map(), name :: atom) ::
          list(AshStateMachine.Transition.t())
  def state_machine_transitions(resource_or_dsl, name) do
    resource_or_dsl
    |> state_machine_transitions()
    |> Enum.filter(&(&1.action == :* || &1.action == name))
  end

  @spec state_machine_all_states(Ash.Resource.record() | map()) :: list(atom)
  def state_machine_all_states(resource_or_dsl) do
    Spark.Dsl.Extension.get_persisted(resource_or_dsl, :all_state_machine_states, [])
  end
end
