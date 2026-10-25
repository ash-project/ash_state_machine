# SPDX-FileCopyrightText: 2023 ash_state_machine contributors <https://github.com/ash-project/ash_state_machine/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule Verification do
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
      transition(:begin_refetched, from: :pending, to: :executing)
      transition(:begin_refetched_without_recheck, from: :pending, to: :executing)
      transition(:next_refetched, from: :pending, to: :executing)
      transition(:begin_always_atomic, from: :pending, to: :executing)
      transition(:reset, from: :*, to: :pending)
      transition(:broken_upsert, from: :*, to: [:foo, :bar])
    end
  end

  actions do
    default_accept :*
    defaults [:read, :create]

    update :begin do
      change transition_state(:executing)
    end

    # ETS doesn't support locks, so this re-read stands in for `get_and_lock_for_update()`
    update :begin_refetched do
      require_atomic? false

      change before_action(fn changeset, _ ->
               %{changeset | data: Ash.get!(Verification, changeset.data.id)}
             end)

      change transition_state(:executing, recheck?: true)
    end

    update :begin_refetched_without_recheck do
      require_atomic? false

      change before_action(fn changeset, _ ->
               %{changeset | data: Ash.get!(Verification, changeset.data.id)}
             end)

      change transition_state(:executing)
    end

    update :next_refetched do
      require_atomic? false

      change before_action(fn changeset, _ ->
               %{changeset | data: Ash.get!(Verification, changeset.data.id)}
             end)

      change next_state(recheck?: true)
    end

    update :begin_always_atomic do
      require_atomic? false

      # A function change can't be done atomically, so the action isn't atomic.
      change fn changeset, _ -> changeset end
      change transition_state(:executing), always_atomic?: true
    end

    update :no_transition_update do
      change transition_state(:executing)
    end

    create :reset do
      upsert? true
      change transition_state(:pending)
    end

    create :broken_upsert do
      upsert? true
      change transition_state(:pending)
    end
  end

  attributes do
    uuid_primary_key :id, writable?: true
  end

  code_interface do
    define :create
    define :begin
    define :reset
    define :broken_upsert
  end
end
