defmodule AshStateMachine.Errors.NoMatchingTransition do
  @moduledoc "Used when a state change occurs in an action with no matching transition"
  use Splode.Error,
    fields: [:action, :target, :old_state],
    class: :invalid

  def message(error) do
    cond do
      error.old_state && error.target ->
        """
        Attempted to change state from #{error.old_state} to #{error.target} in action #{error.action}, but no matching transition was configured.
        """

      error.old_state ->
        """
        Attempted to change state from #{error.old_state} in action #{error.action}, but no matching transition was configured.
        """

      true ->
        """
        Attempted to change state to #{inspect(error.target)} in action #{error.action}, but no matching transition was configured.
        """
    end
  end
end
