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

    # `data-props` carries the raw `code`/`filename` strings on every render,
    # SSR or not -- so `html =~ "hello.ex"` / "hello" / "world" would pass
    # identically against a component that never server-rendered at all
    # (proven: swap `ssr={true}` above for `ssr={false}` and every one of
    # those substring checks still passes). Assert on evidence that only
    # exists once SSR has actually run instead: LiveReact.Test's own `ssr`
    # flag, and the highlight.js markup, which appears only in the
    # server-rendered inner HTML and never in the JSON-encoded props.
    react = LiveReact.Test.get_react(html, name: "examples/CodeBlock")

    assert react.ssr == true
    assert html =~ ~s(<span class="hljs-keyword">def</span>)
    assert html =~ ~s(<span class="hljs-title">hello</span>)
    assert html =~ ~s(<span class="hljs-symbol">:world</span>)
  end

  # Unlike the test above, this one never touches raw HTML substrings: it
  # decodes `data-props` via `LiveReact.Test.get_react/2` and compares each
  # key for exact equality, so it can't pass against mismatched or missing
  # content the way a substring check against markup that always contains
  # the literal prop values could. `ssr` is left at its `:test` default
  # (`false`, see config/test.exs), so this also exercises the client-only
  # path -- no SSR runs, and the test doesn't claim any.
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
