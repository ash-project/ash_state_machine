defmodule AshFsm do
  @moduledoc """
  Documentation for `AshFsm`.
  """

  defmodule Event do
    @moduledoc """
    The configuration for an event.
    """
    @type t :: %__MODULE__{
            action: atom,
            from: [atom],
            to: [atom]
          }

    defstruct [:action, :from, :to]
  end

  @event %Spark.Dsl.Entity{
    name: :event,
    target: Event,
    args: [:action],
    identifier: :action,
    schema: [
      action: [
        type: :atom,
        doc: "The corresponding action that is invoked for the event."
      ],
      from: [
        type: {:or, [{:list, :atom}, :atom]},
        doc:
          "The states in which this action may be called. If not specified, then any state is accepted."
      ],
      to: [
        type: {:or, [{:list, :atom}, :atom]},
        doc:
          "The states that this action may move to. If not specified, then any state is accepted."
      ]
    ]
  }

  @events %Spark.Dsl.Section{
    name: :events,
    entities: [
      @event
    ]
  }

  @fsm %Spark.Dsl.Section{
    name: :fsm,
    schema: [
      deprecated_states: [
        type: {:list, :atom},
        doc: """
        A list of states that have been deprecated.
        The list of states is derived from the events normally.
        Use this option to express that certain types should still
        be included even though no events go to/from that state anymore.
        """
      ],
      state_attribute: [
        type: :atom,
        doc: "The attribute to store the state in.",
        default: :state
      ],
      initial_states: [
        type: {:or, [{:list, :atom}, :atom]},
        doc:
          "The allowed starting states of this state machine. If not specified, all states are allowed."
      ],
      default_initial_state: [
        type: :atom,
        doc: "The default initial state"
      ]
    ],
    sections: [
      @events
    ]
  }

  use Spark.Dsl.Extension,
    sections: [@fsm],
    transformers: [
      AshFsm.Transformers.FillInEventDefaults,
      AshFsm.Transformers.AddState,
      AshFsm.Transformers.EnsureStateSelected
    ],
    verifiers: [
      AshFsm.Verifiers.VerifyEventActions,
      AshFsm.Verifiers.VerifyDefaultInitialState
    ],
    imports: [
      AshFsm.BuiltinChanges
    ]

  def transition_state(%{action_type: :update} = changeset, target) do
    events = AshFsm.Info.fsm_events(changeset.resource, changeset.action.name)
    attribute = AshFsm.Info.fsm_state_attribute!(changeset.resource)
    old_state = Map.get(changeset.data, attribute)

    case Enum.find(events, fn event ->
           old_state in List.wrap(event.from) and target in List.wrap(event.to)
         end) do
      nil ->
        Ash.Changeset.add_error(
          changeset,
          AshFsm.Errors.NoMatchingEvent.exception(
            from: old_state,
            target: target,
            action: changeset.action.name
          )
        )

      _event ->
        Ash.Changeset.force_change_attribute(changeset, attribute, target)
    end
  end
end
