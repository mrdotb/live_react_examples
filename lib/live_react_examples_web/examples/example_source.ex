defmodule LiveReactExamplesWeb.Examples.ExampleSource do
  @moduledoc """
  Reads example source off disk at compile time.

  This replaces fetching source from raw.githubusercontent.com at runtime,
  which broke silently when the examples app moved to its own repository and
  left every code tab showing an empty block. Reading at compile time means
  the code a visitor sees is provably the code that runs, needs no network,
  and appears in the server-rendered HTML.

  Both macros register the file as an `@external_resource`, so editing an
  example recompiles the page that displays it.

  The file is read in the macro's own body, not in the quoted code it
  returns, so a missing file raises `File.Error` immediately at expansion
  time — the same place `@external_resource` would otherwise fail if the
  macro is ever invoked outside a module.
  """

  @doc """
  The preview module's source, rewritten to look like ordinary application
  code.

  For a `:live` example, `LiveReactExamplesWeb.Examples.CounterPreview`
  becomes `MyAppWeb.CounterLive`; the `examples/` component prefix is
  dropped, and the `@moduledoc` and `layout: false` that exist only for
  this site are stripped.

  For a `:dead` example the rewrite goes further: these previews exist to
  show that no LiveView is involved, so displaying them under a fictional
  `MyAppWeb.SimpleLive` module with a `def preview(assigns)` function would
  contradict the point of the example. Instead the module becomes
  `MyAppWeb.PageHTML` — the function-component module a real dead view
  would live in — the function is renamed after the example's slug (e.g.
  `def simple(assigns)`), and `use Phoenix.Component` plus the explicit
  `import LiveReact, only: [react: 1]` (needed here only because this
  module isn't the real `PageHTML`) collapse into the single `use
  MyAppWeb, :html` a real `PageHTML` module carries, which already imports
  `LiveReact` in full.
  """
  defmacro elixir_source(name, kind, id) do
    path =
      Path.join([
        File.cwd!(),
        "lib/live_react_examples_web/examples",
        "#{Macro.underscore(name)}_preview.ex"
      ])

    module_rewrite = if kind == :dead, do: "MyAppWeb.PageHTML", else: "MyAppWeb.#{name}Live"

    contents =
      path
      |> File.read!()
      |> String.replace("LiveReactExamplesWeb.Examples.#{name}Preview", module_rewrite)
      |> String.replace("LiveReactExamplesWeb", "MyAppWeb")
      |> String.replace(~s(name="examples/), ~s(name="))
      |> strip_moduledoc()
      |> String.replace(", layout: false", "")
      |> rewrite_dead_view(kind, id)
      |> String.trim()

    quote do
      @external_resource unquote(path)
      unquote(contents)
    end
  end

  defp rewrite_dead_view(source, :dead, id) do
    source
    |> String.replace(
      "use Phoenix.Component\n\n  import LiveReact, only: [react: 1]",
      "use MyAppWeb, :html"
    )
    |> String.replace(
      "def preview(assigns) do",
      "def #{String.replace(id, "-", "_")}(assigns) do"
    )
  end

  defp rewrite_dead_view(source, _kind, _id), do: source

  @doc """
  The React component's source, verbatim. Tries `.jsx` then `.tsx`.
  """
  defmacro react_source(name) do
    dir = Path.join([File.cwd!(), "assets/react-components/examples"])
    jsx = Path.join(dir, "#{name}.jsx")
    tsx = Path.join(dir, "#{name}.tsx")
    path = if File.exists?(jsx), do: jsx, else: tsx

    contents = File.read!(path)

    quote do
      @external_resource unquote(path)
      unquote(contents)
    end
  end

  @doc """
  Removes a heredoc `@moduledoc` block.

  Kept as a function, not an inline regex in the macro, so it can be tested
  directly — an over-greedy match here silently truncates the displayed source.
  """
  def strip_moduledoc(source) do
    String.replace(source, ~r/\s*@moduledoc\s+"""\R.*?\R\s*"""\R?/s, "\n")
  end
end
