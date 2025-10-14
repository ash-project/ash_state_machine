# SPDX-FileCopyrightText: 2023 ash_state_machine contributors <https://github.com/ash-project/ash_state_machine/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshStateMachine.BuiltinChanges.NextState do
  @moduledoc false
  use Ash.Resource.Change

  def change(changeset, _opts, _) do
    changeset.data
    |> AshStateMachine.possible_next_states(changeset.action.name)
    |> case do
      [to] ->
        AshStateMachine.transition_state(changeset, to)

      [] ->
        Ash.Changeset.add_error(changeset, "Cannot determine next state: no next state available")

      _ ->
        Ash.Changeset.add_error(
          changeset,
          "Cannot determine next state: multiple next states available"
        )
    end
  end
end
