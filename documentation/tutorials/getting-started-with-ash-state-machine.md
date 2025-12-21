<!--
SPDX-FileCopyrightText: 2023 ash_state_machine contributors <https://github.com/ash-project/ash_state_machine/graphs.contributors>

SPDX-License-Identifier: MIT
-->

# Getting Started with State Machines

In this tutorial, we will use AshStateMachine to extend the ticketing
tutorial from the [Ash Getting Started Guide](https://hexdocs.pm/ash/get-started.html).
If you are new to Ash, please consider reading that guide first to get
familiar with Ash and working with Resources.

## What you will learn

This tutorial, we will explore the following topics:

- What a state machine is in Ash
- How states are declared
- How actions trigger transitions
- How transitions are validated

## Installation

### Add the ash_state_machine dependency to your project's dependencies

Add the following dependency to your `mix.exs` file:

```elixir
{:ash_state_machine, "~> 0.2.12"}
```

Next, update your project dependencies by executing `mix deps.get`

# Making a resource into a state machine

A state machine (in this case a "Finite State Machine"), models a
system that can only exist in a single `state` at one time. Its
power comes from the ability to specify transitions between states.
For example, you might have an order state machine with states
`[:pending, :on_its_way, :delivered]`. However, you probably can't go from
`:pending` to `:delivered`, and so you want to only allow
certain transitions in certain circumstances, i.e `:pending ->
:on_its_way -> :delivered`.

This extension's goal is to help you write clear and clean state
machines, with all of the extensibility and power of Ash resources and
actions.

## Add the AshStateMachine extension to your resource

Next, add AshStateMachine as an extension to any existing resource. In
our case, we will add it to the Ticket resource:

```elixir
defmodule Helpdesk.Support.Ticket do
  use Ash.Resource,
    domain: Helpdesk.Support
    data_layer: Ash.DataLayer.Ets
    extensions: [AshStateMachine]

end
```

## Add attributes to your resource if required

This is not a tutorial on [Ash resources](https://hexdocs.pm/ash/get-started.html#steps),
so we won't go into detail here, but we will list the attributes that
we will use in this tutorial:

```elixir
  # The attributes that model a Ticket's data
  attributes do
    uuid_primary_key :id

    attribute :subject, :string
    attribute :description, :string
    attribute :additional_information, :string
  end
```

Note that the previous tutorial uses an attribute named `:status` to
track the ticket status. By default, AshStateMachine uses an attribute
named `:state` that serves the same purpose. For now we are going to
ignore this detail, but we will learn how to change the 'state'
attribute name later.

# Planning our future states

In this example we will proceed in a way that helps to illustrate
AshStateMachine concepts. There is no single 'correct' process for
modelling a domain, and you may choose to follow different steps if
that works better for you.

## Consider the possible states for your application

We will start by listing the states that we think we might need
(and which have been chosen to illustrate some different features)
as comments in our code:

```elixir
# Possible states: [
#   :received, :needs_more_info,
#   :with_it, :with_hr,
#   :will_not_fix, :closed
# ]
...
```

Next, we are going to create some empty actions so that we can think
about how we might like to interact with the Ticket resource.

```elixir
actions do
  create :open do
    accept [:subject, :description]
  end

  update :request_more_information do
  end

  update :assign_to_department do
  end

  update :deny_request do
  end

  update :close do
  end
end
```

## Specify the initial state for the resource

In our example, when a ticket is created, it will start in the
`:received` state, awaiting triage. We can add the following block to
specify the initial state:

```elixir
state_machine do
  initial_states [:received]
  default_initial_state :received
end
```

# Transitioning from one state to another

Ash uses `transition_state/1` to requests a state transition. Whether
the transition is allowed is determined later by the
state_machine.transitions configuration.

In our example, we will start with the simple idea that any user can
request more information about a ticket at any time.

## Use `transition_state` in your actions

We need to update our `:request_more_information` action so that it
requests a transition to the `:needs_more_info` state:

```elixir
actions do
  update :request_more_information do
    change transition_state(:needs_more_info)
  end
end
```

## Add allowed transitions

The power of AshStateMachine is that we can model which transitions
are allowed based upon the current state. To start, we are going to
allow users to 'request more information' from any state.

We accomplish this by adding
[transitions](https://hexdocs.pm/ash_state_machine/dsl-ashstatemachine.html#state_machine-transitions)
to our resource:

```elixir
state_machine do
  initial_states [:received]
  default_initial_state :received

  transitions do
    # the :request_more_information action can transition from
    # :received, :with_it or :with_hr to :needs_more_info.
    # we do not allow closed tickets to request more information.
    transition :request_more_information,
      from: [:received, :with_it, :with_hr],
      to: :needs_more_info
  end
end
```

The syntax is: transition (one or more actions), from: (one or more
states), to: (one or more states).

Note: You must define transitions for your actions. If you call
`change transition_state` and there isn't a matching `from` and
`to` state, the action will fail.


# Conditional state transitions

Sometimes you may need to transfer to one of multiple states depending
upon a particular condition, such as a passed-in argument or an
application-specific value.

## State transitions based upon an argument

In our example, we will let a support user transfer a ticket to the IT
department or the HR department by passing an
[argument](https://hexdocs.pm/ash/actions.html#accepting-inputs) to
the `:assign_to_department` action

First we will update our action:

```elixir
actions do
  update :assign_to_department do
    argument :department, :atom,
      allow_nil?: false,
      constraints: [
        one_of: [:IT, :HR]
      ]

    if :department == :IT do
      change transition_state(:with_it)
    else
      change transition_state(:with_hr)
    end
  end
end
```

We do not want to let the departments transfer tickets to each other,
so we will not allow a transition from `:with_it` to `:with_hr` or
vice versa.

Note that the conditional does not bypass any transition rules.
Even when transitions are chosen tynamically, the resulting
state must still be permitted by the `transitions` block.

```elixir
state_machine do
  transitions do
    # assign_to_dept can transition from
    # :received or :needs_more_info
    # and can transition to
    # :with_it or :with_hr
    transition(:assign_to_department,
      from: [:received, :needs_more_info],
      to: [:with_it, :with_hr]
    )
  end
end
```
  * [ ]


### Advanced: State transitions based upon changesets

For more complex scenarios, you can also branch based upon the
contents of a changeset, as the following example illustrates:

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

# Declaring a custom state attribute

As mentioned earlier, AshStateMachine uses the `:state` attribute by default.
When AshStateMachine is imported into a resource, the `:state` attribute is
created on the resource with the following definition:

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

In our example, if we wanted to change the name of the attribute from
`:state` to `:status` (to match the value from the previous tutorial),
we would do it like this:

```elixir
state_machine do
  initial_states([:pending])
  default_initial_state(:pending)
  state_attribute(:status) # <-- save state in an attribute named :status
end
```

If you need more control, you can declare the attribute yourself on
the resource:

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

Be aware that the type of this attribute needs to be `:atom` or a type
created with `Ash.Type.Enum`. Both the `default` and list of values
need to be correct!

# Next steps

The true power of AshStateMachine is that it integrates seemlessly with the
rest of the Ash ecosystem. You can easily add guards, policies, authorisation
and any other Ash concept to your state machines.
