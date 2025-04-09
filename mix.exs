defmodule AshStateMachine.MixProject do
  use Mix.Project

  @version "0.2.9"

  @description """
  The extension for building state machines with Ash resources.
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
      docs: &docs/0,
      description: @description,
      source_url: "https://github.com/ash-project/ash_state_machine",
      homepage_url: "https://github.com/ash-project/ash_state_machine",
      consolidate_protocols: Mix.env() != :test
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

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      logo: "logos/small-logo.png",
      extra_section: "GUIDES",
      before_closing_head_tag: fn type ->
        if type == :html do
          """
          <script>
            if (location.hostname === "hexdocs.pm") {
              var script = document.createElement("script");
              script.src = "https://plausible.io/js/script.js";
              script.setAttribute("defer", "defer")
              script.setAttribute("data-domain", "ashhexdocs")
              document.head.appendChild(script);
            }
          </script>
          """
        end
      end,
      before_closing_body_tag: fn
        :html ->
          """
          <script src="https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js"></script>
          <script>mermaid.initialize({startOnLoad: true})</script>
          """

        _ ->
          ""
      end,
      extras: [
        {"README.md", title: "Home"},
        "documentation/tutorials/getting-started-with-ash-state-machine.md",
        "documentation/topics/what-is-ash-state-machine.md",
        "documentation/topics/charts.md",
        "documentation/topics/working-with-ash-can.md",
        {"documentation/dsls/DSL-AshStateMachine.md",
         search_data: Spark.Docs.search_data_for(AshStateMachine)},
        "CHANGELOG.md"
      ],
      groups_for_extras: [
        Tutorials: ~r'documentation/tutorials',
        "How To": ~r'documentation/how_to',
        Topics: ~r'documentation/topics',
        DSLs: ~r'documentation/dsls',
        "About AshStateMachine": [
          "CHANGELOG.md"
        ]
      ],
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
      {:ash, ash_version("~> 3.0 and >= 3.4.66")},
      {:igniter, "~> 0.5", only: [:dev, :test]},
      {:simple_sat, "~> 0.1", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.36", only: [:dev, :test]},
      {:ex_check, "~> 0.12", only: [:dev, :test]},
      {:credo, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:dialyxir, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:sobelow, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:git_ops, "~> 2.5", only: [:dev, :test]},
      {:mix_audit, ">= 0.0.0", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases do
    [
      sobelow: "sobelow --skip",
      credo: "credo --strict",
      docs: [
        "spark.cheat_sheets",
        "docs",
        "spark.replace_doc_links"
      ],
      "spark.formatter": "spark.formatter --extensions AshStateMachine",
      "spark.cheat_sheets": "spark.cheat_sheets --extensions AshStateMachine",
      "spark.cheat_sheets_in_search": "spark.cheat_sheets_in_search --extensions AshStateMachine"
    ]
  end

  defp ash_version(default_version) do
    case System.get_env("ASH_VERSION") do
      nil -> default_version
      "local" -> [path: "../ash"]
      "main" -> [git: "https://github.com/ash-project/ash.git"]
      version -> "~> #{version}"
    end
  end
end
