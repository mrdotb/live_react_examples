defmodule LiveReactExamplesWeb.Examples.HybridFormLiveTest do
  use LiveReactExamplesWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "the example page renders with the preview tab by default", %{conn: conn} do
    conn = get(conn, ~p"/examples/hybrid-form")
    html = html_response(conn, 200)

    assert html =~ "Hybrid Form"
    assert html =~ ~s(data-name="examples/HybridForm")
  end

  test "the react control starts at the form's own value, and a phx-change validate reaches handle_event",
       %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/examples/hybrid-form")
    preview = find_live_child(view, "hybrid-form-preview")

    react = LiveReact.Test.get_react(preview, name: "examples/HybridForm")
    assert react.props["value"] == [4000, 30000]
    assert react.props["inputName"] == "settings[delay_between]"

    # Not a pushEvent from the component: this is an ordinary phx-change on
    # the form, exactly what a native <input name="settings[delay_between]">
    # would send when the browser submits the slider's hidden inputs.
    html =
      render_change(preview, "validate", %{
        "settings" => %{"email" => "changed@example.com", "delay_between" => ["1000", "5000"]}
      })

    assert LiveReact.Test.get_react(html, name: "examples/HybridForm").props_diff ==
             [["replace", "/value", ["1000", "5000"]]]

    assert html =~ "changed@example.com"
  end
end
