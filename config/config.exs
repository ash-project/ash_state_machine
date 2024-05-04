import Config

config :spark, :formatter,
  remove_parens?: true,
  "Ash.Domain": [],
  "Ash.Registry": [],
  "Ash.Resource": []

if Mix.env() == :test do
  config :ash, :validate_domain_resource_inclusion?, false
  config :ash, :validate_domain_config_inclusion?, false
  config :ash_state_machine, :ash_domains, [Domain]
  config :logger, level: :warning
end

if Mix.env() == :dev do
  config :git_ops,
    mix_project: AshStateMachine.MixProject,
    changelog_file: "CHANGELOG.md",
    repository_url: "https://github.com/ash-project/ash_state_machine",
    # Instructs the tool to manage your mix version in your `mix.exs` file
    # See below for more information
    manage_mix_version?: true,
    # Instructs the tool to manage the version in your README.md
    # Pass in `true` to use `"README.md"` or a string to customize
    manage_readme_version: [
      "README.md",
      "documentation/tutorials/getting-started-with-ash-state-machine.md"
    ],
    version_tag_prefix: "v"
end
