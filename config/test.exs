import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :live_react_examples, LiveReactExamplesWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 3202],
  secret_key_base: "1TSUMeDi3xh+wePzvzKMq73p/bD2psOzg340hjtEcR8WGPxm0qINVteU03whCTcS",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Server-side rendering via LiveReact.SSR.NodeJS (used by :prod and :test)
# shells out to a Node process whose ESM `import` resolution needs a
# `node_modules` next to priv/react-components/server.js. Nothing in the
# build pipeline populates that directory (see assets/package.json's
# build-server script and the Dockerfile), so SSR is a pre-existing gap on
# that path, not something introduced here. Dev is unaffected: it uses
# LiveReact.SSR.ViteJS, which renders through the Vite dev server.
# Disabling it for tests keeps the suite deterministic without requiring a
# full Vite/Node build; no test asserts on SSR output.
config :live_react, ssr: false
