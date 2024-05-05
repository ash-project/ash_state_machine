# Getting Started with State Machines

## Get familiar with Ash resources

If you haven't already, read the [Ash Getting Started Guide](https://hexdocs.pm/ash/get-started.html), and familiarize yourself with Ash and Ash resources.

## Bring in the ash_state_machine dependency

```elixir
{:ash_state_machine, "~> 0.2.3-rc.1"}
```

## Add the extension to your resource

```elixir
use Ash.Resource,
  extensions: [AshStateMachine]
```

## Add initial states, and a default initial state

```elixir
use Ash.Resource,
  extensions: [AshStateMachine]

...

state_machine do
  inital_states [:pending]
  default_inital_state :pending
end
```

## Add allowed transitions

```elixir
state_machine do
  inital_states [:pending]
  default_inital_state :pending

  transitions do
    # `:begin` action can move state from `:pending` to `:started`/`:aborted`
    transition :begin, from: :pending, to: [:started, :aborted]
  end
end
```

## Use `transition_state` in your actions

### For simple/static state transitions

```elixir
actions do
  update :begin do
    # for a static state transition
    change transition_state(:started)
  end
end
```

### For dynamic/conditional state transitions

```elixir
defmodule Start do
  use Ash.Resource.Change

  def change(changeset, _, _) do
    if ready_to_start?(changeset) do
      AshStateMachine.transition_state(changeset, :started)
    else
      AshStateMachine.transition_state(changeset, :aborted)
    end
  end
end

actions do
  update :begin do
    # for a dynamic state transition
    change Start
  end
end
```

## Making a resource into a state machine

The concept of a state machine (in this case a "Finite State Machine"), essentially involves a single `state`, with specified transitions between states. For example, you might have an order state machine with states `[:pending, :on_its_way, :delivered]`. However, you can't go from `:pending` to `:delivered` (probably), and so you want to only allow certain transitions in certain circumstances, i.e `:pending -> :on_its_way -> :delivered`.

This extension's goal is to help you write clear and clean state machines, with all of the extensibility and power of Ash resources and actions.
