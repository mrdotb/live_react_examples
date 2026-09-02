defmodule LiveReactExamplesWeb.Examples.ServerEventsLiveTest do
  use LiveReactExamplesWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "the example page renders with the preview tab by default", %{conn: conn} do
    conn = get(conn, ~p"/examples/server-events")
    html = html_response(conn, 200)

    assert html =~ "Server Events"
    assert html =~ ~s(data-name="examples/ServerEvents")
  end

  test "clicking info calls handle_event and push_event reaches the client as a real phx push",
       %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/examples/server-events")
    preview = find_live_child(view, "server-events-preview")

    render_click(preview, "info")

    # Not just "the click didn't crash": assert_push_event proves the exact
    # server -> client push phoenix_live_view actually delivers, which is
    # the whole point of push_event over ordinary prop reassignment.
    assert_push_event(preview, "info", %{message: "This is an info message"})
  end

  test "clicking error pushes the error event, not info", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/examples/server-events")
    preview = find_live_child(view, "server-events-preview")

    render_click(preview, "error")

    assert_push_event(preview, "error", %{message: "This is an error message"})
    refute_push_event(preview, "info", %{})
  end

  test "the old flat route still works — stage 1b migrates it", %{conn: conn} do
    assert {:ok, _view, _html} = live(conn, ~p"/flash-sonner")
  end
end
