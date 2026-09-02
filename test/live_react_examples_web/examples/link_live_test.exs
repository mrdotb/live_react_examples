defmodule LiveReactExamplesWeb.Examples.LinkLiveTest do
  use LiveReactExamplesWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "the example page renders with the preview tab by default", %{conn: conn} do
    conn = get(conn, ~p"/examples/link")
    html = html_response(conn, 200)

    assert html =~ "Link"
    assert html =~ ~s(data-name="examples/Link")
  end

  test "one Link uses href, the other uses navigate — not the same prop twice", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/examples/link")
    preview = find_live_child(view, "link-preview")
    html = render(preview)

    react_1 = LiveReact.Test.get_react(html, id: "examples/Link-1")
    react_2 = LiveReact.Test.get_react(html, id: "examples/Link-2")

    assert react_1.props["href"] == "/examples/counter"
    refute Map.has_key?(react_1.props, "navigate")

    assert react_2.props["navigate"] == "/examples/context"
    refute Map.has_key?(react_2.props, "href")
  end

  test "the old flat route still works — stage 1b migrates it", %{conn: conn} do
    assert {:ok, _view, _html} = live(conn, ~p"/link-usage")
  end
end
