defmodule AshFsm.Transformers.AddState do
  use Spark.Dsl.Transformer
  alias Spark.Dsl.Transformer

  def after?(_), do: true

  def transform(dsl_state) do
    deprecated_states =
      case AshFsm.Info.fsm_deprecated_states(dsl_state) do
        {:ok, value} -> value || []
        _ -> []
      end

    all_states = Enum.uniq(AshFsm.Info.fsm_all_states(dsl_state) ++ deprecated_states)
    attribute_name = AshFsm.Info.fsm_state_attribute!(dsl_state)
    module = Transformer.get_persisted(dsl_state, :module)

    case Ash.Resource.Info.attribute(dsl_state, attribute_name) do
      nil ->
        default =
          case AshFsm.Info.fsm_default_initial_state(dsl_state) do
            {:ok, value} ->
              value

            _ ->
              nil
          end

        Ash.Resource.Builder.add_attribute(dsl_state, attribute_name, :atom,
          default: default,
          constraints: [
            one_of: all_states
          ]
        )

      attribute ->
        {type, constraints} =
          if Ash.Type.NewType.new_type?(attribute.type) do
            {Ash.Type.NewType.subtype_of(attribute.type),
             Ash.Type.NewType.constraints(attribute.type, attribute.constraints)}
          else
            {attribute.type, attribute.constraints}
          end

        case AshFsm.Info.fsm_default_initial_state(dsl_state) do
          {:ok, default} ->
            if attribute.default != default do
              raise Spark.Error.DslError,
                module: module,
                path: [:attributes, attribute.name],
                message: """
                Expected the attribute #{attribute.name} to have `default` set to #{inspect(default)}
                """
            end

          _ ->
            :ok
        end

        cond do
          type == Ash.Type.Atom ->
            if Enum.sort(constraints[:one_of]) != Enum.sort(all_states) do
              {:ok, dsl_state}
            else
              raise Spark.Error.DslError,
                module: module,
                path: [:attributes, attribute.name],
                message: """
                Expected the attribute #{attribute.name} to have the `one_of` constraints with the following values:
                #{inspect(Enum.sort(all_states))}
                """
            end

          function_exported?(type, :values, 0) ->
            if Enum.sort(type.values()) != Enum.sort(all_states) do
              {:ok, dsl_state}
            else
              raise Spark.Error.DslError,
                module: module,
                path: [:attributes, attribute.name],
                message: """
                Expected the attribute #{attribute.name} to have the `one_of` constraints with the following values:
                #{inspect(Enum.sort(all_states))}
                """
            end

          true ->
            raise Spark.Error.DslError,
              module: module,
              path: [:attributes, attribute.name],
              message: """
              Expected the attribute #{attribute.name} to be an `:atom` type or an `Ash.Type.Enum`. Got #{inspect(type)}.
              """
        end
    end
  end
end
