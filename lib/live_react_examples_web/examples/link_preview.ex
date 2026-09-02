defmodule LiveReactExamplesWeb.Examples.LinkPreview do
  @moduledoc """
  Minimal working Link example. This module's source is displayed verbatim
  on the example page, so it deliberately contains no page chrome.
  """
  use LiveReactExamplesWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket, layout: false}
  end

  def render(assigns) do
    ~H"""
    <div class="flex gap-3">
      <.react
        name="examples/Link"
        href="/examples/counter"
        className="rounded-md border px-3 py-1"
        socket={@socket}
      >
        href — full page reload
      </.react>

      <.react
        name="examples/Link"
        navigate="/examples/context"
        className="rounded-md border px-3 py-1"
        socket={@socket}
      >
        navigate — same process, no reload
      </.react>
    </div>
    """
  end
end
