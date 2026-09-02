defmodule LiveReactExamplesWeb.Examples.LazyPreview do
  @moduledoc """
  A React component rendered from an ordinary controller-rendered page. There
  is no LiveView and no socket here. This module's source is displayed on the
  example page.
  """
  use Phoenix.Component

  import LiveReact, only: [react: 1]

  def preview(assigns) do
    ~H"""
    <.react name="examples/Lazy" />
    """
  end
end
