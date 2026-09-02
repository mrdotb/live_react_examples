defmodule LiveReactExamplesWeb.Examples.SSRPreview do
  @moduledoc """
  Minimal working SSR example. This module's source is displayed verbatim on
  the example page, so it deliberately contains no page chrome.
  """
  use LiveReactExamplesWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket, layout: false}
  end

  def render(assigns) do
    ~H"""
    <div class="flex gap-4">
      <.react ssr={true} name="examples/SSR" socket={@socket} text="Rendered on the server" />
      <.react ssr={false} name="examples/SSR" socket={@socket} text="Rendered only in the browser" />
    </div>
    """
  end
end
