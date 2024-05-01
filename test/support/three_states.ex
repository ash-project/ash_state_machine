defmodule ThreeStates do
  @moduledoc false
  use Ash.Resource,
    domain: Domain,
    data_layer: Ash.DataLayer.Ets,
    extensions: [AshStateMachine]

  state_machine do
    initial_states [:pending]
    default_initial_state :pending

    transitions do
      transition(:begin, from: :pending, to: :executing)
      transition(:complete, from: :executing, to: :complete)
      transition(:*, from: :*, to: :pending)
    end
  end

  actions do
    default_accept :*
    defaults [:read, :create]

    update :begin do
      change transition_state(:executing)
    end

    update :complete do
      change transition_state(:complete)
    end
  end

  ets do
    private? true
  end

  attributes do
    uuid_primary_key :id
  end

  code_interface do
    define :create
    define :begin
    define :complete
  end
end
