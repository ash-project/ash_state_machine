defmodule AshFsm.BuiltinChanges do
  @moduledoc """
  Changes for working with AshFsm resources.
  """

  @doc """
  Changes the state to the target state, validating the transition
  """
  def transition_state(target) do
    {AshFsm.BuiltinChanges.TransitionState, target: target}
  end
end
