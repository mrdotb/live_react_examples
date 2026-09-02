defmodule LiveReactExamplesWeb.Examples.AsyncLiveTest do
  @moduledoc """
  `assign_async/3` starts loading, then resolves to either `:ok` or
  `:error`. LiveReact ships an encoder for `Phoenix.LiveView.AsyncResult`
  itself, so the struct reaches React unchanged and these assertions read
  its `loading`/`ok`/`failed` fields straight out of the decoded prop (via
  `LiveReact.Test.get_react/2`) rather than substring-matching HTML. All
  three states must actually be reachable in a test, or the example cannot
  claim to demonstrate them.
  """
  use LiveReactExamplesWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "the page renders", %{conn: conn} do
    html = conn |> get(~p"/examples/async") |> html_response(200)

    assert html =~ "async-preview"
    assert html =~ ~s(data-name="examples/Async")
  end

  test "reaches loading, then ok, then failed", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/examples/async")
    preview = find_live_child(view, "async-preview")

    # The async task sleeps before resolving, so the very first connected
    # render — before render_async waits for anything — is caught mid
    # flight: loading is set and ok is not yet true. If assign_async's
    # loading state were skipped or collapsed into the result, this would
    # fail.
    loading = LiveReact.Test.get_react(html, name: "examples/Async").props["stats"]
    assert loading["loading"]
    refute loading["ok"]
    assert loading["result"] == nil

    # Wait for it to resolve, then confirm the ok state. The task sleeps
    # 400ms, longer than render_async's 100ms default, so give it room.
    html = render_async(preview, 1000)
    ok = LiveReact.Test.get_react(html, name: "examples/Async").props["stats"]
    assert ok["ok"] == true
    refute ok["loading"]
    assert ok["result"]["stars"] == 1234
    assert ok["result"]["downloads"] == 98_765

    # Trigger the failure path and wait for it to resolve too.
    render_click(preview, "fail")
    html = render_async(preview, 1000)
    failed = LiveReact.Test.get_react(html, name: "examples/Async").props["stats"]
    assert failed["failed"] == "the upstream service is unavailable"
    refute failed["loading"]
  end
end
