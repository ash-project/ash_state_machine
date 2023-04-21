defmodule AshFsm.Verifiers.VerifyEventActions do
  use Spark.Dsl.Verifier

  def verify(dsl_state) do
    dsl_state
    |> AshFsm.Info.fsm_events()
    |> Enum.each(fn event ->
      action = Ash.Resource.Info.action(dsl_state, event.action)

      unless action && action.type == :update do
        raise Spark.Error.DslError,
          module: Spark.Dsl.Verifier.get_persisted(dsl_state, :module),
          path: [:fsm, :events, :event, event.action],
          message: """
          Event configured with action `:#{event.action}` but no such update action is defined.
          """
      end
    end)

    :ok
  end
end
