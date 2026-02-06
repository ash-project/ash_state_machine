# SPDX-FileCopyrightText: 2023 ash_state_machine contributors <https://github.com/ash-project/ash_state_machine/graphs/contributors>
#
# SPDX-License-Identifier: MIT

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
