ExUnit.start()

# The :assets tag marks tests that shell out to `npm run build` (see
# LiveReactExamples.AssetsBuildTest) and take several seconds. They are slow
# enough that they should not run on every `mix test`, so they are excluded
# by default and opted into explicitly in CI via `mix test --include assets`.
ExUnit.configure(exclude: [:assets])
