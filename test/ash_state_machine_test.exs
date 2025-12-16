# SPDX-FileCopyrightText: 2023 ash_state_machine contributors <https://github.com/ash-project/ash_state_machine/graphs.contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshStateMachineTest do
  use ExUnit.Case
  doctest AshStateMachine
  import ExUnit.CaptureIO

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

    test "`from: :*` can transition from any state" do
      for state <- [:pending, :confirmed, :on_its_way, :arrived, :error] do
        assert {:ok, machine} = Order.abort(%Order{state: state})
        assert machine.state == :aborted
      end
    end

    test "`from: :*` cannot transition _to_ any state" do
      for state <- [:pending, :confirmed, :on_its_way, :arrived, :error] do
        assert {:error, reason} = Order.reroute(%Order{state: state})

        # if state != :aborted do
        #   assert Ash.can?({%Order{state: state}, :reroute}, nil) == false
        # end

        assert Exception.message(reason) =~ ~r/no matching transition/i
      end
    end

    test "NoMatchingTransition error can be converted to Ash error class" do
      error =
        AshStateMachine.Errors.NoMatchingTransition.exception(
          old_state: :pending,
          target: :invalid,
          action: :some_action
        )

      assert %Ash.Error.Invalid{} = Ash.Error.to_error_class(error)
    end

    test "create actions are allowed with `upsert? true`" do
      state_machine = Verification.create!() |> Verification.begin!()
      assert Verification.reset!(%{id: state_machine.id}).state == :pending
    end

    test "create upsert? actions do not allow invalid states" do
      state_machine = Verification.create!() |> Verification.begin!()
      assert {:error, reason} = Verification.broken_upsert(%{id: state_machine.id})
      assert Exception.message(reason) =~ ~r/no matching transition/i
    end

    test "create actions without `upsert? true` do not compile" do
      result =
        capture_io(:stderr, fn ->
          defmodule CreateWithoutUpsert do
            use Ash.Resource,
              domain: nil,
              extensions: [AshStateMachine]

            state_machine do
              initial_states [:pending]

              transitions do
                transition :reset, from: :*, to: :pending
              end
            end

            actions do
              create :reset do
                change transition_state("pending")
              end
            end
          end
        end)

      assert result =~ ~r/non-upsert create action/
    end

    test "create action transitions without `from: :*` do not compile" do
      result =
        capture_io(:stderr, fn ->
          defmodule CreateWithoutAllowingFromAll do
            use Ash.Resource,
              domain: nil,
              extensions: [AshStateMachine]

            state_machine do
              initial_states [:pending, :howdy]

              transitions do
                transition :reset, from: :howdy, to: :pending
              end
            end

            actions do
              create :reset do
                upsert? true
                change transition_state(:pending)
              end
            end
          end
        end)

      assert result =~ ~r/must allow transitions from all states/
    end

    test "any action other than update or create with upsert? true does not compile" do
      result =
        capture_io(:stderr, fn ->
          defmodule DeleteAction do
            use Ash.Resource,
              domain: nil,
              extensions: [AshStateMachine]

            state_machine do
              initial_states [:pending]

              transitions do
                transition :delete, from: :*, to: :pending
              end
            end

            actions do
              destroy :delete do
                change transition_state(:pending)
              end
            end
          end
        end)

      assert result =~ ~r/no such create or update action/
    end
  end

  describe "charts" do
    test "it generates the appropriate chart" do
      assert AshStateMachine.Charts.mermaid_flowchart(ThreeStates) ==
               """
               flowchart TD
               pending --> |begin| executing
               executing --> |complete| complete
               complete -->  pending
               executing -->  pending
               pending -->  pending
               """
               |> String.trim_trailing()
    end
  end

  describe "next state" do
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

  describe "possible_next_states/1" do
    test "it correctly returns the next states" do
      record = ThreeStates.create!()
      assert [:executing, :pending] = AshStateMachine.possible_next_states(record)
    end
  end

  describe "possible_next_states/2" do
    test "it correctly returns the next states" do
      record = ThreeStates.create!()
      assert [:pending] = AshStateMachine.possible_next_states(record, :complete)
    end
  end
end
