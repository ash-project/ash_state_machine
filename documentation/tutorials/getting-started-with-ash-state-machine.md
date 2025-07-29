# Getting Started with State Machines

## Get familiar with Ash resources

If you haven't already, read the [Ash Getting Started Guide](https://hexdocs.pm/ash/get-started.html), and familiarize yourself with Ash and Ash resources.

## Bring in the ash_state_machine dependency

```elixir
{:ash_state_machine, "~> 0.2.12"}
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
  initial_states [:pending]
  default_initial_state :pending
end
```

## Add allowed transitions

```elixir
state_machine do
  initial_states [:pending]
  default_initial_state :pending

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

## Declaring a custom state attribute

By default, a `:state` attribute is created on the resource that looks like this:

```elixir
attribute :state, :atom do
  allow_nil? false
  default AshStateMachine.Info.state_machine_initial_default_state(dsl_state)
  public? true
  constraints one_of: [
    AshStateMachine.Info.state_machine_all_states(dsl_state)
  ]
end
```

You can change the name of this attribute, without declaring an attribute yourself, like so:

```elixir
state_machine do
  initial_states([:pending])
  default_initial_state(:pending)
  state_attribute(:alternative_state) # <-- save state in an attribute named :alternative_state
end
```

If you need more control, you can declare the attribute yourself on the resource:

```elixir
attributes do
  attribute :alternative_state, :atom do
    allow_nil? false
    default :issued
    public? true
    constraints one_of: [:issued, :sold, :reserved, :retired]
  end
end
```

Be aware that the type of this attribute needs to be `:atom` or a type created with `Ash.Type.Enum`. Both the `default` and list of values need to be correct! 


## Making a resource into a state machine

The concept of a state machine (in this case a "Finite State Machine"), essentially involves a single `state`, with specified transitions between states. For example, you might have an order state machine with states `[:pending, :on_its_way, :delivered]`. However, you can't go from `:pending` to `:delivered` (probably), and so you want to only allow certain transitions in certain circumstances, i.e `:pending -> :on_its_way -> :delivered`.

This extension's goal is to help you write clear and clean state machines, with all of the extensibility and power of Ash resources and actions.
