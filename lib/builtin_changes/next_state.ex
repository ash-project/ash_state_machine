# SPDX-FileCopyrightText: 2023 ash_state_machine contributors <https://github.com/ash-project/ash_state_machine/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshStateMachine.BuiltinChanges.NextState do
  @moduledoc false
  use Ash.Resource.Change

  def change(changeset, opts, _) do
    if opts[:recheck?] do
      AshStateMachine.transition_and_recheck(changeset, &next_state/1)
    else
      next_state(changeset)
    end
  end

  defp next_state(changeset) do
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
