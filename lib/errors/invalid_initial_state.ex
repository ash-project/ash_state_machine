defmodule AshStateMachine.Errors.InvalidInitialState do
  @moduledoc "Used when an initial state is set that is not a valid initial state"
  use Ash.Error.Exception

  def_ash_error([:action, :target], class: :invalid)

  defimpl Ash.ErrorKind do
    def id(_), do: Ash.UUID.generate()

    def code(_), do: "invalid_initial_state"

    def message(error) do
      """
      Attempted to set initial state to `:#{error.target}` in action `:#{error.action}`, but it is not a valid initial state.
      """
    end
  end
end
