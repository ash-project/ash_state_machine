defmodule AshStateMachine.Transformers.AddState do
  # Adds or enforces details about the state attribute
  @moduledoc false
  use Spark.Dsl.Transformer
  alias Spark.Dsl.Transformer

  def before?(Ash.Resource.Transformers.DefaultAccept), do: true
  def before?(_), do: false

  def after?(AshStateMachine.Transformers.FillInTransitionDefaults), do: true
  def after?(_), do: false

  def transform(dsl_state) do
    deprecated_states = AshStateMachine.Info.state_machine_deprecated_states!(dsl_state)

    all_states =
      Enum.uniq(AshStateMachine.Info.state_machine_all_states(dsl_state) ++ deprecated_states)

    attribute_name = AshStateMachine.Info.state_machine_state_attribute!(dsl_state)
    module = Transformer.get_persisted(dsl_state, :module)

    case Ash.Resource.Info.attribute(dsl_state, attribute_name) do
      nil ->
        default =
          case AshStateMachine.Info.state_machine_default_initial_state(dsl_state) do
            {:ok, value} ->
              value

            _ ->
              nil
          end

        Ash.Resource.Builder.add_attribute(dsl_state, attribute_name, :atom,
          default: default,
          allow_nil?: false,
          public?: true,
          constraints: [
            one_of: all_states
          ]
        )

      attribute ->
        if attribute.allow_nil? do
          raise Spark.Error.DslError,
            module: module,
            path: [:attributes, attribute.name],
            message: """
            Expected the attribute #{attribute.name} not to be `allow_nil? true`. This is required for `AshStateMachine`
            """
        end

        {type, constraints} =
          if Ash.Type.NewType.new_type?(attribute.type) do
            {Ash.Type.NewType.subtype_of(attribute.type),
             Ash.Type.NewType.constraints(attribute.type, attribute.constraints)}
          else
            {attribute.type, attribute.constraints}
          end

        case AshStateMachine.Info.state_machine_default_initial_state(dsl_state) do
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
            if Enum.sort(constraints[:one_of]) == Enum.sort(all_states) do
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
            if Enum.sort(type.values()) == Enum.sort(all_states) do
              {:ok, dsl_state}
            else
              raise Spark.Error.DslError,
                module: module,
                path: [:attributes, attribute.name],
                message: """
                Expected the attribute #{attribute.name} to support the following values:
                #{inspect(Enum.sort(all_states))}

                Got

                #{inspect(Enum.sort(type.values()))}
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
