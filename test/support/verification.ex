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
