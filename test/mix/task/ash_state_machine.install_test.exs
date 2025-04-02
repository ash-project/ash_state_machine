defmodule Mix.Tasks.AshStateMachine.InstallTest do
  use ExUnit.Case

  import Igniter.Test

  setup_all do
    igniter =
      test_project()
      |> Igniter.compose_task("ash_state_machine.install")

    [igniter: igniter]
  end

  test "add ash_state_machine to the formatter", %{igniter: igniter} do
    igniter
    |> assert_has_patch(".formatter.exs", """
    1 1   |# Used by "mix format"
    2 2   |[
    3   - |  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"]
      3 + |  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
      4 + |  import_deps: [:ash_state_machine]
    4 5   |]
    5 6   |
    """)
  end
end
