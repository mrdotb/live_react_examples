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
    <.react name="examples/Link" socket={@socket} />
    """
  end
end
