defmodule LiveReactExamplesWeb.Examples.TypescriptLive do
  use LiveReactExamplesWeb.Examples.ExamplePage, id: "typescript"

  alias LiveReactExamplesWeb.Examples.TypescriptPreview

  def render(assigns) do
    ~H"""
    <.example_page {example_assigns(assigns)}>
      <:preview>
        <TypescriptPreview.preview />
      </:preview>

      <:concepts>
        <p>
          A component can be written in <code>.tsx</code>
          instead of <code>.jsx</code>. LiveReact imports the type <code>LiveProps</code>
          from <code>live_react</code>, so props coming from the server carry types
          too, and a mismatched prop is caught by the type checker rather than at
          runtime.
        </p>
      </:concepts>

      <:how_it_works>
        <p>
          Vite transpiles <code>.tsx</code>
          the same way it transpiles <code>.jsx</code>
          — types are stripped at build
          time and never reach the browser. Nothing about registering or rendering the
          component changes; only the file extension and the type annotations do.
        </p>
      </:how_it_works>
    </.example_page>
    """
  end
end
