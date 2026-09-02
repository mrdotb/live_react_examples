defmodule LiveReactExamplesWeb.Examples.LinkDemoLive do
  use LiveReactExamplesWeb.Examples.ExamplePage, id: "link-demo"

  alias LiveReactExamplesWeb.Examples.LinkDemoPreview

  def render(assigns) do
    ~H"""
    <.example_page {example_assigns(assigns)}>
      <:preview>
        <LinkDemoPreview.preview
          current_path={@current_path}
          mount_count={@mount_count}
          params_update_count={@params_update_count}
          socket={@socket}
        />
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

    mount_count = Process.get(:link_demo_mount_count, 0) + 1
    Process.put(:link_demo_mount_count, mount_count)

    {:ok, assign(socket, mount_count: mount_count, params_update_count: 0, current_path: "")}
  end

  def handle_params(params, uri, socket) do
    {:noreply, socket} = super(params, uri, socket)

    %{path: path} = URI.parse(uri)
    count = socket.assigns[:params_update_count] || 0

    {:noreply, assign(socket, current_path: path, params_update_count: count + 1)}
  end
end
