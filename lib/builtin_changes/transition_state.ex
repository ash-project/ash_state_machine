defmodule AshStateMachine.BuiltinChanges.TransitionState do
  @moduledoc false
  use Ash.Resource.Change

  def change(changeset, opts, _) do
    AshStateMachine.transition_state(changeset, opts[:target])
  end

  def atomic(changeset, opts, _) do
    transitions =
      AshStateMachine.Info.state_machine_transitions(changeset.resource, changeset.action.name)

    attribute = AshStateMachine.Info.state_machine_state_attribute!(changeset.resource)
    old_state = expr(^ref(attribute))
    target = opts[:target]
    all_states = AshStateMachine.Info.state_machine_all_states(changeset.resource)

    if !Ash.Expr.expr?(target) && target not in all_states do
      {:atomic, AshStateMachine.no_such_state(changeset, target), %{}}
    else
      states_expr =
        Enum.reduce(transitions, nil, fn transition, expr ->
          state_expr =
            expr(
              ^old_state in ^List.wrap(transition.from) and ^target in ^List.wrap(transition.to)
            )

          expr(^state_expr or ^expr)
        end)

      new_state_value =
        expr(
          cond do
            ^target not in ^all_states ->
              error(
                AshStateMachine.Errors.NoMatchingTransition,
                %{old_state: ^old_state, target: ^target, action: ^changeset.action.name}
              )

            ^states_expr ->
              ^opts[:target]

            true ->
              error(
                AshStateMachine.Errors.NoMatchingTransition,
                %{
                  old_state: ^old_state,
                  target: ^target,
                  action: ^changeset.action.name
                }
              )
          end
        )

      {:atomic, %{attribute => new_state_value}}
    end
  end
end
