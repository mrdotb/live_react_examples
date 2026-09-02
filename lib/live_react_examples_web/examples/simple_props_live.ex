defmodule LiveReactExamplesWeb.Examples.SimplePropsLive do
  use LiveReactExamplesWeb.Examples.ExamplePage, id: "simple-props"

  alias LiveReactExamplesWeb.Examples.SimplePropsPreview

  def render(assigns) do
    ~H"""
    <.example_page {example_assigns(assigns)}>
      <:preview>
        <SimplePropsPreview.preview />
      </:preview>

      <:concepts>
        <p>
          Any assign passed to <code>react/1</code>
          becomes a prop, including plain Elixir maps — they cross to JavaScript as
          JSON, so <code>{"%{name: \"mrdotb\", age: 30}"}</code>
          arrives in React as <code>{"{name, age}"}</code>.
        </p>
      </:concepts>

      <:how_it_works>
        <p>
          The template hard-codes a map and hands it straight to the component. There
          is no state, no event and no socket — this example is only about values
          arriving as props from wherever the template is rendered.
        </p>
      </:how_it_works>
    </.example_page>
    """
  end
end
