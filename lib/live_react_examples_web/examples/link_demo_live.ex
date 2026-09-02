defmodule LiveReactExamplesWeb.Examples.LinkDemoLive do
  use LiveReactExamplesWeb.Examples.ExamplePage, id: "link-demo"

  # Not `live_render`'d, unlike every other `:live` example's preview:
  # `patch`/`navigate` only work on a LiveView mounted directly by the
  # router (a nested child raises "cannot push_patch/2 ... because the
  # given path does not point to the current root view"), so the mount and
  # params tracking this example exists to show has to run on this module,
  # the real router-mounted view — not on a separate child process.
  #
  # `LinkDemoPreview` still holds the actual logic, and it still actually
  # runs: `mount/3` and `handle_params/3` below call straight into its
  # same-named functions rather than duplicating them, so the code the
  # LiveView tab displays is provably the code executing on every request,
  # just invoked directly instead of dispatched to a separate process.
  alias LiveReactExamplesWeb.Examples.LinkDemoPreview

  def render(assigns) do
    ~H"""
    <.example_page {example_assigns(assigns)}>
      <:preview>
        {LinkDemoPreview.render(assigns)}
      </:preview>

      <:concepts>
        <p>
          <code>patch</code>
          and <code>navigate</code>
          both keep the browser on the same
          page without a full reload, but they do different things to the
          LiveView process underneath: patch calls <code>handle_params/3</code>
          on the LiveView that's already running; navigate mounts a brand new
          one, in the same connection.
        </p>
      </:concepts>

      <:how_it_works>
        <p>
          <code>mount_count</code> is stored in the process dictionary, not in
          an assign, specifically so it survives a remount — every route in
          this app's router lives in the single default (unnamed) live
          session, so <code>navigate</code> reuses the same BEAM process even
          though it calls <code>mount/3</code> again from scratch.
        </p>
        <p>
          Click "patch": the URL changes, <code>params_update_count</code>
          goes up, <code>mount_count</code>
          does not — same process, same
          mount, only <code>handle_params/3</code>
          ran again. Click "navigate": <code>mount_count</code>
          goes up too — a fresh LiveView, reusing the
          connection but not the state.
        </p>
      </:how_it_works>
    </.example_page>
    """
  end

  def mount(params, session, socket) do
    {:ok, socket} = super(params, session, socket)
    LinkDemoPreview.mount(params, session, socket)
  end

  def handle_params(params, uri, socket) do
    {:noreply, socket} = super(params, uri, socket)
    LinkDemoPreview.handle_params(params, uri, socket)
  end
end
