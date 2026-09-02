defmodule LiveReactExamplesWeb.Examples.DeadExampleTest do
  @moduledoc """
  Dead-view examples demonstrate React with no LiveView socket. The page still
  needs to show them, so the preview renders inline rather than through
  live_render/3 — and a standalone route proves the socket-free claim.
  """
  use LiveReactExamplesWeb.ConnCase, async: true

  test "the example page renders the component inline", %{conn: conn} do
    html = conn |> get(~p"/examples/simple") |> html_response(200)

    assert html =~ "Hello React"
    # No child LiveView: rendering it as one would defeat the demonstration.
    # Not `refute html =~ "data-phx-session"` — the page itself (SimpleLive)
    # is still a top-level LiveView route and always carries its own session
    # marker; `data-phx-parent-id` is what uniquely marks a *child* LiveView
    # mounted via live_render/3, which is what would defeat the point here.
    refute html =~ "data-phx-parent-id"
  end

  test "the page offers a standalone socket-free route", %{conn: conn} do
    html = conn |> get(~p"/examples/simple") |> html_response(200)
    assert html =~ "/examples/simple/raw"
  end

  test "the standalone route has no LiveView socket at all", %{conn: conn} do
    html = conn |> get(~p"/examples/simple/raw") |> html_response(200)

    # Not `assert html =~ "Hello world!"`: config/test.exs turns SSR off
    # (`config :live_react, ssr: false`, "no test asserts on SSR output") so
    # the component always renders as an empty placeholder div in this
    # environment, hydrated client-side only. Assert the component mounted
    # instead — the same pattern `counter_live_test.exs` uses.
    assert html =~ ~s(data-name="examples/Simple")
    refute html =~ "data-phx-main"
    refute html =~ "data-phx-session"
  end

  test "the liveview tab shows the dead-view source, rewritten", %{conn: conn} do
    html = conn |> get(~p"/examples/simple?tab=liveview") |> html_response(200)

    assert html =~ "MyAppWeb"
    refute html =~ "LiveReactExamplesWeb"
  end

  test "a live example has no standalone route", %{conn: conn} do
    assert conn |> get(~p"/examples/counter") |> html_response(200) =~ "counter-preview"

    # Not `assert_raise Phoenix.Router.NoRouteError`: as `counter_live_test.exs`
    # already documents, `Phoenix.LiveView.RenderErrors` does not reraise a
    # plain `NoRouteError`, so `assert_raise` can never observe one here — it
    # always sees a plain sent 404 with no exception to catch.
    conn = get(conn, "/examples/counter/raw")
    assert conn.status == 404
  end
end
