defmodule AshStateMachine.Transformers.FillInTransitionDefaults do
  use Spark.Dsl.Transformer
  alias Spark.Dsl.Transformer
  @moduledoc false

  def transform(dsl_state) do
    initial_states = AshStateMachine.Info.state_machine_initial_states!(dsl_state)

    transitions =
      dsl_state
      |> AshStateMachine.Info.state_machine_transitions()

    all_states =
      transitions
      |> Enum.flat_map(fn transition ->
        List.wrap(transition.from) ++ List.wrap(transition.to)
      end)
      |> Enum.concat(List.wrap(initial_states))
      |> Enum.uniq()

    dsl_state =
      Transformer.set_option(
        dsl_state,
        [:state_machine],
        :initial_states,
        List.wrap(initial_states)
      )

    {:ok, Transformer.persist(dsl_state, :all_state_machine_states, all_states)}
  end
end
