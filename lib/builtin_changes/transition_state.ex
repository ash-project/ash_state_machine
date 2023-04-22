defmodule AshStateMachine.BuiltinChanges.TransitionState do
  use Ash.Resource.Change

  def change(changeset, opts, _) do
    AshStateMachine.transition_state(changeset, opts[:target])
  end
end
