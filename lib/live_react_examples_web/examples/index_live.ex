defmodule LiveReactExamplesWeb.Examples.IndexLive do
  use LiveReactExamplesWeb, :live_view

  alias LiveReactExamples.Examples

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Examples · LiveReact examples",
       categories: Examples.by_category()
     )}
  end

  def render(assigns) do
    ~H"""
    <div class="mx-auto w-full max-w-5xl">
      <header class="mb-10">
        <h1 class="text-3xl font-semibold text-[color:var(--text)]">Examples</h1>
        <p class="mt-3 max-w-2xl text-[color:var(--text-muted)]">
          Each example shows a live preview, the LiveView that drives it, and the React
          component it renders — the real source, embedded at compile time, so what you
          read is what runs.
        </p>
        <p class="mt-3 max-w-2xl text-[color:var(--text-muted)]">
          Some examples run inside a LiveView with a socket. Others are plain
          controller-rendered pages, showing that React components work <strong>without</strong>
          a LiveView at all. Each example says which it is.
        </p>
      </header>

      <section :for={%{category: category, items: items} <- @categories} class="mb-10">
        <h2 class="mb-4 text-sm font-semibold uppercase tracking-wide text-[color:var(--text-muted)]">
          {category}
        </h2>

        <ul class="grid gap-4 sm:grid-cols-2">
          <li :for={item <- items}>
            <%!--
              Not `~p"/examples/#{item.id}"`: the router generates one literal
              route per ready example, never a dynamic `/examples/:slug` (see
              the same note in `ExampleComponents.example_page/1`), so a
              dynamic `~p` interpolation here can never verify and would warn
              permanently under `--warnings-as-errors`.
            --%>
            <.link
              :if={item.status == :ready}
              navigate={"/examples/#{item.id}"}
              class="block h-full rounded-lg border border-[color:var(--edge)] bg-[color:var(--surface-raised)] p-5 hover:border-brand"
            >
              <.card_body item={item} />
            </.link>

            <div
              :if={item.status != :ready}
              class="h-full rounded-lg border border-dashed border-[color:var(--edge)] p-5 opacity-60"
            >
              <.card_body item={item} />
              <p class="mt-3 text-xs text-[color:var(--text-muted)]">coming soon</p>
            </div>
          </li>
        </ul>
      </section>
    </div>
    """
  end

  attr :item, :map, required: true

  defp card_body(assigns) do
    ~H"""
    <div class="flex items-start gap-3">
      <span class={[@item.icon, "mt-0.5 h-5 w-5 flex-none text-brand"]} />
      <div>
        <h3 class="font-medium text-[color:var(--text)]">{@item.title}</h3>
        <p class="mt-1 text-sm text-[color:var(--text-muted)]">{@item.description}</p>
        <p class="mt-2 text-xs text-[color:var(--text-muted)]">
          {if @item.kind == :live, do: "LiveView", else: "no socket"}
        </p>
      </div>
    </div>
    """
  end
end
