defmodule LiveReactExamplesWeb.Examples.LinkLiveTest do
  use LiveReactExamplesWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "the example page renders with the preview tab by default", %{conn: conn} do
    conn = get(conn, ~p"/examples/link")
    html = html_response(conn, 200)

    assert html =~ "Link"
    assert html =~ ~s(data-name="examples/Link")
  end

  test "the preview mounts a single Link component with no routing props", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/examples/link")
    preview = find_live_child(view, "link-preview")
    html = render(preview)

    # Code review (finding 4): href/navigate used to be passed in from HEEx
    # as props on two separate `<.react name="examples/Link">` calls — the
    # unusual way to use `Link`, and it left the React tab with nothing of
    # its own to show. Now the component takes its targets from its own
    # JSX, so exactly one instance mounts, carrying no routing props at all.
    react = LiveReact.Test.get_react(html, name: "examples/Link")
    refute Map.has_key?(react.props, "href")
    refute Map.has_key?(react.props, "navigate")

    assert_raise RuntimeError, fn ->
      LiveReact.Test.get_react(html, id: "examples/Link-2")
    end
  end

  test "the react tab shows real JSX usage of Link, not a bare re-export", %{conn: conn} do
    html = conn |> get(~p"/examples/link?tab=react") |> html_response(200)

    # Code review (finding 4): the file used to be a three-line
    # `export { Link };` re-export, which taught nothing about how `Link`
    # is actually used from JSX. Assert on content only real usage would
    # contain — a component definition and both navigation modes wired to
    # real paths.
    assert html =~ "function LinkExample"
    assert html =~ "examples/counter"
    assert html =~ "examples/context"
    assert html =~ "navigate"
  end
end
