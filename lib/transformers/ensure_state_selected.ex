defmodule AshFsm.Transformers.EnsureStateSelected do
  use Spark.Dsl.Transformer

  def transform(dsl_state) do
    Ash.Resource.Builder.add_preparation(
      dsl_state,
      {Ash.Resource.Preparation.Build,
       ensure_selected: [
         AshFsm.Info.fsm_state_attribute(dsl_state)
       ]}
    )
  end
end
