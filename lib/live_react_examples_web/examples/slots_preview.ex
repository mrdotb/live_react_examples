defmodule LiveReactExamplesWeb.Examples.SlotsPreview do
  @moduledoc """
  Minimal working Slots example. This module's source is displayed verbatim
  on the example page, so it deliberately contains no page chrome.
  """
  use LiveReactExamplesWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :count, 0), layout: false}
  end

  def render(assigns) do
    ~H"""
    <.react name="examples/Slots" count={@count} socket={@socket}>
      <.button phx-click="set_count" phx-value-value={@count + 1}>
        Increment from HEEx
      </.button>
    </.react>
    """
  end

  def handle_event("set_count", %{"value" => value}, socket) do
    {:noreply, assign(socket, :count, String.to_integer(value))}
  end
end
