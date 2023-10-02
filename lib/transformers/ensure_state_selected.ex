defmodule AshStateMachine.Transformers.EnsureStateSelected do
  # Ensures that `state` is always selected on queries.
  @moduledoc false
  use Spark.Dsl.Transformer

  def transform(dsl_state) do
    Ash.Resource.Builder.add_preparation(
      dsl_state,
      {Ash.Resource.Preparation.Build,
       ensure_selected: [
         AshStateMachine.Info.state_machine_state_attribute(dsl_state)
       ]}
    )
  end
end
