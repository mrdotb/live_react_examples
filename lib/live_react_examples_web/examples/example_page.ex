defmodule LiveReactExamplesWeb.Examples.ExamplePage do
  @moduledoc """
  Injects everything an example page needs except its content.

  Without this, each of the 14 example modules repeats the same `mount/3`,
  the same `handle_params/3` tab fallback, the same three module attributes
  and the same imports — duplicated logic, not just duplicated declarations.
  The tab fallback in particular is behaviour worth testing once rather than
  fourteen times.

  A using module supplies only `render/1`, with a `:preview` slot and its
  prose:

      defmodule MyExampleLive do
        use LiveReactExamplesWeb.Examples.ExamplePage, id: "counter"

        def render(assigns) do
          ~H\"\"\"
          <.example_page {example_assigns(assigns)}>
            <:preview>…</:preview>
            <:concepts>…</:concepts>
            <:how_it_works>…</:how_it_works>
          </.example_page>
          \"\"\"
        end
      end
  """

  defmacro __using__(opts) do
    id = Keyword.fetch!(opts, :id)

    # Resolved at compile time: an unknown slug is a build failure, not a 404.
    {:ok, example} = LiveReactExamples.Examples.fetch(id)
    name = example.module

    quote do
      use LiveReactExamplesWeb, :live_view

      require LiveReactExamplesWeb.Examples.ExampleSource, as: ExampleSource

      import LiveReactExamplesWeb.Examples.ExampleComponents

      @example unquote(Macro.escape(example))
      @elixir_source ExampleSource.elixir_source(
                       unquote(name),
                       unquote(example.kind),
                       unquote(id)
                     )
      @react_source ExampleSource.react_source(unquote(name))

      @impl Phoenix.LiveView
      def mount(_params, _session, socket) do
        {:ok,
         assign(socket,
           page_title: "#{@example.title} · LiveReact examples",
           example: @example,
           elixir_source: @elixir_source,
           react_source: @react_source
         )}
      end

      @impl Phoenix.LiveView
      def handle_params(params, _uri, socket) do
        tab = if params["tab"] in tabs(), do: params["tab"], else: "preview"
        {:noreply, assign(socket, :tab, tab)}
      end

      defoverridable mount: 3, handle_params: 3

      @doc false
      def example_assigns(assigns) do
        Map.take(assigns, [:example, :tab, :elixir_source, :react_source])
      end
    end
  end
end
