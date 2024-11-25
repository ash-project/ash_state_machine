defmodule AshStateMachine.Verifiers.VerifyTransitionActions do
  # Verifies that each transition corresponds to an update action
  @moduledoc false
  use Spark.Dsl.Verifier

  def verify(dsl_state) do
    dsl_state
    |> AshStateMachine.Info.state_machine_transitions()
    |> Enum.reject(fn transition ->
      transition.action == :*
    end)
    |> Enum.each(fn transition ->
      action = Ash.Resource.Info.action(dsl_state, transition.action)

      case validate(action) do
        :ok ->
          :ok

        {:error, err} ->
          raise Spark.Error.DslError,
            module: Spark.Dsl.Verifier.get_persisted(dsl_state, :module),
            path: [:state_machine, :transitions, :transition, transition.action],
            message: """
            #{error_message(err, transition.action)}
            """
      end
    end)

    :ok
  end

  defp validate(action) do
    case action do
      %{type: :update} -> :ok
      %{type: :create, upsert?: true} -> :ok
      %{type: :create, upsert?: false} -> {:error, :create_must_upsert}
      nil -> {:error, :no_such_action}
      _ -> {:error, :no_such_action}
    end
  end

  defp error_message(err, action) do
    case err do
      :no_such_action ->
        "Transition configured with action `:#{action}` but no such create or update action is defined. Actions must be of type update or create with `upsert?: true`"

      :create_must_upsert ->
        "Transition configured with non-upsert create action `:#{action}`. Create actions must be configured with `upsert? true` to allow state transitions."
    end
  end
end
