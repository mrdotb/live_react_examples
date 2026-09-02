defmodule LiveReactExamplesWeb.Examples.CounterLiveTest do
  use LiveReactExamplesWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "the example page renders with the preview tab by default", %{conn: conn} do
    conn = get(conn, ~p"/examples/counter")
    html = html_response(conn, 200)

    assert html =~ "Counter"
    assert html =~ "Key concepts"
  end

  test "the liveview tab shows real embedded source, not an empty block", %{conn: conn} do
    html = conn |> get(~p"/examples/counter?tab=liveview") |> html_response(200)

    # The bug this whole stage exists to fix: the old implementation fetched
    # source over the network and silently rendered nothing when it 404'd.
    assert html =~ "MyAppWeb.CounterLive"
    assert html =~ "def mount"
    refute html =~ "LiveReactExamplesWeb"
  end

  test "the react tab shows the component source", %{conn: conn} do
    html = conn |> get(~p"/examples/counter?tab=react") |> html_response(200)

    assert html =~ "export function Counter"
    assert html =~ "Counter.jsx"
  end

  test "an unknown tab falls back to preview rather than erroring", %{conn: conn} do
    html = conn |> get(~p"/examples/counter?tab=nonsense") |> html_response(200)

    refute html =~ "MyAppWeb.CounterLive"
    # Refuting the source alone doesn't prove the preview came back — a fallback
    # that renders neither would pass just as well. Assert the preview's React
    # component actually rendered.
    assert html =~ ~s(data-name="examples/Counter")
  end

  test "an unknown slug 404s", %{conn: conn} do
    # Not `assert_error_sent/2`: Phoenix's `RenderErrors` explicitly does not
    # reraise a plain `NoRouteError` (see its moduledoc — "the error is
    # reraised unless it is a NoRouteError"), so `assert_error_sent` can never
    # observe one; it always sees a plain sent 404 with no exception to
    # catch. Assert the response directly instead.
    conn = get(conn, "/examples/no-such-example")
    assert conn.status == 404
  end

  test "the preview is a real child liveview that responds to events", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/examples/counter")

    preview = find_live_child(view, "counter-preview")
    assert LiveReact.Test.get_react(preview, name: "examples/Counter").props["count"] == 0

    # Not `.props["count"]` after the hook: LiveReact sends only a diff on
    # update (`phx-update="ignore"`, applied client-side), so `data-props`
    # stays at its initial-render value and `get_react/2` reads it verbatim —
    # this is `enable_props_diff`, documented in `LiveReact.Test`'s own
    # moduledoc, and reproduces the same interaction Task 3 hit with
    # `render_component/2`. Assert on the decoded diff instead of changing
    # `config/test.exs`.
    html = render_hook(preview, "set_count", %{"value" => 7})

    assert LiveReact.Test.get_react(html, name: "examples/Counter").props_diff ==
             [["replace", "/count", 7]]
  end

  test "the old flat route still works — stage 1b migrates it", %{conn: conn} do
    assert {:ok, _view, _html} = live(conn, ~p"/live-counter")
  end
end
