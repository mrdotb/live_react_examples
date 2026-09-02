defmodule LiveReactExamplesWeb.Examples.LazyLive do
  use LiveReactExamplesWeb.Examples.ExamplePage, id: "lazy"

  alias LiveReactExamplesWeb.Examples.LazyPreview

  def render(assigns) do
    ~H"""
    <.example_page {example_assigns(assigns)}>
      <:preview>
        <LazyPreview.preview />
      </:preview>

      <:concepts>
        <p>
          <code>React.lazy</code>
          wraps a dynamic <code>import()</code>, so the wrapped module is fetched as
          its own chunk only when it is first rendered, and <code>Suspense</code>
          renders a fallback while that chunk loads. Nothing about this is specific to
          LiveReact — it is ordinary React code splitting, running inside a
          Phoenix-rendered page.
        </p>
      </:concepts>

      <:how_it_works>
        <p>
          The build tool splits the lazily imported component into its own bundle at
          build time. In this demo the chunk loads too fast to see the fallback, but
          the network tab shows a separate request for it, made only once <code>Lazy</code>
          renders — not on first page load.
        </p>
      </:how_it_works>
    </.example_page>
    """
  end
end
