defmodule LiveReactExamples.SSRBundleTest do
  @moduledoc """
  Guards the production SSR contract.

  `config/prod.exs` renders through `LiveReact.SSR.NodeJS`, which runs
  `priv/react-components/server.js` directly under Node. The release never
  copies `assets/node_modules`, and the Dockerfile's runner stage copies only
  the release, so nothing is reachable by Node's upward module resolution from
  `priv/`. The bundle must therefore be self-contained.

  It was not: Vite externalised `react` and every other runtime dependency, so
  `server.js` kept bare imports and `NodeJS.call!` raised
  `ERR_MODULE_NOT_FOUND` — meaning every page rendering a React component
  would have 500'd in production. This test fails if that regresses.

  Note the dev path is different and deliberately NOT covered here:
  `config/dev.exs` uses `LiveReact.SSR.ViteJS`, which renders through the Vite
  dev server and resolves from `assets/node_modules`. React must stay
  *external* there — Vite's dev module runner evaluates inlined modules as
  ESM, and `react/jsx-dev-runtime.js` is CJS, so bundling it raises
  "ReferenceError: module is not defined". `assets/vite.config.js` splits the
  two cases; exercising the dev half needs a running Vite server, so the
  reasoning is recorded in that file's comment instead.
  """
  use ExUnit.Case, async: false

  @moduletag :assets
  @moduletag timeout: 300_000

  @bundle Path.expand("../priv/react-components/server.js", __DIR__)

  setup_all do
    {output, status} =
      System.cmd("npm", ["run", "build-server"],
        cd: Path.expand("../assets", __DIR__),
        stderr_to_stdout: true
      )

    assert status == 0, "SSR bundle build failed:\n#{output}"
    :ok
  end

  test "the SSR bundle imports with no node_modules reachable from priv/" do
    refute File.exists?(Path.expand("../priv/react-components/node_modules", __DIR__)),
           "a node_modules under priv/react-components/ would mask the very failure " <>
             "this test exists to catch — it is not committed and must not be required"

    script = """
    import(#{Jason.encode!(@bundle)})
      .then(() => console.log("RESOLVED OK"))
      .catch((e) => console.log("FAILED:" + e.code));
    """

    {output, _status} =
      System.cmd("node", ["--input-type=module", "-e", script],
        cd: System.tmp_dir!(),
        stderr_to_stdout: true
      )

    assert output =~ "RESOLVED OK",
           "priv/react-components/server.js could not be imported standalone. " <>
             "Production runs it under Node with nothing reachable from priv/, so " <>
             "bare imports mean every React page 500s. Got:\n#{output}"
  end

  test "the bundle exports the render function LiveReact.SSR.NodeJS calls" do
    script = """
    import(#{Jason.encode!(@bundle)})
      .then((m) => console.log(typeof (m.render ?? m.default?.render)))
      .catch((e) => console.log("FAILED:" + e.code));
    """

    {output, _status} =
      System.cmd("node", ["--input-type=module", "-e", script],
        cd: System.tmp_dir!(),
        stderr_to_stdout: true
      )

    assert output =~ "function",
           "LiveReact.SSR.NodeJS calls {server.js, \"render\"}; the bundle must export it. " <>
             "Got:\n#{output}"
  end
end
