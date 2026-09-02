defmodule LiveReactExamplesWeb.RoutesSmokeTest do
  @moduledoc """
  Renders every route through the real layout chrome.

  Component-level and `/simple`-only tests don't catch a layout regression on
  the other thirteen routes (a missing assign, a broken `on_mount`, …). This
  walks every route in the router and asserts each one renders successfully
  and still carries the shared header/footer chrome.

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

  @routes [
    # Dead views (`PageController` actions).
    "/simple",
    "/simple-props",
    "/typescript",
    "/lazy",
    # LiveViews.
    "/live-counter",
    "/log-list",
    "/flash-sonner",
    "/ssr",
    "/hybrid-form",
    "/slot",
    "/context",
    "/link-demo",
    "/link-usage",
    "/stream-demo"
  ]

  for path <- @routes do
    test "GET #{path} renders successfully with the shared layout chrome", %{conn: conn} do
      html = conn |> get(unquote(path)) |> html_response(200)

      assert html =~ ~s(id="theme-toggle")
      assert html =~ "hexdocs.pm/live_react"
    end
  end
end
