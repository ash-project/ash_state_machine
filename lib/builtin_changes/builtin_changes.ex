# SPDX-FileCopyrightText: 2023 ash_state_machine contributors <https://github.com/ash-project/ash_state_machine/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshStateMachine.BuiltinChanges do
  @moduledoc """
  Changes for working with AshStateMachine resources.
  """

  @doc """
  Changes the state to the target state, validating the transition

  In non-atomic update actions, the transition is checked again in a `before_action` hook.
  Declare `get_and_lock_for_update()` before this change to check the transition against
  the locked record rather than the one the action was called with.
  """
  def transition_state(target) do
    {AshStateMachine.BuiltinChanges.TransitionState, target: target}
  end

  @doc """
  Try and transition to the next state. Must be only one possible next state.

  The next state is picked again in a `before_action` hook. Declare
  `get_and_lock_for_update()` before this change to pick it from the locked record.
  """
  def next_state, do: AshStateMachine.BuiltinChanges.NextState
end
