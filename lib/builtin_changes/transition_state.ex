defmodule AshStateMachine.BuiltinChanges.TransitionState do
  @moduledoc """
  Transitions the state to a new state, validating the transition.
  """
  use Ash.Resource.Change

  def change(changeset, opts, _) do
    AshStateMachine.transition_state(changeset, opts[:target])
  end
end
