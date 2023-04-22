defmodule AshStateMachine.Verifiers.VerifyTransitionActions do
  use Spark.Dsl.Verifier

  def verify(dsl_state) do
    dsl_state
    |> AshStateMachine.Info.state_machine_transitions()
    |> Enum.reject(fn transition ->
      transition.action == :*
    end)
    |> Enum.each(fn transition ->
      action = Ash.Resource.Info.action(dsl_state, transition.action)

      unless action && action.type == :update do
        raise Spark.Error.DslError,
          module: Spark.Dsl.Verifier.get_persisted(dsl_state, :module),
          path: [:state_machine, :transitions, :transition, transition.action],
          message: """
          Transition configured with action `:#{transition.action}` but no such update action is defined.
          """
      end
    end)

    :ok
  end
end
