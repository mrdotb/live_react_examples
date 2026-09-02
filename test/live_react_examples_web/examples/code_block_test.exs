defmodule LiveReactExamplesWeb.Examples.CodeBlockTest do
  @moduledoc """
  CodeBlock is rendered through LiveReact's SSR so that source appears in the
  initial HTML — for search engines, for no-JS readers, and because it makes
  every example page a live demonstration of the library.
  """
  use LiveReactExamplesWeb.ConnCase, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest
  import LiveReact, only: [react: 1]

  # Rendered via `rendered_to_string(~H"...")` rather than
  # `render_component(&LiveReact.react/1, ...)`. Phoenix's `render_component/2`
  # unconditionally sets `assigns.__changed__` to `%{}` (not `nil`) for a
  # function component -- see `Phoenix.LiveViewTest.__render_component__/4`.
  # LiveReact's `render/1` treats `__changed__ == nil` as the signal for an
  # initial, dead render (that's how it decides whether to run SSR and
  # whether props diffing has anything to diff against); a non-nil empty map
  # reads as "a connected update where nothing changed", so SSR never fires
  # and diffed props come back empty regardless of a per-component `ssr: true`
  # override. `rendered_to_string/1` over a bare `~H` template does not go
  # through that helper, so `__changed__` stays `nil` and both SSR and props
  # behave as they do from a real dead render -- the same reason Task 4's
  # `ExampleComponentsTest` renders `.example_page` the same way.
  test "server-renders the code into the initial HTML" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.react
        name="examples/CodeBlock"
        code="def hello, do: :world"
        language="elixir"
        filename="hello.ex"
        side="server"
        ssr={true}
      />
      """)

    assert html =~ "hello.ex"
    assert html =~ "hello"
    assert html =~ "world"
  end

  test "the props reach the component" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.react
        name="examples/CodeBlock"
        code="const a = 1"
        language="jsx"
        filename="thing.jsx"
        side="client"
      />
      """)

    props = LiveReact.Test.get_react(html, name: "examples/CodeBlock").props

    assert props["code"] == "const a = 1"
    assert props["language"] == "jsx"
    assert props["filename"] == "thing.jsx"
    assert props["side"] == "client"
  end
end
