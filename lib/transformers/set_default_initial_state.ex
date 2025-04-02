defmodule AshStateMachine.Transformers.SetDefaultInitialState do
  # If there is only one value in inital_states we can set it
  # as the default
  @moduledoc false
  use Spark.Dsl.Transformer

  alias Spark.Dsl.Transformer

  def transform(dsl_state) do
    case AshStateMachine.Info.state_machine_default_initial_state(dsl_state) do
      {:ok, _state} ->
        {:ok, dsl_state}

      _ ->
        case AshStateMachine.Info.state_machine_initial_states(dsl_state) do
          {:ok, [default_state]} ->
            dsl_state =
              dsl_state
              |> Transformer.set_option([:state_machine], :default_initial_state, default_state)

            {:ok, dsl_state}

          _ ->
            {:ok, dsl_state}
        end
    end
  end
end
