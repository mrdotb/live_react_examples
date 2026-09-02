defmodule LiveReactExamplesWeb.Examples.SSRLive do
  use LiveReactExamplesWeb.Examples.ExamplePage, id: "ssr"

  def render(assigns) do
    ~H"""
    <.example_page {example_assigns(assigns)}>
      <:preview>
        {live_render(@socket, LiveReactExamplesWeb.Examples.SSRPreview, id: "ssr-preview")}
      </:preview>

      <:concepts>
        <p>
          The same component is rendered twice here, once with <code>{"ssr={true}"}</code>
          and once with <code>{"ssr={false}"}</code>. Everything
          else about them is identical — the contrast is the whole point.
        </p>
      </:concepts>

      <:how_it_works>
        <p>
          With <code>{"ssr={true}"}</code> (the default), the server renders the
          component to HTML on the first response, so its content is present
          before any JavaScript runs and visible to a client with JS
          disabled or slow to load. React then hydrates that markup in the
          browser.
        </p>
        <p>
          With <code>{"ssr={false}"}</code>, the server sends only an empty
          placeholder; the component exists nowhere until React mounts it in
          the browser. Reach for this for anything that only makes sense
          client-side — a component that touches <code>window</code>,
          a
          third-party widget with no server-safe render path, or anything
          where paying for SSR buys nothing.
        </p>
      </:how_it_works>
    </.example_page>
    """
  end
end
