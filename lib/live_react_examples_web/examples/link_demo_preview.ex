defmodule LiveReactExamplesWeb.Examples.LinkDemoPreview do
  @moduledoc """
  Minimal working Link Demo example. This module's source is displayed
  verbatim on the example page, so it deliberately contains no page chrome.
  """
  use LiveReactExamplesWeb, :live_view

  def mount(_params, _session, socket) do
    # Stored in the process dictionary, not an assign, specifically so it
    # survives a remount: every route in this app's router lives in the
    # single default (unnamed) live session, so `navigate` reuses the same
    # BEAM process even though it calls `mount/3` again from scratch.
    mount_count = Process.get(:link_demo_mount_count, 0) + 1
    Process.put(:link_demo_mount_count, mount_count)

    socket = assign(socket, mount_count: mount_count, params_update_count: 0, current_path: "")
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <.react
      name="examples/LinkDemo"
      currentPath={@current_path}
      mountCount={@mount_count}
      paramsUpdateCount={@params_update_count}
      socket={@socket}
    />
    """
  end

  def handle_params(_params, uri, socket) do
    %{path: path} = URI.parse(uri)

    socket =
      assign(socket,
        current_path: path,
        params_update_count: socket.assigns.params_update_count + 1
      )

    {:noreply, socket}
  end
end
