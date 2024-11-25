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
      all_states = dsl_state |> AshStateMachine.Info.state_machine_all_states()

      case validate(action, transition, all_states) do
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

  defp validate(nil, _, _), do: {:error, :no_such_action}
  defp validate(%{type: :update}, _, _), do: :ok
  defp validate(%{type: :create, upsert?: false}, _, _), do: {:error, :create_must_upsert}

  defp validate(%{type: :create}, %{from: from}, all_states) do
    case Enum.sort(from) == Enum.sort(all_states) do
      true -> :ok
      false -> {:error, :create_must_allow_from_all}
    end
  end

  defp validate(_, _, _), do: {:error, :no_such_action}

  defp error_message(err, action) do
    case err do
      :no_such_action ->
        "Transition configured with action `:#{action}` but no such create or update action is defined. Actions must be of type update or create with `upsert?: true`"

      :create_must_upsert ->
        "Transition configured with non-upsert create action `:#{action}`. Create actions must be configured with `upsert? true` to allow state transitions."

      :create_must_allow_from_all ->
        "Transition configured with create action `:#{action}` must allow transitions from all states."
    end
  end
end
