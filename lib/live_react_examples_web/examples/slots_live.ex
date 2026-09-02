defmodule LiveReactExamplesWeb.Examples.SlotsLive do
  use LiveReactExamplesWeb.Examples.ExamplePage, id: "slots"

  def render(assigns) do
    ~H"""
    <.example_page {example_assigns(assigns)}>
      <:preview>
        {live_render(@socket, LiveReactExamplesWeb.Examples.SlotsPreview, id: "slots-preview")}
      </:preview>

      <:concepts>
        <p>
          The default slot passed to <code>&lt;.react&gt;</code>
          becomes <code>children</code>
          in React. It is ordinary HEEx — a <code>.button</code>
          with a <code>phx-click</code>, in this case — rendered by the LiveView and
          handed to React as markup, not as data.
        </p>
      </:concepts>

      <:how_it_works>
        <p>
          The button inside the slot is not wired through <code>pushEvent</code>
          at all — it's a plain <code>phx-click</code>
          that Phoenix handles the
          same way it would outside a React tree. React only renders <code>children</code>; it has no idea the markup came from HEEx.
        </p>
        <p>
          This is the tool for mixing an existing LiveView component — a
          modal, a table row, anything already built in HEEx — into a page
          that's otherwise composed with React, without rewriting it.
        </p>
      </:how_it_works>
    </.example_page>
    """
  end
end
