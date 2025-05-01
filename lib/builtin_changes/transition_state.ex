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
    target = maybe_cast_to_atom(opts[:target])
    all_states = AshStateMachine.Info.state_machine_all_states(changeset.resource)

    if !Ash.Expr.expr?(target) && target not in all_states do
      AshStateMachine.no_such_state(changeset, target)

      {:atomic,
       %{
         attribute =>
           expr(
             error(
               AshStateMachine.Errors.NoMatchingTransition,
               %{
                 old_state: ^old_state,
                 target: ^target,
                 action: ^changeset.action.name
               }
             )
           )
       }}
    else
      states_expr =
        Enum.reduce(transitions, nil, fn transition, expr ->
          state_expr =
            expr(
              ^old_state in ^List.wrap(transition.from) and ^target in ^List.wrap(transition.to)
            )

          if is_nil(expr) do
            state_expr
          else
            expr(^state_expr or ^expr)
          end
        end)

      has_matching_transition =
        {:atomic, [], expr(not (^states_expr)),
         expr(
           error(
             AshStateMachine.Errors.NoMatchingTransition,
             %{
               old_state: ^old_state,
               target: ^target,
               action: ^changeset.action.name
             }
           )
         )}

      {:atomic, %{attribute => opts[:target]},
       [
         has_matching_transition
       ]}
    end
  end

  def maybe_cast_to_atom(target) when is_binary(target) do
    String.to_existing_atom(target)
  rescue
    _ -> target
  end

  def maybe_cast_to_atom(target), do: target
end
