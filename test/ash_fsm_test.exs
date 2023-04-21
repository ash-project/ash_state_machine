defmodule AshFsmTest do
  use ExUnit.Case
  doctest AshFsm

  defmodule ThreeStates do
    use Ash.Resource,
      data_layer: Ash.DataLayer.Ets,
      extensions: [AshFsm]

    fsm do
      default_initial_state :pending

      events do
        event :begin, from: :pending, to: :executing
        event :complete, from: :executing, to: :complete
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
      define_for AshFsmTest.Api
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
      assert Enum.sort(AshFsm.Info.fsm_all_states(ThreeStates)) ==
               Enum.sort([:executing, :pending, :complete])
    end
  end

  describe "behavior" do
    test "begins in the appropriate state" do
      assert ThreeStates.create!().state == :pending
    end

    test "it transitions to the appropriate state" do
      fsm = ThreeStates.create!()

      assert ThreeStates.begin!(fsm).state == :executing
    end

    test "it transitions again to the appropriate state" do
      fsm = ThreeStates.create!() |> ThreeStates.begin!()

      assert ThreeStates.complete!(fsm).state == :complete
    end
  end
end
