defmodule LiveReactExamplesWeb.Examples.EncoderLive do
  use LiveReactExamplesWeb.Examples.ExamplePage, id: "encoder"

  def render(assigns) do
    ~H"""
    <.example_page {example_assigns(assigns)}>
      <:preview>
        {live_render(@socket, LiveReactExamplesWeb.Examples.EncoderPreview, id: "encoder-preview")}
      </:preview>

      <:concepts>
        <p>
          LiveReact's default <code>LiveReact.Encoder</code>
          implementation for a plain struct sends every field.
          <code>{"@derive {LiveReact.Encoder, except: [:api_token]}"}</code>
          overrides that per struct, deciding once, in one place, what that struct is
          allowed to send — every call site that passes it as a prop gets the same
          guarantee, with nothing to remember or repeat.
        </p>
      </:concepts>

      <:how_it_works>
        <p>
          The component below renders exactly what it received — there is no
          filtering on the React side, and none in the preview's <code>render/1</code>
          either. The excepted field is absent from the serialised payload
          because the encoder never emits it, not because something downstream
          hides it. Open this page's source and search <code>data-props</code>
          — <code>api_token</code>
          isn't in there, and neither is its value.
        </p>
        <p>
          <code>except:</code>
          has a counterpart, <code>only:</code>, for the opposite shape: an allowlist
          instead of a denylist. Either way, the struct's definition is the one
          place this decision lives.
        </p>
      </:how_it_works>
    </.example_page>
    """
  end
end
