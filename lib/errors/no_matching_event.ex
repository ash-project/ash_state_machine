defmodule AshFsm.Errors.NoMatchingEvent do
  @moduledoc "Used when a state change occurs in an action with no matching event"
  use Ash.Error.Exception

  def_ash_error([:action, :target, :old_state], class: :invalid)

  defimpl Ash.ErrorKind do
    def id(_), do: Ash.UUID.generate()

    def code(_), do: "no_matching_event"

    def message(error) do
      """
      Attempted to change state from #{error.old_state} to #{error.target} in action #{error.action}, but no matching event was configured.
      """
    end
  end
end
