defmodule AshFsmTest do
  use ExUnit.Case
  doctest AshFsm

  defmodule TwoStates do
    use Ash.Resource,
      data_layer: Ash.DataLayer.Ets,
      extensions: [AshFsm]

    fsm do
      initial_states([:pending])

      events do
        event(:begin, from: :pending, to: :executing)
        event(:complete, from: :executing, to: :complete)
      end
    end

    ets do
      private? true
    end

    attributes do
      uuid_primary_key :id
    end
  end

  test "greets the world" do
    IO.inspect(AshFsm.Info.fsm_all_states(TwoStates))
  end
end
