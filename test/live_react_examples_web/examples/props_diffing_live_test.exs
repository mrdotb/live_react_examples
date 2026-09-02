defmodule LiveReactExamplesWeb.Examples.PropsDiffingLiveTest do
  @moduledoc """
  Props diffing is the headline 2.0 change and is invisible by design, so
  this example exists to make it observable. These assertions read the
  actual wire-level patch LiveReact computed for each instance separately
  (via `LiveReact.Test.get_react/2`, addressed by the per-instance id
  LiveReact assigns automatically — see `ssr_live_test.exs` for the same
  idiom): a diffed component must receive a patch naming the one path that
  changed, and an undiffed one must receive no patch at all. An assertion
  that both instances would satisfy identically, diffing on or off, would
  defeat the entire point of this example.
  """
  use LiveReactExamplesWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "the page renders both instances", %{conn: conn} do
    html = conn |> get(~p"/examples/props-diffing") |> html_response(200)

    assert html =~ "props-diffing-preview"
    assert html =~ ~s(data-name="examples/PropsDiffing")
  end

  test "the component receives no server-computed byte figures", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/examples/props-diffing")
    preview = find_live_child(view, "props-diffing-preview")
    html = render(preview)

    # The byte counts shown on the page must come from measuring the real
    # `data-props`/`data-props-diff` attributes client-side, not from a
    # server-side reconstruction smuggled in as a prop. If either key
    # reappears here, the page is fabricating numbers again.
    for id <- ["examples/PropsDiffing-1", "examples/PropsDiffing-2"] do
      props = LiveReact.Test.get_react(html, id: id).props
      refute Map.has_key?(props, "patch_bytes")
      refute Map.has_key?(props, "full_bytes")
    end
  end

  test "the diffed instance uses diff mode and the other does not", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/examples/props-diffing")
    preview = find_live_child(view, "props-diffing-preview")
    html = render(preview)

    # LiveReact numbers same-name instances "examples/PropsDiffing-1",
    # "examples/PropsDiffing-2", … in render order (see ssr_live_test.exs).
    diffed = LiveReact.Test.get_react(html, id: "examples/PropsDiffing-1")
    undiffed = LiveReact.Test.get_react(html, id: "examples/PropsDiffing-2")

    assert diffed.use_diff
    refute undiffed.use_diff
  end

  test "changing one field sends a patch naming the counter path to the diffed instance only",
       %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/examples/props-diffing")
    preview = find_live_child(view, "props-diffing-preview")

    render_hook(preview, "touch_one_field", %{})
    html = render(preview)

    diffed = LiveReact.Test.get_react(html, id: "examples/PropsDiffing-1")
    undiffed = LiveReact.Test.get_react(html, id: "examples/PropsDiffing-2")

    # The diffed instance's patch touches only the field that changed. If
    # diffing were silently disabled (e.g. `diff={true}` dropped, or the
    # whole payload resent as a "replace the top-level key" patch instead
    # of a real sub-diff) this path would be "/payload" instead of
    # "/payload/counter", and this assertion would catch it.
    assert [["replace", path, 1]] = diffed.props_diff
    assert path == "/payload/counter"

    # The undiffed instance computed no patch at all: `diff={false}` means
    # it resends the whole payload as a fresh `data-props` snapshot on
    # every update instead. If diffing were silently applied to it too,
    # this would fail.
    assert undiffed.props_diff == []
  end
end
