defmodule LiveReactExamplesWeb.Examples.EventsPreview do
  @moduledoc """
  Minimal working Events example. This module's source is displayed verbatim
  on the example page, so it deliberately contains no page chrome.
  """
  use LiveReactExamplesWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :items, []), layout: false}
  end

  def render(assigns) do
    ~H"""
    <.react name="examples/Events" items={@items} socket={@socket} />
    """
  end

  def handle_event("add_item", %{"body" => body}, socket) do
    item = %{id: System.unique_integer([:positive]), body: body}
    {:noreply, assign(socket, :items, socket.assigns.items ++ [item])}
  end
end
