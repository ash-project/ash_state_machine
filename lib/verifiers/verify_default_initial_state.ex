defmodule AshStateMachine.Verifiers.VerifyDefaultInitialState do
  # Verifies the default initial state is in the list of initial states.
  @moduledoc false
  use Spark.Dsl.Verifier

  def verify(dsl_state) do
    module = Spark.Dsl.Verifier.get_persisted(dsl_state, :module)

    attribute =
      Ash.Resource.Info.attribute(
        dsl_state,
        AshStateMachine.Info.state_machine_state_attribute!(dsl_state)
      )

    case AshStateMachine.Info.state_machine_default_initial_state(dsl_state) do
      {:ok, initial} when not is_nil(initial) ->
        initial_states = AshStateMachine.Info.state_machine_initial_states!(dsl_state)

        unless initial in initial_states do
          raise Spark.Error.DslError,
            module: module,
            path: [:attributes, attribute.name],
            message: """
            Expected `#{inspect(initial)}` to be in the list of `initial_states`, got: #{inspect(initial_states)}
            """
        end

        :ok

      _ ->
        :ok
    end
  end
end
