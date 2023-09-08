defmodule AshStateMachine.BuiltinChanges.NextState do
  @moduledoc """
  Given the action and the current state, attempt to find the next state to
  transition into.
  """
  use Ash.Resource.Change

  def change(changeset, _opts, _) do
    attribute = AshStateMachine.Info.state_machine_state_attribute!(changeset.resource)

    current_state = Map.get(changeset.data, attribute)

    changeset.resource
    |> AshStateMachine.Info.state_machine_transitions(changeset.action.name)
    |> Enum.filter(fn
      %{from: from} when is_list(from) -> current_state in from
      %{from: from} -> current_state == from
    end)
    |> Enum.flat_map(fn
      %{to: to} when is_list(to) -> to
      %{to: to} -> [to]
    end)
    |> Enum.uniq()
    |> Enum.reject(&(&1 == :*))
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
