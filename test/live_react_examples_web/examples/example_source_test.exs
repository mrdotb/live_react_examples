defmodule LiveReactExamplesWeb.Examples.ExampleSourceTest do
  @moduledoc """
  The point of embedding source at compile time is that what a visitor reads
  is provably what runs. These tests pin the rewriting so the displayed code
  stays copy-pasteable into someone else's app.
  """
  use ExUnit.Case, async: true

  require LiveReactExamplesWeb.Examples.ExampleSource, as: ExampleSource

  @elixir ExampleSource.elixir_source("Counter", :live, "counter")
  @react ExampleSource.react_source("Counter")
  @dead_elixir ExampleSource.elixir_source("Simple", :dead, "simple")
  @dead_elixir_dashed ExampleSource.elixir_source("SimpleProps", :dead, "simple-props")

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

  test "a :dead example is rewritten as a real PageHTML module, not a fictional LiveView" do
    # Code review (finding 3): showing `MyAppWeb.SimpleLive` with
    # `def preview(assigns)` under a tab labelled "LiveView" contradicted the
    # example's whole point — that no LiveView is involved. These pin the
    # rewrite so it can't regress silently.
    assert @dead_elixir =~ "MyAppWeb.PageHTML"
    assert @dead_elixir =~ "def simple(assigns) do"
    assert @dead_elixir =~ "use MyAppWeb, :html"

    refute @dead_elixir =~ "MyAppWeb.SimpleLive"
    refute @dead_elixir =~ "def preview"
    refute @dead_elixir =~ "use Phoenix.Component"
    refute @dead_elixir =~ "import LiveReact"
    refute @dead_elixir =~ "LiveReactExamplesWeb"

    assert {:ok, _ast} = Code.string_to_quoted(@dead_elixir)
  end

  test "a :dead example's dashed slug becomes an underscored function name" do
    assert @dead_elixir_dashed =~ "def simple_props(assigns) do"
    refute @dead_elixir_dashed =~ "def simple-props"
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
