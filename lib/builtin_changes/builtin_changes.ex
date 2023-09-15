defmodule AshStateMachine.BuiltinChanges do
  @moduledoc """
  Changes for working with AshStateMachine resources.
  """

  @doc """
  Changes the state to the target state, validating the transition
  """
  def transition_state(target) do
    {AshStateMachine.BuiltinChanges.TransitionState, target: target}
  end

  @doc """
  Try and transition to the next state. Must be only one possible next state.
  """
  def next_state, do: AshStateMachine.BuiltinChanges.NextState
end
