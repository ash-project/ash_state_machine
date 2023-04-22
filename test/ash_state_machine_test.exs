defmodule AshStateMachineTest do
  use ExUnit.Case
  doctest AshStateMachine

  defmodule ThreeStates do
    use Ash.Resource,
      data_layer: Ash.DataLayer.Ets,
      extensions: [AshStateMachine]

    state_machine do
      default_initial_state :pending

      transitions do
        transition(:begin, from: :pending, to: :executing)
        transition(:complete, from: :executing, to: :complete)
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
    test "infers all states" do
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
end
