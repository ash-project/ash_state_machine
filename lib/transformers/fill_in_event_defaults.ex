defmodule AshStateMachine.Transformers.FillInTransitionDefaults do
  use Spark.Dsl.Transformer
  alias Spark.Dsl.Transformer
  @moduledoc false

  def transform(dsl_state) do
    initial_states =
      case AshStateMachine.Info.state_machine_initial_states(dsl_state) do
        {:ok, value} -> List.wrap(value)
        _ -> []
      end

    initial_states =
      case initial_states do
        [] ->
          case AshStateMachine.Info.state_machine_default_initial_state(dsl_state) do
            {:ok, value} when not is_nil(value) ->
              [value]

            _ ->
              initial_states
          end

        _ ->
          initial_states
      end

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
      case AshStateMachine.Info.state_machine_initial_states(dsl_state) do
        {:ok, value} when not is_nil(value) and value != [] ->
          dsl_state

        _ ->
          Transformer.set_option(dsl_state, [:state_machine], :initial_states, all_states)
      end

    {:ok, Transformer.persist(dsl_state, :all_state_machine_states, all_states)}
  end
end
