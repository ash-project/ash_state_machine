# SPDX-FileCopyrightText: 2020 Zach Daniel
#
# SPDX-License-Identifier: MIT

defmodule NextStateMachine do
  @moduledoc false
  use Ash.Resource,
    domain: Domain,
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
      public? true
      constraints one_of: [:a, :b, :c, :d]
      default :a
    end
  end

  actions do
    default_accept :*
    defaults [:read, :create]

    update :next do
      change next_state()
    end
  end

  code_interface do
    define :create
    define :next
  end
end
