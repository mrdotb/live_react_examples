defmodule LiveReactExamplesWeb.Examples.ServerEventsPreview do
  @moduledoc """
  Minimal working Server Events example. This module's source is displayed
  verbatim on the example page, so it deliberately contains no page chrome.
  """
  use LiveReactExamplesWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket, layout: false}
  end

  def render(assigns) do
    ~H"""
    <div class="flex gap-2">
      <.button phx-click="info">info</.button>
      <.button phx-click="error">error</.button>
    </div>
    <.react name="examples/ServerEvents" socket={@socket} />
    """
  end

  def handle_event("info", _params, socket) do
    {:noreply, push_event(socket, "info", %{message: "This is an info message"})}
  end

  def handle_event("error", _params, socket) do
    {:noreply, push_event(socket, "error", %{message: "This is an error message"})}
  end
end
