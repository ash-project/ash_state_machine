# SPDX-FileCopyrightText: 2023 ash_state_machine contributors <https://github.com/ash-project/ash_state_machine/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshStateMachine.BuiltinChanges do
  @moduledoc """
  Changes for working with AshStateMachine resources.
  """

  @doc """
  Changes the state to the target state, validating the transition

  In non-atomic actions, the transition is checked against the record the action was called
  with, which may be out of date. See [Transitions and stale records](getting-started-with-ash-state-machine.md#transitions-and-stale-records)
  for ways to check it against the stored record instead.

  ## Options

  * `:recheck?` - Check the transition again in a `before_action` hook if the record's state
    has changed by then, for example because `get_and_lock_for_update()` read it again.
    Declare the lock before this change. Defaults to `false`.
  """
  def transition_state(target, opts \\ []) do
    {AshStateMachine.BuiltinChanges.TransitionState,
     opts |> Keyword.validate!(recheck?: false) |> Keyword.put(:target, target)}
  end

  @doc """
  Try and transition to the next state. Must be only one possible next state.

  ## Options

  * `:recheck?` - Pick the next state again in a `before_action` hook if the record's state
    has changed by then, for example because `get_and_lock_for_update()` read it again.
    Declare the lock before this change. Defaults to `false`.
  """
  def next_state(opts \\ []) do
    {AshStateMachine.BuiltinChanges.NextState, Keyword.validate!(opts, recheck?: false)}
  end
end
