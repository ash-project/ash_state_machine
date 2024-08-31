defmodule AshStateMachine.Checks.ValidNextState do
  @moduledoc """
  A policy for pre_flight checking if a state transition is allowed.
  """
  use Ash.Policy.FilterCheck

  def describe(_) do
    "allowed to make state transition"
  end

  def filter(
        _actor,
        %{changeset: %Ash.Changeset{action_type: :create} = changeset} = _context,
        _options
      ) do
    attribute = AshStateMachine.Info.state_machine_state_attribute!(changeset.resource)

    if changeset.context[:private][:pre_flight_authorization?] do
      new_state =
        Ash.Changeset.get_attribute(changeset, attribute) ||
          AshStateMachine.Info.state_machine_default_initial_state!(changeset.resource)

      new_state in AshStateMachine.Info.state_machine_initial_states!(changeset.resource)
    else
      true
    end
  end

  def filter(
        _actor,
        %{changeset: %Ash.Changeset{action_type: :update} = changeset} = _context,
        _options
      ) do
    attribute = AshStateMachine.Info.state_machine_state_attribute!(changeset.resource)

    if changeset.context[:private][:pre_flight_authorization?] &&
         (Ash.Changeset.changing_attribute?(changeset, attribute) ||
            get_in(changeset.context, [:state_machine, :attempted_change])) do
      transitions =
        AshStateMachine.Info.state_machine_transitions(changeset.resource, changeset.action.name)

      old_state = expr(^ref(attribute))
      target = Ash.Changeset.get_attribute(changeset, attribute)
      all_states = AshStateMachine.Info.state_machine_all_states(changeset.resource)

      if not is_nil(target) && !Ash.Expr.expr?(target) && target not in all_states do
        false
      else
        states_expr =
          Enum.reduce(transitions, nil, fn transition, expr ->
            state_expr =
              expr(
                ^old_state in ^List.wrap(transition.from) and ^target in ^List.wrap(transition.to)
              )

            expr(^state_expr or ^expr)
          end)

        expr(is_nil(^target) || (^target in ^all_states and ^states_expr))
      end
    else
      # state transitions are checked in validations when using `transition_state`
      true
    end
  end
end
