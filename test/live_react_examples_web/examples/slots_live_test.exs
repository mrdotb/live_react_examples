defmodule LiveReactExamplesWeb.Examples.SlotsLiveTest do
  use LiveReactExamplesWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "the example page renders with the preview tab by default", %{conn: conn} do
    conn = get(conn, ~p"/examples/slots")
    html = html_response(conn, 200)

    assert html =~ "Slots"
    assert html =~ ~s(data-name="examples/Slots")
  end

  test "the react tab is labelled tsx", %{conn: conn} do
    html = conn |> get(~p"/examples/slots?tab=react") |> html_response(200)

    assert html =~ "Slots.tsx"
    assert html =~ "^language^:^tsx^"
  end

  test "the HEEx button rendered inside the slot actually reaches handle_event, not pushEvent",
       %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/examples/slots")
    preview = find_live_child(view, "slots-preview")

    react = LiveReact.Test.get_react(preview, name: "examples/Slots")
    assert react.props["count"] == 0

    # Prove the slot actually carries the HEEx markup, complete with its own
    # phx-click wiring — not merely that a button with this text exists
    # somewhere in the surrounding page chrome. `data-slots` is base64'd
    # markup handed to React for the client-side hook to mount; there is no
    # tracked DOM node for `element/2` + `render_click/1` to find until that
    # hook runs, so a real browser click can't be simulated here — instead
    # assert the exact HEEx the slot carries, phx-click and its value both.
    slot_html = react.slots |> Map.values() |> Enum.join()
    assert slot_html =~ "Increment from HEEx"
    assert slot_html =~ ~s(phx-click="set_count")
    assert slot_html =~ ~s(phx-value-value="1")

    # That button, once clicked in a real browser, sends exactly this event
    # and payload to the LiveView — prove handle_event/3 does the right
    # thing with it.
    html = render_hook(preview, "set_count", %{"value" => "1"})

    assert LiveReact.Test.get_react(html, name: "examples/Slots").props_diff ==
             [["replace", "/count", 1]]
  end
end
