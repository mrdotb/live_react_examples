defmodule LiveReactExamplesWeb.Examples.ExampleSourceTest do
  @moduledoc """
  The point of embedding source at compile time is that what a visitor reads
  is provably what runs. These tests pin the rewriting so the displayed code
  stays copy-pasteable into someone else's app.
  """
  use ExUnit.Case, async: true

  require LiveReactExamplesWeb.Examples.ExampleSource, as: ExampleSource

  @elixir ExampleSource.elixir_source("Counter")
  @react ExampleSource.react_source("Counter")

  test "the elixir source is rewritten to look like a generic app" do
    refute @elixir =~ "LiveReactExamplesWeb"
    refute @elixir =~ "Preview"
    assert @elixir =~ "MyAppWeb.CounterLive"
  end

  test "site-only noise is stripped" do
    refute @elixir =~ "@moduledoc"
    refute @elixir =~ "layout: false"
    refute @elixir =~ "examples/Counter"
    assert @elixir =~ ~s(name="Counter")
  end

  test "the rewritten elixir source is still valid elixir" do
    assert {:ok, _ast} = Code.string_to_quoted(@elixir)
  end

  test "the elixir source is the real module, not a stub" do
    assert @elixir =~ "def mount"
    assert @elixir =~ "def render"
    assert @elixir =~ "handle_event"
  end

  test "the react source is returned verbatim" do
    assert @react =~ "export function Counter"
    assert @react =~ "useLiveReact"
  end

  test "a missing example fails loudly at compile time" do
    assert_raise File.Error, fn ->
      Code.eval_string("""
      require LiveReactExamplesWeb.Examples.ExampleSource, as: ES
      ES.react_source("NoSuchComponent")
      """)
    end
  end

  test "strip_moduledoc removes only the moduledoc, not the code after it" do
    source = """
    defmodule Thing do
      @moduledoc \"\"\"
      Explanatory prose with a stray \"\"\" nowhere near.
      \"\"\"
      def keep_me, do: :ok
    end
    """

    stripped = LiveReactExamplesWeb.Examples.ExampleSource.strip_moduledoc(source)

    refute stripped =~ "Explanatory prose"
    assert stripped =~ "def keep_me"
    assert stripped =~ "defmodule Thing"
    assert {:ok, _ast} = Code.string_to_quoted(stripped)
  end
end
