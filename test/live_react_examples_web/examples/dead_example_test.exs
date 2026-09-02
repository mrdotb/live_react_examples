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

  test "the standalone note appears only under the preview tab", %{conn: conn} do
    # Code review (finding 2): the note sat outside the
    # `:if={@tab == "preview"}` container, so it rendered under every tab,
    # reading as a caption on the LiveView/React code blocks instead of a
    # note on the preview.
    preview = conn |> get(~p"/examples/simple") |> html_response(200)
    assert preview =~ "Open it standalone"

    liveview = conn |> get(~p"/examples/simple?tab=liveview") |> html_response(200)
    refute liveview =~ "Open it standalone"

    react = conn |> get(~p"/examples/simple?tab=react") |> html_response(200)
    refute react =~ "Open it standalone"
  end

  test "the standalone route has no LiveView socket at all", %{conn: conn} do
    html = conn |> get(~p"/examples/simple/raw") |> html_response(200)

    # Not `assert html =~ "Hello world!"`: config/test.exs turns SSR off by
    # default (`config :live_react, ssr: false`), and this route never
    # overrides it, so the component renders as an empty placeholder div in
    # this test run, hydrated client-side only. Assert the component mounted
    # instead — the same pattern `counter_live_test.exs` uses.
    assert html =~ ~s(data-name="examples/Simple")
    refute html =~ "data-phx-main"
    refute html =~ "data-phx-session"
  end

  test "the liveview tab shows the dead-view source, rewritten as a real PageHTML module",
       %{conn: conn} do
    html = conn |> get(~p"/examples/simple?tab=liveview") |> html_response(200)

    assert html =~ "MyAppWeb"
    refute html =~ "LiveReactExamplesWeb"

    # Code review (finding 3): the previous rewrite only swapped the
    # `LiveReactExamplesWeb` prefix, so this tab showed a fictional
    # `MyAppWeb.SimpleLive` module with `use Phoenix.Component` and
    # `def preview(assigns)` — under a tab labelled "LiveView", for the one
    # example whose entire point is that there is no LiveView. The two weak
    # assertions above would have passed on that broken output just as well;
    # assert the actual shape instead.
    assert html =~ "MyAppWeb.PageHTML"
    assert html =~ "def simple(assigns) do"
    assert html =~ "use MyAppWeb, :html"
    refute html =~ "MyAppWeb.SimpleLive"
    refute html =~ "def preview(assigns)"
    refute html =~ "use Phoenix.Component"
  end

  test "the second tab is labelled Template, not LiveView, for a dead example", %{conn: conn} do
    html = conn |> get(~p"/examples/simple?tab=liveview") |> html_response(200)

    assert html =~ "Template"
    assert html =~ "page_html.ex"
    refute html =~ "simple_live.ex"
  end

  test "the rewrite applies to every dead example, not just simple", %{conn: conn} do
    # simple-props is the case worth checking specifically: the slug has a
    # dash, and the rewritten function name must not.
    html = conn |> get(~p"/examples/simple-props?tab=liveview") |> html_response(200)
    assert html =~ "MyAppWeb.PageHTML"
    assert html =~ "def simple_props(assigns) do"
    refute html =~ "def preview(assigns)"

    html = conn |> get(~p"/examples/typescript?tab=liveview") |> html_response(200)
    assert html =~ "MyAppWeb.PageHTML"
    assert html =~ "def typescript(assigns) do"
    refute html =~ "def preview(assigns)"

    html = conn |> get(~p"/examples/lazy?tab=liveview") |> html_response(200)
    assert html =~ "MyAppWeb.PageHTML"
    assert html =~ "def lazy(assigns) do"
    refute html =~ "def preview(assigns)"
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
