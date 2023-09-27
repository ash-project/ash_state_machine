defmodule AshStateMachine.MixProject do
  use Mix.Project

  @version "0.2.2"

  @description """
  An Ash.Resource extension for building finite state machines
  """

  def project do
    [
      app: :ash_state_machine,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      package: package(),
      aliases: aliases(),
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      dialyzer: [plt_add_apps: [:ash, :mix]],
      docs: docs(),
      description: @description,
      source_url: "https://github.com/ash-project/ash_state_machine",
      homepage_url: "https://github.com/ash-project/ash_state_machine"
    ]
  end

  defp package do
    [
      name: :ash_state_machine,
      licenses: ["MIT"],
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*
      CHANGELOG* documentation),
      links: %{
        GitHub: "https://github.com/ash-project/ash_state_machine"
      }
    ]
  end

  defp elixirc_paths(:test) do
    elixirc_paths(:dev) ++ ["test/support"]
  end

  defp elixirc_paths(_) do
    ["lib"]
  end

  defp extras() do
    "documentation/**/*.{md,cheatmd,livemd}"
    |> Path.wildcard()
    |> Enum.map(fn path ->
      title =
        path
        |> Path.basename(".md")
        |> Path.basename(".cheatmd")
        |> Path.basename(".livemd")
        |> String.split(~r/[-_]/)
        |> Enum.map(&capitalize_first/1)
        |> Enum.join(" ")
        |> case do
          "F A Q" ->
            "FAQ"

          other ->
            other
        end

      {String.to_atom(path),
       [
         title: title
       ]}
    end)
  end

  defp capitalize_first(string) do
    [h | t] = String.graphemes(string)
    String.capitalize(h) <> Enum.join(t)
  end

  defp groups_for_extras() do
    [
      Tutorials: [
        ~r'documentation/tutorials'
      ],
      "How To": ~r'documentation/how_to',
      Topics: ~r'documentation/topics',
      DSLs: ~r'documentation/dsls'
    ]
  end

  defp docs do
    [
      main: "get-started-with-state-machines",
      source_ref: "v#{@version}",
      logo: "logos/small-logo.png",
      extra_section: "GUIDES",
      spark: [
        extensions: [
          %{
            module: AshStateMachine,
            name: "AshStateMachine",
            target: "Ash.Resource",
            type: "StateMachine Resource"
          }
        ]
      ],
      before_closing_body_tag: fn
        :html ->
          """
          <script src="https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js"></script>
          <script>mermaid.initialize({startOnLoad: true})</script>
          """

        _ ->
          ""
      end,
      extras: extras(),
      groups_for_extras: groups_for_extras(),
      groups_for_modules: [
        Dsl: [
          AshStateMachine
        ],
        Introspection: [
          AshStateMachine.Info,
          AshStateMachine.Transition
        ],
        Helpers: [
          AshStateMachine.BuiltinChanges
        ],
        Charts: [
          AshStateMachine.Charts
        ],
        Errors: [
          ~r/AshStateMachine.Errors/
        ],
        Internals: ~r/.*/
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ash, "~> 2.7"},
      {:spark, ">= 1.1.22"},
      {:ex_doc, github: "elixir-lang/ex_doc", only: [:dev, :test], runtime: false},
      {:ex_check, "~> 0.12.0", only: [:dev, :test]},
      {:credo, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:dialyxir, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:sobelow, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:git_ops, "~> 2.5.1", only: [:dev, :test]},
      {:excoveralls, "~> 0.13.0", only: [:dev, :test]}
    ]
  end

  defp aliases do
    [
      sobelow: "sobelow --skip",
      credo: "credo --strict",
      docs: [
        "spark.cheat_sheets",
        "docs",
        "spark.replace_doc_links",
        "spark.cheat_sheets_in_search"
      ],
      "spark.formatter": "spark.formatter --extensions AshStateMachine",
      "spark.cheat_sheets": "spark.cheat_sheets --extensions AshStateMachine",
      "spark.cheat_sheets_in_search": "spark.cheat_sheets_in_search --extensions AshStateMachine"
    ]
  end
end
