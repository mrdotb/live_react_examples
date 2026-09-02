defmodule LiveReactExamplesWeb.Examples.EventsLiveTest do
  use LiveReactExamplesWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "the example page renders with the preview tab by default", %{conn: conn} do
    conn = get(conn, ~p"/examples/events")
    html = html_response(conn, 200)

    assert html =~ "Event Handling"
    assert html =~ ~s(data-name="examples/Events")
  end

  test "pushEvent from the component reaches handle_event and the new item comes back as a prop",
       %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/examples/events")

    preview = find_live_child(view, "events-preview")
    assert LiveReact.Test.get_react(preview, name: "examples/Events").props["items"] == []

    html = render_hook(preview, "add_item", %{"body" => "hello from the test"})

    # Not just asserting the event didn't crash: prove the server-held list
    # actually grew by one and carries the pushed body, via the props diff
    # LiveReact sends back — the same technique counter_live_test.exs uses.
    diff = LiveReact.Test.get_react(html, name: "examples/Events").props_diff
    assert [["add", "/items/0", %{"body" => "hello from the test"} = item]] = diff
    assert is_integer(item["id"])
  end
end
