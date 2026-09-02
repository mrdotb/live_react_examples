defmodule LiveReactExamplesWeb.Examples.LinkDemoPreview do
  @moduledoc """
  Renders the LinkDemo component against the page's own socket, rather than
  as a nested `live_render`'d child. `patch`/`navigate` only work on a
  LiveView mounted directly by the router — a child raises
  "cannot push_patch/2 ... because the given path does not point to the
  current root view" — so the mount and params tracking this example exists
  to show has to live on the page's own LiveView, not in here.

  This module's source is displayed verbatim on the example page.
  """
  use Phoenix.Component

  import LiveReact, only: [react: 1]

  attr :current_path, :string, required: true
  attr :mount_count, :integer, required: true
  attr :params_update_count, :integer, required: true
  attr :socket, :map, required: true

  def preview(assigns) do
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
end
