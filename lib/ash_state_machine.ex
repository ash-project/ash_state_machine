defmodule AshStateMachine do
  defmodule Transition do
    @moduledoc """
    The configuration for an transition.
    """
    @type t :: %__MODULE__{
            action: atom,
            from: [atom],
            to: [atom],
            __identifier__: any
          }

    defstruct [:action, :from, :to, :__identifier__]
  end

  require Logger

  @transition %Spark.Dsl.Entity{
    name: :transition,
    target: Transition,
    args: [:action],
    identifier: {:auto, :unique_integer},
    schema: [
      action: [
        type: :atom,
        required: true,
        doc:
          "The corresponding action that is invoked for the transition. Use `:*` to allow any update action to perform this transition."
      ],
      from: [
        type: {:or, [{:list, :atom}, :atom]},
        required: true,
        doc:
          "The states in which this action may be called. If not specified, then any state is accepted. Use `:*` to refer to all states."
      ],
      to: [
        type: {:or, [{:list, :atom}, :atom]},
        required: true,
        doc:
          "The states that this action may move to. If not specified, then any state is accepted. Use `:*` to refer to all states."
      ]
    ]
  }

  @transitions %Spark.Dsl.Section{
    name: :transitions,
    describe: """
    # Wildcards
    Use `:*` to represent "any action" when used in place of an action, or "any state" when used in place of a state.

    For example:

    ```elixir
    transition :*, from: :*, to: :*
    ```

    The full list of states is derived at compile time from the transitions.
    Use the `extra_states` to express that certain types should be included
    in that list even though no transitions go to/from that state explicitly.
    This is necessary for cases where there are states that use `:*` and no
    transition explicitly leads to that transition.
    """,
    entities: [
      @transition
    ]
  }

  @state_machine %Spark.Dsl.Section{
    name: :state_machine,
    schema: [
      deprecated_states: [
        type: {:list, :atom},
        default: [],
        doc: """
        A list of states that have been deprecated but are still valid. These will still be in the possible list of states, but `:*` will not include them.
        """
      ],
      extra_states: [
        type: {:list, :atom},
        default: [],
        doc: """
        A list of states that may be used by transitions to/from `:*`. See the docs on wildcards for more.
        """
      ],
      state_attribute: [
        type: :atom,
        doc: "The attribute to store the state in.",
        default: :state
      ],
      initial_states: [
        type: {:list, :atom},
        required: true,
        doc: "The allowed starting states of this state machine."
      ],
      default_initial_state: [
        type: :atom,
        doc: "The default initial state"
      ]
    ],
    sections: [
      @transitions
    ]
  }

  @sections [@state_machine]

  @moduledoc """
  Provides tools for defining and working with resource-backed state machines.
  """

  use Spark.Dsl.Extension,
    sections: @sections,
    transformers: [
      AshStateMachine.Transformers.SetDefaultInitialState,
      AshStateMachine.Transformers.FillInTransitionDefaults,
      AshStateMachine.Transformers.AddState,
      AshStateMachine.Transformers.EnsureStateSelected
    ],
    verifiers: [
      AshStateMachine.Verifiers.VerifyTransitionActions,
      AshStateMachine.Verifiers.VerifyDefaultInitialState
    ],
    imports: [
      AshStateMachine.BuiltinChanges
    ]

  @doc """
  A utility to transition the state of a changeset, honoring the rules of the resource.
  """
  def transition_state(changeset, target) when is_binary(target) do
    transition_state(changeset, String.to_existing_atom(target))
  rescue
    _ ->
      no_such_state(changeset, target)
  end

  def transition_state(%{action_type: :update} = changeset, target) do
    attribute = AshStateMachine.Info.state_machine_state_attribute!(changeset.resource)
    old_state = Map.get(changeset.data, attribute)

    if target in AshStateMachine.Info.state_machine_all_states(changeset.resource) do
      find_and_perform_transition(changeset, old_state, attribute, target)
    else
      no_such_state(changeset, target)
    end
  end

  def transition_state(%{action_type: :create, action: %{upsert?: true}} = changeset, target) do
    attribute = AshStateMachine.Info.state_machine_state_attribute!(changeset.resource)
    old_state = Map.get(changeset.data, attribute)

    cond do
      target not in AshStateMachine.Info.state_machine_initial_states!(changeset.resource) ->
        invalid_initial_state(changeset, target)

      target not in available_upsert_targets(changeset) ->
        no_matching_transition(changeset, target, old_state)

      true ->
        Ash.Changeset.force_change_attribute(changeset, attribute, target)
    end
  end

  def transition_state(%{action_type: :create} = changeset, target) do
    attribute = AshStateMachine.Info.state_machine_state_attribute!(changeset.resource)

    if target in AshStateMachine.Info.state_machine_initial_states!(changeset.resource) do
      Ash.Changeset.force_change_attribute(changeset, attribute, target)
    else
      invalid_initial_state(changeset, target)
    end
  end

  def transition_state(other, _target) do
    Ash.Changeset.add_error(other, "Can't transition states on destroy actions")
  end

  defp find_and_perform_transition(changeset, old_state, attribute, target) do
    changeset.resource
    |> AshStateMachine.Info.state_machine_transitions(changeset.action.name)
    |> Enum.find(fn transition ->
      old_state in List.wrap(transition.from) and target in List.wrap(transition.to)
    end)
    |> case do
      nil ->
        no_matching_transition(changeset, target, old_state)

      _transition ->
        Ash.Changeset.force_change_attribute(changeset, attribute, target)
    end
  end

  @doc false
  def no_such_state(changeset, target, old_state \\ nil) do
    Logger.error("""
    Attempted to transition to an unknown state.

    This usually means that one of the following is true:

    * You have a missing transition definition in your state machine

      To remediate this, add a transition.

    * You are using `:*` to include a state that appears nowhere in the state machine definition

      To remediate this, add the `extra_states` option and include the state #{inspect(target)}
    """)

    no_matching_transition(changeset, target, old_state)
  end

  @doc false
  defp no_matching_transition(changeset, target, old_state) do
    changeset
    |> Ash.Changeset.set_context(%{state_machine: %{attempted_change: target}})
    |> Ash.Changeset.add_error(
      AshStateMachine.Errors.NoMatchingTransition.exception(
        old_state: old_state,
        target: target,
        action: changeset.action.name
      )
    )
  end

  defp invalid_initial_state(changeset, target) do
    changeset
    |> Ash.Changeset.set_context(%{state_machine: %{attempted_change: target}})
    |> Ash.Changeset.add_error(
      AshStateMachine.Errors.InvalidInitialState.exception(
        target: target,
        action: changeset.action.name
      )
    )
  end

  @doc """
  A reusable helper which returns all possible next states for a record
  (regardless of action).
  """
  @spec possible_next_states(Ash.Resource.record()) :: [atom]
  def possible_next_states(%resource{} = record) do
    state_attribute = AshStateMachine.Info.state_machine_state_attribute!(resource)
    current_state = Map.fetch!(record, state_attribute)

    resource
    |> AshStateMachine.Info.state_machine_transitions()
    |> Enum.map(&%{from: List.wrap(&1.from), to: List.wrap(&1.to)})
    |> Enum.filter(&(current_state in &1.from or :* in &1.from))
    |> Enum.flat_map(& &1.to)
    |> Enum.reject(&(&1 == :*))
    |> Enum.uniq()
  end

  @doc """
  A reusable helper which returns all possible next states for a record given a
  specific action.
  """
  @spec possible_next_states(Ash.Resource.record(), atom) :: [atom]
  def possible_next_states(%resource{} = record, action_name) when is_atom(action_name) do
    state_attribute = AshStateMachine.Info.state_machine_state_attribute!(resource)
    current_state = Map.fetch!(record, state_attribute)

    resource
    |> AshStateMachine.Info.state_machine_transitions(action_name)
    |> Enum.map(&%{from: List.wrap(&1.from), to: List.wrap(&1.to)})
    |> Enum.filter(&(current_state in &1.from or :* in &1.from))
    |> Enum.flat_map(& &1.to)
    |> Enum.reject(&(&1 == :*))
    |> Enum.uniq()
  end

  defp available_upsert_targets(changeset) do
    AshStateMachine.Info.state_machine_transitions(changeset.resource, changeset.action.name)
    |> Enum.map(& &1.to)
    |> List.flatten()
    |> Enum.uniq()
  end
end
