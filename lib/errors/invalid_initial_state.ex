defmodule AshStateMachine.Errors.InvalidInitialState do
  @moduledoc "Used when an initial state is set that is not a valid initial state"
  use Ash.Error.Exception

  use Splode.Error,
    fields: [:action, :target],
    class: :invalid

  def message(error) do
    """
    Attempted to set initial state to `:#{error.target}` in action `:#{error.action}`, but it is not a valid initial state.
    """
  end
end
