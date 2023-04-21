defmodule AshFsm.Transformers.FillInEventDefaults do
  use Spark.Dsl.Transformer
  alias Spark.Dsl.Transformer
  @moduledoc false

  def transform(dsl_state) do
    initial_states =
      case AshFsm.Info.fsm_initial_states(dsl_state) do
        {:ok, value} -> List.wrap(value)
        _ -> []
      end

    initial_states =
      case initial_states do
        [] ->
          case AshFsm.Info.fsm_default_initial_state(dsl_state) do
            {:ok, value} when not is_nil(value) ->
              [value]

            _ ->
              initial_states
          end

        _ ->
          initial_states
      end

    events =
      dsl_state
      |> AshFsm.Info.fsm_events()

    all_states =
      events
      |> Enum.flat_map(fn event ->
        List.wrap(event.from) ++ List.wrap(event.to)
      end)
      |> Enum.concat(List.wrap(initial_states))
      |> Enum.uniq()

    dsl_state =
      case AshFsm.Info.fsm_initial_states(dsl_state) do
        {:ok, value} when not is_nil(value) and value != [] ->
          dsl_state

        _ ->
          Transformer.set_option(dsl_state, [:fsm], :initial_states, all_states)
      end

    {:ok,
     events
     |> Enum.reduce(dsl_state, fn event, dsl_state ->
       Transformer.replace_entity(dsl_state, [:fsm], %{
         event
         | from: event.from || all_states,
           to: event.to || all_states
       })
     end)
     |> Transformer.persist(:all_fsm_states, all_states)}
  end
end
