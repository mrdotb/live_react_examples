defmodule LiveReactExamplesWeb.Examples.ContextPreview do
  @moduledoc """
  Minimal working Context example. This module's source is displayed
  verbatim on the example page, so it deliberately contains no page chrome.
  """
  use LiveReactExamplesWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :count, 10), layout: false}
  end

  def render(assigns) do
    ~H"""
    <.react name="examples/Context" count={@count} socket={@socket} />
    """
  end

  def handle_event("set_count", %{"value" => value}, socket) do
    {:noreply, assign(socket, :count, value)}
  end
end
