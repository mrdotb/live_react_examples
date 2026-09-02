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
  code: `LiveReactExamplesWeb.Examples.CounterPreview` becomes
  `MyAppWeb.CounterLive`, the `examples/` component prefix is dropped, and the
  `@moduledoc` and `layout: false` that exist only for this site are stripped.
  """
  defmacro elixir_source(name) do
    path =
      Path.join([
        File.cwd!(),
        "lib/live_react_examples_web/examples",
        "#{Macro.underscore(name)}_preview.ex"
      ])

    contents =
      path
      |> File.read!()
      |> String.replace("LiveReactExamplesWeb.Examples.#{name}Preview", "MyAppWeb.#{name}Live")
      |> String.replace("LiveReactExamplesWeb", "MyAppWeb")
      |> String.replace(~s(name="examples/), ~s(name="))
      |> strip_moduledoc()
      |> String.replace(", layout: false", "")
      |> String.trim()

    quote do
      @external_resource unquote(path)
      unquote(contents)
    end
  end

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
    String.replace(source, ~r/\s*@moduledoc\s+"""(?:.*?)"""\R?/s, "\n")
  end
end
