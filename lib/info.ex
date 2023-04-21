defmodule AshFsm.Info do
  use Spark.InfoGenerator, extension: AshFsm, sections: [:fsm]

  @spec fsm_all_states(Ash.Resource.record() | map()) :: list(atom)
  def fsm_all_states(resource_or_dsl) do
    Spark.Dsl.Extension.get_persisted(resource_or_dsl, :all_fsm_states, [])
  end
end
