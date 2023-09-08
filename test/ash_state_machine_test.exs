defmodule AshStateMachineTest do
  use ExUnit.Case
  doctest AshStateMachine

  defmodule Order do
    # leaving out data layer configuration for brevity
    use Ash.Resource,
      extensions: [AshStateMachine]

    state_machine do
      initial_states [:pending]
      default_initial_state :pending

      transitions do
        transition :confirm, from: :pending, to: :confirmed
        transition :begin_delivery, from: :confirmed, to: :on_its_way
        transition :package_arrived, from: :on_its_way, to: :arrived
        transition :error, from: [:pending, :confirmed, :on_its_way], to: :error
      end
    end

    actions do
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
    end

    changes do
      # any failures should be captured and transitioned to the error state
      change after_transaction(fn
               changeset, {:ok, result} ->
                 {:ok, result}

               changeset, {:error, error} ->
                 message = Exception.message(error)

                 changeset.data
                 |> Ash.Changeset.for_update(:error, %{
                   message: message,
                   error_state: changeset.data.state
                 })
             end),
             on: [:update]
    end

    attributes do
      uuid_primary_key :id
      # ...attributes like address/delivery options would go here
      attribute :error, :string
      attribute :error_state, :string
      # :state attribute is added for you by `state_machine`
      # however, you can add it yourself, and you will be guided by
      # compile errors on what states need to be allowed by your type.
    end
  end

  defmodule ThreeStates do
    use Ash.Resource,
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
      defaults [:create]

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
      define_for AshStateMachineTest.Api
      define :create
      define :begin
      define :complete
    end
  end

  defmodule Api do
    use Ash.Api

    resources do
      allow_unregistered? true
    end
  end

  describe "transformers" do
    test "infers all states, excluding star (:*)" do
      assert Enum.sort(AshStateMachine.Info.state_machine_all_states(ThreeStates)) ==
               Enum.sort([:executing, :pending, :complete])
    end
  end

  describe "behavior" do
    test "begins in the appropriate state" do
      assert ThreeStates.create!().state == :pending
    end

    test "it transitions to the appropriate state" do
      state_machine = ThreeStates.create!()

      assert ThreeStates.begin!(state_machine).state == :executing
    end

    test "it transitions again to the appropriate state" do
      state_machine = ThreeStates.create!() |> ThreeStates.begin!()

      assert ThreeStates.complete!(state_machine).state == :complete
    end
  end

  describe "charts" do
    test "it generates the appropriate chart" do
      AshStateMachine.Charts.mermaid_state_diagram(Order) |> IO.puts()

      assert AshStateMachine.Charts.mermaid_flowchart(ThreeStates) ==
               """
               flowchart TD
               pending --> |begin| executing
               executing --> |complete| complete
               """
               |> String.trim_trailing()
    end
  end

  describe "next state" do
    defmodule NextStateMachine do
      @moduledoc false
      use Ash.Resource,
        extensions: [AshStateMachine]

      state_machine do
        initial_states [:a]
        default_initial_state :a

        transitions do
          transition :next, from: :a, to: :b
          transition :next, from: :b, to: :c
          transition :next, from: :b, to: :d
        end
      end

      attributes do
        uuid_primary_key :id

        attribute :state, :atom do
          allow_nil? false
          constraints one_of: [:a, :b, :c, :d]
          default :a
        end
      end

      actions do
        defaults [:create]

        update :next do
          change next_state()
        end
      end

      code_interface do
        define_for Api
        define :create
        define :next
      end
    end

    test "when there is only one next state, it transitions into it" do
      assert {:ok, nsm} = NextStateMachine.create(%{state: :a})
      assert {:ok, nsm} = NextStateMachine.next(nsm)
      assert nsm.state == :b
    end

    test "when there is more than one next state, it makes an oopsie" do
      assert {:ok, nsm} = NextStateMachine.create(%{state: :b})
      assert {:error, reason} = NextStateMachine.next(nsm)
      assert Exception.message(reason) =~ ~r/multiple next states/i
    end

    test "when there are no next states available, it also makes an oopsie" do
      assert {:ok, nsm} = NextStateMachine.create(%{state: :c})
      assert {:error, reason} = NextStateMachine.next(nsm)
      assert Exception.message(reason) =~ ~r/no next state/i
    end
  end
end
