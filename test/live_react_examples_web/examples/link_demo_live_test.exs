defmodule LiveReactExamplesWeb.Examples.LinkDemoLiveTest do
  use LiveReactExamplesWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias LiveReactExamplesWeb.Examples.LinkDemoLive

  test "the example page renders with the preview tab by default", %{conn: conn} do
    conn = get(conn, ~p"/examples/link-demo")
    html = html_response(conn, 200)

    assert html =~ "Patch vs Navigate"
    assert html =~ ~s(data-name="examples/LinkDemo")
  end

  test "the liveview tab shows the real tracking, not an empty wrapper", %{conn: conn} do
    html = conn |> get(~p"/examples/link-demo?tab=liveview") |> html_response(200)

    # This is the whole point of the example: what patch/navigate do to the
    # LiveView underneath. If the displayed source were the thin wrapper
    # that used to live in link_demo_live.ex (a 15-line <.react> call with
    # no mount/handle_params override), none of this would be present —
    # exactly the gap code review caught. Mirrors
    # counter_live_test.exs's "the liveview tab shows real embedded source".
    assert html =~ "MyAppWeb.LinkDemoLive"
    assert html =~ "def mount"
    assert html =~ "def handle_params"
    assert html =~ "mount_count"
    assert html =~ "params_update_count"
    refute html =~ "LiveReactExamplesWeb"
  end

  test "patch is handled by the router-mounted LiveView and bumps params_update_count, not mount_count",
       %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/examples/link-demo")

    react = LiveReact.Test.get_react(view, name: "examples/LinkDemo")
    assert react.props["mountCount"] == 1
    assert react.props["paramsUpdateCount"] == 1

    # This is the real click's server-side effect: the Link component's
    # `patch` prop renders `data-phx-link="patch"`, which LiveView's client
    # turns into exactly this — a patch to the LiveView already running.
    html = render_patch(view, ~p"/examples/link-demo?visited=patch")

    # Not `.props`: LiveReact only sends a diff on update (see
    # `enable_props_diff`, documented on `LiveReact.Test` and already relied
    # on by counter_live_test.exs) — `data-props` stays at its initial value.
    diff = LiveReact.Test.get_react(html, name: "examples/LinkDemo").props_diff
    refute Enum.any?(diff, &match?(["replace", "/mountCount", _], &1))
    assert Enum.any?(diff, &match?(["replace", "/paramsUpdateCount", 2], &1))
    # The query changed but the path didn't, so `currentPath` (path-only)
    # correctly has nothing to report — proving it isn't wired is a
    # different failure mode than what this test targets.
    refute Enum.any?(diff, &match?(["replace", "/currentPath", _], &1))
  end

  # `mount_count` lives in the process dictionary specifically so it survives
  # a remount — but Phoenix.LiveViewTest.live/2 always spawns a fresh
  # LiveView process per call, the same way a real browser's `navigate`
  # reuses one process while a brand new page load does not. Proving what
  # actually happens across a `navigate` click therefore means calling the
  # real mount/3 and handle_params/3 directly, in this test process, the
  # same way a real browser socket would call them twice in the one process
  # underneath a navigate.
  test "mount/3 increments the process-dictionary counter across repeated mounts, unaffected by handle_params" do
    socket = %Phoenix.LiveView.Socket{}

    {:ok, socket} = LinkDemoLive.mount(%{}, %{}, socket)
    assert socket.assigns.mount_count == 1
    assert socket.assigns.params_update_count == 0

    {:noreply, socket} =
      LinkDemoLive.handle_params(%{}, "http://x/examples/link-demo", socket)

    assert socket.assigns.mount_count == 1
    assert socket.assigns.params_update_count == 1

    # A second mount — what `navigate` does underneath, in the same process.
    {:ok, socket} = LinkDemoLive.mount(%{}, %{}, socket)
    assert socket.assigns.mount_count == 2
    # A fresh mount starts params_update_count over.
    assert socket.assigns.params_update_count == 0
  end

  test "the old flat route still works — stage 1b migrates it", %{conn: conn} do
    assert {:ok, _view, _html} = live(conn, ~p"/link-demo")
  end
end
