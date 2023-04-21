defmodule AshFsm.BuiltinChanges.TransitionState do
  use Ash.Resource.Change

  def change(changeset, opts, _) do
    AshFsm.transition_state(changeset, opts[:target])
  end
end
