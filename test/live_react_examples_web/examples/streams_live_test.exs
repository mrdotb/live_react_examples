defmodule LiveReactExamplesWeb.Examples.StreamsLiveTest do
  use LiveReactExamplesWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "the example page renders with the preview tab by default", %{conn: conn} do
    conn = get(conn, ~p"/examples/streams")
    html = html_response(conn, 200)

    assert html =~ "Phoenix Streams"
    assert html =~ ~s(data-name="examples/Streams")
  end

  test "a stream/4 assign arrives as a stream diff, and every item carries __dom_id", %{
    conn: conn
  } do
    {:ok, view, _html} = live(conn, ~p"/examples/streams")
    preview = find_live_child(view, "streams-preview")

    react = LiveReact.Test.get_react(preview, name: "examples/Streams")

    # Not a plain prop: `stream/4` assigns are routed to `data-streams-diff`,
    # not `data-props`/`data-props-diff` — the thing this example exists to
    # show. If `messages` were an ordinary assign it would show up in
    # `react.props["messages"]` instead, which it deliberately does not.
    refute Map.has_key?(react.props, "messages")

    [_reset, upsert] = react.streams_diff
    assert ["upsert", "/messages/-", item] = upsert
    assert Map.has_key?(item, "__dom_id")
    assert item["__dom_id"] == "messages-0"
  end

  test "add appends a new item with its own __dom_id via pushEvent -> handle_event", %{
    conn: conn
  } do
    {:ok, view, _html} = live(conn, ~p"/examples/streams")
    preview = find_live_child(view, "streams-preview")

    html = render_hook(preview, "add", %{"text" => "hello from the test"})
    diff = LiveReact.Test.get_react(html, name: "examples/Streams").streams_diff

    assert [["upsert", "/messages/-", item]] = diff
    assert item["text"] == "hello from the test"
    assert item["__dom_id"] == "messages-1"
  end

  test "replace_all resets the stream rather than appending", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/examples/streams")
    preview = find_live_child(view, "streams-preview")

    html = render_hook(preview, "replace_all", %{})
    diff = LiveReact.Test.get_react(html, name: "examples/Streams").streams_diff

    # A reset ships an explicit "replace" with an empty list before the new
    # items — proving this is a full replacement, not an insert on top of
    # the existing conversation.
    assert [["replace", "/messages", []] | inserts] = diff
    assert length(inserts) == 3
  end
end
