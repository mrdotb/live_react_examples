defmodule LiveReactExamplesWeb.Examples.ContextLiveTest do
  use LiveReactExamplesWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "the example page renders with the preview tab by default", %{conn: conn} do
    conn = get(conn, ~p"/examples/context")
    html = html_response(conn, 200)

    assert html =~ "React Context"
    assert html =~ ~s(data-name="examples/Context")
  end

  test "the react tab shows tsx source and is labelled as tsx", %{conn: conn} do
    html = conn |> get(~p"/examples/context?tab=react") |> html_response(200)

    assert html =~ "createContext"
    assert html =~ "Context.tsx"
    # `language` is a prop passed to <.react>, serialized into `data-props`
    # (with `^` in place of `"`), not a literal HTML attribute — matching the
    # pattern already proven correct for the typescript example in Task 4.
    assert html =~ "^language^:^tsx^"
  end

  test "the preview starts at the server-owned count and pushEvent reaches handle_event", %{
    conn: conn
  } do
    {:ok, view, _html} = live(conn, ~p"/examples/context")

    preview = find_live_child(view, "context-preview")
    assert LiveReact.Test.get_react(preview, name: "examples/Context").props["count"] == 10

    html = render_hook(preview, "set_count", %{"value" => 25})

    assert LiveReact.Test.get_react(html, name: "examples/Context").props_diff ==
             [["replace", "/count", 25]]
  end
end
