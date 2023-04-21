defmodule AshFsm do
  @moduledoc """
  Documentation for `AshFsm`.
  """

  defmodule Event do
    @moduledoc """
    The configuration for an event.
    """
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
      state_attribute: [
        type: :atom,
        doc: "The attribute to store the state in.",
        default: :state
      ],
      initial_states: [
        type: {:or, [{:list, :atom}, :atom]},
        doc:
          "The allowed starting states of this state machine. If not specified, all states are allowed."
      ]
    ],
    sections: [
      @events
    ]
  }

  use Spark.Dsl.Extension, sections: [@fsm]
end
