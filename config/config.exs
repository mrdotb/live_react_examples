# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :live_react,
  ssr_module: LiveReact.SSR.NodeJS

config :live_react_examples,
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :live_react_examples, LiveReactExamplesWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: LiveReactExamplesWeb.ErrorHTML, json: LiveReactExamplesWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: LiveReactExamples.PubSub,
  live_view: [signing_salt: "vR6Y0p5z"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
# git_ops derives the next version and the changelog from Conventional Commit
# messages, then tags the release. `mix git_ops.release` bumps the version in
# mix.exs, rewrites CHANGELOG.md and creates a `vX.Y.Z` tag — which is exactly
# what .github/workflows/publish.yml triggers on.
config :git_ops,
  mix_project: LiveReactExamples.MixProject,
  changelog_file: "CHANGELOG.md",
  repository_url: "https://github.com/mrdotb/live_react_examples",
  manage_mix_version?: true,
  manage_readme_version: false,
  version_tag_prefix: "v",
  types: [
    refactor: [header: "Refactors"],
    chore: [hidden?: true],
    docs: [hidden?: true],
    test: [hidden?: true],
    ci: [hidden?: true],
    # git_ops treats every body line shaped like `word: text` as the start of a
    # new commit, so standard git trailers parse as commit types and warn on
    # every release. Declaring them keeps them out of the changelog quietly.
    "co-authored-by": [hidden?: true],
    "claude-session": [hidden?: true]
  ]

import_config "#{config_env()}.exs"
