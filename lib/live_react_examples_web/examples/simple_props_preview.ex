defmodule LiveReactExamplesWeb.Examples.SimplePropsPreview do
  @moduledoc """
  Passes a plain Elixir map into React as a prop. There is no LiveView and no
  socket here. This module's source is displayed on the example page.
  """
  use Phoenix.Component

  import LiveReact, only: [react: 1]

  def preview(assigns) do
    ~H"""
    <.react name="examples/SimpleProps" user={%{name: "mrdotb", age: 30}} />
    """
  end
end
