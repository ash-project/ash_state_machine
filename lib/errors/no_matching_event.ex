defmodule AshStateMachine.Errors.NoMatchingTransition do
  @moduledoc "Used when a state change occurs in an action with no matching transition"
  use Splode.Error,
    fields: [:action, :target, :old_state],
    class: :invalid

  def message(error) do
    """
    Attempted to change state from #{error.old_state} to #{error.target} in action #{error.action}, but no matching transition was configured.
    """
  end
end
