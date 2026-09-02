defmodule LiveReactExamplesWeb.RoutesSmokeTest do
  @moduledoc """
  Renders every example route through the real layout chrome.

  Component-level tests for a single example don't catch a layout
  regression on the others (a missing assign, a broken `on_mount`, …). This
  walks every `:ready` example in the registry and asserts each one renders
  successfully and still carries the shared header/footer chrome. The list
  is derived from `LiveReactExamples.Examples.ready/0` rather than
  hardcoded, so a newly-added example is covered automatically.

  Every route here is exercised with a plain disconnected GET rather than
  `Phoenix.LiveViewTest.live/2`. `live/2` needs `lazy_html` (a test-only hex
  dependency, added separately from this suite) to join the simulated
  socket, and that dependency has nothing to do with what this suite checks:
  whether `mount/3` + `render/1` succeed and the shared layout renders
  around them. A disconnected GET already exercises both `mount/3` and
  `render/1` for a LiveView (Phoenix always renders the dead view before a
  socket ever connects), which is what a layout regression would break.
  """
  use LiveReactExamplesWeb.ConnCase, async: true

  @routes for example <- LiveReactExamples.Examples.ready(), do: "/examples/#{example.id}"

  for path <- ["/examples" | @routes] do
    # /examples/ssr's preview hard-codes `ssr={true}` on one of its two
    # components, overriding `config :live_react, ssr: false`
    # (config/test.exs) — so, unlike every other route here, rendering it
    # shells out to real NodeJS SSR via `priv/react-components/server.js`,
    # gitignored and populated only by `mix assets.build`. Tag just this one
    # generated test `:assets` rather than the whole module, so the smoke
    # test still covers every other route by default.
    if path == "/examples/ssr" do
      @tag :assets
    end

    test "GET #{path} renders successfully with the shared layout chrome", %{conn: conn} do
      html = conn |> get(unquote(path)) |> html_response(200)

      assert html =~ ~s(id="theme-toggle")
      assert html =~ "hexdocs.pm/live_react"
    end
  end
end
