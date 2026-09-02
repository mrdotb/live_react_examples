defmodule LiveReactExamplesWeb.Examples.CounterPreview do
  @moduledoc """
  Minimal working Counter. This module's source is displayed verbatim on the
  example page, so it deliberately contains no page chrome.
  """
  use LiveReactExamplesWeb, :live_view

  def mount(_params, _session, socket) do
    socket = detach_hook(socket, :active_tab, :handle_params)
    {:ok, assign(socket, :count, 0), layout: false}
  end

  def render(assigns) do
    ~H"""
    <.react name="examples/Counter" count={@count} socket={@socket} />
    """
  end

  def handle_event("set_count", %{"value" => value}, socket) do
    {:noreply, assign(socket, :count, value)}
  end
end
