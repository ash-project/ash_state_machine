# SPDX-FileCopyrightText: 2023 ash_state_machine contributors <https://github.com/ash-project/ash_state_machine/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule Domain do
  @moduledoc false
  use Ash.Domain

  resources do
    resource ThreeStates
    resource Order
    resource NextStateMachine
    resource Verification
  end
end
