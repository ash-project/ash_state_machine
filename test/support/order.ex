defmodule Order do
  @moduledoc false
  # leaving out data layer configuration for brevity
  use Ash.Resource,
    domain: Domain,
    extensions: [AshStateMachine],
    authorizers: [Ash.Policy.Authorizer]

  state_machine do
    initial_states [:pending]
    default_initial_state :pending

    transitions do
      transition :confirm, from: :pending, to: :confirmed
      transition :begin_delivery, from: :confirmed, to: :on_its_way
      transition :package_arrived, from: :on_its_way, to: :arrived
      transition :error, from: [:pending, :confirmed, :on_its_way], to: :error
      transition :abort, from: :*, to: :aborted
      transition :reroute, from: :*, to: :rerouted
    end
  end

  policies do
    policy always() do
      authorize_if AshStateMachine.Checks.ValidNextState
    end
  end

  actions do
    default_accept :*
    # create sets the st
    defaults [:create, :read]

    update :confirm do
      # accept [...] you can change other attributes
      # or do anything else an action can normally do
      # this transition will be validated according to
      # the state machine rules above
      change transition_state(:confirmed)
    end

    update :begin_delivery do
      # accept [...]
      change transition_state(:on_its_way)
    end

    update :package_arrived do
      # accept [...]
      change transition_state(:arrived)
    end

    update :error do
      accept [:error_state, :error]
      change transition_state(:error)
    end

    update :abort do
      # accept [...]
      change transition_state(:aborted)
    end

    update :reroute do
      # accept [...]

      # The defined transition for this route contains a `from: :*` but does not include `to: :aborted`
      # This should never succeed
      change transition_state(:aborted)
    end
  end

  changes do
    # any failures should be captured and transitioned to the error state
    change after_transaction(fn
             changeset, {:ok, result}, _ ->
               {:ok, result}

             changeset, {:error, error}, _ ->
               if changeset.context[:error_handler?] do
                 {:error, error}
               else
                 changeset.data
                 |> Ash.Changeset.for_update(:error, %{
                   error_state: changeset.data.state
                 })
                 |> Ash.Changeset.set_context(%{error_handler?: true})
                 |> Ash.update()

                 {:error, error}
               end
           end),
           on: [:update]
  end

  code_interface do
    define :abort
    define :reroute
  end

  attributes do
    uuid_primary_key :id
    # ...attributes like address/delivery options would go here
    attribute :error, :string, public?: true
    attribute :error_state, :string, public?: true
    # :state attribute is added for you by `state_machine`
    # however, you can add it yourself, and you will be guided by
    # compile errors on what states need to be allowed by your type.
  end
end
