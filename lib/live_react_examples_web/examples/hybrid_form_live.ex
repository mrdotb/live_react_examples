defmodule LiveReactExamplesWeb.Examples.HybridFormLive do
  use LiveReactExamplesWeb.Examples.ExamplePage, id: "hybrid-form"

  def render(assigns) do
    ~H"""
    <.example_page {example_assigns(assigns)}>
      <:preview>
        {live_render(@socket, LiveReactExamplesWeb.Examples.HybridFormPreview,
          id: "hybrid-form-preview"
        )}
      </:preview>

      <:concepts>
        <p>
          A React component can sit inside an ordinary <code>&lt;.simple_form&gt;</code>
          alongside HEEx inputs, as long as it renders a field named the way
          <code>Phoenix.HTML.Form</code>
          expects. It doesn't need <code>pushEvent</code>
          at all — the field's value reaches <code>phx-change</code>
          the same
          way any native input's would.
        </p>
      </:concepts>

      <:how_it_works>
        <p>
          The slider passes <code>inputName="settings[delay_between]"</code>
          straight through to Radix's <code>name</code>
          prop, which renders
          hidden inputs under that name for each thumb. The browser submits
          them like any other form field, so <code>phx-change="validate"</code>
          fires exactly as it would for a native <code>&lt;input&gt;</code>.
        </p>
        <p>
          The component's own dragging state — the thumb positions mid-drag —
          lives in <code>useState</code> and never touches the server; only a
          real change event submits a value, same as a native range input.
        </p>
      </:how_it_works>
    </.example_page>
    """
  end
end
